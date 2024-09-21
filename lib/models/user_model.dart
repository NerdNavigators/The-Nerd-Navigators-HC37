// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String name;
  final String imageUrl;
  final int followersCount;
  final int followingCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.imageUrl,
    required this.followersCount,
    required this.followingCount,
  });
}
