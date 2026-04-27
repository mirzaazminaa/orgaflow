import '../../task/domain/models/task_model.dart' as task_domain;
import '../../task/domain/models/task_skill_requirement_model.dart';

enum TaskStatus { backlog, todo, inProgress, done }

extension TaskStatusDatabaseValue on TaskStatus {
  String get databaseValue {
    switch (this) {
      case TaskStatus.backlog:
        return 'backlog';
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }
}

class Task {
  final int id;
  final String? sourceTaskId;
  final String title;
  final String description;
  final String assignee;
  final List<task_domain.TaskAssigneeModel> assignees;
  final bool isAssignedToCurrentUser;
  final bool canCurrentUserUpdateProgress;
  final TaskStatus status;
  final String databaseStatus;
  final double estimatedHours;
  final String priority;
  final DateTime? dueDate;
  final List<String> skills;
  final List<TaskSkillRequirementModel> skillRequirements;
  final List<int> dependencies;

  Task({
    required this.id,
    this.sourceTaskId,
    required this.title,
    required this.description,
    required this.assignee,
    this.assignees = const [],
    this.isAssignedToCurrentUser = false,
    this.canCurrentUserUpdateProgress = false,
    required this.status,
    required this.databaseStatus,
    required this.estimatedHours,
    this.priority = 'medium',
    this.dueDate,
    required this.skills,
    this.skillRequirements = const [],
    required this.dependencies,
  });

  factory Task.fromTaskModel(
    task_domain.TaskModel task, {
    bool canManageTasks = false,
  }) {
    final title = task.title.trim();
    final description = task.description?.trim() ?? '';
    final skills = task.skillRequirements
        .map((requirement) => requirement.skillName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    return Task(
      id: _intIdFromTaskId(task.id),
      sourceTaskId: task.id,
      title: title.isNotEmpty ? title : 'Untitled Task',
      description: description,
      assignee: _assigneeLabel(task.assignees),
      assignees: task.assignees,
      isAssignedToCurrentUser: task.isAssignedToCurrentUser,
      canCurrentUserUpdateProgress:
          canManageTasks || task.isAssignedToCurrentUser,
      status: _statusFromTaskModel(task.status),
      databaseStatus: _normalizeDatabaseStatus(task.status),
      estimatedHours: task.estimatedHours.toDouble(),
      priority: task.priority,
      dueDate: task.dueDate,
      skills: skills,
      skillRequirements: task.skillRequirements,
      dependencies: const [],
    );
  }

  Task copyWith({
    int? id,
    String? sourceTaskId,
    String? title,
    String? description,
    String? assignee,
    List<task_domain.TaskAssigneeModel>? assignees,
    bool? isAssignedToCurrentUser,
    bool? canCurrentUserUpdateProgress,
    TaskStatus? status,
    String? databaseStatus,
    double? estimatedHours,
    String? priority,
    DateTime? dueDate,
    List<String>? skills,
    List<TaskSkillRequirementModel>? skillRequirements,
    List<int>? dependencies,
  }) {
    return Task(
      id: id ?? this.id,
      sourceTaskId: sourceTaskId ?? this.sourceTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      assignees: assignees ?? this.assignees,
      isAssignedToCurrentUser:
          isAssignedToCurrentUser ?? this.isAssignedToCurrentUser,
      canCurrentUserUpdateProgress:
          canCurrentUserUpdateProgress ?? this.canCurrentUserUpdateProgress,
      status: status ?? this.status,
      databaseStatus: databaseStatus ??
          (status != null ? status.databaseValue : this.databaseStatus),
      estimatedHours: estimatedHours ?? this.estimatedHours,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      skills: skills ?? this.skills,
      skillRequirements: skillRequirements ?? this.skillRequirements,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  String get initials {
    final source = assignees.isNotEmpty ? assignees.first.fullName : assignee;
    final names = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((name) => name.isNotEmpty)
        .take(2);

    return names.map((name) => name.substring(0, 1).toUpperCase()).join();
  }

  bool get isBlocked => databaseStatus == 'blocked';

  bool get isLocked => isBlocked;

  static int _intIdFromTaskId(String taskId) {
    final normalized = taskId.replaceAll('-', '');
    final prefix =
        normalized.length >= 8 ? normalized.substring(0, 8) : normalized;

    return int.tryParse(prefix, radix: 16) ?? taskId.hashCode;
  }

  static TaskStatus _statusFromTaskModel(String status) {
    switch (_normalizeDatabaseStatus(status)) {
      case 'todo':
        return TaskStatus.todo;
      case 'in_progress':
      case 'in_review':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'backlog':
      case 'blocked':
      default:
        return TaskStatus.backlog;
    }
  }

  static String _normalizeDatabaseStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('-', '_');
    return normalized.isNotEmpty ? normalized : 'backlog';
  }

  static String _assigneeLabel(
    List<task_domain.TaskAssigneeModel> assignees,
  ) {
    if (assignees.isEmpty) {
      return '';
    }

    if (assignees.length > 1) {
      return '${assignees.length} assignees';
    }

    return assignees.first.fullName.trim();
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final TaskStatus status;
  final int color;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.status,
    required this.color,
  });
}
