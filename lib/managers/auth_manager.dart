import 'dart:io';
import 'package:famlicious_app/services/file_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthManager with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FileUploadService _fileUploadService = FileUploadService();
  String _message = '';
  bool _isLoading = false;
  CollectionReference userCollection = _firebaseFirestore.collection("users");

  String get message => _message; // Getter
  bool get isLoading => _isLoading; // Getter

  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }

  void setIsLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Create a new user with email, password, name, and profile image
  Future<bool> createNewUser({
    required String name,
    required String email,
    required String password,
    required File imageFile,
  }) async {
    setIsLoading(true);
    bool isCreated = false;

    try {
      // Create user with email and password
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload the profile picture and get the URL
      String? photoUrl = await _fileUploadService.uploadFile(
        file: imageFile,
        userUid: userCredential.user!.uid,
      );

      // If the photo URL is successfully retrieved, save user info in Firestore
      if (photoUrl != null) {
        // Create user document
        await userCollection.doc(userCredential.user!.uid).set({
          "name": name,
          "email": email,
          "picture": photoUrl,
          "createdAt": FieldValue.serverTimestamp(),
          "user_id": userCredential.user!.uid,
          "comments_array": [], // Initialize with an empty list
          // Removed arrays to make way for sub-collections
        });

        // Create sub-collections for followers and following
        await userCollection.doc(userCredential.user!.uid).collection('follower_array').doc('initial').set({});
        await userCollection.doc(userCredential.user!.uid).collection('following_array').doc('initial').set({});

        isCreated = true;
      } else {
        setMessage('Image upload failed!');
      }
    } catch (e) {
      setMessage('$e');
      isCreated = false;
    } finally {
      setIsLoading(false); // Set loading to false regardless of outcome
    }

    return isCreated;
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    bool isSuccessful = false;

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        isSuccessful = true;
      } else {
        setMessage('Could not log you in!');
      }
    } catch (e) {
      setMessage('$e');
      isSuccessful = false;
    }

    return isSuccessful;
  }

  Future<bool> sendResetLink(String email) async {
    bool isSent = false;

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      isSent = true;
    } catch (e) {
      setMessage('$e');
      isSent = false;
    }

    return isSent;
  }
}
