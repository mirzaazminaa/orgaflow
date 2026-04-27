begin;

-- 1. Pastikan tidak ada duplicate dependency lama sebelum unique constraint dibuat.
delete from public.task_dependencies a
using public.task_dependencies b
where a.ctid < b.ctid
  and a.task_id = b.task_id
  and a.depends_on_task_id = b.depends_on_task_id;

alter table public.task_dependencies
drop constraint if exists task_dependencies_task_depends_unique;

alter table public.task_dependencies
add constraint task_dependencies_task_depends_unique
unique (task_id, depends_on_task_id);


-- 2. Function untuk validasi DAG:
--    - tidak boleh self dependency
--    - harus satu project
--    - tidak boleh membentuk cycle
create or replace function public.validate_task_dependency_dag()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_task_project_id uuid;
  v_dep_project_id uuid;
  v_cycle_found boolean;
begin
  if new.task_id is null or new.depends_on_task_id is null then
    raise exception
      using
        message = 'Task dan dependency wajib diisi.',
        errcode = '23502';
  end if;

  if new.task_id = new.depends_on_task_id then
    raise exception
      using
        message = 'Task tidak bisa bergantung pada dirinya sendiri.',
        errcode = '23514';
  end if;

  select project_id
    into v_task_project_id
  from public.tasks
  where id = new.task_id;

  select project_id
    into v_dep_project_id
  from public.tasks
  where id = new.depends_on_task_id;

  if v_task_project_id is null or v_dep_project_id is null then
    raise exception
      using
        message = 'Task dependency tidak valid.',
        errcode = '23503';
  end if;

  if v_task_project_id <> v_dep_project_id then
    raise exception
      using
        message = 'Dependency harus berasal dari project yang sama.',
        errcode = '23514';
  end if;

  /*
    Row meaning:
    task_id depends on depends_on_task_id.

    Adding:
    B depends on A

    Cycle exists if A already depends directly/indirectly on B.
  */
  with recursive dependency_chain(depends_on_task_id) as (
    select td.depends_on_task_id
    from public.task_dependencies td
    where td.task_id = new.depends_on_task_id
      and td.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)

    union

    select td.depends_on_task_id
    from public.task_dependencies td
    join dependency_chain dc
      on td.task_id = dc.depends_on_task_id
    where td.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  select exists (
    select 1
    from dependency_chain
    where depends_on_task_id = new.task_id
  )
  into v_cycle_found;

  if v_cycle_found then
    raise exception
      using
        message = 'Dependency membentuk cycle. Task dependency harus berupa DAG.',
        detail = 'Dependency ini akan membuat alur task saling menunggu.',
        errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_task_dependency_dag
on public.task_dependencies;

create trigger trg_validate_task_dependency_dag
before insert or update of task_id, depends_on_task_id
on public.task_dependencies
for each row
execute function public.validate_task_dependency_dag();


-- 3. Function untuk menghitung ulang status blocked berdasarkan dependency.
create or replace function public.recompute_project_task_blocking(
  p_project_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_project_id is null then
    return;
  end if;

  -- Task yang punya dependency belum done harus menjadi blocked,
  -- kecuali task tersebut sudah done.
  update public.tasks t
  set status = 'blocked'::public.task_status_enum
  where t.project_id = p_project_id
    and t.status <> 'done'::public.task_status_enum
    and t.status <> 'blocked'::public.task_status_enum
    and exists (
      select 1
      from public.task_dependencies td
      join public.tasks dep
        on dep.id = td.depends_on_task_id
      where td.task_id = t.id
        and dep.status <> 'done'::public.task_status_enum
    );

  -- Task blocked yang semua dependency-nya sudah done dibuka lagi ke todo.
  update public.tasks t
  set status = 'todo'::public.task_status_enum
  where t.project_id = p_project_id
    and t.status = 'blocked'::public.task_status_enum
    and not exists (
      select 1
      from public.task_dependencies td
      join public.tasks dep
        on dep.id = td.depends_on_task_id
      where td.task_id = t.id
        and dep.status <> 'done'::public.task_status_enum
    );
end;
$$;


-- 4. Trigger: setiap dependency berubah, status blocked dihitung ulang.
create or replace function public.recompute_task_blocking_after_dependency_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project_id uuid;
  v_old_project_id uuid;
begin
  if tg_op in ('INSERT', 'UPDATE') then
    select project_id
      into v_project_id
    from public.tasks
    where id = new.task_id;

    perform public.recompute_project_task_blocking(v_project_id);
  end if;

  if tg_op in ('UPDATE', 'DELETE') then
    select project_id
      into v_old_project_id
    from public.tasks
    where id = old.task_id;

    if v_old_project_id is not null
       and (v_project_id is null or v_project_id <> v_old_project_id) then
      perform public.recompute_project_task_blocking(v_old_project_id);
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_recompute_task_blocking_after_dependency_change
on public.task_dependencies;

create trigger trg_recompute_task_blocking_after_dependency_change
after insert or update or delete
on public.task_dependencies
for each row
execute function public.recompute_task_blocking_after_dependency_change();


-- 5. RPC admin untuk menambah dependency.
create or replace function public.add_task_dependency_dag(
  p_task_id uuid,
  p_depends_on_task_id uuid
)
returns public.task_dependencies
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  new_dependency public.task_dependencies;
begin
  if auth.uid() is null then
    raise exception
      using
        message = 'User belum login.',
        errcode = '28000';
  end if;

  if p_task_id is null or p_depends_on_task_id is null then
    raise exception
      using
        message = 'Task dan dependency wajib diisi.',
        errcode = '23502';
  end if;

  select p.organization_id
    into v_org_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception
      using
        message = 'Task tidak ditemukan.',
        errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using
        message = 'Hanya admin organisasi yang dapat mengatur dependency task.',
        errcode = '42501';
  end if;

  insert into public.task_dependencies (
    task_id,
    depends_on_task_id
  )
  values (
    p_task_id,
    p_depends_on_task_id
  )
  returning *
  into new_dependency;

  return new_dependency;
end;
$$;


-- 6. RPC admin untuk hapus dependency.
create or replace function public.delete_task_dependency_admin(
  p_dependency_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
begin
  if auth.uid() is null then
    raise exception
      using
        message = 'User belum login.',
        errcode = '28000';
  end if;

  if p_dependency_id is null then
    raise exception
      using
        message = 'Dependency wajib dipilih.',
        errcode = '23502';
  end if;

  select p.organization_id
    into v_org_id
  from public.task_dependencies td
  join public.tasks t on t.id = td.task_id
  join public.projects p on p.id = t.project_id
  where td.id = p_dependency_id;

  if v_org_id is null then
    raise exception
      using
        message = 'Dependency tidak ditemukan.',
        errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using
        message = 'Hanya admin organisasi yang dapat menghapus dependency task.',
        errcode = '42501';
  end if;

  delete from public.task_dependencies
  where id = p_dependency_id;
end;
$$;

revoke all on function public.add_task_dependency_dag(uuid, uuid) from public;
grant execute on function public.add_task_dependency_dag(uuid, uuid) to authenticated;

revoke all on function public.delete_task_dependency_admin(uuid) from public;
grant execute on function public.delete_task_dependency_admin(uuid) to authenticated;


-- 7. Perkuat RPC update status agar task yang masih terkunci tidak bisa dipindahkan.
create or replace function public.update_task_status_admin(
  p_task_id uuid,
  p_status text
)
returns public.tasks
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_task public.tasks;
  v_org_id uuid;
  v_project_id uuid;
  normalized_status_text text;
  normalized_status public.task_status_enum;
  v_has_unfinished_dependency boolean;
begin
  if auth.uid() is null then
    raise exception
      using
        message = 'User belum login.',
        errcode = '28000';
  end if;

  if p_task_id is null then
    raise exception
      using
        message = 'Task wajib dipilih.',
        errcode = '23502';
  end if;

  normalized_status_text :=
    lower(
      replace(
        replace(
          btrim(coalesce(p_status, '')),
          '-',
          '_'
        ),
        ' ',
        '_'
      )
    );

  normalized_status :=
    case normalized_status_text
      when 'backlog' then 'backlog'::public.task_status_enum
      when 'todo' then 'todo'::public.task_status_enum
      when 'in_progress' then 'in_progress'::public.task_status_enum
      when 'inprogress' then 'in_progress'::public.task_status_enum
      when 'in_review' then 'in_review'::public.task_status_enum
      when 'blocked' then 'blocked'::public.task_status_enum
      when 'done' then 'done'::public.task_status_enum
      else null
    end;

  if normalized_status is null then
    raise exception
      using
        message = 'Status task tidak valid.',
        detail = format('Status yang diterima: %s', p_status),
        errcode = '23514';
  end if;

  select p.organization_id, p.id
    into v_org_id, v_project_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception
      using
        message = 'Task tidak ditemukan.',
        errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using
        message = 'Hanya admin organisasi yang dapat mengubah status task.',
        errcode = '42501';
  end if;

  select exists (
    select 1
    from public.task_dependencies td
    join public.tasks dep
      on dep.id = td.depends_on_task_id
    where td.task_id = p_task_id
      and dep.status <> 'done'::public.task_status_enum
  )
  into v_has_unfinished_dependency;

  if v_has_unfinished_dependency
     and normalized_status <> 'blocked'::public.task_status_enum then
    raise exception
      using
        message = 'Task masih terkunci karena dependency belum selesai.',
        detail = 'Selesaikan semua dependency task terlebih dahulu.',
        errcode = '23514';
  end if;

  update public.tasks
  set status = normalized_status
  where id = p_task_id
  returning *
  into updated_task;

  perform public.recompute_project_task_blocking(v_project_id);

  select *
    into updated_task
  from public.tasks
  where id = p_task_id;

  return updated_task;
end;
$$;

revoke all on function public.update_task_status_admin(uuid, text) from public;
grant execute on function public.update_task_status_admin(uuid, text) to authenticated;


-- 8. Recompute existing data untuk project yang sudah punya dependency.
do $$
declare
  project_record record;
begin
  for project_record in
    select distinct t.project_id
    from public.task_dependencies td
    join public.tasks t on t.id = td.task_id
  loop
    perform public.recompute_project_task_blocking(project_record.project_id);
  end loop;
end;
$$;

commit;