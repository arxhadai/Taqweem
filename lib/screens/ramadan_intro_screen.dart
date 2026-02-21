import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ramzan_companion/shared/presentation/main_screen.dart';
import 'package:ramzan_companion/painters/particle_painter.dart';
import 'package:hijri/hijri_calendar.dart';

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
          MaterialPageRoute(builder: (_) => const MainScreen()),
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

          // Top decorative space (arch removed in stabilization)

          // Center content with animations
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Crescent Moon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
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
                          Icons.brightness_2,
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
    final hijri = HijriCalendar.fromDate(now);
    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH | ${now.day}/${now.month}/${now.year} CE';
  }
}

