import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/models/user_profile.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }
  
  final repo = ref.watch(profileRepositoryProvider);
  return repo.streamProfile(user.uid);
});
