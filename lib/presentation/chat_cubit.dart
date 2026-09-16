import 'dart:typed_data';

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

    await _sendContent(
      displayText: userInput,
      content: Content.text(userInput),
    );
  }

  Future<void> sendImage({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt =
        'Identify the Flutter widget shown in this image. Explain the visual clues you used, describe its likely purpose, and mention any uncertainty. If it is not a Flutter widget, say what it appears to be instead.',
  }) async {
    if (state.isLoading) return;

    await _sendContent(
      displayText: '[Image] $prompt',
      content: Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]),
      imageBytes: imageBytes,
    );
  }

  Future<void> _sendContent({
    required String displayText,
    required Content content,
    Uint8List? imageBytes,
  }) async {
    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: displayText,
            sender: MessageSender.user,
            timestamp: DateTime.now(),
            imageBytes: imageBytes,
          ),
        ],
        isLoading: true,
      ),
    );

    try {
      final response = await _chat.sendMessage(content);
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
