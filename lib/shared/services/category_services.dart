import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import 'fire_store_service.dart';

class CategoryServices extends ChangeNotifier {
  // TYLKO ta kategoria jest zablokowana do edycji i nieusuwalna
  static final Map<String, Category> _defaults = {
    'Default': Category(id: 'default', name: 'Default', color: Colors.grey),
  };

  Map<String, Category> _categories = Map.of(_defaults);
  StreamSubscription<QuerySnapshot>? _subscription;

  Map<String, Category> getCategories() => _categories;

  void init(String uid) {
    _subscription?.cancel();
    _subscription = firestoreService.categoriesStream(uid).listen((snapshot) {

      // Jeśli użytkownik nie ma żadnych kategorii w Firestore (nowy user)
      // tworzymy Work i Personal w bazie.
      if (snapshot.docs.isEmpty) {
        _seedInitialCategories(uid);
        return;
      }

      final fromFirestore = {
        for (final doc in snapshot.docs)
          (doc.data() as Map<String, dynamic>)['name'] as String:
          Category.fromJson(doc.data() as Map<String, dynamic>),
      };

      // Łączymy: Default (z kodu) + wszystko co w bazie (Work, Personal, inne)
      _categories = {..._defaults, ...fromFirestore};
      notifyListeners();
    });
  }

  Future<void> _seedInitialCategories(String uid) async {
    final starter = [
      Category(name: 'Work', color: Colors.blue),
      Category(name: 'Personal', color: Colors.green),
    ];

    for (var cat in starter) {
      await firestoreService.setCategory(uid, cat.id, cat.toJson());
    }
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _categories = Map.of(_defaults);
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── DODAWANIE ──────────────────────────────────────────────────────────────

  Future<void> addCategory(Category category) async {
    final uid = _uid;
    if (uid == null || _categories.containsKey(category.name)) return;

    _categories = {..._categories, category.name: category};
    notifyListeners();

    unawaited(
      firestoreService.setCategory(uid, category.id, category.toJson()).catchError((e) {
        _categories.remove(category.name);
        notifyListeners();
      }),
    );
  }

  // ── AKTUALIZACJA (Teraz pozwoli edytować Work/Personal) ────────────────────

  Future<void> updateCategory(Category category) async {
    final uid = _uid;
    if (uid == null) return;

    // Szukamy po ID, żeby móc zmienić nazwę
    final oldEntry = _categories.entries.firstWhere(
          (e) => e.value.id == category.id,
      orElse: () => MapEntry(category.name, category),
    );

    // Blokada TYLKO dla systemowego Default
    if (oldEntry.value.id == 'default') return;

    final oldName = oldEntry.key;
    final oldCategory = oldEntry.value;

    _categories = {
      for (final e in _categories.entries)
        if (e.key == oldName) category.name: category else e.key: e.value,
    };
    notifyListeners();

    unawaited(
      firestoreService.setCategory(uid, category.id, category.toJson()).catchError((e) {
        _categories = {
          for (final entry in _categories.entries)
            if (entry.key == category.name) oldName: oldCategory else entry.key: entry.value,
        };
        notifyListeners();
      }),
    );
  }

  // ── USUWANIE ───────────────────────────────────────────────────────────────

  Future<void> deleteCategory(String name) async {
    final uid = _uid;
    if (uid == null || name == 'Default') return;

    final cat = _categories[name];
    if (cat == null) return;

    final backup = Map<String, Category>.from(_categories);
    _categories.remove(name);
    notifyListeners();

    try {
      await firestoreService.moveTasksToDefaultCategory(
        uid: uid,
        oldCategoryId: cat.id,
        defaultCategoryId: 'default',
      );
      await firestoreService.deleteCategory(uid, cat.id);
    } catch (e) {
      _categories = backup;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoryServices = CategoryServices();