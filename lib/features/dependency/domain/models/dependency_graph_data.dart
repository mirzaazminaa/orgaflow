import '../../../task/domain/models/task_model.dart';

class DependencyGraphData {
  const DependencyGraphData({
    required this.nodes,
    required this.edges,
  });

  final List<DependencyGraphNode> nodes;
  final List<DependencyGraphEdge> edges;

  bool get hasTasks => nodes.isNotEmpty;

  bool get hasDependencies => edges.isNotEmpty;
}

class DependencyGraphNode {
  const DependencyGraphNode({
    required this.taskId,
    required this.title,
    required this.description,
    required this.status,
    required this.isBlocked,
    required this.isLocked,
    required this.estimatedHours,
  });

  final String taskId;
  final String title;
  final String description;
  final String status;
  final bool isBlocked;
  final bool isLocked;
  final int estimatedHours;

  factory DependencyGraphNode.fromTaskModel(TaskModel task) {
    final normalizedStatus = _normalizeStatus(task.status);

    return DependencyGraphNode(
      taskId: task.id,
      title: task.title.trim().isNotEmpty ? task.title.trim() : 'Untitled Task',
      description: task.description?.trim() ?? '',
      status: normalizedStatus,
      isBlocked: normalizedStatus == 'blocked',
      isLocked: normalizedStatus == 'blocked',
      estimatedHours: task.estimatedHours,
    );
  }

  static String _normalizeStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('-', '_');
    return normalized.isNotEmpty ? normalized : 'backlog';
  }
}

class DependencyGraphEdge {
  const DependencyGraphEdge({
    required this.dependencyId,
    required this.fromTaskId,
    required this.toTaskId,
  });

  final String dependencyId;
  final String fromTaskId;
  final String toTaskId;
}
