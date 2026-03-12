import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/category.dart';
import '../models/status.dart';
import '../models/task.dart';
import '../services/task_services.dart';
import '../services/group_services.dart';
import '../services/category_services.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    groupServices.init();
    categoryServices.init();
    taskServices.init();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) { // Dodaj context jako parametr
    final title = _titleController.text.trim();

    if (title.isNotEmpty) {
      taskServices.addTask(Task(
        title: title,
        status: Status.todo,
        category: Category(name: "General", color: Colors.blueAccent),
        group: Group(name: "Personal", color: Colors.red),
        description: _descController.text,
        date: DateTime.now(),
      ));

      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding dostosowany do klawiatury
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nowe Zadanie", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Tytuł"),
            autofocus: true,
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Opis"),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _handleSave(context), // Wywołujemy osobną funkcję
            child: const SizedBox(
              width: double.infinity,
              child: Text("Zapisz", textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
// class DropDownCategoryPicker extends StatelessWidget {
//   const DropDownCategoryPicker({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return DropdownButton
//       (
//       value: categoryServices.getCategories().first ?? TextField(),
//       items: [
//         DropdownMenuItem(
//           value: TextField(),
//           child: const Text("Wybierz kategorię"),
//         ),
//       ],
//         onChanged: (){};
//     );
//   }
// }
// class CategoryTextField extends StatelessWidget {
//   const CategoryTextField({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//         decoration: const InputDecoration(labelText: "Kategoria"),
//     );
//   }
// }