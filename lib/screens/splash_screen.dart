import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/delivery_road_scene.dart';
import 'login_screen.dart';

/// Écran de démarrage (Splash Screen) animé avec la camionnette de livraison
/// en mouvement sur une route dynamique et transition Hero vers la page de connexion.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.nextScreen = const LoginScreen(),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.8, curve: AppCurves.spring),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.1, 0.85, curve: AppCurves.smooth),
      ),
    );

    _animCtrl.forward();

    // Redirection automatique après le délai spécifié
    Future.delayed(widget.duration, () {
      if (mounted) _goToNextScreen();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      SlideFadePageRoute(page: widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goToNextScreen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Cercles décoratifs d'arrière-plan avec douce luminescence
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 110,
                  left: -80,
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // Contenu central : Marque + Scène de route dynamique
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titre principal de l'application
                            const Text(
                              'Dokan Delivery',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Color(0x3D000000),
                                    offset: Offset(0, 4),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sous-titre en capsule avec indicateur en direct
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Espace Livreur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Scène vivante de la camionnette sur la route en mouvement
                            const DeliveryRoadScene(
                              carSize: 142,
                              heroTag: 'delivery_vehicle_hero_tag',
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bas de page (indicateur et slogan)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rapidité • Fiabilité • Sécurité',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
