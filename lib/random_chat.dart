import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? matchedUserId;
  String? matchedUserName;
  String? matchedUserImageUrl;
  bool isFindingChat = false;
  Timer? _timer;

  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startChatSession(String currentUserId, String matchedUserId) async {
    await FirebaseFirestore.instance.collection('chat_queue').doc(matchedUserId).update({
      'matched': true,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: currentUserId,
          matchedUserId: matchedUserId,
          matchedUserName: matchedUserName!,
          matchedUserImageUrl: matchedUserImageUrl!,
        ),
      ),
    );
  }

  Future<void> _findChat() async {
    setState(() {
      isFindingChat = true;
    });

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference chatQueue = FirebaseFirestore.instance.collection('chat_queue');

    try {
      QuerySnapshot snapshot = await chatQueue.where(FieldPath.documentId, isNotEqualTo: currentUserId).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot waitingUser = snapshot.docs.first;

        matchedUserId = waitingUser.id;

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(matchedUserId).get();
        matchedUserName = (userSnapshot.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
        matchedUserImageUrl = (userSnapshot.data() as Map<String, dynamic>)['picture'] ?? '';

        chatQueue.doc(waitingUser.id).snapshots().listen((snapshot) {
          if (snapshot.exists && (snapshot.data() as Map<String, dynamic>)['matched'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  currentUserId: currentUserId,
                  matchedUserId: matchedUserId!,
                  matchedUserName: matchedUserName!,
                  matchedUserImageUrl: matchedUserImageUrl!,
                ),
              ),
            );
          }
        });

        await _startChatSession(currentUserId, matchedUserId!);

        await chatQueue.doc(currentUserId).delete();
        await chatQueue.doc(matchedUserId).delete();
      } else {
        await chatQueue.doc(currentUserId).set({
          'waiting_since': FieldValue.serverTimestamp(),
        });

        _timer = Timer(Duration(minutes: 1), () {
          Fluttertoast.showToast(
            msg: "No active user now. Try again later.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );

          chatQueue.doc(currentUserId).delete();

          setState(() {
            isFindingChat = false;
          });
        });
      }
    } catch (e) {
      print("Error finding chat: $e");
      Fluttertoast.showToast(msg: "Error finding chat: $e");
      setState(() {
        isFindingChat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Center(
        child: isFindingChat
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'The Random Reach',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Break your social limits by connecting with strangers in your own college.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Make friends, grow together!!!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _findChat,
              child: Text('Find Chat'),
            ),
            SizedBox(height: 20),
            matchedUserId != null ? _buildMatchedUserInfo() : SizedBox.shrink(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchedUserInfo() {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(matchedUserImageUrl!),
          radius: 30,
        ),
        SizedBox(height: 10),
        Text('Matched User: $matchedUserName', style: TextStyle(fontSize: 20)),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String matchedUserId;
  final String matchedUserName;
  final String matchedUserImageUrl;

  ChatScreen({
    required this.currentUserId,
    required this.matchedUserId,
    required this.matchedUserName,
    required this.matchedUserImageUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference _chatRef;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseFirestore.instance.collection('chats/${widget.currentUserId}_${widget.matchedUserId}/messages');

    _chatRef.orderBy('timestamp', descending: false).snapshots().listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }, onError: (error) {
      print("Error fetching messages: $error");
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatRef.add({
        'text': _messageController.text,
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.matchedUserName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var message = messages[index];
                return ListTile(
                  title: Text(message['text'] ?? ''),
                  subtitle: Text(message['senderId'] == widget.currentUserId ? 'You' : widget.matchedUserName),
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
                      hintText: 'Type your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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
