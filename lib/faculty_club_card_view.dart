import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For Date formatting

class FacultyClubCardView extends StatefulWidget {
  final String community;

  const FacultyClubCardView({Key? key, required this.community}) : super(key: key);

  @override
  _FacultyClubCardViewState createState() => _FacultyClubCardViewState();
}

class _FacultyClubCardViewState extends State<FacultyClubCardView> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();
  DateTime? _eventDate;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  CollectionReference? _clubCardCollection;

  @override
  void initState() {
    super.initState();
    _clubCardCollection = FirebaseFirestore.instance
        .collection('specific_communities')
        .doc('${widget.community}_card_view')
        .collection('events');
    _fetchEventCard();
  }

  Future<void> _fetchEventCard() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('specific_communities').doc('${widget.community}_card_view').get();

      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          _eventNameController.text = data?['event_name'] ?? '';
          _eventTimeController.text = data?['event_time'] ?? '';
          _eventLocationController.text = data?['event_location'] ?? '';
          _eventDate = (data?['event_date'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      // Handle errors if necessary
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _postEventCard() async {
    if (_eventNameController.text.isNotEmpty &&
        _eventTimeController.text.isNotEmpty &&
        _eventLocationController.text.isNotEmpty &&
        _eventDate != null) {
      await FirebaseFirestore.instance.collection('specific_communities').doc('${widget.community}_card_view').set({
        'event_name': _eventNameController.text,
        'event_time': _eventTimeController.text,
        'event_location': _eventLocationController.text,
        'event_date': _eventDate,
        'faculty_uid': _auth.currentUser!.uid,
      });

      // Show alert dialog on successful post
      _showSuccessDialog();
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Event has been successfully posted!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.community} Club Event')),
      body: SingleChildScrollView( // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eventTimeController,
              decoration: const InputDecoration(labelText: 'Event Time'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eventLocationController,
              decoration: const InputDecoration(labelText: 'Event Location'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _eventDate == null
                        ? 'No Event Date Chosen'
                        : 'Event Date: ${DateFormat.yMMMd().format(_eventDate!)}',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _postEventCard,
              child: const Text('Post Event'),
            ),
          ],
        ),
      ),
    );
  }
}
