import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ramzan_companion/features/home/presentation/ramadan_home_screen.dart';
import 'package:ramzan_companion/painters/islamic_arch_painter.dart';
import 'package:ramzan_companion/painters/particle_painter.dart';

class RamadanIntroScreen extends StatefulWidget {
  const RamadanIntroScreen({super.key});

  @override
  State<RamadanIntroScreen> createState() => _RamadanIntroScreenState();
}

class _RamadanIntroScreenState extends State<RamadanIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for entire content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Scale animation for crescent (pulse effect)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Shimmer animation for app name
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Particle floating animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _fadeController.forward();

    // Auto-navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RamadanHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3D2E),
      body: Stack(
        children: [
          // Emerald gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F3D2E), // Deep emerald
                  Color(0xFF145A42), // Lighter emerald
                ],
              ),
            ),
          ),

          // Subtle mosque silhouette
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: MosqueSilhouettePainter(),
              ),
            ),
          ),

          // Floating particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleAnimation.value),
                );
              },
            ),
          ),

          // Top Islamic arch border
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: CustomPaint(
                painter: IslamicArchPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          // Center content with animations
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Crescent Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // Outer glow effect
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.wb_incandescent_rounded,
                          size: 80,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // App Name with Shimmer
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Text(
                          'TAQWEEM',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: Color(0xFFD4AF37).withValues(
                              alpha: 0.7 + (_shimmerAnimation.value * 0.3),
                            ),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Your Ramadan Spiritual Companion',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Hijri Date (Dynamic)
                    Text(
                      _getHijriDate(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHijriDate() {
    final now = DateTime.now();
    return 'Ramadan 1445 AH | ${now.day}/${now.month}/${now.year} CE';
  }
}

/// Custom painter for subtle mosque silhouette
class MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw mosque dome (simple circle)
    canvas.drawCircle(Offset(centerX, centerY - 80), 60, paint);

    // Draw minarets (simple towers)
    canvas.drawRect(
      Rect.fromLTWH(centerX - 150, centerY - 60, 30, 120),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX + 120, centerY - 60, 30, 120),
      paint,
    );

    // Draw minaret tops (circles)
    canvas.drawCircle(Offset(centerX - 135, centerY - 70), 15, paint);
    canvas.drawCircle(Offset(centerX + 135, centerY - 70), 15, paint);

    // Draw main building base
    canvas.drawRect(
      Rect.fromLTWH(centerX - 120, centerY, 240, 100),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
