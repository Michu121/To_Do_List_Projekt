import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import 'fire_store_service.dart';

class CategoryServices extends ChangeNotifier {
  Map<String, Category> _categories = {};
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _isSeedingTriggered = false;

  Map<String, Category> getCategories() => _categories;

  /// Returns the default category object, regardless of its current locale name.
  Category get defaultCategory {
    return _categories.values.firstWhere(
          (c) => c.id == 'default',
      orElse: () => Category(id: 'default', name: 'Default', color: Colors.grey),
    );
  }

  void init(String uid, BuildContext context) {
    final defaultName = AppLocalizations.of(context)?.defaultCategory ?? 'Default';

    final defaultCat = Category(
      id: 'default',
      name: defaultName,
      color: Colors.grey,
    );

    _subscription?.cancel();
    _subscription = firestoreService.categoriesStream(uid).listen((snapshot) async {
      if (snapshot.docs.isEmpty && !_isSeedingTriggered) {
        final hasSeeded = await firestoreService.checkIfAlreadySeeded(uid);
        if (!hasSeeded) {
          _isSeedingTriggered = true;
          await _seedInitialCategories(context, uid);
          return;
        }
      }

      final fromFirestore = {
        for (final doc in snapshot.docs)
          (doc.data() as Map<String, dynamic>)['name'] as String:
          Category.fromJson(doc.data() as Map<String, dynamic>),
      };

      _categories = {
        defaultName: defaultCat,
        ...fromFirestore,
      };
      notifyListeners();
    });
  }

  /// Call this whenever the app locale changes to update the Default category
  /// display name in the in-memory map. Category ids remain stable.
  void updateDefaultName(BuildContext context) {
    final newName = AppLocalizations.of(context)?.defaultCategory ?? 'Default';

    // Find the existing default entry by its stable id
    final oldKey = _categories.keys.firstWhere(
          (k) => _categories[k]?.id == 'default',
      orElse: () => newName,
    );

    if (oldKey == newName) return; // Nothing to do

    _categories.remove(oldKey);
    _categories[newName] = Category(
      id: 'default',
      name: newName,
      color: Colors.grey,
    );
    notifyListeners();
  }

  Future<void> _seedInitialCategories(BuildContext context, String uid) async {
    final t = AppLocalizations.of(context);

    final starter = [
      Category(id: 'work', name: t?.workCategory ?? 'Work', color: Colors.blue),
      Category(id: 'personal', name: t?.personalCategory ?? 'Personal', color: Colors.green),
    ];

    for (var cat in starter) {
      await firestoreService.setCategory(uid, cat.id, cat.toJson());
    }

    await firestoreService.markAsSeeded(uid);
  }

  void clear(BuildContext context) {
    _subscription?.cancel();
    _subscription = null;
    final defaultName = AppLocalizations.of(context)?.defaultCategory ?? 'Default';
    _categories = {
      defaultName: Category(id: 'default', name: defaultName, color: Colors.grey)
    };
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addCategory(Category category) async {
    final uid = _uid;
    if (uid == null || _categories.containsKey(category.name)) return;

    final oldState = Map<String, Category>.from(_categories);
    _categories[category.name] = category;
    notifyListeners();

    try {
      await firestoreService.setCategory(uid, category.id, category.toJson());
    } catch (e) {
      _categories = oldState;
      notifyListeners();
    }
  }

  Future<void> updateCategory(Category category) async {
    final uid = _uid;
    if (uid == null) return;

    final oldEntry = _categories.entries.firstWhere(
          (e) => e.value.id == category.id,
      orElse: () => MapEntry(category.name, category),
    );

    if (oldEntry.value.id == 'default') return;

    final oldName = oldEntry.key;
    final oldState = Map<String, Category>.from(_categories);

    _categories.remove(oldName);
    _categories[category.name] = category;
    notifyListeners();

    try {
      await firestoreService.setCategory(uid, category.id, category.toJson());
    } catch (e) {
      _categories = oldState;
      notifyListeners();
    }
  }

  /// Safely deletes a category: all tasks with this category are moved to the
  /// Default category in Firestore before the category document is deleted.
  Future<void> deleteCategory(String name) async {
    final uid = _uid;
    final cat = _categories[name];

    // Never delete the protected default category
    if (uid == null || cat == null || cat.id == 'default') return;

    final backup = Map<String, Category>.from(_categories);

    // Optimistic local update
    _categories.remove(name);
    notifyListeners();

    try {
      // Move all Firestore tasks that use this category to Default
      await firestoreService.moveTasksToDefaultCategory(
        uid: uid,
        oldCategoryId: cat.id,
        defaultCategoryJson: defaultCategory.toJson(),
      );

      // Delete the category document itself
      await firestoreService.deleteCategory(uid, cat.id);
    } catch (e) {
      // Rollback on error
      _categories = backup;
      notifyListeners();
      debugPrint('deleteCategory error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoryServices = CategoryServices();