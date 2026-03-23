import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/colors.dart';
import '../../models/difficulty.dart';
import '../../models/group.dart';
import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/category_services.dart';
import '../../services/color_services.dart';
import '../../services/group_task_service.dart';
import '../../services/task_services.dart';
import '../pickers/color_picker.dart';
import '../pickers/category_picker.dart';
import '../pickers/group_picker.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.preselectedGroup});

  final Group? preselectedGroup;

  static void show(BuildContext context, {Group? preselectedGroup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => AddTaskSheet(preselectedGroup: preselectedGroup),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _colorServices = ColorServices();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // groups[0] is the "🚫None" sentinel; real groups follow
  late final List<Group> groups = [
    Group(name: '🚫None', color: Colors.grey.shade300),
    ...groupTaskService.groups,
  ];

  Category? _selectedCategory;
  Difficulty _selectedDifficulty = Difficulty.easy;
  ColorsToPick? _selectedColor;
  Group? _selectedGroup;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _selectedCategory = categoryServices.getCategories().values.firstOrNull;
    _selectedGroup = widget.preselectedGroup ?? groups.first;
    _selectedColor = _colorServices.getColors().values.firstOrNull;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isPersonalTask => _selectedGroup == groups.first;

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title cannot be empty');
      return;
    }

    final task = Task(
      title: title,
      status: Status.todo,
      category: _selectedCategory!,
      description: _descController.text,
      color: _selectedColor?.color ?? Colors.transparent,
      date: DateTime.now(),
      group: _isPersonalTask ? null : _selectedGroup,
      difficulty: _selectedDifficulty,
    );

    // Close the sheet immediately — DB writes happen in the background
    Navigator.of(context).pop();

    if (_isPersonalTask) {
      unawaited(taskServices.addTask(task));
    } else {
      groupTaskService.addTask(_selectedGroup!.id, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child:
          Text('Sign in to add tasks', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(12)),
        border:
        Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'New Task',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _DifficultyPicker(
              selected: _selectedDifficulty,
              onChanged: (d) => setState(() => _selectedDifficulty = d),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryPicker(
                  selectedCategory: _selectedCategory,
                  onChanged: (c) => setState(() => _selectedCategory = c),
                ),
                GroupPicker(
                  groups: groups,
                  selected: _selectedGroup,
                  onChanged: (g) => setState(() => _selectedGroup = g),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Color',
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ColorPicker(
              colorServices: _colorServices,
              selectedColor: _selectedColor,
              onTap: (name) {
                setState(() {
                  _colorServices.updateColor(name, true);
                  _selectedColor = _colorServices.getColors()[name];
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSave,
                child: const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker(
      {required this.selected, required this.onChanged});

  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final diff in Difficulty.values)
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6.0),
                  child: GestureDetector(
                    onTap: () => onChanged(diff),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected == diff
                            ? diff.color.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected == diff
                              ? diff.color
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(diff.icon, color: diff.color),
                          Text('${diff.points} pts',
                              style: TextStyle(
                                  fontSize: 10, color: diff.color)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}