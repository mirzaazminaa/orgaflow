import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/task_skill_requirement_model.dart';

class TaskRemoteDatasource {
  TaskRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
    DateTime? dueDate,
  }) async {
    final response = await _client.rpc(
      'create_task_with_requirements',
      params: {
        'p_project_id': projectId,
        'p_title': title,
        'p_description': description,
        'p_estimated_hours': estimatedHours,
        'p_priority': priority,
        'p_due_date': dueDate?.toIso8601String().split('T').first,
        'p_requirements': skillRequirements
            .map((requirement) => requirement.toJson())
            .toList(),
      },
    );

    return TaskModel.fromJson(
      _extractSingleRow(
        response,
        fallbackMessage: 'Response create task dari server tidak valid.',
      ),
    );
  }

  Future<TaskModel> updateTaskWithRequirements({
    required String taskId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
    DateTime? dueDate,
  }) async {
    final response = await _client.rpc(
      'update_task_with_requirements',
      params: {
        'p_task_id': taskId,
        'p_title': title,
        'p_description': description,
        'p_estimated_hours': estimatedHours,
        'p_priority': priority,
        'p_due_date': dueDate?.toIso8601String().split('T').first,
        'p_requirements': skillRequirements
            .map((requirement) => requirement.toJson())
            .toList(),
      },
    );

    return TaskModel.fromJson(
      _extractSingleRow(
        response,
        fallbackMessage: 'Response update task dari server tidak valid.',
      ),
    );
  }

  Future<void> deleteTask({
    required String taskId,
  }) async {
    await _client.rpc(
      'delete_task_cascade',
      params: {
        'p_task_id': taskId,
      },
    );
  }

  Future<List<TaskSkillOptionModel>> fetchActiveSkills() async {
    final response = await _client
        .from('skills')
        .select('id, name, category_code, is_active, sort_order')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map(
          (json) => TaskSkillOptionModel.fromSkillRow(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .where((skill) => skill.hasValidIdentity)
        .toList();
  }

  Future<List<TaskModel>> fetchTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select(
          'id, project_id, parent_task_id, title, description, '
          'estimated_hours, priority, status, due_date, sort_order, '
          'created_by, created_at, updated_at',
        )
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();

    debugPrint('TaskRemoteDatasource.fetchTasks fetched ${rows.length} tasks');
    if (rows.isNotEmpty &&
        (rows.first['title'] as String?)?.trim().isEmpty != false) {
      debugPrint(
          'TaskRemoteDatasource.fetchTasks first raw task: ${rows.first}');
    }

    return rows.map(TaskModel.fromJson).toList();
  }

  Future<Map<String, List<TaskAssigneeModel>>> fetchAssignmentsForTasks(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) {
      return const {};
    }

    final response = await _client
        .from('task_assignments')
        .select(
          'task_id, member_id, '
          'members(id, profile_id, profiles(full_name))',
        )
        .inFilter('task_id', taskIds);

    final assigneesByTaskId = <String, List<TaskAssigneeModel>>{};
    for (final json in response as List<dynamic>) {
      final row = Map<String, dynamic>.from(json as Map);
      final taskId = row['task_id'] as String?;
      if (taskId == null) {
        continue;
      }

      final assignee = TaskAssigneeModel.fromAssignmentJson(row);
      if (assignee.memberId.trim().isEmpty) {
        continue;
      }

      assigneesByTaskId.putIfAbsent(taskId, () => <TaskAssigneeModel>[]);
      assigneesByTaskId[taskId]!.add(assignee);
    }

    return assigneesByTaskId;
  }

  Future<Map<String, List<TaskSkillRequirementModel>>>
      fetchSkillRequirementsForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) {
      return const {};
    }

    final response = await _client
        .from('task_skill_requirements')
        .select('id, task_id, skill_id, minimum_level, priority_weight')
        .inFilter('task_id', taskIds);

    final requirementRows = (response as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();

    if (requirementRows.isEmpty) {
      return const {};
    }

    final skillIds = requirementRows
        .map((row) => row['skill_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final skillNameById = <String, String>{};
    if (skillIds.isNotEmpty) {
      final skillResponse = await _client
          .from('skills')
          .select('id, name, category_code')
          .inFilter('id', skillIds);

      for (final json in skillResponse as List<dynamic>) {
        final row = Map<String, dynamic>.from(json as Map);
        final id = row['id'] as String?;
        final name = row['name'] as String?;
        if (id != null && name != null) {
          skillNameById[id] = name;
        }
      }
    }

    final requirementsByTaskId = <String, List<TaskSkillRequirementModel>>{};
    for (final row in requirementRows) {
      final taskId = row['task_id'] as String?;
      final skillId = row['skill_id'] as String? ?? '';
      if (taskId == null) {
        continue;
      }

      requirementsByTaskId.putIfAbsent(
        taskId,
        () => <TaskSkillRequirementModel>[],
      );
      requirementsByTaskId[taskId]!.add(
        TaskSkillRequirementModel.fromJson({
          ...row,
          'skill_name': skillNameById[skillId] ?? '',
        }),
      );
    }

    return requirementsByTaskId;
  }

  Future<List<Map<String, dynamic>>> fetchDependencies(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) {
      return const [];
    }

    final response = await _client
        .from('task_dependencies')
        .select('task_id, depends_on_task_id')
        .inFilter('task_id', taskIds);

    return (response as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();
  }

  Future<List<TaskModel>> fetchTasksByIds(List<String> taskIds) async {
    if (taskIds.isEmpty) {
      return const [];
    }

    final response =
        await _client.from('tasks').select().inFilter('id', taskIds);

    return (response as List<dynamic>)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> updateTaskStatusAdmin({
    required String taskId,
    required String status,
  }) async {
    final response = await _client.rpc(
      'update_task_status_admin',
      params: {
        'p_task_id': taskId,
        'p_status': status,
      },
    );

    return TaskModel.fromJson(
      _extractSingleRow(
        response,
        fallbackMessage: 'Response update status task dari server tidak valid.',
      ),
    );
  }

  Future<TaskModel> updateTaskStatus({
    required String taskId,
    required String status,
  }) {
    return updateTaskStatusAdmin(taskId: taskId, status: status);
  }

  Future<TaskModel> updateAssignedTaskProgress({
    required String taskId,
    required String status,
  }) async {
    final response = await _client.rpc(
      'update_assigned_task_progress',
      params: {
        'p_task_id': taskId,
        'p_status': status,
      },
    );

    return TaskModel.fromJson(
      _extractSingleRow(
        response,
        fallbackMessage:
            'Response update progres task dari server tidak valid.',
      ),
    );
  }

  Future<void> recomputeProjectTaskBlocking({
    required String projectId,
  }) async {
    await _client.rpc(
      'recompute_project_task_blocking',
      params: {
        'p_project_id': projectId,
      },
    );
  }

  Map<String, dynamic> _extractSingleRow(
    dynamic response, {
    required String fallbackMessage,
  }) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    throw AppError(fallbackMessage);
  }
}
