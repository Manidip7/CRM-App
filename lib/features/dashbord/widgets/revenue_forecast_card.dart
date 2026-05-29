import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/utils/AppColors.dart';


class RevenueForecastCard extends StatelessWidget {
  const RevenueForecastCard({super.key});

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
            'Revenue Forecast (Next 3m)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)}k',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const labels = ['JUL', 'AUG', 'SEP'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  // JUL
                  BarChartGroupData(x: 0, barsSpace: 4, barRods: [
                    BarChartRodData(toY: 72, color: AppColors.barPipeline, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                    BarChartRodData(toY: 45, color: AppColors.barWeighted, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                  ]),
                  // AUG
                  BarChartGroupData(x: 1, barsSpace: 4, barRods: [
                    BarChartRodData(toY: 88, color: AppColors.barPipeline, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                    BarChartRodData(toY: 55, color: AppColors.barWeighted, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                  ]),
                  // SEP
                  BarChartGroupData(x: 2, barsSpace: 4, barRods: [
                    BarChartRodData(toY: 78, color: AppColors.barPipeline, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                    BarChartRodData(toY: 62, color: AppColors.barWeighted, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.barPipeline, label: 'Pipeline'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.barWeighted, label: 'Weighted'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
