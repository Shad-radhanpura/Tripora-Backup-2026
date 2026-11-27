import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Central brand settings for the Tripora logo and its intro animations.
/// Change durations here, not in the widgets.
class TriporaBrand {
  TriporaBrand._();

  static const Color primary = Color(0xFF0078FF);
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFFEBF5FF);
  static const Color accent = Color(0xFF00C5FF);
  static const Color night = Color(0xFF062A55);

  /// Application launch intro. Kept between 1 and 2 seconds.
  static const Duration launchIntro = Duration(milliseconds: 1900);

  /// Welcome intro after a successful login or signup.
  static const Duration welcomeIntro = Duration(milliseconds: 1800);

  /// Shorter intros when the device asks for reduced motion.
  static const Duration reducedIntro = Duration(milliseconds: 300);

  static const String wordmark = 'Tripora';
  static const String tagline = 'Discover More. Travel Smarter.';
}

/// Draws the Tripora mark: a globe with a travel route, a destination pin and a
/// plane marker. [progress] (0 to 1) draws the route; [spin] turns the globe;
/// [pinScale] sizes the destination pin; [glow] (0 to 1) brightens the mark.
class TriporaMarkPainter extends CustomPainter {
  final double progress;
  final double spin;
  final double pinScale;
  final double glow;
  final Color ringColor;
  final Color routeColor;
  final Color badgeStart;
  final Color badgeEnd;

  TriporaMarkPainter({
    this.progress = 1,
    this.spin = 0,
    this.pinScale = 1,
    this.glow = 0,
    this.ringColor = Colors.white,
    this.routeColor = const Color(0xFF00C5FF),
    this.badgeStart = TriporaBrand.primary,
    this.badgeEnd = TriporaBrand.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);
    final r = s * 0.5;

    // Rounded badge with a diagonal gradient.
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s, height: s),
      Radius.circular(s * 0.26),
    );
    canvas.drawRRect(
      badge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [badgeStart, badgeEnd],
        ).createShader(badge.outerRect),
    );

    // Soft glow behind the globe.
    if (glow > 0) {
      canvas.drawCircle(
        c,
        r * 0.95,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12),
      );
    }

    // Globe: outline and rotating meridians clipped to the disc.
    final globeR = r * 0.56;
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035;
    canvas.drawCircle(c, globeR, ring);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: globeR)));
    final meridian = Paint()
      ..color = ringColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02;
    for (var i = 0; i < 3; i++) {
      final phase = spin + i * math.pi / 3;
      final xScale = math.cos(phase).abs();
      canvas.drawOval(
        Rect.fromCenter(center: c, width: globeR * 2 * xScale, height: globeR * 2),
        meridian,
      );
    }
    canvas.drawLine(
      Offset(c.dx - globeR, c.dy),
      Offset(c.dx + globeR, c.dy),
      meridian,
    );
    canvas.restore();

    // Route: a curve from the lower left to the destination, drawn by progress.
    final start = Offset(c.dx - globeR * 0.82, c.dy + globeR * 0.55);
    final end = Offset(c.dx + globeR * 0.55, c.dy - globeR * 0.6);
    final control = Offset(c.dx - globeR * 0.1, c.dy + globeR * 0.9);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    canvas.drawPath(
      drawn,
      Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.05,
    );

    // Plane marker at the head of the route.
    if (progress > 0.02) {
      final head = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0));
      if (head != null) {
        canvas.drawCircle(head.position, s * 0.045, Paint()..color = Colors.white);
      }
    }

    // Destination pin at the end of the route.
    if (pinScale > 0) {
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.scale(pinScale);
      final pin = Path()
        ..moveTo(0, s * 0.11)
        ..cubicTo(-s * 0.09, s * 0.02, -s * 0.07, -s * 0.07, 0, -s * 0.07)
        ..cubicTo(s * 0.07, -s * 0.07, s * 0.09, s * 0.02, 0, s * 0.11)
        ..close();
      canvas.drawPath(pin, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(0, -s * 0.02), s * 0.03, Paint()..color = badgeStart);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(TriporaMarkPainter old) =>
      old.progress != progress ||
      old.spin != spin ||
      old.pinScale != pinScale ||
      old.glow != glow ||
      old.ringColor != ringColor ||
      old.routeColor != routeColor ||
      old.badgeStart != badgeStart ||
      old.badgeEnd != badgeEnd;
}

/// The static Tripora logo: the mark with the wordmark beside it. Uses
/// [FittedBox] so the logo scales down on narrow screens and is never cropped.
class TriporaLogo extends StatelessWidget {
  final double height;
  final bool onDark;
  final bool showWordmark;

  const TriporaLogo({
    super.key,
    this.height = 40,
    this.onDark = false,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = onDark ? Colors.white : TriporaBrand.night;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: height,
              child: CustomPaint(
                painter: TriporaMarkPainter(
                  ringColor: Colors.white,
                  routeColor: onDark ? const Color(0xFFFFFFFF) : TriporaBrand.accent,
                ),
              ),
            ),
            if (showWordmark) ...[
              SizedBox(width: height * 0.25),
              Text(
                TriporaBrand.wordmark,
                style: TextStyle(
                  color: text,
                  fontSize: height * 0.6,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
