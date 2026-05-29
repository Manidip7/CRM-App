import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

class TopSalesPerformersCard extends StatelessWidget {
  const TopSalesPerformersCard({super.key});

  final List<_Performer> _performers = const [
    _Performer(
      name: 'Sarah Jenkins',
      amount: '\$128.5k',
      progress: 1.0,
      avatarUrl: 'https://i.pravatar.cc/80?img=47',
    ),
    _Performer(
      name: 'Marcus Chen',
      amount: '\$102.2k',
      progress: 0.80,
      avatarUrl: 'https://i.pravatar.cc/80?img=51',
    ),
    _Performer(
      name: 'Elena Rodriguez',
      amount: '\$89.4k',
      progress: 0.70,
      avatarUrl: 'https://i.pravatar.cc/80?img=45',
    ),
  ];

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
            'Top Sales Performers',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_performers.length, (i) {
            return Column(
              children: [
                _PerformerRow(performer: _performers[i]),
                if (i < _performers.length - 1) const SizedBox(height: 14),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Performer {
  final String name;
  final String amount;
  final double progress;
  final String avatarUrl;

  const _Performer({
    required this.name,
    required this.amount,
    required this.progress,
    required this.avatarUrl,
  });
}

class _PerformerRow extends StatelessWidget {
  final _Performer performer;

  const _PerformerRow({required this.performer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.progressBg,
          ),
          child: ClipOval(
            child: Image.network(
              performer.avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryLight.withOpacity(0.2),
                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    performer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    performer.amount,
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
                  value: performer.progress,
                  backgroundColor: AppColors.progressBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
