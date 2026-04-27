import 'package:flutter/material.dart';

import '../../../dependency/domain/models/dependency_graph_data.dart';
import '../../../dependency/presentation/presenters/manage_dependency_presenter.dart';
import '../../models/task_model.dart';
import 'dependency_graph_view.dart';

class WorkflowTab extends StatefulWidget {
  const WorkflowTab({
    super.key,
    required this.projectId,
    required this.tasks,
  });

  final String projectId;
  final List<Task> tasks;

  @override
  State<WorkflowTab> createState() => _WorkflowTabState();
}

class _WorkflowTabState extends State<WorkflowTab> {
  final ManageDependencyPresenter _dependencyPresenter =
      ManageDependencyPresenter();

  DependencyGraphData? _graphData;
  bool _isLoadingGraph = true;
  String? _graphError;

  List<Task> get _readyTasks => widget.tasks.where((task) {
        if (task.status == TaskStatus.done) {
          return false;
        }
        return !task.isBlocked;
      }).toList();

  List<Task> get _blockedTasks =>
      widget.tasks.where((task) => task.isBlocked).toList();

  Map<String, int> get _dependencyCountByTaskId {
    final graphData = _graphData;
    if (graphData == null) {
      return const {};
    }

    final counts = <String, int>{};
    for (final edge in graphData.edges) {
      counts[edge.toTaskId] = (counts[edge.toTaskId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  @override
  void didUpdateWidget(covariant WorkflowTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadGraph();
    }
  }

  Future<void> _loadGraph() async {
    setState(() {
      _isLoadingGraph = true;
      _graphError = null;
    });

    final result = await _dependencyPresenter.fetchProjectDependencyGraph(
      widget.projectId,
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isLoadingGraph = false;
        _graphError = result.error!.message;
      });
      return;
    }

    setState(() {
      _graphData = result.data!;
      _isLoadingGraph = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 900;
    final dependencyCountByTaskId = _dependencyCountByTaskId;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphCard(),
          const SizedBox(height: 24),
          isSmall
              ? Column(
                  children: [
                    _buildTaskListCard(
                      'Ready Tasks',
                      _readyTasks,
                      const Color(0xFF00B894),
                      Icons.check_circle_outline,
                      dependencyCountByTaskId,
                    ),
                    const SizedBox(height: 20),
                    _buildTaskListCard(
                      'Blocked Tasks',
                      _blockedTasks,
                      Colors.orange,
                      Icons.block,
                      dependencyCountByTaskId,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTaskListCard(
                        'Ready Tasks',
                        _readyTasks,
                        const Color(0xFF00B894),
                        Icons.check_circle_outline,
                        dependencyCountByTaskId,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTaskListCard(
                        'Blocked Tasks',
                        _blockedTasks,
                        Colors.orange,
                        Icons.block,
                        dependencyCountByTaskId,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildGraphCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dependency Graph',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendDot(const Color(0xFF10B981), 'Done'),
                  _buildLegendDot(const Color(0xFFFB923C), 'Blocked'),
                  _buildLegendDot(const Color(0xFF7C3AED), 'In Progress'),
                  _buildLegendDot(const Color(0xFF94A3B8), 'Backlog'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGraphContent(),
        ],
      ),
    );
  }

  Widget _buildGraphContent() {
    if (_isLoadingGraph) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_graphError != null) {
      return _GraphStateMessage(
        icon: Icons.error_outline,
        title: 'Graph gagal dimuat',
        message: _graphError!,
        actionLabel: 'Coba Lagi',
        onAction: _loadGraph,
      );
    }

    final graphData = _graphData;
    if (graphData == null || !graphData.hasTasks) {
      return const _GraphStateMessage(
        icon: Icons.account_tree_outlined,
        title: 'Belum ada task',
        message: 'Task yang dibuat di project ini akan muncul sebagai node.',
      );
    }

    if (!graphData.hasDependencies) {
      return const _GraphStateMessage(
        icon: Icons.account_tree_outlined,
        title: 'Belum ada dependency',
        message: 'Hubungkan task dengan dependency untuk membentuk graph DAG.',
      );
    }

    return DependencyGraphView(graphData: graphData);
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTaskListCard(
    String title,
    List<Task> taskList,
    Color color,
    IconData icon,
    Map<String, int> dependencyCountByTaskId,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${taskList.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (taskList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Tidak ada task',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ...taskList.map(
              (task) => _buildTaskItem(
                task,
                color,
                dependencyCountByTaskId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    Task task,
    Color color,
    Map<String, int> dependencyCountByTaskId,
  ) {
    final dependencyCount =
        dependencyCountByTaskId[task.sourceTaskId] ?? task.dependencies.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (dependencyCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$dependencyCount deps',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '${task.estimatedHours}h',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GraphStateMessage extends StatelessWidget {
  const _GraphStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
