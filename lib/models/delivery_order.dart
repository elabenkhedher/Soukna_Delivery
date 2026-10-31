import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryOrder {
  // --- Nomenclature officielle selon le cahier des charges ---
  static const assigned = 'Affectée à un livreur';
  static const inProgress = 'En cours';
  static const delivered = 'Livrée';
  static const refused = 'Refusée';
  static const deliveryFailed = 'Échec de livraison';
  static const cancelled = 'Annulée';

  // --- Rétro-compatibilité pour l'interface existante ---
  static const awaitingPickup = 'À récupérer';

  final String id;
  final String customerName;
  final String address;
  final String phone;
  final double total;
  final String livreurId;

  String _status;

  // --- Horodatage pour chaque étape (exigé par le cahier des charges) ---
  DateTime? assignedAt;
  DateTime? inProgressAt;
  DateTime? deliveredAt;
  DateTime? failedAt;
  DateTime? cancelledAt;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.total,
    this.livreurId = '',
    required String status,
    this.assignedAt,
    this.inProgressAt,
    this.deliveredAt,
    this.failedAt,
    this.cancelledAt,
  })  :
        // ignore: prefer_initializing_formals
        _status = status;

  String get status => _status;

  bool get isAssigned =>
      _status == assigned ||
      _status == awaitingPickup ||
      _status == 'Affectée' ||
      _status == 'Affectée à un livreur' ||
      _status == 'À récupérer';

  bool get isInProgress =>
      _status == inProgress ||
      _status == 'En cours' ||
      _status == 'En cours de livraison';

  bool get isDelivered => _status == delivered;

  bool get isFailedOrRefused =>
      _status == refused ||
      _status == deliveryFailed ||
      _status == cancelled ||
      _status == 'Échec de livraison' ||
      _status == 'Refusée' ||
      _status == 'Annulée';

  // --- 1. Instanciation depuis Firestore ---
  factory DeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double parseTotal(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    final id = doc.id;
    final customerName = (data['customerName'] ??
            data['clientName'] ??
            data['nomClient'] ??
            data['clientNom'] ??
            data['nom'] ??
            data['client'] ??
            '')
        .toString();
    final address = (data['address'] ??
            data['adresse'] ??
            data['adresseLivraison'] ??
            '')
        .toString();
    final phone = (data['phone'] ??
            data['telephone'] ??
            data['tel'] ??
            data['numTel'] ??
            '')
        .toString();
    final total = parseTotal(data['total'] ?? data['montant'] ?? data['prix']);
    final livreurId = (data['livreurId'] ??
            data['livreur_id'] ??
            data['delivererId'] ??
            data['idLivreur'] ??
            '')
        .toString();
    final status = (data['status'] ??
            data['statut'] ??
            data['etat'] ??
            assigned)
        .toString();

    return DeliveryOrder(
      id: id,
      customerName: customerName.isNotEmpty ? customerName : 'Client',
      address: address.isNotEmpty ? address : 'Adresse non spécifiée',
      phone: phone,
      total: total,
      livreurId: livreurId,
      status: status,
      assignedAt: parseTimestamp(data['assignedAt'] ?? data['dateAffectation']),
      inProgressAt: parseTimestamp(data['inProgressAt'] ?? data['datePriseEnCharge']),
      deliveredAt: parseTimestamp(data['deliveredAt'] ?? data['dateLivraison']),
      failedAt: parseTimestamp(data['failedAt'] ?? data['dateEchec']),
      cancelledAt: parseTimestamp(data['cancelledAt'] ?? data['dateAnnulation']),
    );
  }

  // --- 2. Conversion en Map pour Firestore (avec horodatage) ---
  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'address': address,
      'phone': phone,
      'total': total,
      'livreurId': livreurId,
      'status': _status,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'inProgressAt': inProgressAt != null ? Timestamp.fromDate(inProgressAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // --- 3. Méthodes métiers avec respect strict du cycle de vie et des dates ---

  void refuse() {
    if (_status != awaitingPickup && _status != assigned) {
      throw StateError(
        'Seule une commande à récupérer peut être refusée.',
      );
    }
    _status = refused;
    failedAt = DateTime.now();
  }

  String advanceStatus() {
    switch (_status) {
      case awaitingPickup:
      case assigned:
        _status = inProgress;
        inProgressAt = DateTime.now();
      case inProgress:
      case 'En cours de livraison':
        _status = delivered;
        deliveredAt = DateTime.now();
      case delivered:
        throw StateError('Une commande livrée ne peut plus être modifiée.');
      case refused:
      case deliveryFailed:
        throw StateError('Une commande refusée ne peut plus être modifiée.');
      default:
        throw StateError('Statut de commande inconnu : $_status');
    }

    return _status;
  }

  /// Le livreur prend en charge la commande : Affectée -> En cours de livraison
  void startDelivery() => advanceStatus();

  /// La commande est livrée avec succès
  void markAsDelivered() {
    if (_status != inProgress && _status != 'En cours de livraison') {
      throw StateError('La commande doit être en cours pour être marquée comme livrée.');
    }
    _status = delivered;
    deliveredAt = DateTime.now();
  }

  /// Gestion de l'échec de livraison
  void markAsFailed() {
    if (_status != inProgress && _status != 'En cours de livraison') {
      throw StateError('Un échec ne peut être déclaré que pour une commande en cours de livraison.');
    }
    _status = deliveryFailed;
    failedAt = DateTime.now();
  }

  /// Annulation de la commande
  void cancel() {
    if (_status == delivered || _status == deliveryFailed) {
      throw StateError('Impossible d\'annuler une commande déjà finalisée.');
    }
    _status = cancelled;
    cancelledAt = DateTime.now();
  }
}
