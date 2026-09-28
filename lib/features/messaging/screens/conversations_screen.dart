import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/nutritionist_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'chat_screen.dart';

/// Liste des conversations (utilisateur voit son coach, nutritionniste voit
/// ses patients).
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _repo = MessageRepository.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDemoThread());
  }

  bool get _isNutritionist =>
      context.read<AuthProvider>().role == 'nutritionist';

  String get _accountId => _isNutritionist
      ? context.read<AuthProvider>().currentNutritionist?.id ?? ''
      : context.read<AppProvider>().user?.id ?? '';

  /// Ouvre automatiquement la conversation avec le nutritionniste démo
  /// (côté utilisateur) pour la démonstration.
  Future<void> _openDemoThread() async {
    if (_isNutritionist) return;
    final userId = _accountId;
    if (userId.isEmpty) return;
    await _repo.openConversation(
      userId: userId,
      nutritionistId: 'acc_demo_nutritionist',
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conversations = _repo.forAccount(_accountId);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversations.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Aucune conversation',
              message: 'Vos échanges avec votre coach apparaîtront ici.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: conversations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final conv = conversations[i];
                final otherName = _otherName(conv, auth);
                final last = conv.lastMessage;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        otherName.isNotEmpty ? otherName[0] : '?',
                        style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(otherName),
                    subtitle: Text(
                      last?.text ?? 'Nouvelle conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _hasUnread(conv)
                        ? Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(conversation: conv)),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }

  bool _hasUnread(ConversationModel conv) {
    final last = conv.lastMessage;
    return last != null && !last.isRead && last.senderId != _accountId;
  }

  String _otherName(ConversationModel conv, AuthProvider auth) {
    if (_isNutritionist) {
      return UserRepository.instance.byId(conv.userId)?.fullName ?? 'Patient';
    }
    return NutritionistRepository.instance.byIdOrNull(conv.nutritionistId)?.fullName ??
        'Coach';
  }
}
