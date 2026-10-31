import 'package:flutter/material.dart';

import '../models/delivery_order.dart';
import '../services/order_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

typedef CommandesScreen = OrdersScreen;

class OrdersScreen extends StatefulWidget {
  final OrderService? orderService;
  final WorkingHoursService? workingHoursService;
  final List<DeliveryOrder>? orders;
  final void Function(DeliveryOrder)? onOrderTap;
  final Future<void> Function()? onRefresh;
  final bool isEmbedded;

  const OrdersScreen({
    super.key,
    this.orderService,
    this.workingHoursService,
    this.orders,
    this.onOrderTap,
    this.onRefresh,
    this.isEmbedded = false,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderService _orderService;
  late final WorkingHoursService _workingHoursService;
  String _activeFilter = 'Toutes';

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
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allOrders = widget.orders ?? _orderService.getOrders();

    final filteredOrders = switch (_activeFilter) {
      'À récupérer' || 'À traiter' => allOrders
          .where((o) => o.isAssigned)
          .toList(),
      'En cours' =>
        allOrders.where((o) => o.isInProgress).toList(),
      'Terminées' => allOrders
          .where((o) => o.isDelivered || o.isFailedOrRefused)
          .toList(),
      _ => allOrders,
    };

    final content = RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: ListView(
        key: const ValueKey('orders-page'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Text(
            'Toutes vos commandes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${allOrders.length} commande${allOrders.length == 1 ? '' : 's'} au total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedText,
                ),
          ),
          const SizedBox(height: 14),

          // Pilules de filtrage interactif (Capsules 100px)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Toutes', 'À récupérer', 'En cours', 'Terminées'].map((f) {
                final isSelected = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: BouncyButton(
                    onTap: () => setState(() => _activeFilter = f),
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
                        f,
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
          const SizedBox(height: 18),

          if (filteredOrders.isEmpty)
            const EmptyState(message: 'Aucune commande disponible.')
          else
            ...filteredOrders.map(
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
        title: const Text('Mes commandes'),
      ),
      body: content,
    );
  }
}
