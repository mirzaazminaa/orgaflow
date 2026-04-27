import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../dependency/domain/models/dependency_graph_data.dart';

class DependencyGraphView extends StatefulWidget {
  const DependencyGraphView({
    super.key,
    required this.graphData,
  });

  final DependencyGraphData graphData;

  @override
  State<DependencyGraphView> createState() => _DependencyGraphViewState();
}

class _DependencyGraphViewState extends State<DependencyGraphView> {
  static const double _nodeWidth = 190;
  static const double _nodeHeight = 78;
  static const double _levelGap = 260;
  static const double _rowGap = 130;

  final TransformationController _transformationController =
      TransformationController();

  Map<String, Offset> _positions = {};
  Size _canvasSize = const Size(960, 460);
  String _layoutSignature = '';

  @override
  void initState() {
    super.initState();
    _resetLayout();
  }

  @override
  void didUpdateWidget(covariant DependencyGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _signatureFor(widget.graphData);
    if (nextSignature != _layoutSignature) {
      _resetLayout();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetLayout() {
    final layout = _calculateLayout(widget.graphData);
    _positions = layout.positions;
    _canvasSize = layout.size;
    _layoutSignature = _signatureFor(widget.graphData);
  }

  @override
  Widget build(BuildContext context) {
    final nodesById = {
      for (final node in widget.graphData.nodes) node.taskId: node,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 420,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(280),
          minScale: 0.35,
          maxScale: 2.5,
          child: SizedBox(
            width: _canvasSize.width,
            height: _canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DependencyGraphPainter(
                      edges: widget.graphData.edges,
                      positions: _positions,
                      nodesById: nodesById,
                      nodeSize: const Size(_nodeWidth, _nodeHeight),
                    ),
                  ),
                ),
                for (final node in widget.graphData.nodes)
                  if (_positions.containsKey(node.taskId))
                    Positioned(
                      left: _positions[node.taskId]!.dx,
                      top: _positions[node.taskId]!.dy,
                      child: _DependencyGraphNodeCard(
                        node: node,
                        width: _nodeWidth,
                        height: _nodeHeight,
                        onDragUpdate: (details) {
                          _moveNode(node.taskId, details.delta);
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _moveNode(String taskId, Offset delta) {
    final currentPosition = _positions[taskId];
    if (currentPosition == null) {
      return;
    }

    final scale = _transformationController.value.getMaxScaleOnAxis();
    final adjustedDelta = delta / (scale == 0 ? 1 : scale);
    final nextPosition = _clampPosition(currentPosition + adjustedDelta);

    setState(() {
      _positions = {
        ..._positions,
        taskId: nextPosition,
      };
    });
  }

  Offset _clampPosition(Offset position) {
    return Offset(
      position.dx.clamp(24, _canvasSize.width - _nodeWidth - 24).toDouble(),
      position.dy.clamp(24, _canvasSize.height - _nodeHeight - 24).toDouble(),
    );
  }

  _GraphLayout _calculateLayout(DependencyGraphData data) {
    final nodeIds = data.nodes.map((node) => node.taskId).toSet();
    final prerequisitesByTaskId = {
      for (final node in data.nodes) node.taskId: <String>[],
    };

    for (final edge in data.edges) {
      if (nodeIds.contains(edge.fromTaskId) &&
          nodeIds.contains(edge.toTaskId)) {
        prerequisitesByTaskId[edge.toTaskId]!.add(edge.fromTaskId);
      }
    }

    final levelByTaskId = <String, int>{};
    final visiting = <String>{};

    int levelFor(String taskId) {
      final cached = levelByTaskId[taskId];
      if (cached != null) {
        return cached;
      }

      if (visiting.contains(taskId)) {
        return 0;
      }

      visiting.add(taskId);
      final prerequisites = prerequisitesByTaskId[taskId] ?? const <String>[];
      final level = prerequisites.isEmpty
          ? 0
          : prerequisites
              .where(nodeIds.contains)
              .map((dependencyTaskId) => levelFor(dependencyTaskId) + 1)
              .fold<int>(
                0,
                (maxLevel, level) => math.max(maxLevel, level),
              );
      visiting.remove(taskId);
      levelByTaskId[taskId] = level;
      return level;
    }

    for (final node in data.nodes) {
      levelFor(node.taskId);
    }

    final nodesByLevel = <int, List<DependencyGraphNode>>{};
    for (final node in data.nodes) {
      final level = levelByTaskId[node.taskId] ?? 0;
      nodesByLevel.putIfAbsent(level, () => <DependencyGraphNode>[]).add(node);
    }

    final maxLevel = nodesByLevel.keys.fold<int>(
      0,
      (maxLevel, level) => math.max(maxLevel, level),
    );
    final maxRows = nodesByLevel.values.fold<int>(
      1,
      (maxRows, nodes) => math.max(maxRows, nodes.length),
    );

    final width = math.max(960.0, 160 + (maxLevel + 1) * _levelGap);
    final height = math.max(460.0, 150 + maxRows * _rowGap);
    final positions = <String, Offset>{};

    for (final entry in nodesByLevel.entries) {
      final level = entry.key;
      final nodes = entry.value;
      final groupHeight = (nodes.length - 1) * _rowGap + _nodeHeight;
      final startY = (height - groupHeight) / 2;
      final x = 80 + level * _levelGap;

      for (var index = 0; index < nodes.length; index++) {
        positions[nodes[index].taskId] = Offset(x, startY + index * _rowGap);
      }
    }

    return _GraphLayout(
      positions: positions,
      size: Size(width, height),
    );
  }

  String _signatureFor(DependencyGraphData data) {
    final nodePart = data.nodes.map((node) => node.taskId).toList()..sort();
    final edgePart = data.edges
        .map((edge) =>
            '${edge.dependencyId}:${edge.fromTaskId}>${edge.toTaskId}')
        .toList()
      ..sort();

    return '${nodePart.join('|')}::${edgePart.join('|')}';
  }
}

class _GraphLayout {
  const _GraphLayout({
    required this.positions,
    required this.size,
  });

  final Map<String, Offset> positions;
  final Size size;
}

class _DependencyGraphPainter extends CustomPainter {
  const _DependencyGraphPainter({
    required this.edges,
    required this.positions,
    required this.nodesById,
    required this.nodeSize,
  });

  final List<DependencyGraphEdge> edges;
  final Map<String, Offset> positions;
  final Map<String, DependencyGraphNode> nodesById;
  final Size nodeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
      final fromPosition = positions[edge.fromTaskId];
      final toPosition = positions[edge.toTaskId];
      if (fromPosition == null ||
          toPosition == null ||
          nodesById[edge.fromTaskId] == null ||
          nodesById[edge.toTaskId] == null) {
        continue;
      }

      final start = Offset(
        fromPosition.dx + nodeSize.width,
        fromPosition.dy + nodeSize.height / 2,
      );
      final end = Offset(
        toPosition.dx,
        toPosition.dy + nodeSize.height / 2,
      );
      final controlGap = math.max(48.0, (end.dx - start.dx).abs() / 2);
      final control1 = Offset(start.dx + controlGap, start.dy);
      final control2 = Offset(end.dx - controlGap, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(path, edgePaint);
      _drawArrowHead(canvas, arrowPaint, end, control2);
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Paint paint,
    Offset tip,
    Offset previousPoint,
  ) {
    const arrowSize = 9.0;
    final angle = math.atan2(
      tip.dy - previousPoint.dy,
      tip.dx - previousPoint.dx,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle - math.pi / 6),
        tip.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle + math.pi / 6),
        tip.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DependencyGraphPainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.positions != positions ||
        oldDelegate.nodesById != nodesById;
  }
}

class _DependencyGraphNodeCard extends StatelessWidget {
  const _DependencyGraphNodeCard({
    required this.node,
    required this.width,
    required this.height,
    required this.onDragUpdate,
  });

  final DependencyGraphNode node;
  final double width;
  final double height;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForStatus(node);

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDragUpdate,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (node.isLocked) ...[
                    Icon(Icons.lock_outline, size: 13, color: colors.text),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      node.title,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _StatusBadge(
                    label: _statusLabel(node.status),
                    colors: colors,
                  ),
                  const Spacer(),
                  Text(
                    '${node.estimatedHours}h',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NodeColors _colorsForStatus(DependencyGraphNode node) {
    if (node.isBlocked || node.status == 'blocked') {
      return const _NodeColors(
        background: Color(0xFFFFF7ED),
        border: Color(0xFFFB923C),
        badgeBackground: Color(0xFFFFEDD5),
        text: Color(0xFF9A3412),
      );
    }

    switch (node.status) {
      case 'done':
        return const _NodeColors(
          background: Color(0xFFECFDF5),
          border: Color(0xFF10B981),
          badgeBackground: Color(0xFFD1FAE5),
          text: Color(0xFF047857),
        );
      case 'in_progress':
      case 'in_review':
        return const _NodeColors(
          background: Color(0xFFF5F3FF),
          border: Color(0xFF7C3AED),
          badgeBackground: Color(0xFFEDE9FE),
          text: Color(0xFF5B21B6),
        );
      case 'todo':
        return const _NodeColors(
          background: Color(0xFFEFF6FF),
          border: Color(0xFF3B82F6),
          badgeBackground: Color(0xFFDBEAFE),
          text: Color(0xFF1D4ED8),
        );
      case 'backlog':
      default:
        return const _NodeColors(
          background: Color(0xFFF8FAFC),
          border: Color(0xFF94A3B8),
          badgeBackground: Color(0xFFE2E8F0),
          text: Color(0xFF475569),
        );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'done':
        return 'Done';
      case 'blocked':
        return 'Blocked';
      case 'todo':
        return 'Todo';
      case 'backlog':
      default:
        return 'Backlog';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.colors,
  });

  final String label;
  final _NodeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.badgeBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
      ),
    );
  }
}

class _NodeColors {
  const _NodeColors({
    required this.background,
    required this.border,
    required this.badgeBackground,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color badgeBackground;
  final Color text;
}
