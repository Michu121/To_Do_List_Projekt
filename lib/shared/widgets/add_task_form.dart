import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/colors.dart';
import '../models/status.dart';
import '../models/task.dart';
import '../services/category_services.dart';
import '../services/task_services.dart';
import '../services/color_services.dart';
import 'color_picker.dart';
import 'dropdown_category_picker.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final colorServices = ColorServices();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // 1. Dodajemy zmienną przechowującą wybór
  Category? _selectedCategory = categoryServices.getCategories().values.first;
  ColorsToPick? _selectedColor;
  String? _errorText;


  void _handleSave(BuildContext context) {
    final title = _titleController.text.trim();

    if (title.isNotEmpty) {
      taskServices.addTask(
        Task(
          title: title,
          status: Status.todo,
          category: _selectedCategory!,
          description: _descController.text,
          color: _selectedColor?.color ?? Colors.grey.shade300,
          date: DateTime.now(),
        ),
      );
      Navigator.of(context).pop();
    }else{
      setState(() {
        _errorText = "Tytuł nie może być pusty";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            const Text(
              "Nowe Zadanie",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Tytuł", errorText: _errorText),
              autofocus: true,
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Opis"),
            ),
            const SizedBox(height: 20),
            // 3. Przekazujemy stan i funkcję aktualizującą

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Kategoria"),
                    DropDownCategoryPicker(
                      selectedCategory: _selectedCategory,
                      onChanged: (Category? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),

                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ColorPicker(
              colorServices: colorServices,
              selectedColor: _selectedColor,
              onTap: (String name) {
                setState(() {
                  colorServices.updateColor(name, true);
                  final updatedColors = colorServices.getColors();
                  _selectedColor = updatedColors[name];
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                onPressed: () => _handleSave(context),
                child: const Text("Zapisz", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
