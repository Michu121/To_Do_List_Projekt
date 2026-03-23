import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import 'fire_store_service.dart';

class CategoryServices extends ChangeNotifier {
  static final Map<String, Category> _defaults = {
    'Work': Category(name: 'Work', color: Colors.blue),
    'Personal': Category(name: 'Personal', color: Colors.green),
    'Default': Category(name: 'Default', color: Colors.grey),
  };

  Map<String, Category> _categories = Map.of(_defaults);
  StreamSubscription<QuerySnapshot>? _subscription;

  Map<String, Category> getCategories() => _categories;

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.categoriesStream(uid).listen((snapshot) {
      final fromFirestore = {
        for (final doc in snapshot.docs)
          (doc.data() as Map<String, dynamic>)['name'] as String:
          Category.fromJson(doc.data() as Map<String, dynamic>),
      };
      _categories = {..._defaults, ...fromFirestore};
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _categories = Map.of(_defaults);
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addCategory(Category category) async {
    final uid = _uid;
    if (uid == null) return;
    if (_categories.containsKey(category.name)) return;

    // 1. Optimistic local update
    _categories = {..._categories, category.name: category};
    notifyListeners();

    // 2. Persist in background — roll back on failure
    unawaited(
      firestoreService
          .setCategory(uid, category.id, category.toJson())
          .catchError((e) {
        _categories.remove(category.name);
        notifyListeners();
        debugPrint('addCategory error: $e');
      }),
    );
  }

  Future<void> updateCategory(Category category) async {
    final uid = _uid;
    if (uid == null) return;

    final oldEntry = _categories.entries.firstWhere(
          (e) => e.value.id == category.id,
      orElse: () => MapEntry(category.name, category),
    );
    final oldName = oldEntry.key;
    final oldCategory = oldEntry.value;

    // 1. Optimistic local update
    _categories = {
      for (final e in _categories.entries)
        if (e.key == oldName) category.name: category else e.key: e.value,
    };
    notifyListeners();

    // 2. Persist in background — roll back on failure
    unawaited(
      firestoreService
          .setCategory(uid, category.id, category.toJson())
          .catchError((e) {
        _categories = {
          for (final entry in _categories.entries)
            if (entry.key == category.name)
              oldName: oldCategory
            else
              entry.key: entry.value,
        };
        notifyListeners();
        debugPrint('updateCategory error: $e');
      }),
    );
  }

  Future<void> deleteCategory(String name) async {
    final uid = _uid;
    if (uid == null) return;
    if (_defaults.containsKey(name)) return;
    final cat = _categories[name];
    if (cat == null) return;

    // 1. Optimistic local removal
    _categories = {
      for (final e in _categories.entries)
        if (e.key != name) e.key: e.value,
    };
    notifyListeners();

    // 2. Persist in background — roll back on failure
    unawaited(
      firestoreService.deleteCategory(uid, cat.id).catchError((e) {
        _categories = {..._categories, name: cat};
        notifyListeners();
        debugPrint('deleteCategory error: $e');
      }),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoryServices = CategoryServices();