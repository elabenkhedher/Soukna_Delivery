import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/delivery_order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'auth_gate.dart';

typedef ProfilScreen = ProfileScreen;

class ProfileScreen extends StatelessWidget {
  final OrderService? orderService;
  final List<DeliveryOrder>? orders;
  final VoidCallback? onLogout;
  final bool isEmbedded;

  const ProfileScreen({
    super.key,
    this.orderService,
    this.orders,
    this.onLogout,
    this.isEmbedded = false,
  });

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (onLogout != null) {
      onLogout!();
      return;
    }
    await AuthService().signOut();
    if (!context.mounted) return;
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
    final service = orderService ?? OrderService();
    final currentUser = AuthService().currentUser;

    final orderList = orders ?? service.getOrders();
    final totalAssigned = orderList.length;
    final totalDelivered = orderList.where((o) => o.isDelivered).length;

    final content = ListView(
      key: const ValueKey('profile-page'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Carte profil & avatar
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  currentUser?.displayName ?? 'Espace livreur',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'Compte vérifié',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isDark ? AppColors.darkMuted : AppColors.mutedText,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Détails et statistiques
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              if (currentUser?.email != null) ...[
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Adresse e-mail'),
                  subtitle: Text(currentUser!.email!),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              if (currentUser?.uid != null) ...[
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Mon UID Livreur (Firebase)'),
                  subtitle: Text(
                    currentUser!.uid,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copier mon UID',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: currentUser.uid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UID copié dans le presse-papier !')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              const ListTile(
                leading: Icon(Icons.badge_outlined),
                title: Text('Rôle'),
                subtitle: Text('Livreur officiel'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Commandes attribuées'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$totalAssigned',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Commandes livrées'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$totalDelivered',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bouton de déconnexion
        OutlinedButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se déconnecter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(
              color: colorScheme.error.withValues(alpha: 0.6),
              width: 1.5,
            ),
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: content,
    );
  }
}
