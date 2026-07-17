import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic set method
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _firestore.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  // Generic update method
  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _firestore.doc(path);
    await reference.update(data);
  }

  // Generic delete method
  Future<void> deleteDocument({required String path}) async {
    final reference = _firestore.doc(path);
    await reference.delete();
  }

  // Generic add method (generates auto ID)
  Future<String> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final reference = _firestore.collection(collectionPath);
    final doc = await reference.add(data);
    return doc.id;
  }

  // Generic document stream
  Stream<T?> documentStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
  }) {
    final reference = _firestore.doc(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return builder(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // Generic collection stream
  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    Query query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((snapshot) => builder(snapshot.data() as Map<String, dynamic>, snapshot.id))
          .where((value) => value != null)
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Future<T?> getDocument<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
  }) async {
    final reference = _firestore.doc(path);
    final snapshot = await reference.get();
    if (snapshot.exists && snapshot.data() != null) {
      return builder(snapshot.data()!, snapshot.id);
    }
    return null;
  }
}
