import 'package:livreur_app/models/delivery_order.dart';

List<DeliveryOrder> getSampleOrders() => [
  DeliveryOrder(
    id: '1001',
    customerName: 'Ahmed Ben Ali',
    address: 'Tunis Centre',
    phone: '20000001',
    total: 85.500,
    status: 'En cours',
  ),
  DeliveryOrder(
    id: '1002',
    customerName: 'Sarra Mansouri',
    address: 'La Marsa',
    phone: '20000002',
    total: 42.000,
    status: 'Livrée',
  ),
  DeliveryOrder(
    id: '1003',
    customerName: 'Mohamed Trabelsi',
    address: 'Ariana',
    phone: '20000003',
    total: 120.000,
    status: 'À récupérer',
  ),
  DeliveryOrder(
    id: '1004',
    customerName: 'Amira Gharbi',
    address: 'Nabeul',
    phone: '20000004',
    total: 63.000,
    status: 'En cours',
  ),
];
