import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/delivery_stats.dart';
import '../theme/app_theme.dart';
import 'bouncy_button.dart';

/// Sélecteur de période dynamique pour filtrer les statistiques.
class PeriodSelector extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodSelected;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: DashboardPeriod.values.map((period) {
            final isSelected = period == selectedPeriod;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: BouncyButton(
                scaleFactor: 0.95,
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                    onPeriodSelected(period);
                  }
                },
                child: AnimatedContainer(
                  duration: AppDurations.quick,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.primary : AppColors.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkMuted : AppColors.mutedText),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
