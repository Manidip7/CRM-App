import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';


class StatCardsRow extends StatelessWidget {
  final OverviewStats stats;

  const StatCardsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TOTAL LEADS',
            value: _thousands(stats.totalLeads),
            change: _signed(stats.totalLeadsGrowthPercentage),
            // 0% is neither a rise nor a fall — treat it as neutral-positive so
            // it doesn't render in alarm red.
            isPositive: stats.totalLeadsGrowthPercentage >= 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'WIN RATE',
            value: '${_trim(stats.winRatePercentage)}%',
            change: _signed(stats.winRateChangePercentage),
            isPositive: stats.winRateChangePercentage >= 0,
          ),
        ),
      ],
    );
  }

  /// `1284` → `1,284`.
  static String _thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Drops a pointless `.0` so `25.0` reads as `25` but `24.8` survives.
  static String _trim(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  static String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${_trim(value)}%';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AppColors.green : AppColors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    change,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
