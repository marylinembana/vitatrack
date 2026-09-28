import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Liste des notifications et rappels.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository.instance;
  late final String _userId =
      context.read<AppProvider>().user?.id ?? '';
  List<NotificationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _items = _repo.forUser(_userId);
  }

  IconData _icon(String type) => switch (type) {
        'reminder' => Icons.alarm,
        'message' => Icons.chat_bubble_outline,
        'plan' => Icons.restaurant_menu,
        _ => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: () async {
                await _repo.markAllRead(_userId);
                setState(() => _items = _repo.forUser(_userId));
              },
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Aucune notification',
              message: 'Vos rappels et notifications apparaîtront ici.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final n = _items[i];
                return AppCard(
                  onTap: () async {
                    await _repo.markRead(n.id);
                    setState(() => _items = _repo.forUser(_userId));
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icon(n.type), color: AppColors.primary),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: n.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(n.body,
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(DateUtils.relativeLabel(n.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          height: 10,
                          width: 10,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
