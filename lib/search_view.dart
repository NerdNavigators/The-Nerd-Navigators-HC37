import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:famlicious_app/models/user_model.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<String> _following = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Fetch the logged-in user's following list
    DocumentSnapshot currentUserSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    _following = List<String>.from(currentUserSnapshot['following_array'] ?? []);

    // Fetch all users excluding the current user
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit the number of users fetched
        .get();

    setState(() {
      _users = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return UserModel(
          uid: doc.id,
          name: data['name'],
          imageUrl: data['picture'],
          followersCount: data['followers'] ?? 0,
          followingCount: data['following'] ?? 0,
        );
      }).where((user) => user.uid != currentUserId).toList(); // Exclude the current user

      _filteredUsers = _users; // Initially show all users
      isLoading = false;
    });
  }

  void _searchUsers() {
    String query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredUsers = _users
          .where((user) => user.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _followUser(UserModel user) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'followers': FieldValue.increment(1),
        'follower_array': FieldValue.arrayUnion([currentUserId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'following': FieldValue.increment(1),
        'following_array': FieldValue.arrayUnion([user.uid]),
      });

      setState(() {
        _following.add(user.uid);
      });
    }
  }

  Future<void> _unfollowUser(UserModel user) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'followers': FieldValue.increment(-1),
        'follower_array': FieldValue.arrayRemove([currentUserId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'following': FieldValue.increment(-1),
        'following_array': FieldValue.arrayRemove([user.uid]),
      });

      setState(() {
        _following.remove(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _searchUsers(),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          UserModel user = _filteredUsers[index];
          bool isFollowing = _following.contains(user.uid);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.imageUrl),
            ),
            title: Text(user.name),
            trailing: ElevatedButton(
              onPressed: () {
                if (isFollowing) {
                  _unfollowUser(user);
                } else {
                  _followUser(user);
                }
              },
              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
            ),
          );
        },
      ),
    );
  }
}
