import '../../../../core/result/result.dart';
import '../../data/repositories/task_dependency_repository.dart';
import '../../domain/models/dependency_graph_data.dart';
import '../../domain/models/manage_dependency_data.dart';

class ManageDependencyPresenter {
  ManageDependencyPresenter({
    TaskDependencyRepository? repository,
  }) : _repository = repository ?? TaskDependencyRepository();

  final TaskDependencyRepository _repository;

  Future<Result<ManageDependencyData>> loadData({
    required String taskId,
    required String projectId,
  }) {
    return _repository.fetchData(
      taskId: taskId,
      projectId: projectId,
    );
  }

  Future<Result<void>> addDependency({
    required String taskId,
    required String dependsOnTaskId,
  }) {
    return _repository.addDependency(
      taskId: taskId,
      dependsOnTaskId: dependsOnTaskId,
    );
  }

  Future<Result<void>> deleteDependency(String dependencyId) {
    return _repository.deleteDependency(dependencyId);
  }

  Future<Result<DependencyGraphData>> fetchProjectDependencyGraph(
    String projectId,
  ) {
    return _repository.fetchProjectDependencyGraph(projectId: projectId);
  }
}
