import 'package:ai_chatbot/data/chat_message_model.dart';
import 'package:ai_chatbot/utils/message_sender_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Replace with your actual Gemini API key
  static final _apiKey = dotenv.env['API_KEY'] ?? 'API_KEY_NOT_FOUND';
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  // Set up the Gemini model
  late final GenerativeModel _model;
  late final ChatSession _chat;
  @override
  void initState() {
    super.initState();
    // Initialise Gemini with the gemini-3.6-flash model
    _model = GenerativeModel(model: 'gemini-3.6-flash', apiKey: _apiKey);
    // Start a chat session — this remembers conversation history
    _chat = _model.startChat(
      history: [
        Content.text(
          'You are a helpful Flutter development assistant. '
          'Answer questions clearly and concisely. '
          'When showing code, use Dart/Flutter syntax.',
        ),
      ],
    );
    // Add a welcome message from the AI
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your Flutter AI assistant. '
            'Ask me anything about Flutter, Dart, or mobile development!',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send a message to Gemini and get a response
  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;
    // Add user's message to the chat
    setState(() {
      _messages.add(
        ChatMessage(
          text: userInput,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      // Send message to Gemini
      final response = await _chat.sendMessage(Content.text(userInput));
      final aiText = response.text ?? 'Sorry, I could not generate a response.';
      // Add AI response to the chat
      setState(() {
        _messages.add(
          ChatMessage(
            text: aiText,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      // Stampa l'errore reale nella console di debug di VS Code o Android Studio

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Error: ${e.toString()}', // Mostra l'errore reale anche in UI per test
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // Scroll to the latest message automatically
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 16,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            SizedBox(width: 10),
            Text('AI Assistant'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Loading indicator when AI is thinking
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 14,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          // Message input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // Builds each chat bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 14,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 14,
              child: Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  // Builds the text input bar at the bottom
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about Flutter...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _isLoading ? null : _sendMessage,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
