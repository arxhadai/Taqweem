import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ramzan_companion/data/duas.dart';

class RamadanDuaOverlay extends StatefulWidget {
  final DuaContent dua;
  final String hijriDate;
  final String currentTime;
  final int currentRoza;
  final int totalRoza;
  final VoidCallback onDismiss;

  const RamadanDuaOverlay({
    super.key,
    required this.dua,
    required this.hijriDate,
    required this.currentTime,
    required this.currentRoza,
    required this.totalRoza,
    required this.onDismiss,
  });

  @override
  State<RamadanDuaOverlay> createState() => _RamadanDuaOverlayState();
}

class _RamadanDuaOverlayState extends State<RamadanDuaOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    // Setup fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Auto-dismiss after 5 minutes
    _autoDismissTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Image with overlay
            Positioned.fill(
              child: Image.asset(
                'assets/images/ramadan_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Top Section: Date and Time
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.hijriDate,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.currentTime,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Center Section: Dua Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dua Title
                            Text(
                              widget.dua.title,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Arabic Text
                            Text(
                              widget.dua.arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Divider
                            Container(
                              width: 60,
                              height: 2,
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            // English Translation
                            Text(
                              widget.dua.english,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Urdu Translation
                            Text(
                              widget.dua.urdu,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Reference
                            Text(
                              widget.dua.reference,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom Section: Roza Status
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Roza ${widget.currentRoza} of ${widget.totalRoza}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed: ${widget.currentRoza - 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Remaining: ${widget.totalRoza - (widget.currentRoza - 1)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Return Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Return to Ramadan Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
