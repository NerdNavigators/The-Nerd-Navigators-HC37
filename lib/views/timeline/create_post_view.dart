import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostManager with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  final CollectionReference<Map<String, dynamic>> _postCollection =
  _firebaseFirestore.collection("posts");
  final CollectionReference<Map<String, dynamic>> _userCollection =
  _firebaseFirestore.collection("users");

  String _message = '';

  String get message => _message; // Getter for message

  // Getter for currentUserUid
  String? get currentUserUid => _firebaseAuth.currentUser?.uid;

  /// Method to set the message
  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }

  /// Method to submit a post with an image, description, and create a comments_array subcollection
  Future<bool> submitPost({
    required String description,
    required File postImage,
  }) async {
    bool isSubmitted = false;

    // Ensure the user is authenticated
    if (_firebaseAuth.currentUser == null) {
      setMessage('User is not authenticated!');
      return isSubmitted;
    }

    String userUid = _firebaseAuth.currentUser!.uid; // Get current user UID
    FieldValue timeStamp = FieldValue.serverTimestamp();

    // Upload the image to Firebase Storage and get the URL
    String? imageUrl = await _uploadPostImage(postImage, userUid);

    if (imageUrl != null) {
      try {
        // Get the user's name from Firestore
        DocumentSnapshot userDoc = await _userCollection.doc(userUid).get();
        String username = userDoc['name'] ?? 'Unknown User';

        // Create a new post document in Firestore
        DocumentReference postRef = await _postCollection.add({
          "description": description,
          "image_url": imageUrl,
          "createdAt": timeStamp,
          "user_uid": userUid, // Ensure user ID is included
          "username": username,
          "like_count": 0, // Initialize like count
          "comment_count": 0, // Initialize comment count
          "liked_by": [], // Initialize an empty list for users who liked the post
        });

        // Create an empty comments_array subcollection
        await postRef.collection('comments_array').add({
          'placeholder': 'This will be replaced when the first comment is added',
        });

        isSubmitted = true;
        setMessage('Post submitted successfully!');
        Fluttertoast.showToast(
          msg: "Post submitted successfully!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (error) {
        isSubmitted = false;
        setMessage('Error: $error');
        Fluttertoast.showToast(
          msg: "Error: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      isSubmitted = false;
      setMessage('Image upload failed!');
      Fluttertoast.showToast(
        msg: "Image upload failed!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    return isSubmitted;
  }

  /// Method to upload the post image to Firebase Storage and get the image URL
  Future<String?> _uploadPostImage(File image, String userUid) async {
    try {
      // Create a unique file path for the image
      String filePath = 'posts/$userUid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

      // Upload the file to Firebase Storage
      await storageRef.putFile(image);

      // Get the URL of the uploaded image
      String imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  /// Stream to get all posts sorted by createdAt (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPosts() {
    return _postCollection.orderBy('createdAt', descending: true).snapshots();
  }
}
