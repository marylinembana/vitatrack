import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/message_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Conversation d'un compte avec son interlocuteur (patient ↔ coach).
class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = MessageRepository.instance;
  final _scrollController = ScrollController();

  String get _myId {
    final auth = context.read<AuthProvider>();
    return auth.role == 'nutritionist'
        ? auth.currentNutritionist?.id ?? ''
        : context.read<AppProvider>().user?.id ?? '';
  }

  String get _myRole => context.read<AuthProvider>().role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    await _repo.markConversationRead(widget.conversation.id, _myId);
  }

  Future<void> _send(String text) async {
    await _repo.send(
      conversationId: widget.conversation.id,
      senderId: _myId,
      senderRole: _myRole,
      text: text,
    );
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation =
        _repo.byId(widget.conversation.id) ?? widget.conversation;
    return Scaffold(
      appBar: AppBar(
        title: Text(conversation.nutritionistId == _myId
            ? 'Patient'
            : 'Mon coach'),
        backgroundColor: AppColors.primarySoft,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: conversation.messages.length,
              itemBuilder: (context, i) {
                final message = conversation.messages[i];
                return MessageBubble(
                  message: message,
                  isMine: message.senderId == _myId,
                );
              },
            ),
          ),
          const Divider(height: 1),
          ChatInput(onSend: _send),
        ],
      ),
    );
  }
}
