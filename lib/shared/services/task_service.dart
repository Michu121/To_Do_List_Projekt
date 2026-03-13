import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {

  final db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> tasks(String groupId) {

    return db
        .collection("groups")
        .doc(groupId)
        .collection("tasks")
        .orderBy("date")
        .snapshots();
  }

  Future<void> addTask(
      String groupId,
      Map<String,dynamic> task
      ) async {

    await db
        .collection("groups")
        .doc(groupId)
        .collection("tasks")
        .add(task);
  }

}