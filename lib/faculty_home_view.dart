import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faculty_view.dart';
import 'communities_view.dart';
import 'package:unicons/unicons.dart';
import 'package:famlicious_app/views/auth/login_view.dart';

class FacultyHomeView extends StatefulWidget {
  const FacultyHomeView({Key? key}) : super(key: key);

  @override
  _FacultyHomeViewState createState() => _FacultyHomeViewState();
}

class _FacultyHomeViewState extends State<FacultyHomeView> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  int _currentIndex = 0;
  bool _isAvailable = false; // Track availability status

  final List<Widget> _views = [
    FacultyView(),
    const CommunitiesView(),
  ];

  @override
  void initState() {
    super.initState();
    isUserAuth();
    _getAvailabilityStatus(); // Fetch current availability status on init
  }

  void isUserAuth() {
    _firebaseAuth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
        );
      }
    });
  }

  Future<void> _getAvailabilityStatus() async {
    String userId = _firebaseAuth.currentUser!.uid;

    DocumentSnapshot doc = await _firestore.collection('professors').doc(userId).get();
    if (doc.exists) {
      setState(() {
        _isAvailable = doc['isAvailable'] ?? false; // Get the availability status
      });
    }
  }

  void _toggleAvailability(bool value) async {
    setState(() {
      _isAvailable = value;
    });

    String userId = _firebaseAuth.currentUser!.uid;

    // Update the availability status in Firestore
    await _firestore.collection('professors').doc(userId).set({
      'isAvailable': _isAvailable,
    }, SetOptions(merge: true)); // Use merge to avoid overwriting other fields

    // Optionally, show a message to indicate success
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isAvailable ? 'You are now available' : 'You are now unavailable'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is authenticated
    if (_firebaseAuth.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Home'),
        actions: [
          Switch(
            value: _isAvailable,
            onChanged: _toggleAvailability,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'App Logo',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(UniconsLine.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                // Handle the dashboard action
              },
            ),
            ListTile(
              leading: const Icon(UniconsLine.setting),
              title: const Text('Settings'),
              onTap: () {
                // Handle the settings action
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        children: _views,
        index: _currentIndex,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).iconTheme.color,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(UniconsLine.user),
            label: 'Faculty',
          ),
          BottomNavigationBarItem(
            icon: Icon(UniconsLine.comment_dots),
            label: 'Communities',
          ),
        ],
      ),
    );
  }
}
