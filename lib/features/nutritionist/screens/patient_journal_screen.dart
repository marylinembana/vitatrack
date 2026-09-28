import 'package:flutter/material.dart' hide DateUtils;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../data/models/meal_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/meal_repository.dart';

/// Consultation en lecture seule du journal alimentaire d'un patient.
class PatientJournalScreen extends StatefulWidget {
  final UserModel user;
  const PatientJournalScreen({super.key, required this.user});

  @override
  State<PatientJournalScreen> createState() => _PatientJournalScreenState();
}

class _PatientJournalScreenState extends State<PatientJournalScreen> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final meals =
        MealRepository.instance.forDay(widget.user.id, _day);
    final total = meals.fold<double>(
        0, (sum, MealModel m) => sum + m.totals.calories);

    return Scaffold(
      appBar: AppBar(title: Text('Journal — ${widget.user.fullName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingSm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => setState(() =>
                        _day = _day.subtract(const Duration(days: 1))),
                    icon: const Icon(Icons.chevron_left)),
                Text(DateUtils.relativeLabel(_day),
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    onPressed: DateUtils.isSameDay(_day, DateTime.now())
                        ? null
                        : () => setState(
                            () => _day = _day.add(const Duration(days: 1))),
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${meals.length} repas',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('${total.round()} kcal',
                    style: const TextStyle(
                        color: AppColors.calories,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: meals.isEmpty
                ? const EmptyState(
                    icon: Icons.restaurant_menu,
                    title: 'Aucun repas ce jour',
                    message: 'Le patient n\'a rien enregistré.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    itemCount: meals.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.paddingSm),
                    itemBuilder: (context, i) => MealCard(meal: meals[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
