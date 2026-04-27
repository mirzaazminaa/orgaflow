import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/task_skill_requirement_model.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepository {
  TaskRepository({
    TaskRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? TaskRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final TaskRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<TaskModel>> createTask({
    required String projectId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
  }) async {
    try {
      await _requireManageContext();

      if (title.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Judul task wajib diisi.'),
        );
      }

      if (estimatedHours <= 0) {
        return Result<TaskModel>.failure(
          const AppError('Estimasi jam wajib lebih dari 0.'),
        );
      }

      final validSkillRequirements =
          _normalizeSkillRequirements(skillRequirements);

      final task = await _remoteDatasource.createTask(
        projectId: projectId,
        title: title.trim(),
        description: description.trim(),
        estimatedHours: estimatedHours,
        priority: priority,
        skillRequirements: validSkillRequirements,
      );

      return Result<TaskModel>.success(task);
    } catch (error) {
      return Result<TaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<TaskModel>> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
    DateTime? dueDate,
  }) async {
    try {
      await _requireManageContext();

      if (taskId.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      if (title.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Judul task wajib diisi.'),
        );
      }

      if (estimatedHours <= 0) {
        return Result<TaskModel>.failure(
          const AppError('Estimasi jam wajib lebih dari 0.'),
        );
      }

      final validSkillRequirements =
          _normalizeSkillRequirements(skillRequirements);

      final task = await _remoteDatasource.updateTaskWithRequirements(
        taskId: taskId.trim(),
        title: title.trim(),
        description: description.trim(),
        estimatedHours: estimatedHours,
        priority: priority,
        dueDate: dueDate,
        skillRequirements: validSkillRequirements,
      );

      return Result<TaskModel>.success(task);
    } catch (error) {
      return Result<TaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteTask(String taskId) async {
    try {
      await _requireManageContext();

      if (taskId.trim().isEmpty) {
        return Result<void>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      await _remoteDatasource.deleteTask(taskId: taskId.trim());
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<TaskModel>>> fetchTasks(String projectId) async {
    try {
      final tasks = await _remoteDatasource.fetchTasks(projectId);
      final taskIds = tasks.map((task) => task.id).toList();
      final context = await _sessionService.getCurrentContext();
      final currentMemberId = context?.activeMember?.id;

      final relatedData = await Future.wait<dynamic>([
        _remoteDatasource.fetchSkillRequirementsForTasks(taskIds),
        _remoteDatasource.fetchAssignmentsForTasks(taskIds),
      ]);

      final requirementsByTaskId =
          relatedData[0] as Map<String, List<TaskSkillRequirementModel>>;
      final assigneesByTaskId =
          relatedData[1] as Map<String, List<TaskAssigneeModel>>;

      final tasksWithRelatedData = tasks
          .map(
            (task) => task.copyWith(
              skillRequirements: requirementsByTaskId[task.id] ?? const [],
              assignees: _markCurrentUserAssignees(
                assigneesByTaskId[task.id] ?? const [],
                currentMemberId,
              ),
            ),
          )
          .toList();

      return Result<List<TaskModel>>.success(tasksWithRelatedData);
    } catch (error) {
      return Result<List<TaskModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<TaskSkillOptionModel>>> fetchActiveSkills() async {
    try {
      final skills = await _remoteDatasource.fetchActiveSkills();
      return Result<List<TaskSkillOptionModel>>.success(skills);
    } catch (error) {
      return Result<List<TaskSkillOptionModel>>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<void>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final normalizedTaskId = taskId.trim();
      if (normalizedTaskId.isEmpty) {
        return Result<void>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      final normalizedStatus = _normalizeTaskStatus(status);
      final context = await _requireActiveContext();

      if (_canManageContext(context)) {
        await _remoteDatasource.updateTaskStatusAdmin(
          taskId: normalizedTaskId,
          status: normalizedStatus,
        );
      } else {
        await _remoteDatasource.updateAssignedTaskProgress(
          taskId: normalizedTaskId,
          status: normalizedStatus,
        );
      }
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> evaluateTaskStatuses(String projectId) async {
    try {
      final normalizedProjectId = projectId.trim();
      if (normalizedProjectId.isEmpty) {
        return Result<void>.failure(
          const AppError('Project tidak valid.'),
        );
      }

      await _remoteDatasource.recomputeProjectTaskBlocking(
        projectId: normalizedProjectId,
      );
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<bool> canManageTasks({
    bool refresh = false,
  }) async {
    final context = await _sessionService.getCurrentContext(refresh: refresh);
    return _canManageContext(context);
  }

  List<TaskSkillRequirementInput> _normalizeSkillRequirements(
    List<TaskSkillRequirementInput> skillRequirements,
  ) {
    final validSkillRequirements = skillRequirements
        .where((requirement) => requirement.skillId.trim().isNotEmpty)
        .map(
          (requirement) => TaskSkillRequirementInput(
            skillId: requirement.skillId.trim(),
            minimumLevel: requirement.minimumLevel,
            priorityWeight: requirement.priorityWeight,
          ),
        )
        .toList();

    if (validSkillRequirements.isEmpty) {
      throw const AppError('Minimal satu skill requirement wajib dipilih.');
    }

    return validSkillRequirements;
  }

  String _normalizeTaskStatus(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    const validStatuses = {
      'backlog',
      'todo',
      'in_progress',
      'in_review',
      'done',
      'blocked',
      'cancelled',
    };

    if (!validStatuses.contains(normalizedStatus)) {
      throw const AppError('Status task tidak valid.');
    }

    return normalizedStatus;
  }

  bool _canManageContext(SessionContext? context) {
    final activeMember = context?.activeMember;
    if (activeMember == null) {
      return false;
    }

    final role = activeMember.role.toLowerCase();
    final positionCode = activeMember.positionCode?.toLowerCase();

    return activeMember.isOwner ||
        role == 'admin' ||
        role == 'kadep' ||
        role == 'ketua_divisi' ||
        role == 'kepala_departemen' ||
        positionCode == 'kadep' ||
        positionCode == 'ketua_divisi' ||
        positionCode == 'kepala_departemen' ||
        positionCode == 'koordinator_divisi';
  }

  List<TaskAssigneeModel> _markCurrentUserAssignees(
    List<TaskAssigneeModel> assignees,
    String? currentMemberId,
  ) {
    if (assignees.isEmpty) {
      return const [];
    }

    final normalizedCurrentMemberId = currentMemberId?.trim();
    return assignees
        .map(
          (assignee) => assignee.copyWith(
            isCurrentUser: normalizedCurrentMemberId != null &&
                normalizedCurrentMemberId.isNotEmpty &&
                assignee.memberId == normalizedCurrentMemberId,
          ),
        )
        .toList();
  }

  Future<SessionContext> _requireActiveContext() async {
    if (_sessionService.currentUserId == null) {
      throw const AppError('User belum login.');
    }

    final context = await _sessionService.getCurrentContext(refresh: true);

    if (context == null || context.activeMember == null) {
      throw const AppError('User belum memiliki membership aktif.');
    }

    return context;
  }

  Future<SessionContext> _requireManageContext() async {
    final context = await _requireActiveContext();

    if (!_canManageContext(context)) {
      throw const AppError(
        'Anda tidak memiliki izin untuk mengelola task.',
      );
    }

    return context;
  }
}
