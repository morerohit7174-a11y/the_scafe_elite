// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bills_provider.dart';
import '../providers/login_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterCtrl; // master timeline
  late AnimationController _bubblesCtrl; // floating bubbles
  late AnimationController _glowCtrl; // logo glow pulse
  late AnimationController _shimmerCtrl; // text shimmer
  late AnimationController _waveCtrl; // ripple waves
  late AnimationController _rotateCtrl; // outer ring rotate
  late AnimationController _floatCtrl; // logo float
  late AnimationController _steamCtrl; // steam wisps

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowPulse;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _loaderOpacity;
  late Animation<double> _shimmer;
  late Animation<double> _float;
  late Animation<double> _rotate;
  late Animation<double> _wave;
  late Animation<double> _steam;

  String _loadingText = 'Brewing your experience...';
  double _progress = 0.0;

  final math.Random _rng = math.Random(42);
  late final List<_BubbleData> _bubbles;
  late final List<_SteamData> _steams;
  late final List<_StarData> _stars;

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(22, (_) => _BubbleData(_rng));
    _steams = List.generate(6, (i) => _SteamData(i, _rng));
    _stars = List.generate(30, (_) => _StarData(_rng));
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Master fade
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bgFade = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeIn);

    // Bubbles — slow continuous rise
    _bubblesCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    // Logo bounce in
    final logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: logoCtrl, curve: const Interval(0, 0.3, curve: Curves.easeIn)));
    logoCtrl.forward();

    // Glow pulse
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Text
    final textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _titleOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: textCtrl, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: textCtrl, curve: Curves.easeOutBack));
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: textCtrl,
        curve: const Interval(0.4, 1, curve: Curves.easeOut)));
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
            CurvedAnimation(
                parent: textCtrl,
                curve: const Interval(0.4, 1, curve: Curves.easeOutBack)));

    // Loader
    final loaderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loaderOpacity = CurvedAnimation(parent: loaderCtrl, curve: Curves.easeIn);

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shimmer = Tween<double>(begin: -2, end: 3).animate(_shimmerCtrl);

    // Logo float up-down
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Outer ring slow rotate
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
    _rotate = Tween<double>(begin: 0, end: math.pi * 2).animate(_rotateCtrl);

    // Ripple waves
    _waveCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _wave = Tween<double>(begin: 0, end: math.pi * 2).animate(_waveCtrl);

    // Steam
    _steamCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _steam = Tween<double>(begin: 0, end: 1).animate(_steamCtrl);

    // Start delayed animations
    Future.delayed(const Duration(milliseconds: 600), textCtrl.forward);
    Future.delayed(const Duration(milliseconds: 1100), loaderCtrl.forward);
  }

  Future<void> _startSequence() async {
    _masterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    _set('Brewing your experience...', 0.15);
    await Future.delayed(const Duration(milliseconds: 600));
    
    // ✅ Restore user session from Firebase
    _set('Checking your session...', 0.25);
    if (mounted) {
      final loginProv = context.read<LoginProvider>();
      await loginProv.restoreSession();
    }
    
    _set('Loading menu...', 0.38);
    await Future.delayed(const Duration(milliseconds: 600));

    _set('Loading sales data...', 0.72);
    if (mounted) {
      try {
        // ✅ Load bills with retry logic
        await context.read<BillsProvider>().loadBills();
        debugPrint("✅ Bills loaded successfully");
      } catch (e) {
        debugPrint("❌ Failed to load bills: $e");
        // Continue anyway, user can still use app
      }
    }

    _set('Almost ready! ☕', 1.0);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) =>
                FadeTransition(opacity: a, child: const _NavWrapper()),
            transitionDuration: const Duration(milliseconds: 800),
          ));
    }
  }

  void _set(String t, double v) {
    if (mounted)
      setState(() {
        _loadingText = t;
        _progress = v;
      });
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _bubblesCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _waveCtrl.dispose();
    _steamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080503),
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(children: [
          // ── 1. Deep gradient background ───────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.5,
                colors: [
                  Color(0xFF2E1804),
                  Color(0xFF180C03),
                  Color(0xFF080503),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),

          // ── 2. Starfield ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              size: sz,
              painter: _StarfieldPainter(_stars, _glowPulse.value),
            ),
          ),

          // ── 3. Rising bubbles ─────────────────────────────────────
          AnimatedBuilder(
            animation: _bubblesCtrl,
            builder: (_, __) => CustomPaint(
              size: sz,
              painter: _BubblePainter(_bubbles, _bubblesCtrl.value, sz),
            ),
          ),

          // ── 4. Ripple wave rings ──────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _wave,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: List.generate(4, (i) {
                  final phase = (i / 4);
                  final t = (_waveCtrl.value + phase) % 1.0;
                  final scale = 0.4 + t * 1.4;
                  final opacity = (1 - t) * 0.12;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4A017)
                              .withValues(alpha: opacity),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── 5. Rotating decorative outer ring ─────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _rotate.value,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _DashedRingPainter(
                    color: const Color(0xFFD4A017).withValues(alpha: 0.25),
                    radius: 100,
                    dashCount: 36,
                    strokeWidth: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // ── 6. Steam wisps above logo area ────────────────────────
          Positioned(
            top: sz.height * 0.18,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _steamCtrl,
              builder: (_, __) => SizedBox(
                height: 80,
                child: Stack(
                  children: _steams.map((s) {
                    final t = (_steam.value + s.delay) % 1.0;
                    final x = sz.width / 2 + s.offsetX;
                    final y = 80 - t * 90;
                    final opacity = t < 0.3
                        ? t / 0.3 * 0.35
                        : t > 0.7
                            ? (1 - t) / 0.3 * 0.35
                            : 0.35;
                    final wobble = math.sin(t * math.pi * 3 + s.phase) * 12;
                    return Positioned(
                      left: x + wobble - s.size / 2,
                      top: y,
                      child: Container(
                        width: s.size,
                        height: s.size * 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(s.size),
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFB8860B)
                                  .withValues(alpha: opacity),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── 7. Background large glow ──────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 280 + _glowPulse.value * 60,
                height: 280 + _glowPulse.value * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFB8860B)
                        .withValues(alpha: _glowPulse.value * 0.1),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // ── 8. Main content ───────────────────────────────────────
          Column(children: [
            const Spacer(flex: 3),

            // Logo
            AnimatedBuilder(
              animation: Listenable.merge([_floatCtrl, _glowCtrl]),
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _float.value),
                child: Opacity(
                  opacity: _logoOpacity.value.clamp(0, 1),
                  child: Transform.scale(
                    scale: _logoScale.value.clamp(0, 1),
                    child: Stack(alignment: Alignment.center, children: [
                      // Outer glow halo
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, __) => Container(
                          width: 170 + _glowPulse.value * 40,
                          height: 170 + _glowPulse.value * 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              const Color(0xFFD4A017)
                                  .withValues(alpha: _glowPulse.value * 0.2),
                              const Color(0xFFB8860B)
                                  .withValues(alpha: _glowPulse.value * 0.08),
                              Colors.transparent,
                            ], stops: const [
                              0,
                              0.5,
                              1
                            ]),
                          ),
                        ),
                      ),

                      // Slow rotating dashed ring
                      AnimatedBuilder(
                        animation: _rotateCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: _rotate.value * 0.25,
                          child: CustomPaint(
                            size: const Size(158, 158),
                            painter: _DashedRingPainter(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.5),
                              radius: 79,
                              dashCount: 28,
                              strokeWidth: 1.8,
                            ),
                          ),
                        ),
                      ),

                      // Counter-rotating inner ring
                      AnimatedBuilder(
                        animation: _rotateCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: -_rotate.value * 0.4,
                          child: CustomPaint(
                            size: const Size(144, 144),
                            painter: _DashedRingPainter(
                              color: const Color(0xFFB8860B)
                                  .withValues(alpha: 0.3),
                              radius: 72,
                              dashCount: 16,
                              strokeWidth: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Gold sweep gradient ring
                      Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFFFFE066).withValues(alpha: 0.95),
                              const Color(0xFFD4A017).withValues(alpha: 0.5),
                              const Color(0xFF6B4A0A).withValues(alpha: 0.2),
                              const Color(0xFFD4A017).withValues(alpha: 0.5),
                              const Color(0xFFFFE066).withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),

                      // Inner dark border
                      Container(
                        width: 127,
                        height: 127,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF100803),
                        ),
                      ),

                      // Cafe logo image
                      Container(
                        width: 121,
                        height: 121,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFF5F0E6)),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/image.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2A1507),
                                child: const Icon(Icons.coffee,
                                    color: Color(0xFFB8860B), size: 60)),
                          ),
                        ),
                      ),

                      // Shimmer sweep on logo
                      AnimatedBuilder(
                        animation: _shimmer,
                        builder: (_, __) => ClipOval(
                          child: Container(
                            width: 121,
                            height: 121,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(_shimmer.value - 0.8, -1),
                                end: Alignment(_shimmer.value + 0.3, 1),
                                colors: const [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color(0x28FFFFFF),
                                  Color(0x10FFFFFF),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.3, 0.5, 0.65, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 42),

            // Title + subtitle
            AnimatedBuilder(
              animation: Listenable.merge([_titleOpacity, _shimmerCtrl]),
              builder: (_, __) => Column(children: [
                // Gold shimmer title
                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (_, __) => ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          begin: Alignment(_shimmer.value - 1.5, 0),
                          end: Alignment(_shimmer.value + 0.5, 0),
                          colors: const [
                            Color(0xFFD9C9A8),
                            Color(0xFFFFEBAA),
                            Color(0xFFFFD700),
                            Color(0xFFFFEBAA),
                            Color(0xFFD9C9A8),
                          ],
                          stops: const [0, 0.3, 0.5, 0.7, 1],
                        ).createShader(b),
                        child: const Text('The Cafe Elite',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                    color: Color(0xFFB8860B),
                                    blurRadius: 24,
                                    offset: Offset(0, 3)),
                                Shadow(
                                    color: Color(0xFF000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 1)),
                              ],
                            )),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Decorative row
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _gem(),
                          _thinLine(),
                          _thinLine(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AnimatedBuilder(
                              animation: _glowCtrl,
                              builder: (_, __) => Icon(Icons.auto_awesome,
                                  color: Color.lerp(
                                      const Color(0xFFB8860B),
                                      const Color(0xFFFFD700),
                                      _glowPulse.value)!,
                                  size: 16),
                            ),
                          ),
                          _thinLine(),
                          _thinLine(),
                          _gem(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('TRUST THE TASTE',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB8860B),
                              letterSpacing: 5.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      const Text('FINE CAFÉ & BISTRO',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B5030),
                              letterSpacing: 4,
                              fontWeight: FontWeight.w400)),
                    ]),
                  ),
                ),
              ]),
            ),

            const Spacer(flex: 3),

            // Loading section
            FadeTransition(
              opacity: _loaderOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.6), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(_loadingText,
                        key: ValueKey(_loadingText),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A6A40),
                            letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 14),

                  // Progress bar with glowing dot
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Track
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color:
                                const Color(0xFFB8860B).withValues(alpha: 0.1),
                          ),
                        ),
                        // Glow fill
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF5C2E00),
                                Color(0xFFB8860B),
                                Color(0xFFFFD700),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.7),
                                    blurRadius: 12,
                                    spreadRadius: 1)
                              ],
                            ),
                          ),
                        ),
                        // Glowing dot
                        if (v > 0.01)
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) => Positioned(
                              left:
                                  v * (MediaQuery.of(context).size.width - 88) -
                                      6,
                              top: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFFFD700)
                                            .withValues(
                                                alpha: 0.5 +
                                                    _glowPulse.value * 0.5),
                                        blurRadius: 14,
                                        spreadRadius: 3)
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 800),
                      builder: (_, v, __) => Text('${(v * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B5030),
                              letterSpacing: 1)),
                    ),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 28),

            FadeTransition(
              opacity: _loaderOpacity,
              child: const Text('v 1.0.0',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF3A2010),
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 32),
          ]),
        ]),
      ),
    );
  }

  // Helpers
  Widget _gem() => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFFD4A017),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                blurRadius: 6)
          ],
        ),
      );

  Widget _thinLine() => Container(
        width: 36,
        height: 1,
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.transparent, Color(0xFFB8860B)]),
        ),
      );
}

// ── Data models ───────────────────────────────────────────────────────────────
class _BubbleData {
  final double x, startY, size, speed, opacity, delay, wobbleFreq;
  _BubbleData(math.Random r)
      : x = r.nextDouble(),
        startY = r.nextDouble() * 0.5 + 0.8,
        size = r.nextDouble() * 44 + 6,
        speed = r.nextDouble() * 0.3 + 0.1,
        opacity = r.nextDouble() * 0.14 + 0.03,
        delay = r.nextDouble(),
        wobbleFreq = r.nextDouble() * 4 + 2;
}

class _SteamData {
  final double offsetX, size, delay, phase;
  _SteamData(int i, math.Random r)
      : offsetX = (i - 2.5) * 14.0 + r.nextDouble() * 10 - 5,
        size = r.nextDouble() * 10 + 6,
        delay = r.nextDouble(),
        phase = r.nextDouble() * math.pi * 2;
}

class _StarData {
  final double x, y, size, opacity;
  _StarData(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = r.nextDouble() * 2 + 0.5,
        opacity = r.nextDouble() * 0.4 + 0.05;
}

// ── Custom Painters ───────────────────────────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final List<_BubbleData> bubbles;
  final double t;
  final Size screen;
  _BubblePainter(this.bubbles, this.t, this.screen);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final progress = (t + b.delay) % 1.0;
      final y = (b.startY - progress * b.speed * 2.2) * size.height;
      if (y < -b.size || y > size.height + b.size) continue;
      final wobble = math.sin(progress * math.pi * b.wobbleFreq) * 18;
      final cx = b.x * size.width + wobble;
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFD4A017).withValues(alpha: b.opacity * 0.9),
          const Color(0xFFB8860B).withValues(alpha: b.opacity * 0.4),
          Colors.transparent,
        ], stops: const [
          0,
          0.55,
          1
        ]).createShader(Rect.fromCircle(center: Offset(cx, y), radius: b.size));

      canvas.drawCircle(Offset(cx, y), b.size / 2, paint);

      // Bubble outline
      canvas.drawCircle(
          Offset(cx, y),
          b.size / 2,
          Paint()
            ..color = const Color(0xFFD4A017).withValues(alpha: b.opacity * 1.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);

      // Highlight
      canvas.drawCircle(
        Offset(cx - b.size * 0.18, y - b.size * 0.18),
        b.size * 0.12,
        Paint()..color = Colors.white.withValues(alpha: b.opacity * 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}

class _StarfieldPainter extends CustomPainter {
  final List<_StarData> stars;
  final double pulse;
  _StarfieldPainter(this.stars, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = s.opacity * (0.7 + pulse * 0.3);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = const Color(0xFFD4A017).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.pulse != pulse;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double radius, strokeWidth;
  final int dashCount;
  _DashedRingPainter(
      {required this.color,
      required this.radius,
      required this.dashCount,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final dashAngle = math.pi * 2 / dashCount;
    final gapRatio = 0.38;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * dashAngle, dashAngle * (1 - gapRatio), false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

// ── Nav wrapper ───────────────────────────────────────────────────────────────
class _NavWrapper extends StatelessWidget {
  const _NavWrapper();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
    return const Scaffold(backgroundColor: Color(0xFF080503));
  }
}
