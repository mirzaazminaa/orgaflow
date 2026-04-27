import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/dependency_graph_data.dart';
import '../../domain/models/manage_dependency_data.dart';
import '../datasources/task_dependency_remote_datasource.dart';

class TaskDependencyRepository {
  TaskDependencyRepository({
    TaskDependencyRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource = remoteDatasource ?? TaskDependencyRemoteDatasource();

  final TaskDependencyRemoteDatasource _remoteDatasource;

  Future<Result<ManageDependencyData>> fetchData({
    required String taskId,
    required String projectId,
  }) async {
    try {
      final data = await _remoteDatasource.fetchData(
        taskId: taskId,
        projectId: projectId,
      );
      return Result<ManageDependencyData>.success(data);
    } catch (error) {
      return Result<ManageDependencyData>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> addDependency({
    required String taskId,
    required String dependsOnTaskId,
  }) async {
    try {
      await _remoteDatasource.addDependency(
        taskId: taskId,
        dependsOnTaskId: dependsOnTaskId,
      );
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteDependency(String dependencyId) async {
    try {
      await _remoteDatasource.deleteDependency(dependencyId);
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<DependencyGraphData>> fetchProjectDependencyGraph({
    required String projectId,
  }) async {
    try {
      final data = await _remoteDatasource.fetchProjectDependencyGraph(
        projectId: projectId,
      );
      return Result<DependencyGraphData>.success(data);
    } catch (error) {
      return Result<DependencyGraphData>.failure(ErrorMapper.map(error));
    }
  }
}
