import 'package:famlicious_app/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GeneralCommunityView extends StatefulWidget {
  const GeneralCommunityView({Key? key}) : super(key: key);

  @override
  _GeneralCommunityViewState createState() => _GeneralCommunityViewState();
}

class _GeneralCommunityViewState extends State<GeneralCommunityView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> upcomingEvents = [];
  List<Map<String, dynamic>> upcomingSubmissions = [];
  bool isEventsView = true; // Track which view is currently displayed
  bool isLoading = true; // Loading indicator
  String errorMessage = ''; // Error message for UI

  @override
  void initState() {
    super.initState();
    fetchEvents();
    fetchSubmissions();
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
    );
  }

  Future<void> fetchEvents() async {
    final now = DateTime.now();
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Fetch the 'events' document
      final eventsDoc = await FirebaseFirestore.instance
          .collection('general_community')
          .doc('events')
          .get();

      if (eventsDoc.exists) {
        // Fetch the sub-collection 'events'
        final eventsSnapshot = await eventsDoc.reference.collection('events').get();

        upcomingEvents = [];
        if (eventsSnapshot.docs.isEmpty) {
          errorMessage = 'No upcoming events found.';
        } else {
          for (var eventDoc in eventsSnapshot.docs) {
            // Extract event attributes
            String eventName = eventDoc['event_name'];
            DateTime eventDate = eventDoc['event_date'].toDate(); // Assuming event_date is a Timestamp
            String location = eventDoc['location'];

            // Only include upcoming events
            if (eventDate.isAfter(now)) {
              upcomingEvents.add({
                'event_name': eventName,
                'event_date': eventDate,
                'location': location,
              });
            }
          }

          // Sort upcoming events by date
          upcomingEvents.sort((a, b) => a['event_date'].compareTo(b['event_date']));
        }
      } else {
        errorMessage = 'Events document does not exist.';
      }
    } catch (e) {
      errorMessage = 'Error fetching events: $e';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSubmissions() async {
    final now = DateTime.now();
    try {
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection('general_community')
          .doc('submission')
          .collection('submission')
          .get();

      upcomingSubmissions = [];
      for (var doc in submissionSnapshot.docs) {
        String submissionDeadline = doc.id; // The document ID is the submission deadline
        var submissionTitlesSnapshot = await FirebaseFirestore.instance
            .collection('general_community')
            .doc('submission')
            .collection('submission')
            .doc(submissionDeadline)
            .collection(submissionDeadline) // Collection named after the deadline
            .get();

        for (var titleDoc in submissionTitlesSnapshot.docs) {
          upcomingSubmissions.add({
            'submission_deadline': submissionDeadline,
            'submission_name': titleDoc.id, // Document ID is the submission title
            'details': titleDoc.data(),
          });
        }
      }

      // Filter and sort upcoming submissions
      upcomingSubmissions = upcomingSubmissions.where((submission) {
        DateTime submissionDeadlineDate =
        DateFormat('yyyy-MM-dd').parse(submission['submission_deadline']);
        return submissionDeadlineDate.isAfter(now);
      }).toList();

      upcomingSubmissions.sort((a, b) => DateFormat('yyyy-MM-dd')
          .parse(a['submission_deadline'])
          .compareTo(DateFormat('yyyy-MM-dd').parse(b['submission_deadline'])));

      setState(() {}); // Update UI
    } catch (e) {
      print('Error fetching submissions: $e');
      setState(() {
        errorMessage = 'Error fetching submissions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('General Community Portal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Footer buttons to toggle between Events and Submissions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEventsView = true;
                  });
                },
                child: Text('Events'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEventsView = false;
                  });
                },
                child: Text('Submissions'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : isEventsView
                  ? _buildEventsList()
                  : _buildSubmissionsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 10),
        if (upcomingEvents.isEmpty)
          Text('No upcoming events.', style: TextStyle(color: Colors.grey)),
        for (var event in upcomingEvents)
          Card(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(event['event_name']),
              subtitle: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(event['event_date'])}\nLocation: ${event['location']}'),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Submissions', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 10),
        if (upcomingSubmissions.isEmpty)
          Text('No upcoming submissions.', style: TextStyle(color: Colors.grey)),
        for (var submission in upcomingSubmissions)
          Card(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(submission['submission_name']),
              subtitle: Text('Deadline: ${submission['submission_deadline']}'),
            ),
          ),
      ],
    );
  }
}
