import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_services.dart';
import '../../notifiers/rotate_notifier.dart';

class CategoryPicker extends StatefulWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;



  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();

}

class _CategoryPickerState extends State<CategoryPicker> {
  bool rotate = false;
  final rotateNotifier = RotateNotifier();



  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right:8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: (){
                _showPicker(context);
                setState(() {
                  rotateNotifier.changeValue(true);
                });

              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).cardColor
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: widget.selectedCategory?.color ?? Colors.grey.shade400, radius: 8),
                        const SizedBox(width: 10),
                        Text(widget.selectedCategory?.name ?? "Wybierz", style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    ValueListenableBuilder(
                      valueListenable: rotateNotifier,
                      builder: (context, value, child) {
                        return AnimatedRotation(
                          turns: value ? -0.5 : -1,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(Icons.arrow_drop_down),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    // 1. Chowa klawiaturę, żeby zwolnić miejsce
    FocusScope.of(context).unfocus();

    final categories = categoryServices.getCategories().values.toList();

    // 2. Pokazuje menu jako mały "Dialog" pod spodem lub nad klawiaturą
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(10),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 170),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cat == widget.selectedCategory ? cat.color : Colors.grey.shade200
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cat == widget.selectedCategory ? cat.color.withValues(alpha:0.2) : Colors.transparent,
                          blurRadius: 6,
                          spreadRadius: 1
                        )
                      ]
                    ),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: cat.color, radius: 8),
                      title: Text(cat.name),
                      onTap: () {
                        setState(() {
                          rotateNotifier.changeValue(false);
                        });
                        widget.onChanged(cat);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {
      rotateNotifier.changeValue(false);

    }));
  }
}