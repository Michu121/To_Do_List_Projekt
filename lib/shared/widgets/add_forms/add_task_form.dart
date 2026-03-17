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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
  final List<Group> groups = [Group(name: '🚫None', color: Colors.grey.shade300),...groupTaskService.groups];

  Category? _selectedCategory;
  Difficulty? _selectedDifficulty;
  ColorsToPick? _selectedColor;
  Group? _selectedGroup;
  String? _titleError;
  bool _saving = false;

  double get size => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _selectedCategory = categoryServices.getCategories().values.firstOrNull;
    _selectedGroup = widget.preselectedGroup ?? groups.firstOrNull;
    _selectedDifficulty = Difficulty.easy;
    _selectedColor = _colorServices.getColors().values.firstOrNull;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(BuildContext context) async {
    final title = _titleController.text.trim();
    String? tErr;

    if (title.isEmpty) tErr = 'Title cannot be empty';

    if (tErr != null) {
      setState(() {
        _titleError = tErr;
      });
      return;
    }

    setState(() => _saving = true);

    final task = Task(
      title: title,
      status: Status.todo,
      category: _selectedCategory!,
      description: _descController.text,
      color: _selectedColor?.color ?? Colors.grey.shade300,
      date: DateTime.now(),
      group: _selectedGroup == groups.firstOrNull
          ? null
          : _selectedGroup,
      difficulty: _selectedDifficulty!,
    );
    if (_selectedGroup == groupTaskService.groups.firstOrNull) {
      groupTaskService.addTask(_selectedGroup!.id, task);
    }else{
      taskServices.addTask(task);
    }

    setState(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Sign in to add tasks', style: TextStyle(fontSize: 16)),
        ),
      );
    }


    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                if (_titleError != null) setState(() => _titleError = null);
              },
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
              selected: _selectedDifficulty ?? Difficulty.easy,
              onChanged: (diff) {
                setState(() => _selectedDifficulty = diff);
              },
            ),
            const SizedBox(height: 16),
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
                  onChanged: (g) => setState(() {
                    _selectedGroup = g;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
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
              width: size,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : () => _handleSave(context),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.selected, required this.onChanged});

  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final diff in Difficulty.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
                          Text(
                            "${diff.points} pts",
                            style: TextStyle(fontSize: 10, color: diff.color),
                          ),
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
