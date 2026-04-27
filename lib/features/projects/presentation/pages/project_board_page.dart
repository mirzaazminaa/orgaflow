import 'package:flutter/material.dart';

import '../../../../core/widgets/responsive_sidebar.dart';
import '../../../dependency/presentation/presenters/manage_dependency_presenter.dart';
import '../../../task/domain/models/task_skill_requirement_model.dart';
import '../../../task/presentation/presenters/create_task_presenter.dart';
import '../../../task/presentation/presenters/task_list_presenter.dart';
import '../../models/task_model.dart';
import '../widgets/kanban_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/team_tab.dart';
import '../widgets/workflow_tab.dart';

class ProjectBoardPage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String projectDescription;

  const ProjectBoardPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectDescription = '',
  });

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TaskListPresenter _taskListPresenter = TaskListPresenter();
  late TabController _tabController;

  List<Task> _tasks = [];
  bool _isLoadingTasks = true;
  bool _canManageTasks = false;

  final List<KanbanColumn> _columns = [
    KanbanColumn(
      id: "backlog",
      title: "Backlog",
      status: TaskStatus.backlog,
      color: 0xFF718096,
    ),
    KanbanColumn(
      id: "todo",
      title: "Todo",
      status: TaskStatus.todo,
      color: 0xFF00CEC9,
    ),
    KanbanColumn(
      id: "in-progress",
      title: "In Progress",
      status: TaskStatus.inProgress,
      color: 0xFF6C5CE7,
    ),
    KanbanColumn(
      id: "done",
      title: "Done",
      status: TaskStatus.done,
      color: 0xFF00B894,
    ),
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    _fetchProjectTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _fetchProjectTasks({bool showLoading = true}) async {
    if (showLoading && !_isLoadingTasks) {
      setState(() {
        _isLoadingTasks = true;
      });
    }

    final fetchTasksFuture = _taskListPresenter.fetchTasks(widget.projectId);
    final canManageFuture = _taskListPresenter.canManageTasks();

    final result = await fetchTasksFuture;
    var canManageTasks = _canManageTasks;
    try {
      canManageTasks = await canManageFuture;
    } catch (_) {
      canManageTasks = _canManageTasks;
    }

    if (!mounted) {
      return false;
    }

    if (result.isFailure) {
      setState(() {
        _canManageTasks = canManageTasks;
        _isLoadingTasks = false;
      });
      _showMessage(result.error!.message);
      return false;
    }

    final mappedTasks = result.data!
        .map((task) => Task.fromTaskModel(task, canManageTasks: canManageTasks))
        .toList();
    if (mappedTasks.isNotEmpty) {
      final firstTask = mappedTasks.first;
      debugPrint(
        'ProjectBoardPage mapped first task: '
        'sourceTaskId=${firstTask.sourceTaskId}, '
        'title="${firstTask.title}", '
        'description="${firstTask.description}", '
        'estimatedHours=${firstTask.estimatedHours}, '
        'skills=${firstTask.skills}, '
        'status=${firstTask.databaseStatus}, '
        'isBlocked=${firstTask.isBlocked}, '
        'assignee="${firstTask.assignee}", '
        'isAssignedToCurrentUser=${firstTask.isAssignedToCurrentUser}',
      );
    }

    setState(() {
      _tasks = mappedTasks;
      _canManageTasks = canManageTasks;
      _isLoadingTasks = false;
    });
    return true;
  }

  Future<void> _showAddTaskDialog() async {
    if (!_canManageTasks) {
      _showMessage('Anda tidak memiliki izin untuk mengelola task.');
      return;
    }

    final result = await showDialog<_TaskDialogResult>(
      context: context,
      builder: (context) => _AddTaskDialog(
        projectId: widget.projectId,
        existingTasks: _tasks,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result?.saved == true) {
      final refreshed = await _fetchProjectTasks();
      if (!mounted) {
        return;
      }
      if (refreshed) {
        _showMessage(result?.message ?? 'Task berhasil dibuat');
      }
    }
  }

  Future<void> _showEditTaskDialog(Task task) async {
    if (!_canManageTasks) {
      _showMessage('Anda tidak memiliki izin untuk mengelola task.');
      return;
    }

    if (task.sourceTaskId == null || task.sourceTaskId!.trim().isEmpty) {
      _showMessage('Task tidak valid.');
      return;
    }

    final result = await showDialog<_TaskDialogResult>(
      context: context,
      builder: (context) => _AddTaskDialog(
        projectId: widget.projectId,
        existingTasks: _tasks,
        taskToEdit: task,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result?.saved == true) {
      final refreshed = await _fetchProjectTasks();
      if (!mounted) {
        return;
      }
      if (refreshed) {
        _showMessage(result?.message ?? 'Task berhasil diperbarui');
      }
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    if (!_canManageTasks) {
      _showMessage('Anda tidak memiliki izin untuk mengelola task.');
      return;
    }

    final taskId = task.sourceTaskId;
    if (taskId == null || taskId.trim().isEmpty) {
      _showMessage('Task tidak valid.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus task?'),
        content: Text('Task "${task.title}" akan dihapus beserta relasinya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final result = await _taskListPresenter.deleteTask(taskId);

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      _showMessage(result.error!.message);
      return;
    }

    final refreshed = await _fetchProjectTasks();

    if (!mounted) {
      return;
    }

    if (refreshed) {
      _showMessage('Task berhasil dihapus');
    }
  }

  Future<void> _moveTask(int taskId, TaskStatus newStatus) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      _showMessage('Task tidak ditemukan.');
      return;
    }

    final task = _tasks[taskIndex];
    if (task.isLocked) {
      _showMessage('Task masih terkunci karena dependency belum selesai');
      return;
    }

    if (!_canUpdateProgress(task)) {
      _showMessage(
        'Anda hanya dapat mengubah progres task yang ditugaskan kepada Anda.',
      );
      return;
    }

    final previousStatus = task.status;
    if (previousStatus == newStatus) {
      return;
    }

    final sourceTaskId = task.sourceTaskId?.trim();
    if (sourceTaskId == null || sourceTaskId.isEmpty) {
      _showMessage('Task tidak valid.');
      return;
    }

    final previousTask = task;
    setState(() {
      _tasks = [
        for (final currentTask in _tasks)
          if (currentTask.id == taskId)
            currentTask.copyWith(status: newStatus)
          else
            currentTask,
      ];
    });

    final result = await _taskListPresenter.updateTaskStatus(
      taskId: sourceTaskId,
      status: newStatus.databaseValue,
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _tasks = [
          for (final currentTask in _tasks)
            if (currentTask.id == taskId) previousTask else currentTask,
        ];
      });
      _showMessage(result.error!.message);
      debugPrint(
        'Rolled back task status update: taskId=$sourceTaskId, '
        'from=${newStatus.databaseValue}, '
        'to=${previousStatus.databaseValue}',
      );
      return;
    }

    await _fetchProjectTasks(showLoading: false);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _canUpdateProgress(Task task) {
    return _canManageTasks || task.canCurrentUserUpdateProgress;
  }

  int get _daysRemaining {
    // Demo: 18 days remaining
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/projects'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Header
                  _buildProjectHeader(isSmallScreen),
                  // Tab Bar
                  _buildTabBar(),
                  // Tab Content
                  _buildCurrentTabContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen && _canManageTasks
          ? FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCurrentTabContent() {
    if (_isLoadingTasks) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_currentIndex) {
      case 0:
        return OverviewTab(
          tasks: _tasks,
          dueDate: DateTime.now().add(Duration(days: _daysRemaining)),
          projectDescription:
              'Acara pelantikan pengurus baru organisasi mahasiswa periode 2024/2025',
        );
      case 1:
        return KanbanTab(
          tasks: _tasks,
          columns: _columns,
          canManageTasks: _canManageTasks,
          onMoveTask: _moveTask,
          onAddTask: _showAddTaskDialog,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _confirmDeleteTask,
        );
      case 2:
        return WorkflowTab(
          projectId: widget.projectId,
          tasks: _tasks,
        );
      case 3:
        return const TeamTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProjectHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 28,
        20,
        isSmallScreen ? 16 : 28,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (widget.projectDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.projectDescription,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Countdown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00CEC9), Color(0xFF00B894)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00CEC9).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${_daysRemaining}d',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 14),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF6C5CE7),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF6C5CE7),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Papan Tugas (Kanban)'),
          Tab(text: 'Alur Kerja (Graph)'),
          Tab(text: 'Tim'),
        ],
      ),
    );
  }
}

class _TaskDialogResult {
  const _TaskDialogResult({
    required this.saved,
    this.message,
  });

  final bool saved;
  final String? message;
}

class _AddTaskDialog extends StatefulWidget {
  final String projectId;
  final List<Task> existingTasks;
  final Task? taskToEdit;

  const _AddTaskDialog({
    required this.projectId,
    required this.existingTasks,
    this.taskToEdit,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _skillSearchController = TextEditingController();
  final CreateTaskPresenter _createTaskPresenter = CreateTaskPresenter();
  final TaskListPresenter _taskListPresenter = TaskListPresenter();
  final ManageDependencyPresenter _dependencyPresenter =
      ManageDependencyPresenter();

  List<TaskSkillOptionModel> _availableSkills = [];
  final List<TaskSkillRequirementModel> _selectedSkills = [];
  final Set<String> _selectedDependencyTaskIds = <String>{};
  String _skillSearch = '';
  String? _skillLoadError;
  bool _isLoadingSkills = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    _prefillTaskForEdit();
    _loadSkills();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  void _prefillTaskForEdit() {
    final task = widget.taskToEdit;
    if (task == null) {
      return;
    }

    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _hoursController.text = task.estimatedHours.round().toString();
    _selectedSkills.addAll(task.skillRequirements);
  }

  Future<void> _loadSkills() async {
    final result = await _createTaskPresenter.fetchActiveSkills();

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      debugPrint('AddTaskDialog skill fetch error: ${result.error!.message}');
      setState(() {
        _skillLoadError = result.error!.message;
        _isLoadingSkills = false;
      });
      _showMessage(result.error!.message);
      return;
    }

    debugPrint('AddTaskDialog fetched skills: ${result.data!.length}');
    setState(() {
      _availableSkills = result.data!;
      _skillLoadError = null;
      _isLoadingSkills = false;
    });
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final hoursText = _hoursController.text.trim();

    if (title.isEmpty) {
      _showMessage('Judul task wajib diisi');
      return;
    }

    if (hoursText.isEmpty) {
      _showMessage('Bobot jam harus diisi');
      return;
    }

    final estimatedHours = int.tryParse(hoursText);
    if (estimatedHours == null || estimatedHours <= 0) {
      _showMessage('Bobot jam harus angka lebih dari 0');
      return;
    }

    final validSelectedSkills = _selectedSkills
        .where((skill) => skill.skillId.trim().isNotEmpty)
        .toList();
    debugPrint('AddTaskDialog selected skills: ${validSelectedSkills.length}');

    if (validSelectedSkills.isEmpty) {
      _showMessage('Minimal satu skill harus dipilih');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final skillRequirementInputs = validSelectedSkills
        .map(
          (skill) => TaskSkillRequirementInput(
            skillId: skill.skillId,
            minimumLevel: skill.minimumLevel,
            priorityWeight: skill.priorityWeight,
          ),
        )
        .toList();

    if (_isEditing) {
      final taskToEdit = widget.taskToEdit!;
      final taskId = taskToEdit.sourceTaskId;
      if (taskId == null || taskId.trim().isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        _showMessage('Task tidak valid.');
        return;
      }

      final result = await _taskListPresenter.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        estimatedHours: estimatedHours,
        priority: taskToEdit.priority,
        dueDate: taskToEdit.dueDate,
        skillRequirements: skillRequirementInputs,
      );

      if (!mounted) {
        return;
      }

      if (result.isFailure) {
        setState(() {
          _isSubmitting = false;
        });
        _showMessage(result.error!.message);
        return;
      }

      Navigator.pop(
        context,
        const _TaskDialogResult(
          saved: true,
          message: 'Task berhasil diperbarui',
        ),
      );
      return;
    }

    final result = await _createTaskPresenter.createTask(
      projectId: widget.projectId,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      priority: 'medium',
      skillRequirements: skillRequirementInputs,
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isSubmitting = false;
      });
      _showMessage(result.error!.message);
      return;
    }

    final createdTask = result.data!;
    String? warningMessage;
    for (final dependencyTaskId in _selectedDependencyTaskIds) {
      final dependencyResult = await _dependencyPresenter.addDependency(
        taskId: createdTask.id,
        dependsOnTaskId: dependencyTaskId,
      );

      if (!mounted) {
        return;
      }

      if (dependencyResult.isFailure) {
        warningMessage =
            'Task dibuat, tetapi dependency gagal disimpan: ${dependencyResult.error!.message}';
        break;
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      _TaskDialogResult(
        saved: true,
        message: warningMessage,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<TaskSkillOptionModel> get _filteredSkills {
    final selectedSkillIds =
        _selectedSkills.map((skill) => skill.skillId).toSet();

    return _availableSkills
        .where(
          (skill) =>
              skill.skillName
                  .toLowerCase()
                  .contains(_skillSearch.toLowerCase()) &&
              !selectedSkillIds.contains(skill.skillId),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSkills = _filteredSkills;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Task' : 'Input Task Manual',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Judul Task',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Cetak Banner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Deskripsi',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan detail task yang harus dikerjakan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bobot Jam (Estimasi Waktu)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _hoursController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '5',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'jam',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Skill Tags',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedSkills.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill.skillName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: _isSubmitting
                                        ? null
                                        : () => setState(
                                              () => _selectedSkills.removeWhere(
                                                (selected) =>
                                                    selected.skillId ==
                                                    skill.skillId,
                                              ),
                                            ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _skillSearchController,
                      enabled: !_isSubmitting && !_isLoadingSkills,
                      onChanged: (value) =>
                          setState(() => _skillSearch = value),
                      decoration: InputDecoration(
                        hintText: _isLoadingSkills
                            ? 'Memuat skill...'
                            : 'Cari atau pilih skill...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSkillOptions(filteredSkills),
                    if (!_isEditing) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Dependency (Prasyarat Task)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: widget.existingTasks.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                itemCount: widget.existingTasks.length,
                                itemBuilder: (context, index) {
                                  final task = widget.existingTasks[index];
                                  final taskId = task.sourceTaskId;
                                  return CheckboxListTile(
                                    value: taskId != null &&
                                        _selectedDependencyTaskIds
                                            .contains(taskId),
                                    onChanged: taskId == null || _isSubmitting
                                        ? null
                                        : (value) => setState(() {
                                              if (value == true) {
                                                _selectedDependencyTaskIds
                                                    .add(taskId);
                                              } else {
                                                _selectedDependencyTaskIds
                                                    .remove(taskId);
                                              }
                                            }),
                                    title: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      task.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    dense: true,
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  'Belum ada task lain',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        _isSubmitting || _isLoadingSkills ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isSubmitting
                          ? 'Menyimpan...'
                          : _isEditing
                              ? 'Simpan Perubahan'
                              : 'Tambah Task',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillOptions(List<TaskSkillOptionModel> filteredSkills) {
    if (_isLoadingSkills) {
      return const SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_availableSkills.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada skill aktif',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (_skillLoadError != null) ...[
            const SizedBox(height: 4),
            Text(
              _skillLoadError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ],
      );
    }

    if (_skillSearch.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        constraints: const BoxConstraints(maxHeight: 150),
        child: filteredSkills.isNotEmpty
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredSkills.map(_buildAvailableSkillChip).toList(),
              )
            : Center(
                child: Text(
                  'Tidak ada skill yang cocok',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSkills
          .where(
            (skill) => !_selectedSkills.any(
              (selected) => selected.skillId == skill.skillId,
            ),
          )
          .take(6)
          .map(_buildAvailableSkillChip)
          .toList(),
    );
  }

  Widget _buildAvailableSkillChip(TaskSkillOptionModel skill) {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : () => setState(() {
                if (!_selectedSkills.any(
                  (selected) => selected.skillId == skill.skillId,
                )) {
                  _selectedSkills.add(
                    TaskSkillRequirementModel.fromSkillOption(skill),
                  );
                }
                _skillSearchController.clear();
                _skillSearch = '';
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '+ ${skill.skillName}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
