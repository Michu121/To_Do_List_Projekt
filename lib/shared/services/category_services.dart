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
      _categories = {
        ..._defaults,
        ...fromFirestore,
      };
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
    await firestoreService.setCategory(uid, category.id, category.toJson());
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    final uid = _uid;
    if (uid == null) return;
    await firestoreService.setCategory(uid, category.id, category.toJson());
  }

  Future<void> deleteCategory(String name) async {
    final uid = _uid;
    if (uid == null) return;
    if (_defaults.containsKey(name)) return;
    final cat = _categories[name];
    if (cat == null) return;
    await firestoreService.deleteCategory(uid, cat.id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoryServices = CategoryServices();