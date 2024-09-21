import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famlicious_app/services/file_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostManager with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  final CollectionReference<Map<String, dynamic>> _postCollection =
  _firebaseFirestore.collection("posts");
  final CollectionReference<Map<String, dynamic>> _userCollection =
  _firebaseFirestore.collection("users");

  final FileUploadService _fileUploadService = FileUploadService();

  String _message = '';

  String get message => _message; // Getter for message

  // Getter for currentUserUid
  String? get currentUserUid => _firebaseAuth.currentUser?.uid;

  /// Method to increment like count
  Future<void> incrementLikeCount(String postId) async {
    var postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({
      'like_count': FieldValue.increment(1),
    });
  }

  /// Method to get all posts sorted by creation date (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPostsSortedByDate() {
    return _postCollection.orderBy('createdAt', descending: true).snapshots();
  }

  /// Method to toggle like for a post
  Future<void> toggleLikePost(String postId, postData, bool userLiked) async {
    String? userUid = currentUserUid;
    if (userUid == null) {
      return; // Handle the case where the user is not logged in
    }

    var postRef = _postCollection.doc(postId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (snapshot.exists) {
        List likedBy = snapshot['liked_by'] ?? [];
        bool userHasLiked = likedBy.contains(userUid);
        int newLikeCount = userHasLiked
            ? (snapshot['like_count'] ?? 0) - 1
            : (snapshot['like_count'] ?? 0) + 1;

        transaction.update(postRef, {
          'like_count': newLikeCount,
          'liked_by': userHasLiked
              ? FieldValue.arrayRemove([userUid])
              : FieldValue.arrayUnion([userUid]),
        });
      }
    });
  }

  /// Method to add a comment to a post
  Future<void> addComment(String postId, String comment) async {
    var postRef = _postCollection.doc(postId);
    await postRef.update({
      'comment_count': FieldValue.increment(1),
      'comments_array': FieldValue.arrayUnion([comment]),
    });
  }

  /// Setter for message
  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }

  /// Method to submit a post
  Future<bool> submitPost({
    String? description,
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

    // Upload the image and get the URL
    String? pictureUrl = await _fileUploadService.uploadPostFile(file: postImage);

    if (pictureUrl != null) {
      try {
        // Create a new post document
        await _postCollection.add({
          "description": description,
          "image_url": pictureUrl,
          "createdAt": timeStamp,
          "user_uid": userUid, // Ensure user ID is included
          "like_count": 0, // Initialize like count
          "comment_count": 0, // Initialize comment count
          "liked_by": [], // Initialize an empty list for users who liked the post
          "comments_array": [] // Initialize an empty array for comments
        });
        isSubmitted = true;
        setMessage('Post submitted successfully!');
      } catch (error) {
        isSubmitted = false;
        setMessage('Error: $error');
      }
    } else {
      isSubmitted = false;
      setMessage('Image upload failed!');
    }

    return isSubmitted;
  }

  /// Stream to get all posts sorted by createdAt (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPosts() {
    return _postCollection.orderBy('createdAt', descending: true).snapshots();
  }

  /// Method to get user info from Firestore by UID
  Future<Map<String, dynamic>?> getUserInfo(String userUid) async {
    Map<String, dynamic>? userData;
    await _userCollection.doc(userUid).get().then(
            (DocumentSnapshot<Map<String, dynamic>> doc) {
          if (doc.exists) {
            userData = doc.data();
          } else {
            userData = null;
          }
        });
    return userData;
  }
}
