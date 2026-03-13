import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/category.dart';

class CategoryServices extends ChangeNotifier {
  Map<String, Category> _categories = {
    "Default": Category(name: "Default", color: Colors.white),
    "Work": Category(name: "Work", color: Colors.blue),
    "Personal": Category(name: "Personal", color: Colors.red),
    "Home": Category(name: "Home", color: Colors.green),
    "Ahh": Category(name: "Ahh", color: Colors.green)
  };
  File? _file;

  Map<String, Category> getCategories() => _categories;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/categories.json');

    if (_file!.existsSync()) {
      String content = await _file!.readAsString();
      if (content.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);

        _categories = {
          for (var item in jsonList)
            Category.fromJson(item).name : Category.fromJson(item)
        };

        notifyListeners();
      }
    }
  }

  Future<void> saveCategories() async {
    if (_file == null) return;

    final jsonList = _categories.values.map((cat) => cat.toJson()).toList();
    await _file!.writeAsString(jsonEncode(jsonList));
  }

  void addCategory(Category category) {
    if (_categories.containsKey(category.name)) {
      return;
    }
    _categories[category.name] = category;
    saveCategories();
    notifyListeners();
  }

  void updateCategory(Category category) {
    if (_categories.containsKey(category.name)) {
      _categories[category.name] = category;
      saveCategories();
      notifyListeners();
    }
  }

  void deleteCategory(String name) {
    _categories.remove(name);
    saveCategories();
    notifyListeners();
  }
}

final categoryServices = CategoryServices();