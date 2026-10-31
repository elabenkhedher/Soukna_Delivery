import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/firebase_role_service.dart';
import '../core/auth/user_role.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _DelivererRoleGate(user: snapshot.data!);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _DelivererRoleGate extends StatefulWidget {
  final User user;
  const _DelivererRoleGate({required this.user});

  @override
  State<_DelivererRoleGate> createState() => _DelivererRoleGateState();
}

class _DelivererRoleGateState extends State<_DelivererRoleGate> {
  late final Future<bool> _check = _isFullyAuthorized();

  Future<bool> _isFullyAuthorized() async {
    final user =
        await FirebaseRoleService().restoreUserWithRole(UserRole.deliverer);
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final hasChangedPassword =
        prefs.getBool('first_password_changed_${user.uid}') ?? false;

    return hasChangedPassword;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const DashboardScreen();
        }

        // Si le premier mot de passe n'a pas encore été validé -> Écran de connexion
        return const LoginScreen();
      },
    );
  }
}
