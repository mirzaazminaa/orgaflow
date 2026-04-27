import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../../task/domain/models/task_model.dart';
import '../../domain/models/dependency_graph_data.dart';
import '../../domain/models/manage_dependency_data.dart';
import '../../domain/models/task_dependency_model.dart';

class TaskDependencyRemoteDatasource {
  TaskDependencyRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<ManageDependencyData> fetchData({
    required String taskId,
    required String projectId,
  }) async {
    final normalizedTaskId = taskId.trim();
    final normalizedProjectId = projectId.trim();

    final responses = await Future.wait<dynamic>([
      _client
          .from('tasks')
          .select()
          .eq('project_id', normalizedProjectId)
          .neq('id', normalizedTaskId)
          .order('created_at', ascending: false),
      _client
          .from('task_dependencies')
          .select(
            'id, depends_on_task_id, tasks!task_dependencies_depends_on_task_id_fkey(title)',
          )
          .eq('task_id', normalizedTaskId),
    ]);

    final dependencies = (responses[1] as List<dynamic>).map((json) {
      final item = Map<String, dynamic>.from(json as Map);
      final taskRelation = item['tasks'];

      String title = 'Task tidak ditemukan';
      if (taskRelation is Map<String, dynamic>) {
        title = taskRelation['title'] as String? ?? title;
      } else if (taskRelation is List && taskRelation.isNotEmpty) {
        final relationMap =
            Map<String, dynamic>.from(taskRelation.first as Map);
        title = relationMap['title'] as String? ?? title;
      }

      return TaskDependencyModel(
        id: item['id'] as String,
        dependsOnTaskId: item['depends_on_task_id'] as String,
        dependsOnTaskTitle: title,
      );
    }).toList();

    final existingDependencyTaskIds =
        dependencies.map((dependency) => dependency.dependsOnTaskId).toSet();
    final tasks = (responses[0] as List<dynamic>)
        .map((json) =>
            TaskModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .where((task) => !existingDependencyTaskIds.contains(task.id))
        .toList();

    return ManageDependencyData(
      tasks: tasks,
      dependencies: dependencies,
    );
  }

  Future<void> addDependency({
    required String taskId,
    required String dependsOnTaskId,
  }) async {
    final normalizedTaskId = taskId.trim();
    final normalizedDependsOnTaskId = dependsOnTaskId.trim();

    if (normalizedTaskId.isEmpty || normalizedDependsOnTaskId.isEmpty) {
      throw const AppError('Task dependency tidak valid.');
    }

    if (normalizedTaskId == normalizedDependsOnTaskId) {
      throw const AppError('Task tidak bisa bergantung pada dirinya sendiri.');
    }

    await _client.rpc('add_task_dependency_dag', params: {
      'p_task_id': normalizedTaskId,
      'p_depends_on_task_id': normalizedDependsOnTaskId,
    });
  }

  Future<void> deleteDependency(String dependencyId) async {
    final normalizedDependencyId = dependencyId.trim();
    if (normalizedDependencyId.isEmpty) {
      throw const AppError('Dependency tidak valid.');
    }

    await _client.rpc('delete_task_dependency_admin', params: {
      'p_dependency_id': normalizedDependencyId,
    });
  }

  Future<DependencyGraphData> fetchProjectDependencyGraph({
    required String projectId,
  }) async {
    final normalizedProjectId = projectId.trim();
    if (normalizedProjectId.isEmpty) {
      throw const AppError('Project tidak valid.');
    }

    final taskResponse = await _client
        .from('tasks')
        .select(
          'id, project_id, parent_task_id, title, description, '
          'estimated_hours, priority, status, due_date, sort_order, '
          'created_by, created_at, updated_at',
        )
        .eq('project_id', normalizedProjectId)
        .order('created_at', ascending: false);

    final taskRows = (taskResponse as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();
    final tasks = taskRows.map(TaskModel.fromJson).toList();
    final taskIds = tasks.map((task) => task.id).toSet();

    if (taskIds.isEmpty) {
      return const DependencyGraphData(nodes: [], edges: []);
    }

    final dependencyResponse = await _client
        .from('task_dependencies')
        .select('id, task_id, depends_on_task_id')
        .inFilter('task_id', taskIds.toList());

    final edges = (dependencyResponse as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .where((row) {
          final dependentTaskId = row['task_id'] as String?;
          final prerequisiteTaskId = row['depends_on_task_id'] as String?;
          return dependentTaskId != null &&
              prerequisiteTaskId != null &&
              taskIds.contains(dependentTaskId) &&
              taskIds.contains(prerequisiteTaskId);
        })
        .map(
          (row) => DependencyGraphEdge(
            dependencyId: row['id'] as String,
            fromTaskId: row['depends_on_task_id'] as String,
            toTaskId: row['task_id'] as String,
          ),
        )
        .toList();

    return DependencyGraphData(
      nodes: tasks.map(DependencyGraphNode.fromTaskModel).toList(),
      edges: edges,
    );
  }
}
