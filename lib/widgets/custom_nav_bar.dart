import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'bouncy_button.dart';

/// Élément de destination pour la barre de navigation personnalisée
class CustomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const CustomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Barre de navigation flottante ergonomique avec pilule active animée (60 FPS)
/// et retour haptique au changement d'onglet.
class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<CustomNavItem> items;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = selectedIndex == index;
            final item = items[index];

            return BouncyButton(
              onTap: () {
                HapticFeedback.selectionClick();
                onItemSelected(index);
              },
              scaleFactor: 0.93,
              child: AnimatedContainer(
                duration: AppDurations.quick,
                curve: AppCurves.smooth,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF1A3535)
                          : AppColors.primarySoft)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkMuted
                              : AppColors.mutedText),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9ADADA)
                              : AppColors.primaryDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
