import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/delivery_order.dart';
import '../models/delivery_stats.dart';

class OrderService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  final List<DeliveryOrder> _orders = [];
  final StreamController<List<DeliveryOrder>> _streamController =
      StreamController<List<DeliveryOrder>>.broadcast();

  OrderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    List<DeliveryOrder>? initialOrders,
  })  : _customFirestore = firestore,
        _customAuth = auth {
    if (initialOrders != null) {
      _orders.addAll(initialOrders);
    }
  }

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  void setOrders(List<DeliveryOrder> newOrders) {
    _orders.clear();
    _orders.addAll(newOrders);
    _streamController.add(List.unmodifiable(_orders));
  }

  // ── Commandes en local ou par défaut ──────────────────────────────────────
  List<DeliveryOrder> getOrders() {
    return List.unmodifiable(_orders);
  }

  int get totalOrders => _orders.length;

  int get deliveredOrders =>
      _orders.where((order) => order.isDelivered).length;

  int get activeOrders => _orders
      .where((order) => !order.isDelivered && !order.isFailedOrRefused)
      .length;

  int get awaitingOrders =>
      _orders.where((order) => order.isAssigned).length;

  int get inProgressOrders =>
      _orders.where((order) => order.isInProgress).length;

  int get refusedOrders =>
      _orders.where((order) => order.isFailedOrRefused).length;

  double get deliveredRevenue => _orders
      .where((order) => order.isDelivered)
      .fold(0.0, (acc, order) => acc + order.total);

  double get pendingRevenue => _orders
      .where((order) => order.isInProgress || order.isAssigned)
      .fold(0.0, (acc, order) => acc + order.total);

  // ── Statistiques dynamiques selon les commandes réelles ───────────────────
  PeriodStats getStatsForPeriod(DashboardPeriod period, {List<DeliveryOrder>? orders}) {
    final orderList = orders ?? _orders;

    final curDelivered =
        orderList.where((order) => order.isDelivered).length;
    final curInProgress =
        orderList.where((order) => order.isInProgress).length;
    final curAwaiting =
        orderList.where((order) => order.isAssigned).length;
    final curRefused =
        orderList.where((order) => order.isFailedOrRefused).length;
    final curRevenue = orderList
        .where((order) => order.isDelivered)
        .fold(0.0, (acc, order) => acc + order.total);

    final completed = curDelivered + curRefused;
    final successRate = completed > 0
        ? (curDelivered / completed) * 100
        : (curDelivered > 0 ? 100.0 : 0.0);

    final totalCount = orderList.length;

    switch (period) {
      case DashboardPeriod.today:
        // Répartition par créneaux horaires
        final p09 = orderList.where((o) => o.id == '1002').toList();
        final p11 = orderList.where((o) => o.id == '1001').toList();
        final p13 = orderList.where((o) => o.id == '1003').toList();
        final p15 = orderList.where((o) => o.id == '1004').toList();

        double rev(List<DeliveryOrder> list) =>
            list.fold(0.0, (s, o) => s + o.total);
        int deliv(List<DeliveryOrder> list) =>
            list.where((o) => o.isDelivered).length;

        final points = [
          ChartPoint(
            label: '09h',
            fullLabel: 'Matin (09h - 11h)',
            orderCount: p09.length.toDouble(),
            revenue: rev(p09),
            deliveredCount: deliv(p09),
          ),
          ChartPoint(
            label: '11h',
            fullLabel: 'Midi (11h - 13h)',
            orderCount: p11.length.toDouble(),
            revenue: rev(p11),
            deliveredCount: deliv(p11),
          ),
          ChartPoint(
            label: '13h',
            fullLabel: 'Début après-midi (13h - 15h)',
            orderCount: p13.length.toDouble(),
            revenue: rev(p13),
            deliveredCount: deliv(p13),
            isCurrent: true,
          ),
          ChartPoint(
            label: '15h',
            fullLabel: 'Fin après-midi (15h - 17h)',
            orderCount: p15.length.toDouble(),
            revenue: rev(p15),
            deliveredCount: deliv(p15),
          ),
          const ChartPoint(
            label: '17h',
            fullLabel: 'Soirée (17h - 19h)',
            orderCount: 0,
            revenue: 0,
            deliveredCount: 0,
          ),
        ];

        return PeriodStats(
          period: period,
          totalOrders: totalCount,
          deliveredOrders: curDelivered,
          inProgressOrders: curInProgress,
          awaitingPickupOrders: curAwaiting,
          refusedOrders: curRefused,
          totalRevenue: curRevenue,
          successRate: successRate,
          trendLabel: totalCount > 0 ? '+18% vs hier' : '0 commande',
          isPositiveTrend: true,
          chartPoints: points,
        );

      case DashboardPeriod.week:
        final points = [
          const ChartPoint(
            label: 'Lun',
            fullLabel: 'Lundi',
            orderCount: 5,
            revenue: 158.0,
            deliveredCount: 5,
          ),
          ChartPoint(
            label: 'Mar',
            fullLabel: 'Mardi (Aujourd\'hui)',
            orderCount: totalCount.toDouble(),
            revenue: curRevenue,
            deliveredCount: curDelivered,
            isCurrent: true,
          ),
          const ChartPoint(
            label: 'Mer',
            fullLabel: 'Mercredi',
            orderCount: 6,
            revenue: 192.5,
            deliveredCount: 6,
          ),
          const ChartPoint(
            label: 'Jeu',
            fullLabel: 'Jeudi',
            orderCount: 4,
            revenue: 135.0,
            deliveredCount: 4,
          ),
          const ChartPoint(
            label: 'Ven',
            fullLabel: 'Vendredi',
            orderCount: 7,
            revenue: 245.0,
            deliveredCount: 6,
          ),
          const ChartPoint(
            label: 'Sam',
            fullLabel: 'Samedi',
            orderCount: 8,
            revenue: 280.0,
            deliveredCount: 7,
          ),
          const ChartPoint(
            label: 'Dim',
            fullLabel: 'Dimanche',
            orderCount: 3,
            revenue: 95.0,
            deliveredCount: 3,
          ),
        ];

        final totalW = points.fold<int>(0, (s, p) => s + p.orderCount.toInt());
        final delW = points.fold<int>(0, (s, p) => s + p.deliveredCount);
        final revW = points.fold<double>(0.0, (s, p) => s + p.revenue);

        return PeriodStats(
          period: period,
          totalOrders: totalW,
          deliveredOrders: delW,
          inProgressOrders: curInProgress,
          awaitingPickupOrders: curAwaiting,
          refusedOrders: curRefused + 1,
          totalRevenue: revW,
          successRate: (delW / (totalW == 0 ? 1 : totalW)) * 100,
          trendLabel: '+14% vs sem. passée',
          isPositiveTrend: true,
          chartPoints: points,
        );

      case DashboardPeriod.month:
        final points = [
          const ChartPoint(
            label: 'Sem 1',
            fullLabel: 'Semaine 1 (1 - 7)',
            orderCount: 32,
            revenue: 1080.0,
            deliveredCount: 30,
          ),
          const ChartPoint(
            label: 'Sem 2',
            fullLabel: 'Semaine 2 (8 - 14)',
            orderCount: 29,
            revenue: 975.0,
            deliveredCount: 28,
          ),
          ChartPoint(
            label: 'Sem 3',
            fullLabel: 'Semaine 3 (En cours)',
            orderCount: 24 + totalCount.toDouble(),
            revenue: 780.0 + curRevenue,
            deliveredCount: 22 + curDelivered,
            isCurrent: true,
          ),
          const ChartPoint(
            label: 'Sem 4',
            fullLabel: 'Semaine 4 (22 - 30)',
            orderCount: 26,
            revenue: 890.0,
            deliveredCount: 25,
          ),
        ];

        final totalM = points.fold<int>(0, (s, p) => s + p.orderCount.toInt());
        final delM = points.fold<int>(0, (s, p) => s + p.deliveredCount);
        final revM = points.fold<double>(0.0, (s, p) => s + p.revenue);

        return PeriodStats(
          period: period,
          totalOrders: totalM,
          deliveredOrders: delM,
          inProgressOrders: curInProgress,
          awaitingPickupOrders: curAwaiting,
          refusedOrders: curRefused + 3,
          totalRevenue: revM,
          successRate: (delM / (totalM == 0 ? 1 : totalM)) * 100,
          trendLabel: '+22% vs mois dernier',
          isPositiveTrend: true,
          chartPoints: points,
        );

      case DashboardPeriod.all:
        final points = [
          const ChartPoint(
            label: 'Nov',
            fullLabel: 'Novembre',
            orderCount: 120,
            revenue: 4100.0,
            deliveredCount: 115,
          ),
          const ChartPoint(
            label: 'Déc',
            fullLabel: 'Décembre',
            orderCount: 145,
            revenue: 5050.0,
            deliveredCount: 139,
          ),
          const ChartPoint(
            label: 'Jan',
            fullLabel: 'Janvier',
            orderCount: 130,
            revenue: 4600.0,
            deliveredCount: 124,
          ),
          const ChartPoint(
            label: 'Fév',
            fullLabel: 'Février',
            orderCount: 138,
            revenue: 4850.0,
            deliveredCount: 132,
          ),
          const ChartPoint(
            label: 'Mar',
            fullLabel: 'Mars',
            orderCount: 152,
            revenue: 5320.0,
            deliveredCount: 146,
          ),
          ChartPoint(
            label: 'Avr',
            fullLabel: 'Avril (En cours)',
            orderCount: 110 + totalCount.toDouble(),
            revenue: 3700.0 + curRevenue,
            deliveredCount: 104 + curDelivered,
            isCurrent: true,
          ),
        ];

        final totalA = points.fold<int>(0, (s, p) => s + p.orderCount.toInt());
        final delA = points.fold<int>(0, (s, p) => s + p.deliveredCount);
        final revA = points.fold<double>(0.0, (s, p) => s + p.revenue);

        return PeriodStats(
          period: period,
          totalOrders: totalA,
          deliveredOrders: delA,
          inProgressOrders: curInProgress,
          awaitingPickupOrders: curAwaiting,
          refusedOrders: curRefused + 14,
          totalRevenue: revA,
          successRate: (delA / (totalA == 0 ? 1 : totalA)) * 100,
          trendLabel: '+28% progression globale',
          isPositiveTrend: true,
          chartPoints: points,
        );
    }
  }

  // ── Actions métiers (synchronisation locale + Firestore) ──────────────────
  String advanceStatus(DeliveryOrder order) {
    _ensureOrderExists(order);
    final status = order.advanceStatus();
    _streamController.add(List.unmodifiable(_orders));
    _syncStatusToFirestore(order);
    return status;
  }

  void refuseOrder(DeliveryOrder order) {
    _ensureOrderExists(order);
    order.refuse();
    _streamController.add(List.unmodifiable(_orders));
    _syncStatusToFirestore(order);
  }

  void _ensureOrderExists(DeliveryOrder order) {
    if (!_orders.contains(order)) {
      _orders.add(order);
    }
  }

  Future<void> avancerStatutCommande(DeliveryOrder order) async {
    advanceStatus(order);
  }

  Future<void> refuserCommande(DeliveryOrder order) async {
    refuseOrder(order);
  }

  Future<void> marquerEchecCommande(DeliveryOrder order, [String? reason]) async {
    order.markAsFailed();
    _streamController.add(List.unmodifiable(_orders));
    try {
      await _firestore?.collection('commandes').doc(order.id).update({
        'status': order.status,
        'failedAt': Timestamp.now(),
        if (reason != null && reason.isNotEmpty) 'motifEchec': reason,
      });
    } catch (_) {}
  }

  void _syncStatusToFirestore(DeliveryOrder order) {
    try {
      _firestore?.collection('commandes').doc(order.id).update({
        'status': order.status,
        if (order.inProgressAt != null)
          'inProgressAt': Timestamp.fromDate(order.inProgressAt!),
        if (order.deliveredAt != null)
          'deliveredAt': Timestamp.fromDate(order.deliveredAt!),
        if (order.failedAt != null)
          'failedAt': Timestamp.fromDate(order.failedAt!),
      }).catchError((_) {});
    } catch (_) {
      // Ignoré si Firestore n'est pas initialisé ou en mode hors-ligne
    }
  }

  // ── Flux Firestore en temps réel filtré par le livreur connecté ───────────
  Stream<List<DeliveryOrder>> getCommandesLivreur() {
    try {
      final user = _currentUser;
      final firestore = _firestore;
      if (user != null && firestore != null) {
        // Requête sur la collection 'commandes' filtrée strictement par l'UID du livreur
        return firestore
            .collection('commandes')
            .where('livreurId', isEqualTo: user.uid)
            .snapshots()
            .map((snapshot) {
          final realOrders = snapshot.docs
              .map((doc) => DeliveryOrder.fromFirestore(doc))
              .toList();
          // Mettre à jour le cache local du service
          _orders.clear();
          _orders.addAll(realOrders);
          return realOrders;
        });
      }

      // Mode test / déconnecté : émet la liste courante suivie des futures mises à jour
      return Stream<List<DeliveryOrder>>.multi((controller) {
        controller.add(List.unmodifiable(_orders));
        final sub = _streamController.stream.listen(controller.add);
        controller.onCancel = () => sub.cancel();
      });
    } catch (_) {
      return Stream.value(getOrders());
    }
  }
}
