import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/delivery_order.dart';
import '../models/delivery_stats.dart';
import '../services/order_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/interactive_activity_chart.dart';
import '../widgets/order_card.dart';
import '../widgets/pending_order_card.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_breakdown_card.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final OrderService? orderService;
  final WorkingHoursService? workingHoursService;
  final List<DeliveryOrder>? orders;
  final String? firestoreError;
  final void Function(DeliveryOrder)? onOrderTap;
  final VoidCallback? onViewAllOrders;
  final Future<void> Function()? onRefresh;
  final bool isEmbedded;

  const HomeScreen({
    super.key,
    this.orderService,
    this.workingHoursService,
    this.orders,
    this.firestoreError,
    this.onOrderTap,
    this.onViewAllOrders,
    this.onRefresh,
    this.isEmbedded = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final OrderService _orderService;
  late final WorkingHoursService _workingHoursService;
  String _selectedFilter = 'Toutes';
  DashboardPeriod _selectedPeriod = DashboardPeriod.today;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _workingHoursService = widget.workingHoursService ?? WorkingHoursService();
  }

  void _openOrder(DeliveryOrder order) async {
    if (widget.onOrderTap != null) {
      widget.onOrderTap!(order);
      return;
    }
    await Navigator.push(
      context,
      SlideFadePageRoute(
        page: OrderDetailsScreen(
          order: order,
          orderService: _orderService,
          workingHoursService: _workingHoursService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (mounted) setState(() {});
  }

  Future<void> _acceptPendingOrder(DeliveryOrder order) async {
    HapticFeedback.mediumImpact();
    try {
      _orderService.advanceStatus(order);
      if (mounted) {
        setState(() {});
        AppSnackBar.showSuccess(
          context,
          'Commande #${order.id} acceptée ! Vous pouvez commencer la livraison.',
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        AppSnackBar.showError(context, error.message);
      }
    }
  }

  Future<void> _refusePendingOrder(DeliveryOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Refuser la commande #${order.id} ?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Cette décision est définitive et la commande sera refusée.',
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
      _orderService.refuseOrder(order);
      if (mounted) {
        setState(() {});
        AppSnackBar.showSuccess(context, 'Commande #${order.id} refusée.');
      }
    } on StateError catch (error) {
      if (mounted) {
        AppSnackBar.showError(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allOrders = widget.orders ?? _orderService.getOrders();
    final now = DateTime.now();
    final isWorking = _workingHoursService.isLoaded &&
        _workingHoursService.isWorkingAt(now);

    final stats = _orderService.getStatsForPeriod(_selectedPeriod, orders: allOrders);
    final pendingOrders = allOrders
        .where((o) => o.isAssigned)
        .toList();

    final filteredOrders = switch (_selectedFilter) {
      'À récupérer' || 'À traiter' => allOrders
          .where((o) => o.isAssigned)
          .toList(),
      'En cours' => allOrders
          .where((o) => o.isInProgress || o.isAssigned)
          .toList(),
      'Livrées' =>
        allOrders.where((o) => o.isDelivered).toList(),
      'Refusées' || 'Échecs' =>
        allOrders.where((o) => o.isFailedOrRefused).toList(),
      _ => allOrders,
    };

    final content = RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: ListView(
        key: const ValueKey('home-page'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          if (widget.firestoreError != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erreur Firebase : ${widget.firestoreError}\nVérifiez les règles de sécurité Firestore de votre projet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ── Carte Hero Banner ergonomique ────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                // Avatar avec icône livreur
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour, Livreur !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Pilule active de statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isWorking
                                  ? AppColors.success
                                  : AppColors.accent)
                              .withValues(alpha: 0.25),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isWorking
                                    ? const Color(0xFF66FFA6)
                                    : AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isWorking
                                  ? 'En service actuellement'
                                  : 'Hors de vos horaires',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Commandes en attente d'acceptation (À récupérer) ──
          if (pendingOrders.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Commandes en attente (${pendingOrders.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'À traiter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pendingOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PendingOrderCard(
                  key: ValueKey('pending-card-${order.id}'),
                  order: order,
                  onAccept: () => _acceptPendingOrder(order),
                  onRefuse: () => _refusePendingOrder(order),
                  onTap: () => _openOrder(order),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Section Activité & Sélecteur Temporel Dynamique ──
          Text(
            'Votre activité',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 12),
          PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodSelected: (period) {
              setState(() => _selectedPeriod = period);
            },
          ),
          const SizedBox(height: 16),

          // ── Grille de cartes statistiques interactives ───────
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              const spacing = 12.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  // Carte 1 : Total commandes
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: 'Total commandes',
                      value: '${stats.totalOrders}',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      trend: stats.trendLabel.split(' ').first,
                      isPositiveTrend: stats.isPositiveTrend,
                      isSelected: _selectedFilter == 'Toutes',
                      subtitle: _selectedPeriod.label,
                      onTap: () {
                        setState(() => _selectedFilter = 'Toutes');
                      },
                    ),
                  ),
                  // Carte 2 : Commandes livrées
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: 'Livrées',
                      value: '${stats.deliveredOrders}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      trend: '${stats.successRate.toStringAsFixed(0)}%',
                      isPositiveTrend: true,
                      isSelected: _selectedFilter == 'Livrées',
                      subtitle: 'Taux : ${stats.successRate.toStringAsFixed(0)}%',
                      onTap: () {
                        setState(() => _selectedFilter = 'Livrées');
                      },
                    ),
                  ),
                  // Carte 3 : En cours
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: 'En cours',
                      value: '${stats.inProgressOrders}',
                      icon: Icons.directions_car_rounded,
                      color: AppColors.accent,
                      trend: stats.inProgressOrders > 0
                          ? '+${stats.inProgressOrders}'
                          : null,
                      isPositiveTrend: stats.inProgressOrders > 0,
                      isSelected: _selectedFilter == 'En cours',
                      subtitle: stats.awaitingPickupOrders > 0
                          ? '${stats.awaitingPickupOrders} en attente'
                          : 'En livraison',
                      onTap: () {
                        setState(() => _selectedFilter = 'En cours');
                      },
                    ),
                  ),
                  // Carte 4 : Gains / Revenus encaissés
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: 'Gains collectés',
                      value: '${stats.totalRevenue.toStringAsFixed(3)} DT',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF10B981),
                      trend: stats.isPositiveTrend ? '+12%' : null,
                      isPositiveTrend: true,
                      subtitle: _selectedPeriod == DashboardPeriod.today &&
                              _orderService.pendingRevenue > 0
                          ? '${_orderService.pendingRevenue.toStringAsFixed(1)} DT en cours'
                          : 'Période choisie',
                      onTap: () {
                        setState(() => _selectedFilter = 'Toutes');
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Graphique interactif d'activité ──────────────────
          InteractiveActivityChart(
            key: ValueKey('chart-${_selectedPeriod.name}'),
            data: stats.chartPoints,
            periodLabel: _selectedPeriod.label,
          ),

          const SizedBox(height: 18),

          // ── Objectif du jour ─────────────────────────────────
          DailyGoalCard(
            deliveredCount: stats.deliveredOrders,
          ),

          const SizedBox(height: 18),

          // ── Répartition des statuts de commande ──────────────
          StatusBreakdownCard(
            deliveredCount: stats.deliveredOrders,
            inProgressCount: stats.inProgressOrders,
            awaitingCount: stats.awaitingPickupOrders,
            refusedCount: stats.refusedOrders,
            activeFilter: _selectedFilter,
            onFilterChanged: (newFilter) {
              setState(() => _selectedFilter = newFilter);
            },
          ),

          const SizedBox(height: 28),

          // ── Commandes récentes avec filtre rapide en pilules ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commandes récentes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              if (widget.onViewAllOrders != null)
                TextButton.icon(
                  onPressed: widget.onViewAllOrders,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Tout voir'),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilules de filtrage interactif (Capsules 100px)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Toutes', 'En cours', 'Livrées', 'À récupérer']
                  .map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: BouncyButton(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    scaleFactor: 0.95,
                    child: AnimatedContainer(
                      duration: AppDurations.quick,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkSurfaceAlt
                                : AppColors.surfaceAlt),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkText
                                  : AppColors.text),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des commandes
          if (filteredOrders.isEmpty)
            const EmptyState(message: 'Aucune commande disponible.')
          else
            ...filteredOrders.take(4).map(
                  (o) => OrderCard(
                    order: o,
                    onTap: () => _openOrder(o),
                  ),
                ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Livreur'),
      ),
      body: content,
    );
  }
}
