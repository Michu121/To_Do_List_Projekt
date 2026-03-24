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
  bool _isSeedingTriggered = false; // Flaga w pamięci, by nie siać kilka razy w jednej sesji

  Map<String, Category> getCategories() => _categories;

  void init(String uid, BuildContext context) {
    final defaultName = AppLocalizations.of(context)?.defaultCategory ?? 'Default';

    final defaultCategory = Category(
        id: 'default',
        name: defaultName,
        color: Colors.grey
    );

    _subscription?.cancel();
    _subscription = firestoreService.categoriesStream(uid).listen((snapshot) async {

      // LOGIKA "RAZ NA ZAWSZE":
      // Sprawdzamy, czy użytkownik ma w ogóle dokument "meta" lub czy kolekcja jest pusta
      // ALBO (uproszczone): używamy SharedPreferences, by zapisać, że już raz dodaliśmy.

      if (snapshot.docs.isEmpty && !_isSeedingTriggered) {
        // Sprawdzamy w Firestore, czy użytkownik już kiedykolwiek miał robiony seed
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
        defaultName: defaultCategory,
        ...fromFirestore,
      };
      notifyListeners();
    });
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

    // 2. KLUCZOWE: Zapisujemy w profilu użytkownika, że seed został wykonany
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

  Future<void> deleteCategory(String name) async {
    final uid = _uid;
    final cat = _categories[name];

    if (uid == null || cat == null || cat.id == 'default') return;

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