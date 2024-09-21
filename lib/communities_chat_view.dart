import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityChatView extends StatefulWidget {
  final String community;

  const CommunityChatView({Key? key, required this.community}) : super(key: key);

  @override
  _CommunityChatViewState createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late CollectionReference _chatCollection;
  List<Map<String, dynamic>> messages = [];
  String? facultyName;
  bool isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _chatCollection = FirebaseFirestore.instance.collection('${widget.community}_chat');
    _fetchFacultyName(); // Fetch faculty name first
    _fetchMessages();
  }

  Future<void> _fetchFacultyName() async {
    final uid = _auth.currentUser!.uid;
    try {
      QuerySnapshot facultyDocs = await FirebaseFirestore.instance.collection('faculty').get();

      for (var doc in facultyDocs.docs) {
        if (doc['uid'] == uid) {
          setState(() {
            facultyName = doc['name']; // Fetch the faculty name
            isLoading = false; // Stop loading
          });
          return; // Exit once we find the match
        }
      }

      // If no matching document found
      setState(() {
        facultyName = 'Anonymous'; // Default name if not found
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        facultyName = 'Error fetching name';
        isLoading = false;
      });
    }
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
        'name': facultyName ?? 'Anonymous', // Use the fetched faculty name
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
                final isFacultyMessage = msg['uid'] == _auth.currentUser!.uid; // Check if it's the faculty's message

                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isFacultyMessage ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['name'],
                        style: TextStyle(fontWeight: isFacultyMessage ? FontWeight.bold : FontWeight.normal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg['message'],
                          style: TextStyle(fontWeight: isFacultyMessage ? FontWeight.bold : FontWeight.normal),
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
