import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livreur_app/models/delivery_stats.dart';
import 'package:livreur_app/screens/home_screen.dart';
import 'package:livreur_app/services/order_service.dart';
import 'package:livreur_app/widgets/daily_goal_card.dart';
import 'package:livreur_app/widgets/interactive_activity_chart.dart';
import 'package:livreur_app/widgets/pending_order_card.dart';
import 'package:livreur_app/widgets/period_selector.dart';
import 'package:livreur_app/widgets/status_breakdown_card.dart';
import 'mocks/sample_orders.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OrderService computes dynamic period statistics correctly', () {
    final service = OrderService(initialOrders: getSampleOrders());
    final todayStats = service.getStatsForPeriod(DashboardPeriod.today);

    expect(todayStats.totalOrders, 4);
    expect(todayStats.deliveredOrders, 1);
    expect(todayStats.inProgressOrders, 2);
    expect(todayStats.awaitingPickupOrders, 1);
    expect(todayStats.totalRevenue, 42.0);
    expect(todayStats.chartPoints.length, 5);

    final weekStats = service.getStatsForPeriod(DashboardPeriod.week);
    expect(weekStats.totalOrders, greaterThan(4));
    expect(weekStats.chartPoints.length, 7);

    final monthStats = service.getStatsForPeriod(DashboardPeriod.month);
    expect(monthStats.totalOrders, greaterThan(weekStats.totalOrders));
    expect(monthStats.chartPoints.length, 4);

    final allStats = service.getStatsForPeriod(DashboardPeriod.all);
    expect(allStats.chartPoints.length, 6);
  });

  testWidgets('PeriodSelector switches period dynamically with haptic feedback', (
    WidgetTester tester,
  ) async {
    DashboardPeriod selected = DashboardPeriod.today;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PeriodSelector(
                selectedPeriod: selected,
                onPeriodSelected: (p) => setState(() => selected = p),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);

    await tester.tap(find.text('Cette semaine'));
    await tester.pumpAndSettle();

    expect(selected, DashboardPeriod.week);
  });

  testWidgets('InteractiveActivityChart toggles between Volume and Revenues without overflow', (
    WidgetTester tester,
  ) async {
    // Tester sur une largeur étroite pour garantir l'absence de débordement
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final points = [
      const ChartPoint(
        label: 'Lun',
        fullLabel: 'Lundi',
        orderCount: 5,
        revenue: 150.0,
      ),
      const ChartPoint(
        label: 'Mar',
        fullLabel: 'Mardi',
        orderCount: 8,
        revenue: 240.0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InteractiveActivityChart(
              data: points,
              periodLabel: 'Cette semaine',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activité des livraisons'), findsOneWidget);
    expect(find.text('Commandes'), findsOneWidget);
    expect(find.text('Gains DT'), findsOneWidget);

    // Switch to Revenues
    await tester.tap(find.text('Gains DT'));
    await tester.pumpAndSettle();

    // Tap first bar to inspect detail tooltip
    await tester.tap(find.text('Lun'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lundi'), findsOneWidget);
  });

  testWidgets('DailyGoalCard lets user interactively change delivery targets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DailyGoalCard(deliveredCount: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Objectif du jour'), findsOneWidget);
    expect(find.text('2 sur 5 livrées'), findsOneWidget);

    // Tap target '8'
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    expect(find.text('2 sur 8 livrées'), findsOneWidget);
  });

  testWidgets('StatusBreakdownCard filters status interactively', (
    WidgetTester tester,
  ) async {
    String filter = 'Toutes';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return StatusBreakdownCard(
                deliveredCount: 3,
                inProgressCount: 2,
                awaitingCount: 1,
                refusedCount: 0,
                activeFilter: filter,
                onFilterChanged: (f) => setState(() => filter = f),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Répartition des commandes'), findsOneWidget);
    expect(find.text('Livrée'), findsOneWidget);

    await tester.tap(find.text('Livrée'));
    await tester.pumpAndSettle();

    expect(filter, 'Livrées');
  });

  testWidgets('HomeScreen renders pending orders at top and allows quick acceptance', (
    WidgetTester tester,
  ) async {
    final orderService = OrderService(initialOrders: getSampleOrders());

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          orderService: orderService,
          isEmbedded: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Vérifier la présence du bloc de commandes en attente en haut
    expect(find.text('Commandes en attente (1)'), findsOneWidget);
    expect(find.byType(PendingOrderCard), findsOneWidget);
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);

    // Accepter la commande directement depuis le dashboard
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();

    // La commande passe en cours, le bloc de commandes en attente disparaît
    expect(find.text('Commandes en attente (1)'), findsNothing);
    expect(find.textContaining('acceptée'), findsOneWidget);
  });

  testWidgets('HomeScreen updates statistics reactively when switching periods', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(isEmbedded: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre activité'), findsOneWidget);
    expect(find.byType(PeriodSelector), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);

    // Tap 'Cette semaine'
    await tester.tap(find.text('Cette semaine'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveActivityChart), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(DailyGoalCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(DailyGoalCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(StatusBreakdownCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(StatusBreakdownCard), findsOneWidget);
  });
}
