import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/permissions/permissions.dart';
import '../../../core/utils/AppColors.dart';
import '../../Leads/model/lead_model.dart';
import '../../Leads/provider/leads_provider.dart';
import '../model/dashboard_overview_model.dart';
import '../model/dashboard_section.dart';
import '../provider/dashboard_provider.dart';

/// The Overview's funnel. Each band is a lead status and is tappable: it filters
/// the Leads list to that status and switches the dashboard to it, so the count
/// the user just read is the list they land on.
class LeadFunnelCard extends ConsumerWidget {
  final LeadFunnel funnel;

  const LeadFunnelCard({super.key, required this.funnel});

  /// Used only when the API omits a stage colour.
  static const List<Color> _fallbackPalette = [
    AppColors.leadFunnelNew,
    AppColors.leadFunnelContacted,
    AppColors.accent,
    AppColors.leadFunnelQualified,
    AppColors.green,
    AppColors.leadFunnelWon,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = [
      for (var i = 0; i < funnel.stages.length; i++)
        _Stage(
          funnel.stages[i].label,
          funnel.stages[i].count,
          funnel.stages[i].color ??
              _fallbackPalette[i % _fallbackPalette.length],
        ),
    ];

    // No point offering the jump to a role that can't open the Leads list.
    final canOpenLeads =
        ref.watch(permissionsProvider).can(AppPermissions.leadsView);

    if (stages.isEmpty) {
      return const _DashCard(
        child: _EmptyState(
          icon: Icons.filter_alt_outlined,
          message: 'No funnel data yet',
        ),
      );
    }

    // The API reports both numbers, so use them rather than re-deriving from
    // the stage counts (which double-count leads sitting in several stages).
    final total = funnel.totalInPipeline;
    final convRate = funnel.conversionRatePercentage;

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
          _Funnel(
            stages: stages,
            onStageTap: canOpenLeads ? (s) => _openStage(ref, s) : null,
          ),
          if (canOpenLeads) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap a stage to see those leads',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Filters the Leads list to the tapped stage and switches to it.
  ///
  /// The funnel only reports a label, so the matching `status_id` is resolved
  /// against `GET /statuses`; a stage whose name the CRM doesn't know still
  /// opens the list, just unfiltered, rather than doing nothing on tap.
  void _openStage(WidgetRef ref, _Stage stage) {
    final statusId = _statusIdFor(ref, stage.label);
    final filter = ref.read(leadsFilterProvider.notifier);
    if (statusId != null) {
      filter.showOnlyStatus(statusId);
    } else {
      filter.clearFilters();
      filter.clearAdvanced();
    }
    ref.read(dashboardNavProvider.notifier).select(DashboardSection.leadsIndex);
  }

  static int? _statusIdFor(WidgetRef ref, String label) {
    final wanted = label.trim().toLowerCase();
    if (wanted.isEmpty) return null;

    for (final status in ref.read(leadStatusesProvider).value ?? const []) {
      if (status.name.trim().toLowerCase() == wanted) return status.id;
    }

    // The statuses may not have loaded (they're fetched lazily), so fall back
    // to the ids the app already maps its own stages to.
    return switch (wanted) {
      'new' || 'new leads' || 'new lead' => LeadStatus.newLead.statusId,
      'contacted' || 'in progress' => LeadStatus.contacted.statusId,
      'qualified' || 'interested' => LeadStatus.qualified.statusId,
      'won' || 'converted' => LeadStatus.won.statusId,
      'lost' => LeadStatus.lost.statusId,
      _ => null,
    };
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

  /// Null when the role can't open the Leads list, which also removes the tap
  /// targets rather than leaving dead ones behind.
  final void Function(_Stage stage)? onStageTap;

  const _Funnel({required this.stages, this.onStageTap});

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
                            // The tap target is the band's own (tapered) width,
                            // not the full row — tapping the empty margin
                            // beside a narrow band shouldn't select it.
                            child: SizedBox(
                              width: w * (_fractionAt(i) + _fractionAt(i + 1)) / 2,
                              height: _segHeight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onStageTap == null
                                    ? null
                                    : () => onStageTap!(stages[i]),
                                child: Center(
                                  child: Text(
                                    '${stages[i].label}  •  ${stages[i].count}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
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

/// Shared "nothing to show" panel for the dashboard cards.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.textLight),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
