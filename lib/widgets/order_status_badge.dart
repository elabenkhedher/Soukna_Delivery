import 'package:flutter/material.dart';

import '../models/delivery_order.dart';
import '../theme/app_theme.dart';

/// Fonctions d'aide pour obtenir la couleur et l'icône associées
/// à chaque statut de commande.
class OrderStatusHelper {
  static Color color(BuildContext context, String status) {
    switch (status) {
      case DeliveryOrder.delivered:
        return AppColors.success;
      case DeliveryOrder.inProgress:
      case 'En cours de livraison':
        return AppColors.warning;
      case DeliveryOrder.refused:
      case DeliveryOrder.deliveryFailed:
      case DeliveryOrder.cancelled:
        return Theme.of(context).colorScheme.error;
      case DeliveryOrder.assigned:
      case DeliveryOrder.awaitingPickup:
      case 'Affectée':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case DeliveryOrder.delivered:
        return Icons.check_circle_rounded;
      case DeliveryOrder.inProgress:
      case 'En cours de livraison':
        return Icons.directions_car_rounded;
      case DeliveryOrder.refused:
      case DeliveryOrder.deliveryFailed:
        return Icons.block_rounded;
      case DeliveryOrder.cancelled:
        return Icons.cancel_outlined;
      case DeliveryOrder.assigned:
      case DeliveryOrder.awaitingPickup:
      case 'Affectée':
      default:
        return Icons.local_shipping_outlined;
    }
  }
}

/// Extension pratique sur [DeliveryOrder] pour accéder directement
/// à sa couleur et son icône de statut.
extension DeliveryOrderStatusX on DeliveryOrder {
  Color statusColor(BuildContext context) =>
      OrderStatusHelper.color(context, status);
  IconData get statusIcon => OrderStatusHelper.icon(status);
}

/// Badge d'affichage du statut d'une commande (forme capsule pilule ergonomique).
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(context, status);
    final statusBg = statusColor.withValues(alpha: 0.12);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
