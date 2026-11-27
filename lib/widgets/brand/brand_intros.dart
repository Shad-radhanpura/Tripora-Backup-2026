import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tripora_brand.dart';

/// Lets the post-login welcome intro run once, right after a successful login
/// or signup. Only [request] sets the flag, and only [consume] clears it, so a
/// session restore, a failed login, or a rebuild cannot trigger the intro.
class PostAuthWelcome {
  PostAuthWelcome._();

  static bool _pending = false;

  /// Call only after authentication has succeeded.
  static void request() => _pending = true;

  /// Returns true at most once per [request].
  static bool consume() {
    final was = _pending;
    _pending = false;
    return was;
  }

  /// Forget any pending intro, for example on sign-out.
  static void clear() => _pending = false;

  @visibleForTesting
  static bool get pendingForTest => _pending;
}

/// Plays the launch logo animation over [child] while the app starts. The
/// child is built straight away, so Firebase and session restore are not held
/// up by the animation. The intro ends once, and the overlay is then removed.
class LaunchIntroGate extends StatefulWidget {
  final Widget child;

  const LaunchIntroGate({super.key, required this.child});

  @override
  State<LaunchIntroGate> createState() => _LaunchIntroGateState();
}

class _LaunchIntroGateState extends State<LaunchIntroGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;
  bool _reduced = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: TriporaBrand.launchIntro)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_started) return;
    _started = true;
    _reduced = reduced;
    _controller.duration = reduced ? TriporaBrand.reducedIntro : TriporaBrand.launchIntro;
    _controller.forward(from: 0);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_finished)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _IntroOverlay(
              progress: _controller.value,
              reduced: _reduced,
              onSkip: _finish,
            ),
          ),
      ],
    );
  }
}

/// The launch composition: a blue gradient, the globe spinning, the route
/// drawing itself, the pin dropping in, a light sweep, and the wordmark.
class _IntroOverlay extends StatelessWidget {
  final double progress;
  final bool reduced;
  final VoidCallback onSkip;

  const _IntroOverlay({required this.progress, required this.reduced, required this.onSkip});

  double _band(double from, double to) {
    if (progress <= from) return 0;
    if (progress >= to) return 1;
    return (progress - from) / (to - from);
  }

  @override
  Widget build(BuildContext context) {
    final route = Curves.easeInOut.transform(_band(0.05, 0.55));
    final pin = Curves.easeOutBack.transform(_band(0.5, 0.75));
    final wordmark = Curves.easeOut.transform(_band(0.7, 1.0));
    final sweep = _band(0.35, 0.7);
    final spin = reduced ? 0.0 : progress * math.pi * 0.9;
    final lift = (1 - Curves.easeOutCubic.transform(_band(0.0, 0.35))) * 24;
    final size = math.min(MediaQuery.sizeOf(context).shortestSide * 0.42, 180.0);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSkip,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TriporaBrand.primaryDark, TriporaBrand.primary, TriporaBrand.accent],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, lift),
                  child: Opacity(
                    opacity: Curves.easeOut.transform(_band(0.0, 0.25)),
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment(-1.2 + sweep * 2.4, -1),
                        end: Alignment(-0.6 + sweep * 2.4, 1),
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: sweep > 0 && sweep < 1 ? 0.55 : 0),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ).createShader(rect),
                      child: SizedBox.square(
                        dimension: size,
                        child: CustomPaint(
                          painter: TriporaMarkPainter(
                            progress: route,
                            spin: spin,
                            pinScale: pin,
                            glow: _band(0.1, 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size * 0.18),
                Opacity(
                  opacity: wordmark,
                  child: Transform.translate(
                    offset: Offset(0, (1 - wordmark) * 12),
                    child: Text(
                      TriporaBrand.wordmark,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size * 0.05),
                Opacity(
                  opacity: wordmark * 0.9,
                  child: Text(
                    TriporaBrand.tagline,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: size * 0.07),
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

/// Plays the welcome composition after a successful login or signup, if one was
/// requested. It is a different design from the launch intro: a deep night
/// background, a tilting 3D emblem, destination markers and a portal glow.
class PostAuthWelcomeGate extends StatefulWidget {
  final Widget child;

  const PostAuthWelcomeGate({super.key, required this.child});

  @override
  State<PostAuthWelcomeGate> createState() => _PostAuthWelcomeGateState();
}

class _PostAuthWelcomeGateState extends State<PostAuthWelcomeGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Consumed once, when this gate is created. Rebuilds cannot replay it.
  final bool _play = PostAuthWelcome.consume();
  bool _finished = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: TriporaBrand.welcomeIntro)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    if (!_play) _finished = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !_play) return;
    _started = true;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.duration = reduced ? TriporaBrand.reducedIntro : TriporaBrand.welcomeIntro;
    _controller.forward(from: 0);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_finished)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _WelcomeOverlay(progress: _controller.value, onSkip: _finish),
          ),
      ],
    );
  }
}

class _WelcomeOverlay extends StatelessWidget {
  final double progress;
  final VoidCallback onSkip;

  const _WelcomeOverlay({required this.progress, required this.onSkip});

  double _band(double from, double to) {
    if (progress <= from) return 0;
    if (progress >= to) return 1;
    return (progress - from) / (to - from);
  }

  @override
  Widget build(BuildContext context) {
    final tilt = (1 - Curves.easeOutBack.transform(_band(0.0, 0.5))) * 0.9;
    final portal = Curves.easeOut.transform(_band(0.0, 0.45));
    final fade = 1 - Curves.easeIn.transform(_band(0.85, 1.0));
    final text = Curves.easeOut.transform(_band(0.5, 0.8));
    final size = math.min(MediaQuery.sizeOf(context).shortestSide * 0.4, 170.0);

    return Opacity(
      opacity: fade,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSkip,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.1,
                colors: [Color(0xFF0B3C7A), TriporaBrand.night],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size * 2.1,
                    height: size * 2.1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Portal ring that opens outwards.
                        Container(
                          width: size * 2.1 * portal,
                          height: size * 2.1 * portal,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TriporaBrand.accent.withValues(alpha: 0.5 * portal),
                              width: 2,
                            ),
                          ),
                        ),
                        // Destination markers that appear one after another.
                        for (var i = 0; i < 5; i++)
                          _marker(i, size),
                        // The emblem, tilting towards the viewer in 3D.
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateX(tilt),
                          child: SizedBox.square(
                            dimension: size,
                            child: CustomPaint(
                              painter: TriporaMarkPainter(
                                progress: _band(0.2, 0.7),
                                spin: progress * math.pi * 0.5,
                                pinScale: Curves.easeOutBack.transform(_band(0.55, 0.8)),
                                glow: portal,
                                badgeStart: TriporaBrand.accent,
                                badgeEnd: TriporaBrand.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size * 0.1),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, (1 - text) * 14),
                      child: Column(
                        children: [
                          Text(
                            'Welcome to ${TriporaBrand.wordmark}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: size * 0.05),
                          Text(
                            'Your next journey starts here',
                            style: TextStyle(color: TriporaBrand.accent, fontSize: size * 0.08),
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
      ),
    );
  }

  Widget _marker(int index, double size) {
    final appear = Curves.easeOutBack.transform(_band(0.3 + index * 0.07, 0.55 + index * 0.07));
    final angle = index * 2 * math.pi / 5 - math.pi / 2;
    final radius = size * 1.02;
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Transform.scale(
        scale: appear,
        child: Container(
          width: size * 0.13,
          height: size * 0.13,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TriporaBrand.accent.withValues(alpha: 0.6),
                blurRadius: size * 0.1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
