import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

class LeadFunnelCard extends StatelessWidget {
  const LeadFunnelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lead Funnel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.tune, color: AppColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          _FunnelBar(label: 'New Leads', value: '1,284 (100%)', fraction: 1.0, color: AppColors.leadFunnelNew),
          const SizedBox(height: 8),
          _FunnelBar(label: 'Contacted', value: '963 (75%)', fraction: 0.75, color: AppColors.leadFunnelContacted),
          const SizedBox(height: 8),
          _FunnelBar(label: 'Qualified', value: '578 (45%)', fraction: 0.45, color: AppColors.leadFunnelQualified),
          const SizedBox(height: 8),
          _FunnelBar(label: 'Won', value: '256 (20%)', fraction: 0.20, color: AppColors.leadFunnelWon),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const _FunnelBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = constraints.maxWidth * fraction;
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Container(
              width: barWidth,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
