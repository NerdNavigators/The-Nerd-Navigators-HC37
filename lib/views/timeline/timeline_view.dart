import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unicons/unicons.dart';
import 'create_post_view.dart';

class TimelineView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No posts available'));
          }

          List<Map<String, dynamic>> posts = [];

          for (var doc in snapshot.data!.docs) {
            var postData = doc.data() as Map<String, dynamic>? ?? {};
            postData['id'] = doc.id;
            posts.add(postData);
          }

          // Sort posts by createdAt
          posts.sort((a, b) {
            var timeA = a['createdAt'] as Timestamp? ?? Timestamp.now();
            var timeB = b['createdAt'] as Timestamp? ?? Timestamp.now();
            return timeB.compareTo(timeA); // Descending order
          });

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostItem(postData: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostView()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Post',
      ),
    );
  }
}

class PostItem extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostItem({required this.postData});

  @override
  Widget build(BuildContext context) {
    String postId = postData['id'] ?? '';
    String description = postData['description'] ?? 'No description available';
    String imageUrl = postData['imageUrl'] ?? '';
    String username = postData['username'] ?? 'Unknown User';
    int likeCount = postData['likes'] ?? 0;
    List<dynamic> likedUsers = postData['liked_users'] ?? [];
    List<dynamic> commentsArray = postData['comments_array'] ?? [];
    int commentCount = postData['comments'] ?? 0;
    String userUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Timestamp createdAt = postData['createdAt'] as Timestamp? ?? Timestamp.now();

    bool userHasLiked = likedUsers.contains(userUid);

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Username
            Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),

            // Post Description
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),

            // Post Image
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),

            // Created At
            Text('Posted on: ${createdAt.toDate()}'),

            // Like and Comment Buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(userHasLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                  onPressed: () => _toggleLikePost(postId, userUid, userHasLiked),
                ),
                Text('$likeCount'),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: () => _showCommentDialog(context, postId),
                ),
                Text('$commentCount'),
              ],
            ),

            // Display Comments
            if (commentsArray.isNotEmpty)
              ...commentsArray.map((comment) {
                return ListTile(
                  title: Text(comment['text'] ?? 'No comment text'),
                  subtitle: Text("By: ${comment['username'] ?? 'Unknown'}"), // Fetching username from comment
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _toggleLikePost(String postId, String userUid, bool userHasLiked) async {
    var postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (snapshot.exists) {
        var newLikeCount = (snapshot['likes'] ?? 0) + (userHasLiked ? -1 : 1);

        transaction.update(postRef, {
          'likes': newLikeCount,
          'liked_users': userHasLiked
              ? FieldValue.arrayRemove([userUid])
              : FieldValue.arrayUnion([userUid]),
        });
      }
    });
  }

  void _showCommentDialog(BuildContext context, String postId) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addComment(postId, commentController.text);
                Navigator.pop(context);
              },
              child: Text('Post'),
            ),
          ],
        );
      },
    );
  }

  void _addComment(String postId, String comment) async {
    var postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    String userUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Fetch the username from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
    String username = userSnapshot['username'] ?? 'Unknown User';

    await postRef.update({
      'comments_array': FieldValue.arrayUnion([{'text': comment, 'username': username}]), // Added username
      'comments': FieldValue.increment(1),
    });
  }
}

class CreatePostView extends StatefulWidget {
  const CreatePostView({Key? key}) : super(key: key);

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _postTxtController = TextEditingController();
  File? _postImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  bool isLoading = false;

  // List of prohibited words
  final List<String> prohibitedWords = [
    "sex", "porn", "drugs", "alcohol", "fight", "kill",
    "पार्टी", "दारू", "गुटखा", "शिव्या",
    "सेक्स", "शराब", "गाली", "जुआ", "अश्लील", "खून"
  ];

  /// Select image from camera or gallery
  Future<void> selectImage(ImageSource imageSource) async {
    XFile? file = await _imagePicker.pickImage(source: imageSource);
    if (file != null) {
      setState(() {
        _postImageFile = File(file.path);
      });
    }
  }

  // Method to validate post description against prohibited words
  bool _validatePostContent(String content) {
    for (String word in prohibitedWords) {
      if (content.toLowerCase().contains(word.toLowerCase())) {
        return false; // Prohibited content found
      }
    }
    return true; // Content is valid
  }

  /// Upload image to Firebase Storage and create a post in Firestore
  Future<void> submitPost() async {
    String postContent = _postTxtController.text.trim();

    // Validate post description for prohibited words
    if (!_validatePostContent(postContent)) {
      Fluttertoast.showToast(
        msg: "Please post wisely!!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Stop submission if invalid content is found
    }

    if (_postImageFile == null) {
      Fluttertoast.showToast(
        msg: "Please select a picture",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = FirebaseStorage.instance.ref().child("posts/$fileName");
      UploadTask uploadTask = reference.putFile(_postImageFile!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Create a new post in Firestore
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      String username = (await FirebaseFirestore.instance.collection('users').doc(userUid).get()).data()?['name'] ?? 'Unknown User';

      await FirebaseFirestore.instance.collection('posts').add({
        'description': postContent,
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'liked_users': [],
        'comments': 0,
        'comments_array': [],
        'username': username, // Include username
      });

      // Clear input fields
      _postTxtController.clear();
      setState(() {
        _postImageFile = null;
        isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Post created successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: "Failed to create post",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postTxtController,
              decoration: InputDecoration(
                labelText: 'Post Description',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            if (_postImageFile != null)
              Image.file(_postImageFile!),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => selectImage(ImageSource.gallery),
                  icon: Icon(Icons.image),
                  label: Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: () => selectImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : submitPost,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}
