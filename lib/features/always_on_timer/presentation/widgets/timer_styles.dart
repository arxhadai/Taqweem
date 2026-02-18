import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerStyleDisplay extends StatelessWidget {
  final Duration duration;
  final String label;
  final Color accentColor;
  final bool useBold;
  final bool useDigital;
  final bool useAnalog; // Placeholder for analog-inspired

  const TimerStyleDisplay({
    super.key,
    required this.duration,
    required this.label,
    this.accentColor = const Color(0xFFFFD700), // Gold
    this.useBold = false,
    this.useDigital = false,
    this.useAnalog = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useAnalog) return _buildAnalog(context);
    if (useDigital) return _buildDigital(context);

    return _buildClassic(context);
  }

  Widget _buildClassic(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _formatDuration(duration),
          style: GoogleFonts.outfit(
            color: accentColor,
            fontSize: useBold ? 72 : 60,
            fontWeight: useBold ? FontWeight.bold : FontWeight.w200,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildDigital(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(duration),
            style: GoogleFonts.orbitron(
              color: accentColor,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: Colors.white54,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalog(BuildContext context) {
    // A minimalist circular progress + digital center
    final progress = (duration.inSeconds % 3600) / 3600;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: accentColor.withValues(alpha: 0.5),
            backgroundColor: Colors.white10,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(duration),
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.robotoMono(color: accentColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}
