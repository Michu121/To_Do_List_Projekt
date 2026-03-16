import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {

  final db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {

    final ref = db.collection("users").doc(user.uid);

    final doc = await ref.get();

    if(!doc.exists) {

      await ref.set(user.toJson());
    }
  }
  Future<void> afterLogin(User user) async {

    final firestore = FirestoreService();

    final model = UserModel(
        uid: user.uid,
        email: user.email ?? "",
        name: user.displayName ?? "",
        photo: user.photoURL
    );

    await firestore.createUser(model);
  }

}