import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';

class LossReasonsCard extends StatelessWidget {
  final List<LossReason> reasons;

  const LossReasonsCard({super.key, required this.reasons});

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
            'Loss Reasons',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (reasons.isEmpty)
            SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  'No lost leads to analyse',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < reasons.length; i++) ...[
              if (i != 0) const SizedBox(height: 14),
              _LossRow(
                label: reasons[i].label,
                percent: reasons[i].percentage.round(),
                fraction: (reasons[i].percentage / 100).clamp(0.0, 1.0),
              ),
            ],
        ],
      ),
    );
  }
}

class _LossRow extends StatelessWidget {
  final String label;
  final int percent;
  final double fraction;

  const _LossRow({
    required this.label,
    required this.percent,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.progressBg,
            valueColor: AlwaysStoppedAnimation<Color>(
              fraction > 0.3 ? AppColors.lossRed : AppColors.lossPink,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
