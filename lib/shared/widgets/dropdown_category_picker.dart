import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_services.dart';

class DropDownCategoryPicker extends StatelessWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;

  const DropDownCategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return InkWell(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        width: size.width * 0.4,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: selectedCategory?.color ?? Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedCategory?.name ?? "Wybierz"),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    // 1. Chowa klawiaturę, żeby zwolnić miejsce
    FocusScope.of(context).unfocus();

    final categories = categoryServices.getCategories().values.toList();

    // 2. Pokazuje menu jako mały "Dialog" pod spodem lub nad klawiaturą
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Wybierz kategorię"),
        content: SizedBox(
          width: double.maxFinite,
          // Ograniczamy wysokość do ok. 3 elementów (3 * 50px)
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: ColoredBox(
                    color: cat.color,
                    child: ListTile(
                      title: Text(cat.name),
                      onTap: () {
                        onChanged(cat);
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
    );
  }
}