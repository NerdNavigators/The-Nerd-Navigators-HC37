import 'package:famlicious_app/random_chat.dart';
import 'package:famlicious_app/search_view.dart';
import 'package:famlicious_app/views/auth/login_view.dart';
import 'package:famlicious_app/views/chat/chat_view.dart';
import 'package:famlicious_app/views/favourite/favourite_view.dart';
import 'package:famlicious_app/views/profile/profile_view.dart';
import 'package:famlicious_app/views/timeline/timeline_view.dart';
import 'package:famlicious_app/ai_career_assistant_view.dart';
import 'package:famlicious_app/wifi_qr_view.dart';
import 'package:famlicious_app/gamezone_view.dart';
import 'package:famlicious_app/maps_view.dart';
import 'package:famlicious_app/general_community_view.dart'; // Import your General Community view
import 'package:famlicious_app/specified_community_view.dart'; // Import your Specified Community view
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _currentIndex = 0;

  final List<Widget> _views = [
    TimelineView(),
    ChatPage(),
    SearchPage(),
    const ProfileView(),
  ];

  get community => null;

  @override
  void initState() {
    super.initState();
    isUserAuth();
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

  @override
  Widget build(BuildContext context) {
    // Check if the user is authenticated
    if (_firebaseAuth.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(

              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png', // Adjust the path based on your assets folder structure
                    height: 80, // Adjust the height as needed
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome to Famlicious',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(UniconsLine.brain),
              title: const Text('Study Sensei'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCareerAssistantView()));
              },
            ),
            ListTile(
              leading: const Icon(UniconsLine.wifi),
              title: const Text('Wifi QR'),
              onTap: () {
        //         Navigator.push(context, MaterialPageRoute(builder: (_) => QRScannerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(UniconsLine.award),
              title: const Text('Gamezone'),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const GamezoneView()));
              },
            ),
            ListTile(
              leading: const Icon(UniconsLine.map),
              title: const Text('Maps'),
              onTap: () {
        //        Navigator.push(context, MaterialPageRoute(builder: (_) => GoogleMapsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group), // Icon for General Community
              title: const Text('General Community'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GeneralCommunityView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people), // Icon for Specified Community
              title: const Text('Specified Community'),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => StudentSpecificClass(community: community)));
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
            icon: Icon(UniconsLine.history),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(UniconsLine.comment_dots),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(UniconsLine.heart),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(UniconsLine.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
