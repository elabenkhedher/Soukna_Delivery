import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'hero_delivery_car.dart';

/// Scène animée de route et de conduite pour la camionnette de livraison Dokan.
/// Intègre :
/// - Silhouette urbaine en arrière-plan avec fenêtres éclairées
/// - Route asphaltée avec marquages blancs en défilement continu
/// - Lignes aérodynamiques de vitesse (speed streaks)
/// - Panaches de fumée / poussière d'échappement qui s'évaporent
/// - Arrivée dynamique du véhicule en décélération douce
/// - Faisceau lumineux des phares et balise de livraison en lévitation
class DeliveryRoadScene extends StatefulWidget {
  final double carSize;
  final bool animate;
  final String heroTag;

  const DeliveryRoadScene({
    super.key,
    this.carSize = 138,
    this.animate = true,
    this.heroTag = 'delivery_vehicle_hero_tag',
  });

  @override
  State<DeliveryRoadScene> createState() => _DeliveryRoadSceneState();
}

class _DeliveryRoadSceneState extends State<DeliveryRoadScene>
    with TickerProviderStateMixin {
  late final AnimationController _driveInCtrl;
  late final AnimationController _roadCtrl;
  late final AnimationController _exhaustCtrl;
  late final AnimationController _beaconCtrl;

  late final Animation<double> _slideInAnim;
  late final Animation<double> _scaleInAnim;
  late final Animation<double> _opacityAnim;

  static bool get _isTestEnv {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. Arrivée dynamique de la voiture depuis la droite
    _driveInCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideInAnim = Tween<double>(begin: 180.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _driveInCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _scaleInAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _driveInCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _driveInCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // 2. Défilement continu de la route et des lignes de vitesse (600ms par cycle)
    _roadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 3. Panaches d'échappement répétés
    _exhaustCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // 4. Balise de livraison en lévitation au-dessus du véhicule
    _beaconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _driveInCtrl.forward();

    if (widget.animate && !_isTestEnv) {
      _roadCtrl.repeat();
      _exhaustCtrl.repeat();
      _beaconCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DeliveryRoadScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate && !_isTestEnv) {
        _roadCtrl.repeat();
        _exhaustCtrl.repeat();
        _beaconCtrl.repeat(reverse: true);
      } else {
        _roadCtrl.stop();
        _exhaustCtrl.stop();
        _beaconCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _driveInCtrl.dispose();
    _roadCtrl.dispose();
    _exhaustCtrl.dispose();
    _beaconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sceneHeight = 220.0;

    return SizedBox(
      height: sceneHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── 1. Silhouette urbaine en arrière-plan ──────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 46,
            height: 90,
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(
                painter: CitySkylinePainter(),
              ),
            ),
          ),

          // ── 2. Route asphaltée avec marquages défilants ────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            height: 48,
            child: AnimatedBuilder(
              animation: _roadCtrl,
              builder: (context, _) {
                final progress = (!_isTestEnv && widget.animate)
                    ? _roadCtrl.value
                    : 0.0;
                return CustomPaint(
                  painter: RoadPainter(progress: progress),
                );
              },
            ),
          ),

          // ── 3. Lignes aérodynamiques de vitesse ────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 20,
            bottom: 40,
            child: AnimatedBuilder(
              animation: _roadCtrl,
              builder: (context, _) {
                final progress = (!_isTestEnv && widget.animate)
                    ? _roadCtrl.value
                    : 0.0;
                return CustomPaint(
                  painter: SpeedWindTrailsPainter(progress: progress),
                );
              },
            ),
          ),

          // ── 4. Panaches de fumée / poussière d'échappement ─────
          AnimatedBuilder(
            animation: Listenable.merge([_driveInCtrl, _exhaustCtrl]),
            builder: (context, _) {
              final slideX = _slideInAnim.value;
              final exhaustProgress = (!_isTestEnv && widget.animate)
                  ? _exhaustCtrl.value
                  : 0.0;
              return Transform.translate(
                offset: Offset(slideX + (widget.carSize * 0.40), 18),
                child: CustomPaint(
                  painter: ExhaustPuffsPainter(progress: exhaustProgress),
                ),
              );
            },
          ),

          // ── 5. Camionnette de livraison animée ─────────────────
          AnimatedBuilder(
            animation: _driveInCtrl,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideInAnim.value, 0),
                child: Transform.scale(
                  scale: _scaleInAnim.value,
                  child: Opacity(
                    opacity: _opacityAnim.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: HeroDeliveryCar(
              size: widget.carSize,
              heroTag: widget.heroTag,
              isDriving: true,
              showHeadlightBeam: true,
              animate: widget.animate,
            ),
          ),

          // ── 6. Balise / Pin de livraison Dokan flottant ────────
          Positioned(
            top: 8,
            child: AnimatedBuilder(
              animation: Listenable.merge([_driveInCtrl, _beaconCtrl]),
              builder: (context, _) {
                final slideX = _slideInAnim.value;
                final levitate = (!_isTestEnv && widget.animate)
                    ? math.sin(_beaconCtrl.value * math.pi) * 6.0
                    : 0.0;
                return Transform.translate(
                  offset: Offset(slideX - 8, -levitate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'EN ROUTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre de la silhouette urbaine lointaine
class CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F3A3D)
      ..isAntiAlias = true;

    final windowPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.35)
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final path = Path()..moveTo(0, h);

    // Profil architectural des bâtiments stylisés
    final buildings = [
      Rect.fromLTWH(0, h * 0.45, w * 0.12, h * 0.55),
      Rect.fromLTWH(w * 0.11, h * 0.25, w * 0.10, h * 0.75),
      Rect.fromLTWH(w * 0.20, h * 0.55, w * 0.08, h * 0.45),
      Rect.fromLTWH(w * 0.27, h * 0.30, w * 0.13, h * 0.70),
      Rect.fromLTWH(w * 0.39, h * 0.60, w * 0.09, h * 0.40),
      Rect.fromLTWH(w * 0.47, h * 0.20, w * 0.11, h * 0.80),
      Rect.fromLTWH(w * 0.57, h * 0.40, w * 0.12, h * 0.60),
      Rect.fromLTWH(w * 0.68, h * 0.32, w * 0.10, h * 0.68),
      Rect.fromLTWH(w * 0.77, h * 0.50, w * 0.11, h * 0.50),
      Rect.fromLTWH(w * 0.87, h * 0.28, w * 0.14, h * 0.72),
    ];

    for (final rect in buildings) {
      path.addRect(rect);
    }

    canvas.drawPath(path, paint);

    // Petites fenêtres éclairées chaleureuses
    final windowOffsets = [
      Offset(w * 0.14, h * 0.38),
      Offset(w * 0.17, h * 0.48),
      Offset(w * 0.31, h * 0.42),
      Offset(w * 0.35, h * 0.52),
      Offset(w * 0.51, h * 0.32),
      Offset(w * 0.54, h * 0.45),
      Offset(w * 0.71, h * 0.44),
      Offset(w * 0.90, h * 0.40),
      Offset(w * 0.93, h * 0.52),
    ];

    for (final pt in windowOffsets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pt.dx, pt.dy, 4, 6),
          const Radius.circular(1),
        ),
        windowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Peintre de la route asphaltée avec défilement continu
class RoadPainter extends CustomPainter {
  final double progress;

  RoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Asphalte avec léger dégradé de profondeur
    final roadRect = Rect.fromLTWH(0, 0, w, h);
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF142426),
          Color(0xFF0F1C1D),
        ],
      ).createShader(roadRect);

    canvas.drawRect(roadRect, roadPaint);

    // Bordure supérieure de trottoir avec néon / lueur teal
    final curbPaint = Paint()
      ..color = const Color(0xFF26A69A).withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 1), Offset(w, 1), curbPaint);

    // Ligne de sol / bordure inférieure
    final bottomLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), bottomLinePaint);

    // Marquages au sol blancs en pointillé (défilent de gauche à droite)
    // Comme la camionnette fait face à gauche, le défilement vers la droite
    // donne l'illusion parfaite que le véhicule file vers la gauche !
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const dashWidth = 36.0;
    const dashSpacing = 28.0;
    const cycleLength = dashWidth + dashSpacing;

    final offset = (progress * cycleLength);

    for (double x = -cycleLength + offset; x < w + cycleLength; x += cycleLength) {
      final dashRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h * 0.44, dashWidth, 4.0),
        const Radius.circular(2),
      );
      canvas.drawRRect(dashRRect, dashPaint);
    }

    // Plots réfléchissants le long de la route (cat's eyes)
    final studPaint = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.70);
    const studSpacing = 90.0;
    final studOffset = (progress * studSpacing);
    for (double x = -studSpacing + studOffset; x < w + studSpacing; x += studSpacing) {
      canvas.drawCircle(Offset(x, h * 0.82), 2.0, studPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Peintre des lignes aérodynamiques de vent / vitesse
class SpeedWindTrailsPainter extends CustomPainter {
  final double progress;

  SpeedWindTrailsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final trails = [
      {'y': h * 0.18, 'len': 65.0, 'speed': 1.2, 'alpha': 0.35, 'thick': 1.6},
      {'y': h * 0.32, 'len': 90.0, 'speed': 1.5, 'alpha': 0.45, 'thick': 2.0},
      {'y': h * 0.50, 'len': 50.0, 'speed': 1.0, 'alpha': 0.28, 'thick': 1.4},
      {'y': h * 0.68, 'len': 80.0, 'speed': 1.4, 'alpha': 0.38, 'thick': 1.8},
    ];

    for (final trail in trails) {
      final y = trail['y'] as double;
      final len = trail['len'] as double;
      final speed = trail['speed'] as double;
      final alpha = trail['alpha'] as double;
      final thick = trail['thick'] as double;

      final cycle = w + len * 2;
      final x = ((progress * speed * cycle) % cycle) - len;

      final paint = Paint()
        ..strokeWidth = thick
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: alpha),
            const Color(0xFF80DEEA).withValues(alpha: alpha * 0.8),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(x, y, len, thick));

      canvas.drawLine(Offset(x, y), Offset(x + len, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedWindTrailsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Peintre des volutes / bouffées d'échappement qui s'éloignent vers la droite
class ExhaustPuffsPainter extends CustomPainter {
  final double progress;

  ExhaustPuffsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final puffPaint = Paint()..style = PaintingStyle.fill;

    // 3 bouffées étagées dans le temps
    for (int i = 0; i < 3; i++) {
      final t = (progress + (i / 3.0)) % 1.0;

      // Distance horizontale (vers la droite / arrière du véhicule)
      final dx = t * 50.0;
      // Élévation verticale légère
      final dy = -math.sin(t * math.pi) * 8.0;
      // Rayon croissant (2px -> 13px)
      final radius = 2.5 + (t * 11.0);
      // Opacité décroissante (0.45 -> 0.0)
      final alpha = (1.0 - t) * 0.38;

      puffPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), radius, puffPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ExhaustPuffsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
