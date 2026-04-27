import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class KanbanTab extends StatefulWidget {
  final List<Task> tasks;
  final List<KanbanColumn> columns;
  final bool canManageTasks;
  final Future<void> Function(int taskId, TaskStatus newStatus) onMoveTask;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  const KanbanTab({
    super.key,
    required this.tasks,
    required this.columns,
    required this.canManageTasks,
    required this.onMoveTask,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  State<KanbanTab> createState() => _KanbanTabState();
}

class _KanbanTabState extends State<KanbanTab> {
  List<Task> _getTasksByStatus(TaskStatus status) {
    return widget.tasks.where((task) => task.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text('Kanban board untuk manajemen task proyek',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const Spacer(),
              if (!isSmallScreen && widget.canManageTasks)
                ElevatedButton.icon(
                  onPressed: widget.onAddTask,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // Board — no Expanded, let it size itself
        isSmallScreen || isMediumScreen
            ? _buildScrollableBoard()
            : _buildGridBoard(),
      ],
    );
  }

  Widget _buildScrollableBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Container(
              width: 320,
              margin: const EdgeInsets.only(right: 16),
              child: _buildColumn(column, tasks),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridBoard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildColumn(column, tasks),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColumn(KanbanColumn column, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: Color(column.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(column.title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text('${tasks.length}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        // Body — ConstrainedBox replaces Expanded for unbounded parent compatibility
        DragTarget<Task>(
          onWillAcceptWithDetails: (details) =>
              _canUpdateTaskProgress(details.data) &&
              details.data.status != column.status,
          onAcceptWithDetails: (details) async {
            if (details.data.isLocked) {
              _showLockedTaskMessage();
              return;
            }
            if (!_canUpdateTaskProgress(details.data)) {
              return;
            }
            await widget.onMoveTask(details.data.id, column.status);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isHovering
                      ? Color(column.color).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isHovering ? Color(column.color) : Colors.grey.shade200,
                    width: isHovering ? 2 : 1,
                  ),
                ),
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                            widget.canManageTasks
                                ? 'Drop task here'
                                : 'Belum ada task',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ))
                    : Column(
                        children: tasks
                            .map((t) => _buildTaskCard(t, column.color))
                            .toList(),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task, int columnColor) {
    final card = _buildTaskCardSurface(task, columnColor);
    final canUpdateProgress = _canUpdateTaskProgress(task);

    if (task.isLocked) {
      return Tooltip(
        message: 'Task masih terkunci karena dependency belum selesai',
        child: GestureDetector(
          onLongPress: _showLockedTaskMessage,
          child: card,
        ),
      );
    }

    if (!canUpdateProgress) {
      return card;
    }

    return Draggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: Opacity(
            opacity: 0.8,
            child: _buildTaskCardSurface(task, columnColor),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardSurface(task, columnColor),
      ),
      child: card,
    );
  }

  Widget _buildTaskCardSurface(Task task, int columnColor) {
    return Material(
      color: Colors.transparent,
      child: _buildCardContent(task, columnColor),
    );
  }

  Widget _buildCardContent(Task task, int columnColor) {
    final title =
        task.title.trim().isNotEmpty ? task.title.trim() : 'Untitled Task';
    final description = task.description.trim();
    final estimatedHours = task.estimatedHours % 1 == 0
        ? task.estimatedHours.toInt().toString()
        : task.estimatedHours.toStringAsFixed(1);
    final isLocked = task.isLocked;
    final lockedAccentColor = Colors.orange.shade700;

    return Card(
      color: isLocked ? const Color(0xFFFFFBEB) : Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocked ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isLocked ? lockedAccentColor : Color(columnColor),
              width: 3,
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Color(0xFF1F2937)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            child: _buildTaskCardBody(
              task: task,
              title: title,
              description: description,
              estimatedHours: estimatedHours,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCardBody({
    required Task task,
    required String title,
    required String description,
    required String estimatedHours,
  }) {
    final showProgressHandle =
        widget.canManageTasks || task.canCurrentUserUpdateProgress;
    final contentIndent = showProgressHandle ? 22.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (showProgressHandle) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                task.isLocked ? Icons.lock_outline : Icons.drag_indicator,
                size: 16,
                color: task.isLocked
                    ? Colors.orange.shade700
                    : Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.isLocked) ...[
                  const SizedBox(height: 8),
                  _buildLockedBadge(),
                ],
              ],
            ),
          ),
          if (widget.canManageTasks) _buildTaskActionsMenu(task),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(left: contentIndent),
          child: _buildTaskMetadata(task, estimatedHours),
        ),
        if (task.skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: contentIndent),
            child: _buildTaskSkillChips(task.skills),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(left: contentIndent),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(left: contentIndent),
          child: _buildTaskCardFooter(task),
        ),
      ],
    );
  }

  Widget _buildTaskActionsMenu(Task task) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        tooltip: 'Aksi task',
        padding: EdgeInsets.zero,
        child: Center(
          child: Icon(
            Icons.more_vert,
            size: 18,
            color: Colors.grey.shade600,
          ),
        ),
        onSelected: (value) {
          if (value == 'edit') {
            widget.onEditTask(task);
          } else if (value == 'delete') {
            widget.onDeleteTask(task);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMetadata(Task task, String estimatedHours) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.isBlocked) ...[
          Icon(Icons.lock_outline, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            'Menunggu dependency',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (task.dependencies.isNotEmpty) ...[
          Icon(Icons.account_tree, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            '${task.dependencies.length} deps',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '${estimatedHours}h',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: Colors.orange.shade800),
          const SizedBox(width: 4),
          Text(
            'Blocked',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedTaskMessage() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task masih terkunci karena dependency belum selesai'),
      ),
    );
  }

  bool _canUpdateTaskProgress(Task task) {
    return !task.isLocked &&
        (widget.canManageTasks || task.canCurrentUserUpdateProgress);
  }

  Widget _buildTaskSkillChips(List<String> skills) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: skills
          .map(
            (skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTaskCardFooter(Task task) {
    if (task.assignee.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                task.initials,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            task.assignee,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      );
    }

    final assignText = Text(
      '+ Assign',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
      ),
    );

    if (!widget.canManageTasks) {
      return assignText;
    }

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: assignText,
      ),
    );
  }
}
