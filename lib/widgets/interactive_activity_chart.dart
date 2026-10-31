import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/delivery_stats.dart';
import '../theme/app_theme.dart';
import 'bouncy_button.dart';

enum ChartMetric {
  orders('Commandes', Icons.inventory_2_outlined),
  revenue('Gains DT', Icons.payments_outlined);

  final String label;
  final IconData icon;
  const ChartMetric(this.label, this.icon);
}

/// Graphique interactif d'activité avec bascule Volume/Revenus et infobulles tactiles.
class InteractiveActivityChart extends StatefulWidget {
  final List<ChartPoint> data;
  final String periodLabel;

  const InteractiveActivityChart({
    super.key,
    required this.data,
    required this.periodLabel,
  });

  @override
  State<InteractiveActivityChart> createState() =>
      _InteractiveActivityChartState();
}

class _InteractiveActivityChartState extends State<InteractiveActivityChart> {
  ChartMetric _selectedMetric = ChartMetric.orders;
  int? _selectedBarIndex;

  @override
  void didUpdateWidget(covariant InteractiveActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodLabel != widget.periodLabel) {
      _selectedBarIndex = null;
    }
  }

  Widget _buildMetricToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
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
        children: ChartMetric.values.map((metric) {
          final isSel = metric == _selectedMetric;
          return BouncyButton(
            scaleFactor: 0.95,
            onTap: () {
              if (!isSel) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMetric = metric;
                  _selectedBarIndex = null;
                });
              }
            },
            child: AnimatedContainer(
              duration: AppDurations.quick,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    metric.icon,
                    size: 13,
                    color: isSel
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkMuted
                            : AppColors.mutedText),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metric.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      color: isSel
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkMuted
                              : AppColors.mutedText),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    // Calcul de la valeur maximale pour l'échelle
    final values = widget.data.map((p) =>
        _selectedMetric == ChartMetric.orders ? p.orderCount : p.revenue);
    final rawMax = values.isEmpty ? 1.0 : values.reduce(math.max);
    final maxValue = rawMax <= 0 ? 5.0 : rawMax * 1.15;

    // Calcul du total et de la moyenne
    final total = values.fold<double>(0.0, (s, v) => s + v);
    final avg = widget.data.isEmpty ? 0.0 : total / widget.data.length;

    final selectedPoint = (_selectedBarIndex != null &&
            _selectedBarIndex! < widget.data.length)
        ? widget.data[_selectedBarIndex!]
        : null;

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
          // ── En-tête : Titre & Basculeur de Métrique (anti-overflow) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Activité des livraisons',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Touchez une barre pour inspecter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.mutedText,
                          fontSize: 11.5,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildMetricToggle(isDark),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 8),
                  _buildMetricToggle(isDark),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // ── Zone des Barres du Graphique ────────────────────
          SizedBox(
            height: 150,
            child: widget.data.isEmpty
                ? const Center(child: Text('Aucune donnée'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final barCount = widget.data.length;
                      final availableWidth = constraints.maxWidth;
                      final maxBarWidth =
                          math.min(38.0, availableWidth / barCount - 8);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(barCount, (index) {
                          final point = widget.data[index];
                          final val = _selectedMetric == ChartMetric.orders
                              ? point.orderCount
                              : point.revenue;
                          final isSelected = _selectedBarIndex == index;
                          final isCurrent = point.isCurrent;

                          final ratio = (val / maxValue).clamp(0.06, 1.0);
                          final barHeight = 110 * ratio;

                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (_selectedBarIndex == index) {
                                      _selectedBarIndex = null;
                                    } else {
                                      _selectedBarIndex = index;
                                    }
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Valeur affichée si barre sélectionnée ou non nulle
                                    SizedBox(
                                      height: 16,
                                      child: isSelected
                                          ? Text(
                                              _selectedMetric ==
                                                      ChartMetric.orders
                                                  ? '${val.toInt()}'
                                                  : '${val.toStringAsFixed(0)}D',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? AppColors.accent
                                                    : AppColors.primaryDark,
                                              ),
                                            )
                                          : (val > 0 && barCount <= 5
                                              ? Text(
                                                  _selectedMetric ==
                                                          ChartMetric.orders
                                                      ? '${val.toInt()}'
                                                      : '${val.toStringAsFixed(0)}D',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? AppColors.darkMuted
                                                        : AppColors.hintText,
                                                  ),
                                                )
                                              : const SizedBox.shrink()),
                                    ),
                                    const SizedBox(height: 4),

                                    // Barre animée avec Tween
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: barHeight,
                                      ),
                                      duration: AppDurations.normal,
                                      curve: AppCurves.smooth,
                                      builder: (context, height, child) {
                                        return AnimatedContainer(
                                          duration: AppDurations.quick,
                                          height: height,
                                          width: maxBarWidth,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(8),
                                              bottom: Radius.circular(4),
                                            ),
                                            gradient: isSelected
                                                ? AppTheme.accentGradient
                                                : LinearGradient(
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: isCurrent
                                                        ? [
                                                            AppColors.primary,
                                                            AppColors.primaryMid,
                                                          ]
                                                        : [
                                                            (isDark
                                                                    ? AppColors
                                                                        .primary
                                                                    : AppColors
                                                                        .primarySoft)
                                                                .withValues(
                                                                    alpha: 0.8),
                                                            AppColors.primaryMid
                                                                .withValues(
                                                                    alpha: 0.7),
                                                          ],
                                                  ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.accent
                                                          .withValues(alpha: 0.4),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                            border: isCurrent && !isSelected
                                                ? Border.all(
                                                    color: AppColors.accent,
                                                    width: 1.5,
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),

                                    // Étiquette du jour / heure
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isCurrent)
                                          Container(
                                            width: 4,
                                            height: 4,
                                            margin: const EdgeInsets.only(
                                                right: 3),
                                            decoration: const BoxDecoration(
                                              color: AppColors.accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          point.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: (isSelected || isCurrent)
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? (isDark
                                                    ? AppColors.accent
                                                    : AppColors.primary)
                                                : (isCurrent
                                                    ? (isDark
                                                        ? Colors.white
                                                        : AppColors.text)
                                                    : (isDark
                                                        ? AppColors.darkMuted
                                                        : AppColors.hintText)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 14),

          // ── Infobulle dynamique de détail au toucher ─────────
          AnimatedSwitcher(
            duration: AppDurations.quick,
            switchInCurve: AppCurves.smooth,
            child: selectedPoint != null
                ? Container(
                    key: ValueKey('info-${selectedPoint.fullLabel}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.primarySoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPoint.fullLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${selectedPoint.orderCount.toInt()} commande(s) • ${selectedPoint.revenue.toStringAsFixed(3)} DT • ${selectedPoint.deliveredCount} livrée(s)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Fermer',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedBarIndex = null);
                          },
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('summary-pill'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedMetric == ChartMetric.orders
                                ? 'Moyenne : ${avg.toStringAsFixed(1)} cmd / créneau'
                                : 'Moyenne : ${avg.toStringAsFixed(1)} DT / créneau',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedMetric == ChartMetric.orders
                              ? 'Total : ${total.toInt()} commandes'
                              : 'Total : ${total.toStringAsFixed(1)} DT',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
