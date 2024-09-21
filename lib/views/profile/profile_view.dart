import 'package:cached_network_image/cached_network_image.dart';
import 'package:famlicious_app/views/auth/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String? profileImageUrl;
  String? username; // Variable to store username
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user profile and posts using username
  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          profileImageUrl = userDoc['picture'] as String?;
          username = userDoc['name'] as String?; // Fetch the username
        });

        // Now fetch the posts using the username
        if (username != null) {
          await _fetchUserPosts(username!);
        }
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  // Fetch user posts by username instead of userId
  Future<void> _fetchUserPosts(String username) async {
    try {
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('username', isEqualTo: username) // Use username in query
          .get();

      List<Map<String, dynamic>> fetchedPosts = postsSnapshot.docs
          .map((doc) => {
        'postId': doc.id,
        'imageUrl': doc['imageUrl'],
        'createdAt': doc['createdAt'],
      })
          .toList();

      // Sort posts by createdAt
      fetchedPosts.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      setState(() {
        userPosts = fetchedPosts;
      });
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edu Profile'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut().then((value) =>
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                          (route) => false));
            },
            icon: const Icon(UniconsLine.exit),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: profileImageUrl != null
                    ? CachedNetworkImageProvider(profileImageUrl!)
                    : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // Followers and Following Count with StreamBuilder
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error loading data');
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('User not found');
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final followersCount = userData['followers'] ?? 0;
                final followingCount = userData['following'] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$followersCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Followers', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$followingCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Following', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // User Posts Grid or No Posts Message
            const Text('My Posts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: userPosts.isEmpty
                  ? const Center(
                  child: Text('No Posts Yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)))
                  : GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: userPosts.length,
                itemBuilder: (context, index) {
                  String imageUrl = userPosts[index]['imageUrl'] ?? '';

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const Center(
                          child:
                          CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: const Center(
                          child: Icon(Icons.error, size: 40)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
