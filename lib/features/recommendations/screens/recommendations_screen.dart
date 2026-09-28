import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/recommendation_model.dart';
import '../../../../data/repositories/recommendation_repository.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Écran des conseils personnalisés (auto + nutritionniste).
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _repo = RecommendationRepository.instance;
  List<RecommendationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AppProvider>().user;
    if (user == null) return;
    setState(() => _items = _repo.forUser(user.id));
  }

  IconData _icon(String category) => switch (category) {
        'hydratation' => Icons.water_drop_outlined,
        'proteinnes' => Icons.egg_outlined,
        'sommeil' => Icons.bedtime_outlined,
        _ => Icons.psychology_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommandations')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.tips_and_updates_outlined,
              title: 'Pas encore de conseil',
              message:
                  'Vos recommandations personnalisées apparaîtront ici '
                  'en fonction de votre journal et de vos objectifs.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final rec = _items[i];
                return AppCard(
                  onTap: () async {
                    await _repo.markRead(rec.id);
                    _load();
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Icon(_icon(rec.category),
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(rec.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium)),
                                if (!rec.isRead)
                                  Container(
                                    height: 8,
                                    width: 8,
                                    decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(rec.body,
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text(DateUtils.relativeLabel(rec.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
