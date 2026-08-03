import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';


class RevenueForecastCard extends StatelessWidget {
  final RevenueForecast forecast;

  const RevenueForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final months = forecast.forecastByMonth;

    // Amounts arrive in full units (e.g. 17623.34) but read best as "17.6k",
    // so the chart is drawn in thousands and the axis follows.
    final maxAmount = months.fold<double>(0, (m, f) {
      final biggest = f.pipeline > f.weighted ? f.pipeline : f.weighted;
      return biggest > m ? biggest : m;
    });
    final maxY = maxAmount <= 0 ? 1.0 : (maxAmount / 1000) * 1.2;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Revenue Forecast (Next ${months.length}m)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(forecast.weightedForecast),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'weighted of ${_money(forecast.totalPipeline)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (months.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No forecast data yet',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      // rodIndex 0 is pipeline, 1 is weighted.
                      final series = rodIndex == 0 ? 'Pipeline' : 'Weighted';
                      return BarTooltipItem(
                        '$series  ${rod.toY.toStringAsFixed(1)}k',
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
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[idx].month.toUpperCase(),
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
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(x: i, barsSpace: 4, barRods: [
                      BarChartRodData(
                        toY: months[i].pipeline / 1000,
                        color: AppColors.barPipeline,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: months[i].weighted / 1000,
                        color: AppColors.barWeighted,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
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
        ],
      ),
    );
  }

  /// `25176.2` → `25.2k`.
  static String _money(double value) => value.abs() >= 1000
      ? '${(value / 1000).toStringAsFixed(1)}k'
      : value.toStringAsFixed(0);
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
