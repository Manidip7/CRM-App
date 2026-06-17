import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

class LeadFunnelCard extends StatelessWidget {
  const LeadFunnelCard({super.key});

  static const List<_Stage> _stages = [
    _Stage('New Leads', 20, AppColors.leadFunnelNew),
    _Stage('Contacted', 15, AppColors.leadFunnelContacted),
    _Stage('Qualified', 2, AppColors.accent),
    _Stage('Proposal Sent', 5, AppColors.leadFunnelQualified),
    _Stage('Negotiation', 0, AppColors.green),
    _Stage('Won', 5, AppColors.leadFunnelWon),
  ];

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final total = stages.fold<int>(0, (a, b) => a + b.count);
    final won = stages.last.count;
    final convRate = total == 0 ? 0 : ((won / total) * 100).round();

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_alt_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lead Funnel',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$total leads in pipeline',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppColors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$convRate%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Funnel(stages: stages),
        ],
      ),
    );
  }
}

class _Stage {
  final String label;
  final int count;
  final Color color;
  const _Stage(this.label, this.count, this.color);
}

class _Funnel extends StatelessWidget {
  final List<_Stage> stages;
  const _Funnel({required this.stages});

  static const double _segHeight = 35;
  static const double _gap = 5;
  // Funnel taper: top width -> bottom width (as fraction of available width).
  static const double _topFraction = 1.0;
  static const double _bottomFraction = 0.4;

  double _fractionAt(int boundary) {
    final t = boundary / stages.length;
    return _topFraction + (_bottomFraction - _topFraction) * t;
  }

  @override
  Widget build(BuildContext context) {
    final n = stages.length;
    final totalHeight = n * _segHeight + (n - 1) * _gap;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(w, totalHeight),
                  painter: _FunnelPainter(
                    stages: stages,
                    segHeight: _segHeight,
                    gap: _gap,
                    fractionAt: _fractionAt,
                    progress: t,
                  ),
                ),
                // Text overlay aligned to each band.
                Column(
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      Opacity(
                        opacity: (t * n - i).clamp(0.0, 1.0),
                        child: SizedBox(
                          height: _segHeight,
                          width: double.infinity,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${stages[i].label}  •  ${stages[i].count}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i != n - 1) const SizedBox(height: _gap),
                    ],
                  ],
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _FunnelPainter extends CustomPainter {
  final List<_Stage> stages;
  final double segHeight;
  final double gap;
  final double Function(int boundary) fractionAt;
  final double progress;

  _FunnelPainter({
    required this.stages,
    required this.segHeight,
    required this.gap,
    required this.fractionAt,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final n = stages.length;

    for (var i = 0; i < n; i++) {
      // Reveal segments progressively for a nice grow-in.
      final segReveal = (progress * n - i).clamp(0.0, 1.0);
      if (segReveal <= 0) continue;

      final topW = size.width * fractionAt(i) * segReveal;
      final botW = size.width * fractionAt(i + 1) * segReveal;
      final top = i * (segHeight + gap);
      final bottom = top + segHeight;

      final color = stages[i].color;
      final path = Path()
        ..moveTo(cx - topW / 2, top)
        ..lineTo(cx + topW / 2, top)
        ..lineTo(cx + botW / 2, bottom)
        ..lineTo(cx - botW / 2, bottom)
        ..close();

      // soft shadow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // gradient fill
      final rect = Rect.fromLTRB(cx - topW / 2, top, cx + topW / 2, bottom);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_FunnelPainter old) =>
      old.progress != progress || old.stages != stages;
}

class _DashCard extends StatelessWidget {
  final Widget child;
  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
