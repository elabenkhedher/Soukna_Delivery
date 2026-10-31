enum DashboardPeriod {
  today('Aujourd\'hui'),
  week('Cette semaine'),
  month('Ce mois'),
  all('Tout');

  final String label;
  const DashboardPeriod(this.label);
}

class ChartPoint {
  final String label;
  final String fullLabel;
  final double orderCount;
  final double revenue;
  final int deliveredCount;
  final bool isCurrent;

  const ChartPoint({
    required this.label,
    required this.fullLabel,
    required this.orderCount,
    required this.revenue,
    this.deliveredCount = 0,
    this.isCurrent = false,
  });
}

class PeriodStats {
  final DashboardPeriod period;
  final int totalOrders;
  final int deliveredOrders;
  final int inProgressOrders;
  final int awaitingPickupOrders;
  final int refusedOrders;
  final double totalRevenue;
  final double successRate;
  final String trendLabel;
  final bool isPositiveTrend;
  final List<ChartPoint> chartPoints;

  const PeriodStats({
    required this.period,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.inProgressOrders,
    required this.awaitingPickupOrders,
    required this.refusedOrders,
    required this.totalRevenue,
    required this.successRate,
    required this.trendLabel,
    required this.isPositiveTrend,
    required this.chartPoints,
  });
}
