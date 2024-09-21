import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:famlicious_app/views/auth/login_view.dart'; // Make sure to import your login view here
import 'package:unicons/unicons.dart';

class FacultyView extends StatefulWidget {
  const FacultyView({Key? key}) : super(key: key);

  @override
  _FacultyViewState createState() => _FacultyViewState();
}

class _FacultyViewState extends State<FacultyView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty View'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                // Navigate to LoginView after successful logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                      (route) => false, // Prevent returning to previous views
                );
              } catch (e) {
                // Display error message if any issue occurs during logout
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                  ),
                );
              }
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
            const Text(
              'Welcome to the Faculty Portal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Manage Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Replace this with actual event management widget or content
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Event management content goes here...'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Manage Submissions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Replace this with actual submission management widget or content
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Submission management content goes here...'),
            ),
          ],
        ),
      ),
    );
  }
}
