import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentSpecificClass extends StatefulWidget {
  final String community;

  const StudentSpecificClass({Key? key, required this.community}) : super(key: key);

  @override
  _StudentSpecificClassState createState() => _StudentSpecificClassState();
}

class _StudentSpecificClassState extends State<StudentSpecificClass> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late CollectionReference _chatCollection;
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _chatCollection = FirebaseFirestore.instance.collection('${widget.community}_chat');
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    _chatCollection.orderBy('timestamp').snapshots().listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final uid = _auth.currentUser!.uid;

      await _chatCollection.add({
        'uid': uid,
        'name': 'Student', // Placeholder name; you can fetch actual name if needed
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear(); // Clear the input field
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.community} Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent background for student messages
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey), // Optional border for clarity
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['name'], // Display the sender's name
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg['message'],
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
