/// ============================================================
///  RÔLES APPLICATIFS — PARTAGÉ PAR LES 3 APPS
///  (admin : app admin · deliverer : app livreur · client : app client)
///
///  Le rôle est stocké dans Firestore : collection `users`, document
///  avec l'uid Firebase, champ `role`.
/// ============================================================
enum UserRole {
  admin,
  deliverer,
  client,
  pending; // compte créé sans rôle, en attente d'attribution manuelle

  /// Valeur du champ `role` dans Firestore
  String get role => name;

  /// Lit la valeur du champ `role` et renvoie le rôle correspondant
  /// (null si absent/inconnu). Reconnait aussi les variantes en français ("livreur").
  static UserRole? fromField(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();

    if (normalized == 'deliverer' || normalized == 'livreur') {
      return UserRole.deliverer;
    }
    if (normalized == 'admin' || normalized == 'administrateur') {
      return UserRole.admin;
    }
    if (normalized == 'client' || normalized == 'acheteur') {
      return UserRole.client;
    }

    for (final role in values) {
      if (role.role == normalized) return role;
    }
    return null;
  }
}
