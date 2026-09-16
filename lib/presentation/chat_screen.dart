import 'dart:typed_data';

import 'package:ai_chatbot/data/chat_message_model.dart';
import 'package:ai_chatbot/presentation/chat_cubit.dart';
import 'package:ai_chatbot/presentation/chat_state.dart';
import 'package:ai_chatbot/presentation/profile_cubit.dart';
import 'package:ai_chatbot/presentation/profile_state.dart';
import 'package:ai_chatbot/utils/message_sender_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

enum _AvatarAction { camera, gallery, remove }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static String get _apiKey {
    try {
      return dotenv.env['API_KEY'] ?? 'API_KEY_NOT_FOUND';
    } catch (_) {
      return 'API_KEY_NOT_FOUND';
    }
  }

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    await context.read<ChatCubit>().sendMessage(_controller.text);
    _controller.clear();
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null || !context.mounted) return;

    final imageBytes = await image.readAsBytes();
    if (!context.mounted) return;

    await context.read<ChatCubit>().sendImage(
      imageBytes: imageBytes,
      mimeType: image.mimeType ?? 'image/jpeg',
    );
  }

  Future<void> _showImageSourcePicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null && context.mounted) {
      await _pickImage(context, source);
    }
  }

  Future<void> _pickUserAvatar(
    BuildContext providerContext,
    ImageSource source,
  ) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (image == null || !providerContext.mounted) return;

    final avatarBytes = await image.readAsBytes();
    if (!providerContext.mounted) return;
    await providerContext.read<ProfileCubit>().setAvatar(avatarBytes);
  }

  Future<void> _showAvatarSourcePicker(BuildContext providerContext) async {
    final hasAvatar =
        providerContext.read<ProfileCubit>().state.avatarBytes != null;
    final action = await showModalBottomSheet<_AvatarAction>(
      context: providerContext,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, _AvatarAction.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, _AvatarAction.gallery),
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove avatar'),
                  onTap: () => Navigator.pop(context, _AvatarAction.remove),
                ),
            ],
          ),
        );
      },
    );
    if (action == null || !providerContext.mounted) return;

    switch (action) {
      case _AvatarAction.camera:
        await _pickUserAvatar(providerContext, ImageSource.camera);
      case _AvatarAction.gallery:
        await _pickUserAvatar(providerContext, ImageSource.gallery);
      case _AvatarAction.remove:
        await providerContext.read<ProfileCubit>().removeAvatar();
    }
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ChatCubit(apiKey: _apiKey)),
        BlocProvider(create: (_) => ProfileCubit()),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          return BlocConsumer<ChatCubit, ChatState>(
            listener: (_, __) => _scrollToBottom(),
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(
                  title: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        radius: 16,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('AI Assistant'),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  actions: [
                    IconButton(
                      onPressed: () => _showAvatarSourcePicker(context),
                      tooltip: 'Change your avatar',
                      icon: _buildUserAvatar(profileState.avatarBytes),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            state.messages[index],
                            profileState.avatarBytes,
                          );
                        },
                      ),
                    ),
                    if (state.isLoading) _buildLoadingIndicator(),
                    _buildInputBar(context, state.isLoading),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            radius: 14,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          SizedBox(width: 8),
          Text('AI is thinking...', style: TextStyle(color: Colors.grey)),
          SizedBox(width: 8),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  // Builds each chat bubble
  Widget _buildMessageBubble(ChatMessage message, Uint8List? avatarBytes) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 280,
                        height: 190,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(avatarBytes, radius: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Uint8List? avatarBytes, {double radius = 16}) {
    return CircleAvatar(
      backgroundColor: Colors.grey,
      radius: radius,
      backgroundImage: avatarBytes == null ? null : MemoryImage(avatarBytes),
      child:
          avatarBytes == null
              ? Icon(Icons.person, color: Colors.white, size: radius)
              : null,
    );
  }

  // Builds the text input bar at the bottom
  Widget _buildInputBar(BuildContext context, bool isLoading) {
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
            IconButton(
              onPressed:
                  isLoading ? null : () => _showImageSourcePicker(context),
              tooltip: 'Identify a widget from an image',
              icon: const Icon(Icons.image_search),
            ),
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
                onSubmitted: (_) => _sendMessage(context),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: isLoading ? null : () => _sendMessage(context),
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
