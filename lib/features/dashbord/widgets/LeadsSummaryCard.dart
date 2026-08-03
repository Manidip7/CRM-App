import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/dashboard_overview_model.dart';


class LeadsSummaryCard extends StatelessWidget {
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final int totalCount;

  const LeadsSummaryCard({
    super.key,
    this.todayCount = 0,
    this.weekCount = 0,
    this.monthCount = 0,
    this.totalCount = 0,
  });

  /// Builds the card straight from the API's `leads_counter` block.
  LeadsSummaryCard.fromCounter(LeadsCounter counter, {super.key})
      : todayCount = counter.today,
        weekCount = counter.week,
        monthCount = counter.month,
        totalCount = counter.total;

  @override
  Widget build(BuildContext context) {
    final maxVal = [todayCount, weekCount, monthCount, totalCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF5), width: 0.8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header label
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Color(0xFF8A8FAD)),
              const SizedBox(width: 5),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'LEADS ',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A8FAD),
                        letterSpacing: 0.6,
                      ),
                    ),
                    TextSpan(
                      text: '(T / W / M / TOTAL)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB0B4CC),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Values row
          IntrinsicHeight(
            child: Row(
              children: [
                _SegmentValue(label: 'TODAY', value: todayCount, isZero: todayCount == 0),
                _VerticalDivider(),
                _SegmentValue(label: 'WEEK', value: weekCount, isZero: weekCount == 0),
                _VerticalDivider(),
                _SegmentValue(label: 'MONTH', value: monthCount, isZero: monthCount == 0),
                _VerticalDivider(),
                _SegmentValue(label: 'TOTAL', value: totalCount, isZero: totalCount == 0),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar row
          Row(
            children: [
              _MiniProgressBar(
                fraction: todayCount / maxVal,
                hasValue: todayCount > 0,
              ),
              const SizedBox(width: 3),
              _MiniProgressBar(
                fraction: weekCount / maxVal,
                hasValue: weekCount > 0,
              ),
              const SizedBox(width: 3),
              _MiniProgressBar(
                fraction: monthCount / maxVal,
                hasValue: monthCount > 0,
                flex: 2,
              ),
              const SizedBox(width: 3),
              _MiniProgressBar(
                fraction: totalCount / maxVal,
                hasValue: totalCount > 0,
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentValue extends StatelessWidget {
  final String label;
  final int value;
  final bool isZero;

  const _SegmentValue({
    required this.label,
    required this.value,
    required this.isZero,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB0B4CC),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: isZero ? 20 : 22,
              fontWeight: FontWeight.w600,
              color: isZero ? const Color(0xFF8A8FAD) : const Color(0xFF534AB7),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFEEEFF5),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double fraction;
  final bool hasValue;
  final int flex;

  const _MiniProgressBar({
    required this.fraction,
    required this.hasValue,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFF534AB7) : const Color(0xFFEEEFF5),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}