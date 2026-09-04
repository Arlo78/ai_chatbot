import 'package:ai_chatbot/data/chat_message_model.dart';
import 'package:ai_chatbot/presentation/chat_state.dart';
import 'package:ai_chatbot/utils/message_sender_enum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required String apiKey})
    : _chat = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
      ).startChat(
        history: [
          Content.text(
            'You are a helpful Flutter development assistant. '
            'Answer questions clearly and concisely. '
            'When showing code, use Dart/Flutter syntax.',
          ),
        ],
      ),
      super(
        ChatState(
          messages: [
            ChatMessage(
              text:
                  'Hello! I\'m your Flutter AI assistant. '
                  'Ask me anything about Flutter, Dart, or mobile development!',
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          ],
          isLoading: false,
        ),
      );

  final ChatSession _chat;

  Future<void> sendMessage(String text) async {
    final userInput = text.trim();
    if (userInput.isEmpty || state.isLoading) return;

    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: userInput,
            sender: MessageSender.user,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: true,
      ),
    );

    try {
      final response = await _chat.sendMessage(Content.text(userInput));
      final aiText = response.text ?? 'Sorry, I could not generate a response.';
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(
              text: aiText,
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          ],
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(
              text: 'Error: $error',
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          ],
          isLoading: false,
        ),
      );
    }
  }
}
