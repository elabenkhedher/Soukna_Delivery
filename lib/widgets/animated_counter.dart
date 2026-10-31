import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Un texte animé avec effet de compteur fluide (roll-up) lors des changements de valeur.
class AnimatedCounterText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounterText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 450),
    this.curve = AppCurves.smooth,
  });

  @override
  Widget build(BuildContext context) {
    // Tenter d'extraire la partie numérique et le suffixe/prefixe
    final numericRegex = RegExp(r'^([^\d\.\,]*)([\d\.\,]+)(.*)$');
    final match = numericRegex.firstMatch(text.trim());

    if (match == null) {
      return Text(text, style: style);
    }

    final prefix = match.group(1) ?? '';
    final numString = match.group(2)!.replaceAll(',', '.');
    final suffix = match.group(3) ?? '';
    final targetValue = double.tryParse(numString);

    if (targetValue == null) {
      return Text(text, style: style);
    }

    final hasDecimals = numString.contains('.');
    final decimalPlaces = hasDecimals ? numString.split('.')[1].length : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formattedNum = hasDecimals
            ? val.toStringAsFixed(decimalPlaces)
            : val.round().toString();
        return Text(
          '$prefix$formattedNum$suffix',
          style: style,
        );
      },
    );
  }
}
