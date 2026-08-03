import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';

/// A single lead/opportunity source row feeding the distribution chart.
class SourceDatum {
  final String label;
  final int value;

  /// Colour the backend assigned to this source (e.g. Facebook blue). `null`
  /// falls back to the cycling palette below.
  final Color? color;

  const SourceDatum(this.label, this.value, {this.color});
}

class SourceDistributionCard extends StatelessWidget {
  /// Pass any number of sources. When omitted, sample data is used.
  final List<SourceDatum>? sources;

  /// How many individual slices to show before the rest collapse into "Others".
  final int maxSlices;

  const SourceDistributionCard({
    super.key,
    this.sources,
    this.maxSlices = 4,
  });

  /// Builds the card from the API's `source_distribution` block, keeping each
  /// source's brand colour.
  SourceDistributionCard.fromDistribution(
    SourceDistribution distribution, {
    super.key,
    this.maxSlices = 4,
  }) : sources = [
          for (final s in distribution.sources)
            SourceDatum(s.name, s.count, color: s.color),
        ];

  // Cycling palette — every slice always gets a color, no matter how many.
  static const List<Color> _palette = [
    AppColors.donutBlue,
    AppColors.donutTeal,
    AppColors.donutGreen,
    AppColors.primaryLight,
    AppColors.accent,
    AppColors.leadFunnelContacted,
    Color(0xFFFFB547),
    Color(0xFFFF7043),
  ];

  static const List<SourceDatum> _sample = [
    SourceDatum('FB Ads', 540),
    SourceDatum('Manual', 360),
    SourceDatum('Referral', 300),
  ];

  @override
  Widget build(BuildContext context) {
    final data = (sources ?? _sample)
        .where((s) => s.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'Source Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            _buildEmptyState()
          else
            _buildChart(_groupSlices(data)),
        ],
      ),
    );
  }

  /// Collapses everything beyond [maxSlices] into a single "Others" slice so
  /// the donut + legend stay readable with many sources.
  List<_Slice> _groupSlices(List<SourceDatum> data) {
    final total = data.fold<int>(0, (sum, s) => sum + s.value);

    if (data.length <= maxSlices) {
      return [
        for (var i = 0; i < data.length; i++)
          _Slice(
            label: data[i].label,
            value: data[i].value,
            percent: total == 0 ? 0 : data[i].value / total * 100,
            color: data[i].color ?? _palette[i % _palette.length],
          ),
      ];
    }

    final head = data.take(maxSlices - 1).toList();
    final tail = data.skip(maxSlices - 1).toList();
    final othersValue = tail.fold<int>(0, (sum, s) => sum + s.value);

    return [
      for (var i = 0; i < head.length; i++)
        _Slice(
          label: head[i].label,
          value: head[i].value,
          percent: total == 0 ? 0 : head[i].value / total * 100,
          color: head[i].color ?? _palette[i % _palette.length],
        ),
      _Slice(
        label: 'Others (${tail.length})',
        value: othersValue,
        percent: total == 0 ? 0 : othersValue / total * 100,
        color: AppColors.textLight,
      ),
    ];
  }

  Widget _buildChart(List<_Slice> slices) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut chart
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 38,
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(
                        value: s.value.toDouble(),
                        color: s.color,
                        radius: 22,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _formatCount(total),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Legend — Expanded so long labels never overflow horizontally.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < slices.length; i++) ...[
                if (i != 0) const SizedBox(height: 12),
                _LegendItem(slice: slices[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_large_rounded,
                size: 40, color: AppColors.textLight),
            const SizedBox(height: 8),
            Text(
              'No source data yet',
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

  static String _formatCount(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

class _Slice {
  final String label;
  final int value;
  final double percent;
  final Color color;
  const _Slice({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });
}

class _LegendItem extends StatelessWidget {
  final _Slice slice;

  const _LegendItem({required this.slice});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: slice.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Flexible + ellipsis keeps long source names from overflowing.
        Expanded(
          child: Text(
            slice.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${slice.percent.round()}%',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
