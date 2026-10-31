import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'bouncy_button.dart';

/// Carte interactive d'objectif journalier avec jauge animée et sélection de cible.
class DailyGoalCard extends StatefulWidget {
  final int deliveredCount;

  const DailyGoalCard({
    super.key,
    required this.deliveredCount,
  });

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  int _targetGoal = 5;

  static const _availableGoals = [4, 6, 8, 10];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    final progressRatio =
        (widget.deliveredCount / _targetGoal).clamp(0.0, 1.0);
    final percentage = (progressRatio * 100).round();
    final isCompleted = widget.deliveredCount >= _targetGoal;
    final remaining = (_targetGoal - widget.deliveredCount).clamp(0, 99);

    final motivationalText = isCompleted
        ? 'Objectif atteint ! Excellent travail ! 🎉'
        : remaining == 1
            ? 'Plus qu\'une livraison pour décrocher votre objectif !'
            : 'Encore $remaining livraisons pour valider la tournée';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.border.withValues(alpha: 0.65),
        ),
        boxShadow: AppShadows.soft(),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [AppColors.success, Color(0xFF22C55E)],
                        )
                      : AppTheme.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted
                              ? AppColors.success
                              : AppColors.accent)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.flag_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectif du jour',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motivationalText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? AppColors.success
                            : (isDark
                                ? AppColors.darkMuted
                                : AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge pourcentage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? AppColors.success
                          : AppColors.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: (isCompleted
                            ? AppColors.success
                            : AppColors.primary)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Barre de progression animée ──────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.surfaceAlt,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progressRatio),
                    duration: AppDurations.normal,
                    curve: AppCurves.smooth,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.success,
                                      Color(0xFF22C55E),
                                    ],
                                  )
                                : AppTheme.primaryGradient,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Ligne inférieure : Décompte & Sélecteur de cible ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.deliveredCount} sur $_targetGoal livrées',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.text,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cible : ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkMuted : AppColors.hintText,
                    ),
                  ),
                  ..._availableGoals.map((g) {
                    final isSel = g == _targetGoal;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: BouncyButton(
                        scaleFactor: 0.9,
                        onTap: () {
                          if (!isSel) {
                            HapticFeedback.selectionClick();
                            setState(() => _targetGoal = g);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkSurfaceAlt
                                    : AppColors.surfaceAlt),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '$g',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSel
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSel
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkMuted
                                      : AppColors.mutedText),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
