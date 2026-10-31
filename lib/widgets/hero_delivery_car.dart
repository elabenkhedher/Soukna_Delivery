import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Camionnette d'expédition vectorielle 3/4 avant (Delivery Box Truck)
/// avec le livreur souriant en casquette, identique à la référence photo.
/// Intègre une micro-animation permanente de suspension / moteur vivant (60 FPS).
class HeroDeliveryCar extends StatefulWidget {
  final double size;
  final Color? cabColor;
  final Color? boxColor;
  final Color? accentColor;
  final String heroTag;
  final bool animate;
  final bool isDriving;
  final bool showHeadlightBeam;
  final double? wheelRotation;

  const HeroDeliveryCar({
    super.key,
    this.size = 220,
    this.cabColor,
    this.boxColor,
    this.accentColor,
    this.heroTag = 'delivery_vehicle_hero_tag',
    this.animate = true,
    this.isDriving = false,
    this.showHeadlightBeam = false,
    this.wheelRotation,
  });

  @override
  State<HeroDeliveryCar> createState() => _HeroDeliveryCarState();
}

class _HeroDeliveryCarState extends State<HeroDeliveryCar>
    with TickerProviderStateMixin {
  late final AnimationController _motionCtrl;
  late final AnimationController _wheelCtrl;
  late final Animation<double> _bounceAnim;

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
    final motionDuration = widget.isDriving
        ? const Duration(milliseconds: 420)
        : const Duration(milliseconds: 1400);

    _motionCtrl = AnimationController(
      vsync: this,
      duration: motionDuration,
    );

    final bounceRange = widget.isDriving ? 2.6 : 2.0;
    _bounceAnim = Tween<double>(begin: -bounceRange, end: bounceRange).animate(
      CurvedAnimation(
        parent: _motionCtrl,
        curve: Curves.easeInOutSine,
      ),
    );

    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // En environnement de test widget, on évite le repeat infini pour permettre à pumpAndSettle() de terminer
    if (widget.animate && !_isTestEnv) {
      _motionCtrl.repeat(reverse: true);
      if (widget.isDriving) {
        _wheelCtrl.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(covariant HeroDeliveryCar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate ||
        widget.isDriving != oldWidget.isDriving) {
      if (widget.animate && !_isTestEnv) {
        if (!_motionCtrl.isAnimating) {
          _motionCtrl.repeat(reverse: true);
        }
        if (widget.isDriving && !_wheelCtrl.isAnimating) {
          _wheelCtrl.repeat();
        } else if (!widget.isDriving && _wheelCtrl.isAnimating) {
          _wheelCtrl.stop();
        }
      } else {
        _motionCtrl.stop();
        _wheelCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _motionCtrl.dispose();
    _wheelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspectHeight = widget.size * 0.95;

    Widget truck = AnimatedBuilder(
      animation: Listenable.merge([_bounceAnim, _wheelCtrl]),
      builder: (context, child) {
        final bounce = (widget.animate && !_isTestEnv) ? _bounceAnim.value : 0.0;
        final tilt = (widget.isDriving && widget.animate && !_isTestEnv)
            ? math.sin(_motionCtrl.value * 2 * math.pi) * 0.012
            : 0.0;

        final double currentWheelRotation = widget.wheelRotation ??
            ((widget.isDriving && widget.animate && !_isTestEnv)
                ? -_wheelCtrl.value * 2 * math.pi
                : 0.0);

        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(0.0, bounce)
            ..rotateZ(tilt),
          child: SizedBox(
            width: widget.size,
            height: aspectHeight,
            child: CustomPaint(
              painter: DeliveryBoxTruckPainter(
                cabColor: widget.cabColor ?? const Color(0xFFD3E7E5),
                boxColor: widget.boxColor ?? const Color(0xFF98B8B5),
                accentColor: widget.accentColor ?? AppColors.accent,
                brandColor: AppColors.primary,
                wheelRotation: currentWheelRotation,
                showHeadlightBeam: widget.showHeadlightBeam,
              ),
            ),
          ),
        );
      },
    );

    return Hero(
      tag: widget.heroTag,
      flightShuttleBuilder:
          (context, animation, direction, fromContext, toContext) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppCurves.heroCurve,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.92).animate(curvedAnimation),
          child: toContext.widget,
        );
      },
      child: truck,
    );
  }
}

/// Peintre vectoriel 3/4 perspective de la camionnette d'expédition (Box Truck)
/// avec cabine avant tournée vers la gauche/face, caisse arrière et chauffeur casqué.
class DeliveryBoxTruckPainter extends CustomPainter {
  final Color cabColor;
  final Color boxColor;
  final Color accentColor;
  final Color brandColor;
  final double wheelRotation;
  final bool showHeadlightBeam;

  const DeliveryBoxTruckPainter({
    required this.cabColor,
    required this.boxColor,
    required this.accentColor,
    required this.brandColor,
    this.wheelRotation = 0.0,
    this.showHeadlightBeam = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // ─────────────────────────────────────────────────────────────
    // 0. FAISCEAU LUMINEUX DES PHARES AVANT (Optionnel)
    // ─────────────────────────────────────────────────────────────
    if (showHeadlightBeam) {
      final beamPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;

      final beamPath = Path()
        ..moveTo(w * 0.14, h * 0.65)
        ..lineTo(-w * 0.60, h * 0.52)
        ..lineTo(-w * 0.70, h * 0.90)
        ..lineTo(w * 0.14, h * 0.74)
        ..close();

      final beamGradient = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white.withValues(alpha: 0.38),
          const Color(0xFFFFF59D).withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.70, 1.0],
      );

      beamPaint.shader = beamGradient.createShader(
        Rect.fromLTRB(-w * 0.70, h * 0.52, w * 0.14, h * 0.90),
      );
      canvas.drawPath(beamPath, beamPaint);
      beamPaint.shader = null;
    }

    // ─────────────────────────────────────────────────────────────
    // 1. OMBRE AU SOL EN PERSPECTIVE (Ultra-douce)
    // ─────────────────────────────────────────────────────────────
    paint.color = Colors.black.withValues(alpha: 0.12);
    final shadowPath = Path()
      ..moveTo(w * 0.08, h * 0.88)
      ..lineTo(w * 0.38, h * 0.93)
      ..lineTo(w * 0.88, h * 0.88)
      ..lineTo(w * 0.94, h * 0.82)
      ..lineTo(w * 0.40, h * 0.80)
      ..close();
    canvas.drawPath(shadowPath, paint);

    // ─────────────────────────────────────────────────────────────
    // 2. CHÂSSIS INFÉRIEUR ET ROUES ARRIÈRE
    // ─────────────────────────────────────────────────────────────
    // Châssis métallique sombre
    paint.color = const Color(0xFF263238);
    final chassisPath = Path()
      ..moveTo(w * 0.35, h * 0.70)
      ..lineTo(w * 0.86, h * 0.69)
      ..lineTo(w * 0.86, h * 0.78)
      ..lineTo(w * 0.62, h * 0.78)
      ..lineTo(w * 0.35, h * 0.77)
      ..close();
    canvas.drawPath(chassisPath, paint);

    // Roue arrière droite (intérieur/arrière)
    _drawWheel(
      canvas,
      center: Offset(w * 0.78, h * 0.78),
      radiusX: w * 0.088,
      radiusY: w * 0.088,
      isFront: false,
      wheelRotation: wheelRotation,
    );

    // ─────────────────────────────────────────────────────────────
    // 3. CAISSE D'EXPÉDITION (GRAND CONTAINER ARRIÈRE 3D)
    // ─────────────────────────────────────────────────────────────
    // Face latérale droite de la caisse (vue en perspective)
    final boxSidePath = Path()
      ..moveTo(w * 0.32, h * 0.18) // Haut avant
      ..lineTo(w * 0.64, h * 0.15) // Haut centre
      ..lineTo(w * 0.94, h * 0.19) // Haut arrière droit
      ..lineTo(w * 0.94, h * 0.65) // Bas arrière droit
      ..lineTo(w * 0.58, h * 0.68) // Bas milieu
      ..lineTo(w * 0.32, h * 0.67) // Bas avant
      ..close();

    final boxSideGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        boxColor,
        Color.lerp(boxColor, Colors.black, 0.18)!,
      ],
    );
    paint.shader = boxSideGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(boxSidePath, paint);
    paint.shader = null;

    // Face supérieure / biseau de toit de la caisse
    final boxTopPath = Path()
      ..moveTo(w * 0.32, h * 0.18)
      ..lineTo(w * 0.64, h * 0.15)
      ..lineTo(w * 0.94, h * 0.19)
      ..lineTo(w * 0.68, h * 0.14)
      ..close();
    paint.color = Color.lerp(boxColor, Colors.white, 0.25)!;
    canvas.drawPath(boxTopPath, paint);

    // Cadre / profilé de la caisse
    strokePaint.color = Color.lerp(boxColor, Colors.black, 0.25)!;
    strokePaint.strokeWidth = 2.0;
    canvas.drawPath(boxSidePath, strokePaint);

    // Bande décorative de livraison Dokan sur la caisse
    paint.color = accentColor;
    final boxStripe = Path()
      ..moveTo(w * 0.34, h * 0.42)
      ..lineTo(w * 0.92, h * 0.44)
      ..lineTo(w * 0.92, h * 0.47)
      ..lineTo(w * 0.34, h * 0.45)
      ..close();
    canvas.drawPath(boxStripe, paint);

    // Logo / lettrage symbolique "DOKAN" sur la caisse
    paint.color = Colors.white.withValues(alpha: 0.9);
    paint.style = PaintingStyle.fill;
    final logoBadge = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, h * 0.30, w * 0.24, h * 0.08),
      const Radius.circular(4),
    );
    canvas.drawRRect(logoBadge, paint);

    paint.color = brandColor;
    canvas.drawCircle(Offset(w * 0.67, h * 0.34), w * 0.022, paint);
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.72, h * 0.34),
      Offset(w * 0.83, h * 0.34),
      paint,
    );

    // Lignes de reflet aérodynamique sur la caisse (style photo)
    paint.color = Colors.white.withValues(alpha: 0.22);
    final highlightPath = Path()
      ..moveTo(w * 0.68, h * 0.26)
      ..lineTo(w * 0.92, h * 0.36)
      ..lineTo(w * 0.90, h * 0.42)
      ..lineTo(w * 0.68, h * 0.30)
      ..close();
    canvas.drawPath(highlightPath, paint);

    // ─────────────────────────────────────────────────────────────
    // 4. CHAUFFEUR LIVREUR SOURIANT AVEC CASQUETTE (DANS LA CABINE)
    // ─────────────────────────────────────────────────────────────
    // Corps & T-shirt Dokan du livreur
    paint.color = brandColor;
    final driverBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.48, w * 0.18, h * 0.18),
      const Radius.circular(12),
    );
    canvas.drawRRect(driverBody, paint);

    // Col du polo
    paint.color = Color.lerp(brandColor, Colors.white, 0.25)!;
    final collarPath = Path()
      ..moveTo(w * 0.42, h * 0.50)
      ..lineTo(w * 0.46, h * 0.55)
      ..lineTo(w * 0.50, h * 0.50)
      ..close();
    canvas.drawPath(collarPath, paint);

    // Bras accoudé à la portière
    paint.color = const Color(0xFFFFCC80); // Peau naturelle
    final armPath = Path()
      ..moveTo(w * 0.38, h * 0.54)
      ..quadraticBezierTo(w * 0.48, h * 0.56, w * 0.56, h * 0.58)
      ..lineTo(w * 0.55, h * 0.61)
      ..quadraticBezierTo(w * 0.46, h * 0.60, w * 0.38, h * 0.58)
      ..close();
    canvas.drawPath(armPath, paint);

    // Tête du chauffeur
    paint.color = const Color(0xFFFFCC80);
    canvas.drawCircle(Offset(w * 0.47, h * 0.42), w * 0.08, paint);

    // Cheveux bruns sur les tempes
    paint.color = const Color(0xFF5D4037);
    final hairPath = Path()
      ..moveTo(w * 0.41, h * 0.38)
      ..lineTo(w * 0.40, h * 0.45)
      ..lineTo(w * 0.43, h * 0.42)
      ..close();
    canvas.drawPath(hairPath, paint);

    // Oreille
    paint.color = const Color(0xFFFFA726);
    canvas.drawCircle(Offset(w * 0.54, h * 0.43), w * 0.018, paint);

    // Yeux expressifs et souriants
    paint.color = const Color(0xFF212121);
    canvas.drawCircle(Offset(w * 0.44, h * 0.41), w * 0.012, paint);
    canvas.drawCircle(Offset(w * 0.49, h * 0.41), w * 0.012, paint);

    // Points de lumière dans les yeux
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.445, h * 0.405), w * 0.004, paint);
    canvas.drawCircle(Offset(w * 0.495, h * 0.405), w * 0.004, paint);

    // Sourcils bienveillants
    paint.color = const Color(0xFF4E342E);
    strokePaint.color = const Color(0xFF4E342E);
    strokePaint.strokeWidth = 1.8;
    strokePaint.strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.38),
      Offset(w * 0.45, h * 0.375),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.48, h * 0.375),
      Offset(w * 0.51, h * 0.385),
      strokePaint,
    );

    // Nez discret
    canvas.drawLine(
      Offset(w * 0.46, h * 0.42),
      Offset(w * 0.45, h * 0.44),
      strokePaint,
    );

    // Sourire chaleureux
    paint.color = Colors.white;
    final mouthPath = Path()
      ..moveTo(w * 0.43, h * 0.46)
      ..quadraticBezierTo(w * 0.47, h * 0.50, w * 0.50, h * 0.46)
      ..close();
    canvas.drawPath(mouthPath, paint);
    strokePaint.color = const Color(0xFF4E342E);
    strokePaint.strokeWidth = 1.2;
    canvas.drawPath(mouthPath, strokePaint);

    // CASQUETTE DE LIVREUR DOKAN (Bleue / Teal Dokan)
    paint.color = brandColor;
    final capDome = Path()
      ..moveTo(w * 0.38, h * 0.37)
      ..quadraticBezierTo(w * 0.47, h * 0.28, w * 0.56, h * 0.36)
      ..lineTo(w * 0.38, h * 0.37)
      ..close();
    canvas.drawPath(capDome, paint);

    // Visière de la casquette orientée vers l'avant
    paint.color = Color.lerp(brandColor, Colors.black, 0.2)!;
    final capVisor = Path()
      ..moveTo(w * 0.38, h * 0.37)
      ..quadraticBezierTo(w * 0.33, h * 0.37, w * 0.30, h * 0.39)
      ..quadraticBezierTo(w * 0.36, h * 0.41, w * 0.44, h * 0.38)
      ..close();
    canvas.drawPath(capVisor, paint);

    // ─────────────────────────────────────────────────────────────
    // 5. CABINE AVANT DU VÉHICULE (3/4 VUE AVANT)
    // ─────────────────────────────────────────────────────────────
    // Montant et carrosserie avant
    final cabPath = Path()
      // Toit cabine
      ..moveTo(w * 0.34, h * 0.37)
      ..quadraticBezierTo(w * 0.24, h * 0.39, w * 0.17, h * 0.44)
      // Pare-brise avant descendant
      ..quadraticBezierTo(w * 0.12, h * 0.54, w * 0.11, h * 0.65)
      // Calandre & Pare-chocs avant
      ..quadraticBezierTo(w * 0.11, h * 0.76, w * 0.14, h * 0.79)
      ..lineTo(w * 0.38, h * 0.83)
      // Aile avant & Passage de roue avant gauche
      ..arcToPoint(
        Offset(w * 0.58, h * 0.78),
        radius: Radius.circular(w * 0.11),
        clockwise: false,
      )
      ..lineTo(w * 0.59, h * 0.72)
      // Portière latérale
      ..lineTo(w * 0.58, h * 0.54)
      ..lineTo(w * 0.36, h * 0.52)
      ..lineTo(w * 0.35, h * 0.37)
      ..close();

    final cabGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cabColor,
        Color.lerp(cabColor, Colors.white, 0.3)!,
        Color.lerp(cabColor, const Color(0xFF78909C), 0.25)!,
      ],
    );
    paint.shader = cabGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(cabPath, paint);
    paint.shader = null;

    // Contour net de cabine
    strokePaint.color = const Color(0xFF546E7A);
    strokePaint.strokeWidth = 1.6;
    canvas.drawPath(cabPath, strokePaint);

    // Grand pare-brise avant bombé avec reflet
    paint.color = const Color(0xFF1E2B2F);
    final windshieldPath = Path()
      ..moveTo(w * 0.20, h * 0.44)
      ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.36, h * 0.43)
      ..lineTo(w * 0.35, h * 0.60)
      ..quadraticBezierTo(w * 0.22, h * 0.62, w * 0.15, h * 0.61)
      ..quadraticBezierTo(w * 0.16, h * 0.50, w * 0.20, h * 0.44)
      ..close();
    canvas.drawPath(windshieldPath, paint);

    // Reflet de lumière blanc sur le pare-brise
    paint.color = Colors.white.withValues(alpha: 0.35);
    final glassShine = Path()
      ..moveTo(w * 0.22, h * 0.45)
      ..lineTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.22, h * 0.58)
      ..lineTo(w * 0.17, h * 0.58)
      ..close();
    canvas.drawPath(glassShine, paint);

    // Phares avant en amande (Vue 3/4)
    // Phare gauche (face avant)
    paint.color = Colors.white;
    final headlightLeft = Path()
      ..moveTo(w * 0.13, h * 0.66)
      ..quadraticBezierTo(w * 0.16, h * 0.64, w * 0.18, h * 0.68)
      ..quadraticBezierTo(w * 0.16, h * 0.73, w * 0.13, h * 0.72)
      ..close();
    canvas.drawPath(headlightLeft, paint);
    paint.color = const Color(0xFFFFF176); // Ampoule allumée
    canvas.drawCircle(Offset(w * 0.155, h * 0.68), w * 0.015, paint);

    // Phare droit (face principale)
    paint.color = Colors.white;
    final headlightRight = Path()
      ..moveTo(w * 0.28, h * 0.69)
      ..quadraticBezierTo(w * 0.33, h * 0.67, w * 0.35, h * 0.72)
      ..quadraticBezierTo(w * 0.32, h * 0.77, w * 0.27, h * 0.75)
      ..close();
    canvas.drawPath(headlightRight, paint);
    paint.color = const Color(0xFFFFF176);
    canvas.drawCircle(Offset(w * 0.31, h * 0.72), w * 0.018, paint);

    // Pare-chocs avant inférieur
    paint.color = const Color(0xFF37474F);
    final bumperPath = Path()
      ..moveTo(w * 0.13, h * 0.77)
      ..lineTo(w * 0.38, h * 0.81)
      ..lineTo(w * 0.38, h * 0.85)
      ..lineTo(w * 0.14, h * 0.81)
      ..close();
    canvas.drawPath(bumperPath, paint);

    // Feux antibrouillard / clignotants ambrés sur le pare-chocs
    paint.color = accentColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.775, w * 0.045, h * 0.02),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.29, h * 0.80, w * 0.055, h * 0.022),
        const Radius.circular(2),
      ),
      paint,
    );

    // Rétroviseur latéral sur tige (comme sur la photo)
    paint.color = const Color(0xFF263238);
    strokePaint.color = const Color(0xFF263238);
    strokePaint.strokeWidth = 3.0;
    canvas.drawLine(
      Offset(w * 0.16, h * 0.58),
      Offset(w * 0.07, h * 0.58),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.07, h * 0.58),
      Offset(w * 0.07, h * 0.53),
      strokePaint,
    );

    // Miroir ovale
    final mirrorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.49, w * 0.045, h * 0.08),
      const Radius.circular(6),
    );
    paint.color = const Color(0xFF37474F);
    canvas.drawRRect(mirrorRect, paint);
    paint.color = const Color(0xFF90A4AE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.055, h * 0.50, w * 0.035, h * 0.065),
        const Radius.circular(4),
      ),
      paint,
    );

    // Poignée de portière
    paint.color = const Color(0xFF37474F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.50, h * 0.63, w * 0.05, h * 0.015),
        const Radius.circular(2),
      ),
      paint,
    );

    // ─────────────────────────────────────────────────────────────
    // 6. ROUE AVANT PRINCIPALE (EN PERSPECTIVE DÉTAILLÉE)
    // ─────────────────────────────────────────────────────────────
    _drawWheel(
      canvas,
      center: Offset(w * 0.48, h * 0.82),
      radiusX: w * 0.11,
      radiusY: w * 0.11,
      isFront: true,
      wheelRotation: wheelRotation,
    );
  }

  void _drawWheel(
    Canvas canvas, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required bool isFront,
    double wheelRotation = 0.0,
  }) {
    final paint = Paint()..isAntiAlias = true;

    // Pneu noir épais
    paint.color = const Color(0xFF212121);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      paint,
    );

    // Jante extérieure acier
    paint.color = const Color(0xFFECEFF1);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 1.35,
        height: radiusY * 1.35,
      ),
      paint,
    );

    // Centre de jante bleu canard / gris
    paint.color = const Color(0xFF37474F);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 0.95,
        height: radiusY * 0.95,
      ),
      paint,
    );

    // Branches / rayons dynamiques de la jante
    final spokePaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = radiusX * 0.14
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5 + wheelRotation;
      final x1 = center.dx + (radiusX * 0.16) * math.cos(angle);
      final y1 = center.dy + (radiusY * 0.16) * math.sin(angle);
      final x2 = center.dx + (radiusX * 0.42) * math.cos(angle);
      final y2 = center.dy + (radiusY * 0.42) * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), spokePaint);
    }

    // Trous / écrous de jante en cercle
    paint.color = const Color(0xFFCFD8DC);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5 + wheelRotation;
      final ex = center.dx + (radiusX * 0.32) * math.cos(angle);
      final ey = center.dy + (radiusY * 0.32) * math.sin(angle);
      canvas.drawCircle(Offset(ex, ey), radiusX * 0.075, paint);
    }

    // Écrou central
    paint.color = const Color(0xFFECEFF1);
    canvas.drawCircle(center, radiusX * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant DeliveryBoxTruckPainter oldDelegate) {
    return oldDelegate.cabColor != cabColor ||
        oldDelegate.boxColor != boxColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.brandColor != brandColor ||
        oldDelegate.wheelRotation != wheelRotation ||
        oldDelegate.showHeadlightBeam != showHeadlightBeam;
  }
}
