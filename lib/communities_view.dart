import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'communities_chat_view.dart'; // Ensure this is imported correctly
import 'faculty_club_card_view.dart'; // Ensure this is imported correctly

class CommunitiesView extends StatefulWidget {
  const CommunitiesView({Key? key}) : super(key: key);

  @override
  _CommunitiesViewState createState() => _CommunitiesViewState();
}

class _CommunitiesViewState extends State<CommunitiesView> {
  String? community;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCommunity();
  }

  Future<void> _fetchCommunity() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      QuerySnapshot facultyDocs = await FirebaseFirestore.instance.collection('faculty').get();

      for (var doc in facultyDocs.docs) {
        if (doc['uid'] == uid) {
          setState(() {
            community = doc['community'];
            isLoading = false;
          });
          return; // Exit after finding the matching document
        }
      }

      // If no matching document found
      setState(() {
        community = 'Please join any specific community';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        community = 'Error fetching community: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no community or 'none' is returned
    if (community == 'none' || community == null) {
      return Center(
        child: Text(community == null
            ? 'Please join any specific community'
            : 'No community assigned.'),
      );
    }

    return Column(
      children: [
        // Fixed upper part: Faculty Club Card View
        Container(
          height: 350, // Set a fixed height for the upper box
          child: FacultyClubCardView(community: community!), // Display the Faculty Club Card View here
        ),
        // Scrollable lower part: Chat functionality
        Expanded(
          child: CommunityChatView(community: community!), // Use the actual chat view
        ),
      ],
    );
  }
}
