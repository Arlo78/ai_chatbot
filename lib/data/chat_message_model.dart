import 'dart:typed_data';

import 'package:ai_chatbot/utils/message_sender_enum.dart';

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes,
  });
}
