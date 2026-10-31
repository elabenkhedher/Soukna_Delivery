import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'bouncy_button.dart';

/// Bouton d'action principal ergonomique avec micro-interaction physique (rebond 60 FPS),
/// dégradé de couleur fidèle, état de chargement fluide et retour haptique.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    this.height = 54,
    this.width = double.infinity,
    this.borderRadius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    Widget buttonContent;
    if (isLoading) {
      buttonContent = const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.4,
        ),
      );
    } else {
      buttonContent = Row(
        key: ValueKey('label-$label'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    final container = AnimatedContainer(
      duration: AppDurations.quick,
      curve: AppCurves.smooth,
      height: height,
      decoration: BoxDecoration(
        gradient: enabled ? AppTheme.primaryGradient : null,
        color: !enabled
            ? colorScheme.primary.withValues(alpha: 0.55)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: AppDurations.quick,
          child: buttonContent,
        ),
      ),
    );

    final wrapped = BouncyButton(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            }
          : null,
      scaleFactor: enabled ? 0.96 : 1.0,
      child: container,
    );

    if (width != null) {
      return SizedBox(width: width, child: wrapped);
    }
    return wrapped;
  }
}
