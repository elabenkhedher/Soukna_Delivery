import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'role_denied_exception.dart';
import 'user_role.dart';

/// ============================================================
///  SERVICE D'AUTHENTIFICATION FIREBASE + CONTRÔLE DE RÔLE
///  Réutilisable tel quel dans les 3 apps (admin, deliverer, client) :
///  seule la valeur de `requiredRole` change à l'usage.
///
///  Principe : le rôle vit dans Firestore — collection `users`,
///  document avec l'uid, champ `role` ('admin' / 'deliverer' / 'livreur' /
///  'client' / 'pending').
/// ============================================================
class FirebaseRoleService {
  /// Nom du champ qui porte le rôle dans le document utilisateur
  static const String roleField = 'role';

  /// Collection Firestore des profils utilisateurs
  static const String usersCollection = 'users';

  FirebaseRoleService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(usersCollection);

  // ── Rôle d'un utilisateur (document Firestore users/{uid}) ────────────────
  Future<UserRole?> roleOf(User user) async {
    try {
      final doc = await _users.doc(user.uid).get();
      return UserRole.fromField(doc.data()?[roleField]);
    } catch (_) {
      return null;
    }
  }

  // ── Connexion contrôlée par rôle ──────────────────────────────────────────
  /// Ouvre la session Firebase puis exige que le compte porte [requiredRole].
  /// Sinon : déconnexion immédiate + [RoleDeniedException].
  Future<UserCredential> signInWithRole({
    required String email,
    required String password,
    required UserRole requiredRole,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    var role = await roleOf(user);
    if (role == null) {
      // Si le profil n'existe pas encore dans Firestore, on le crée automatiquement
      try {
        await createUserDoc(user, initialRole: requiredRole);
        role = requiredRole;
      } catch (_) {
        // Si la création Firestore échoue, poursuivre
      }
    }

    if (role == requiredRole) return credential;

    // Rôle absent ou insuffisant → on referme la session
    await _auth.signOut();
    throw RoleDeniedException(expected: requiredRole, actual: role);
  }

  // ── Restauration contrôlée de la session ─────────────────────────────────
  /// Vérifie l'utilisateur déjà connecté au lancement de l'app :
  /// rôle correct → utilisateur renvoyé, sinon déconnecté + `null`.
  Future<User?> restoreUserWithRole(UserRole requiredRole) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final role = await roleOf(user);
      if (role == requiredRole || role == null) return user;
    } catch (_) {
      // Vérification impossible (ex : hors-ligne)
      return user;
    }

    await _auth.signOut();
    return null;
  }

  // ── Création du profil Firestore ──────────────────────────────────────────
  Future<void> createUserDoc(
      User user, {
        required UserRole initialRole,
      }) async {
    final docRef = _users.doc(user.uid);
    final existing = await docRef.get();

    // Profil déjà présent → ne pas écraser
    if (existing.exists) return;

    await docRef.set({
      roleField: initialRole.role,
      'email': user.email ?? '',
      'name': user.displayName ?? '',
    });
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();
}
