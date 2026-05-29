import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

class LossReasonsCard extends StatelessWidget {
  const LossReasonsCard({super.key});

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
          _LossRow(label: 'Pricing too high', percent: 42, fraction: 0.42),
          const SizedBox(height: 14),
          _LossRow(label: 'Competitor Chosen', percent: 28, fraction: 0.28),
          const SizedBox(height: 14),
          _LossRow(label: 'Missing Features', percent: 16, fraction: 0.16),
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
