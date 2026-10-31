import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/delivery_order.dart';
import '../services/order_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailsScreen extends StatefulWidget {
  final DeliveryOrder order;
  final OrderService orderService;
  final WorkingHoursService workingHoursService;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.orderService,
    required this.workingHoursService,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: AppCurves.smooth);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _advanceStatus() {
    HapticFeedback.lightImpact();
    late final String status;
    try {
      status = widget.orderService.advanceStatus(widget.order);
    } on StateError catch (error) {
      AppSnackBar.showError(context, error.message);
      return;
    }
    setState(() {});
    AppSnackBar.showSuccess(context, 'Nouveau statut : $status');
  }

  Future<void> _refuseOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text(
          'Refuser cette commande ?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Cette décision est définitive et la commande sera '
          'ajoutée à votre historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      widget.orderService.refuseOrder(widget.order);
    } on StateError catch (error) {
      AppSnackBar.showError(context, error.message);
      return;
    }
    setState(() {});
    AppSnackBar.showSuccess(context, 'Commande refusée.');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDelivered = order.isDelivered;
    final isRefused = order.isFailedOrRefused;

    final statusStep = order.isDelivered
        ? 2
        : order.isInProgress
            ? 1
            : order.isAssigned
                ? 0
                : -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Commande #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ── Bannière statut ──────────────────────────────
            _StatusBanner(order: order),
            const SizedBox(height: 22),

            // ── Infos client ────────────────────────────────
            const _SectionTitle(title: 'Informations client'),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Client',
                    value: order.customerName,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse de livraison',
                    value: order.address,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: order.phone,
                    isPhone: true,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Montant à encaisser',
                    value: '${order.total.toStringAsFixed(3)} TND',
                    isAmount: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Progression de la livraison ──────────────────
            if (!isRefused) ...[
              const _SectionTitle(title: 'Progression de la livraison'),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 22,
                  ),
                  child: _DeliveryTimeline(currentStep: statusStep),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // ── Suggestion d'horaires ─────────────────────────
            if (order.status == DeliveryOrder.awaitingPickup) ...[
              _WorkingHoursSuggestion(
                workingHoursService: widget.workingHoursService,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(
        order: order,
        isDelivered: isDelivered,
        isRefused: isRefused,
        onAdvance: _advanceStatus,
        onRefuse: _refuseOrder,
      ),
    );
  }
}

// ── Bannière statut ────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final DeliveryOrder order;
  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = order.statusColor(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(order.statusIcon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                ),
                const SizedBox(height: 6),
                OrderStatusBadge(
                  status: order.status,
                  fontSize: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline de livraison ─────────────────────────────────────
class _DeliveryTimeline extends StatelessWidget {
  final int currentStep;
  const _DeliveryTimeline({required this.currentStep});

  static const _steps = [
    ('Affectée', Icons.assignment_outlined),
    ('En cours', Icons.directions_car_rounded),
    ('Livrée', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ligne de liaison
                    if (i < _steps.length - 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 2.5,
                          margin: const EdgeInsets.only(left: 30),
                          color: i < currentStep
                              ? AppColors.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    // Cercle d'étape
                    AnimatedContainer(
                      duration: AppDurations.medium,
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= currentStep
                            ? (i == currentStep
                                ? AppColors.primary
                                : AppColors.success)
                            : colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: i <= currentStep
                              ? Colors.transparent
                              : colorScheme.outline.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: i == currentStep
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        i < currentStep
                            ? Icons.check_rounded
                            : _steps[i].$2,
                        color: i <= currentStep
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _steps[i].$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == currentStep
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i <= currentStep
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Ligne info ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPhone;
  final bool isAmount;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPhone = false,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isAmount ? FontWeight.w800 : FontWeight.w600,
              color: isAmount ? AppColors.primary : null,
              fontSize: isAmount ? 16 : 14,
            ),
      ),
      trailing: isPhone
          ? IconButton(
              tooltip: 'Copier le numéro',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                AppSnackBar.showSuccess(context, 'Numéro copié');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── Suggestion horaires ────────────────────────────────────────
class _WorkingHoursSuggestion extends StatelessWidget {
  final WorkingHoursService workingHoursService;
  const _WorkingHoursSuggestion({required this.workingHoursService});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoaded = workingHoursService.isLoaded;
    final isWorking =
        isLoaded && workingHoursService.isWorkingAt(DateTime.now());

    final color = !isLoaded
        ? colorScheme.onSurfaceVariant
        : isWorking
            ? AppColors.primary
            : colorScheme.error;

    return Card(
      elevation: 0,
      color: !isLoaded
          ? colorScheme.surfaceContainerHighest
          : isWorking
              ? AppColors.primarySoft
              : colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(
          !isLoaded
              ? Icons.schedule_outlined
              : isWorking
                  ? Icons.schedule_rounded
                  : Icons.event_busy_rounded,
          color: color,
        ),
        title: Text(
          !isLoaded
              ? 'Suggestion indisponible'
              : isWorking
                  ? '💡 Suggestion : accepter'
                  : '⚠ Suggestion : refuser',
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
        subtitle: Text(
          !isLoaded
              ? 'Les horaires ne sont pas disponibles.'
              : isWorking
                  ? 'Vous êtes dans vos horaires. Vous restez libre de votre décision.'
                  : 'Vous êtes hors de vos horaires. Vous restez libre de votre décision.',
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
    );
  }
}

// ── Actions bas de page ───────────────────────────────────────
class _BottomActions extends StatelessWidget {
  final DeliveryOrder order;
  final bool isDelivered;
  final bool isRefused;
  final VoidCallback onAdvance;
  final VoidCallback onRefuse;

  const _BottomActions({
    required this.order,
    required this.isDelivered,
    required this.isRefused,
    required this.onAdvance,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (isDelivered || isRefused) {
      content = Card(
        color: isDelivered ? AppColors.primarySoft : colorScheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ListTile(
          leading: Icon(
            isDelivered ? Icons.check_circle_rounded : Icons.block_rounded,
            color: isDelivered ? AppColors.primary : colorScheme.error,
          ),
          title: Text(
            isDelivered ? 'Commande terminée' : 'Commande refusée',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDelivered ? AppColors.primary : colorScheme.error,
            ),
          ),
          subtitle: Text(
            isDelivered
                ? 'Cette livraison est définitivement terminée.'
                : 'Cette commande a été refusée définitivement.',
          ),
        ),
      );
    } else if (order.isInProgress) {
      content = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('advance-order-status'),
          onPressed: onAdvance,
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('Marquer comme livrée'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            key: const ValueKey('accept-order'),
            onPressed: onAdvance,
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Accepter la commande'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('refuse-order'),
            onPressed: onRefuse,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Refuser la commande'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error, width: 1.5),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: content,
      ),
    );
  }
}
