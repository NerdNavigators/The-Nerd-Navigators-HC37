import 'package:flutter/material.dart';
import 'package:google_generative_ai/'
    'google_generative_ai.dart';
import 'package:intl/intl.dart';

class AiCareerAssistantView extends StatefulWidget {
  const AiCareerAssistantView({Key? key}) : super(key: key);

  @override
  _AiCareerAssistantViewState createState() => _AiCareerAssistantViewState();
}

class _AiCareerAssistantViewState extends State<AiCareerAssistantView> {
  final TextEditingController _userInput = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const apiKey = "AIzaSyANa5YC1XwsDVBrFl4VxiPzIT3fwsx7exg"; // Replace with your actual API key
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final List<Message> _messages = [];
  bool _isLoading = false; // To track loading state

  @override
  void initState() {
    super.initState();
    // Adding an initial bot message
    _messages.add(Message(
      isUser: false,
      message: "Hello, how can I help you?",
      date: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add the user's message to the chat
    setState(() {
      _messages.add(Message(isUser: true, message: message, date: DateTime.now()));
      _isLoading = true; // Start loading indicator
    });

    // Scroll down when a new message is sent
    _scrollToBottom();

    // Clear the user input field
    _userInput.clear();

    // Add loading animation
    setState(() {
      // Show a custom loading animation while waiting for the response
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.removeLast(); // Remove any previous loading indicator
      }
      _messages.add(Message(isUser: false, message: "", date: DateTime.now(), isLoading: true));
    });

    final content = [Content.text(message)];
    final response = await model.generateContent(content);

    // Avoid symbols in the response (like "*" or "#")
    final cleanResponse = response.text?.replaceAll(RegExp(r'[#*]'), '');

    // Update the message with the response
    setState(() {
      // Remove the loading indicator
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.removeLast(); // Remove the loading indicator
      }
      _messages.add(Message(
        isUser: false,
        message: cleanResponse ?? "Unable to answer the question. Please try again.",
        date: DateTime.now(),
        isLoading: false,
      ));
      _isLoading = false; // Stop loading indicator
    });

    // Scroll down when bot replies
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 2, 87, 156),
        title: Row(
          children: const [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.chat, color: Color.fromARGB(255, 2, 87, 156)),
            ),
            SizedBox(width: 10),
            Text('StudySensei', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Messages(
                  isUser: message.isUser,
                  message: message.message,
                  date: DateFormat('HH:mm').format(message.date),
                  isLoading: message.isLoading, // Pass the loading state to Messages widget
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // Widget for the input area
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                controller: _userInput,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type a message",
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _sendMessage(_userInput.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 2, 87, 156),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Message model class with loading state
class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final bool isLoading; // Add loading state

  Message({required this.isUser, required this.message, required this.date, this.isLoading = false});
}

// Chat bubble widget for messages
class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  final bool isLoading; // Add loading state

  const Messages({
    Key? key,
    required this.isUser,
    required this.message,
    required this.date,
    this.isLoading = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color.fromARGB(255, 2, 87, 156) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              _CustomLoadingAnimation() // Show loading animation if isLoading is true
            else
              Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                date,
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Loading Animation Widget
class _CustomLoadingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: const Color.fromARGB(255, 2, 87, 156),
      ),
    );
  }
}
