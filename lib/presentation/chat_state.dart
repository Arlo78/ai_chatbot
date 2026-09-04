import 'package:ai_chatbot/data/chat_message_model.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  const ChatState({required this.messages, required this.isLoading});

  final List<ChatMessage> messages;
  final bool isLoading;

  @override
  List<Object> get props => [messages, isLoading];

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
