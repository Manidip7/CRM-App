import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';

class LeadToWonTrendCard extends StatelessWidget {
  final LeadToWonTrend trend;

  const LeadToWonTrendCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final points = trend.trendPoints;
    // A shorter conversion time is an improvement, so a negative change is the
    // good direction here — the arrow and colour follow that, not the sign.
    final improving = trend.changeVsLastMonthPercentage <= 0;
    final changeColor = improving ? AppColors.green : AppColors.red;

    // Headroom above the tallest point so the line never touches the top edge;
    // a flat all-zero series still needs a non-zero axis.
    final maxValue =
        points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead to Won Trend',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Average conversion time across stages',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_num(trend.avgConversionDays)} Days',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        improving ? Icons.trending_down : Icons.trending_up,
                        color: changeColor,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_signed(trend.changeVsLastMonthPercentage)} vs last month',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: changeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No trend data yet',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
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
                        // One label per point, straight from the API's `day`.
                        final idx = value.round();
                        if (idx < 0 || idx >= points.length || value != idx) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[idx].day.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 22,
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                      final i = s.x.round();
                      final day = i >= 0 && i < points.length
                          ? points[i].day
                          : '';
                      return LineTooltipItem(
                        '$day  ${_num(s.y)}',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].value),
                    ],
                    isCurved: true,
                    color: AppColors.trendLine,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      // Mark the peak — with mostly-flat data that's the only
                      // point worth drawing attention to.
                      checkToShowDot: (spot, _) =>
                          maxValue > 0 && spot.y == maxValue,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: AppColors.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.trendFill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact number: `50126.4` → `50.1k`, `0.1` → `0.1`, `3.0` → `3`.
  static String _num(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  static String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${_num(value)}%';
}
