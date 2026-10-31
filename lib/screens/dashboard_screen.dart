import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/delivery_order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'auth_gate.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'order_details_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'working_hours_screen.dart';

class DashboardScreen extends StatefulWidget {
  final OrderService? orderService;
  const DashboardScreen({super.key, this.orderService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final OrderService _orderService;
  final WorkingHoursService _workingHoursService = WorkingHoursService();
  int _selectedIndex = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _animCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: AppCurves.smooth);
    _loadWorkingHours();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const _destinations = [
    _NavItem('Accueil', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Commandes', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('Historique', Icons.history_rounded, Icons.history_rounded),
    _NavItem('Horaires', Icons.schedule_outlined, Icons.schedule_rounded),
    _NavItem('Profil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  static const _titles = [
    'Dashboard Livreur',
    'Mes commandes',
    'Historique',
    'Mes horaires',
    'Mon profil',
  ];

  Future<void> _loadWorkingHours() async {
    try {
      await _workingHoursService.load();
      if (mounted) setState(() {});
    } catch (_) {
      // Les erreurs et chargements sont également gérés par WorkingHoursScreen
    }
  }

  void _openOrder(DeliveryOrder order) async {
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

  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      SlideFadePageRoute(page: const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<DeliveryOrder>>(
      stream: _orderService.getCommandesLivreur(),
      builder: (context, snapshot) {
        final liveOrders = snapshot.data ?? _orderService.getOrders();

        final pages = [
          HomeScreen(
            orderService: _orderService,
            workingHoursService: _workingHoursService,
            orders: liveOrders,
            firestoreError: snapshot.hasError ? snapshot.error.toString() : null,
            onOrderTap: _openOrder,
            onViewAllOrders: () => setState(() => _selectedIndex = 1),
            isEmbedded: true,
          ),
          OrdersScreen(
            orderService: _orderService,
            workingHoursService: _workingHoursService,
            orders: liveOrders,
            onOrderTap: _openOrder,
            isEmbedded: true,
          ),
          HistoryScreen(
            orderService: _orderService,
            workingHoursService: _workingHoursService,
            historyOrders: liveOrders,
            onOrderTap: _openOrder,
            isEmbedded: true,
          ),
          WorkingHoursScreen(
            workingHoursService: _workingHoursService,
            onHoursChanged: () {
              if (mounted) setState(() {});
            },
            isEmbedded: true,
          ),
          ProfileScreen(
            orderService: _orderService,
            orders: liveOrders,
            onLogout: _logout,
            isEmbedded: true,
          ),
        ];

        return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: AppDurations.quick,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            _titles[_selectedIndex],
            key: ValueKey(_titles[_selectedIndex]),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex != 4)
            IconButton(
              tooltip: 'Déconnexion',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppCurves.smooth,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          indicatorColor:
              isDark ? const Color(0xFF1A3535) : AppColors.primarySoft,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndex = index);
          },
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationDestination(
                key: ValueKey('nav-$i'),
                icon: Icon(_destinations[i].icon),
                selectedIcon: Icon(
                  _destinations[i].selectedIcon,
                  color: AppColors.primary,
                ),
                label: _destinations[i].label,
              ),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.label, this.icon, this.selectedIcon);
}
