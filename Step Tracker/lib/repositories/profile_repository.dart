import 'package:stride_ai/core/constants/firebase_constants.dart';
import 'package:stride_ai/models/user_profile.dart';
import 'package:stride_ai/repositories/firestore_service.dart';

class ProfileRepository {
  final FirestoreService _service = FirestoreService();

  Future<void> saveProfile(UserProfile profile) async {
    await _service.setDocument(
      path: '${FirebaseConstants.usersCollection}/${profile.uid}',
      data: profile.toJson(),
    );
  }

  Future<UserProfile?> getProfile(String uid) async {
    return await _service.getDocument<UserProfile>(
      path: '${FirebaseConstants.usersCollection}/$uid',
      builder: (data, documentID) => UserProfile.fromJson(data, documentID),
    );
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _service.documentStream<UserProfile>(
      path: '${FirebaseConstants.usersCollection}/$uid',
      builder: (data, documentID) => UserProfile.fromJson(data, documentID),
    );
  }
}
