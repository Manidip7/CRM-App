import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';

class ResponseRateCard extends StatelessWidget {
  final ResponseRate rate;

  const ResponseRateCard({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    // The gauge sweeps a half-circle, so the percentage maps to 0..1. Clamped
    // because the API can report over 100%.
    final gauge = (rate.averageSpeedPercentage / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response Rate',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Semi Donut Gauge
          Center(
            child: SizedBox(
              width: 180,
              height: 110,
              child: CustomPaint(
                painter: _SemiDonutPainter(value: gauge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_pct(rate.averageSpeedPercentage)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'AVERAGE\nSPEED',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RateMetric(
                  label: 'UNDER 1H',
                  value: '${_pct(rate.under1hPercentage)}%'),
              Container(width: 1, height: 36, color: AppColors.divider),
              _RateMetric(
                  label: 'TARGET', value: '${_pct(rate.targetPercentage)}%'),
            ],
          ),
        ],
      ),
    );
  }

  /// Drops a pointless `.0` so `90.0` reads as `90` but `87.5` survives.
  static String _pct(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}

class _RateMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RateMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SemiDonutPainter extends CustomPainter {
  final double value;
  const _SemiDonutPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 10;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = AppColors.progressBg
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9D97E8), AppColors.primary],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background arc (half circle)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi,
      math.pi * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_SemiDonutPainter old) => old.value != value;
}
