import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/dashboard_overview_model.dart';

class TopSalesPerformersCard extends StatelessWidget {
  final List<SalesPerformer> performers;

  const TopSalesPerformersCard({super.key, required this.performers});

  @override
  Widget build(BuildContext context) {
    // Bars are relative to the leader, so everyone reads against the top
    // seller rather than an invented target. With no sales at all every bar
    // sits empty instead of dividing by zero.
    final top = performers.fold<double>(
        0, (m, p) => p.salesAmount > m ? p.salesAmount : m);

    final rows = [
      for (final p in performers)
        _Performer(
          name: p.name,
          amount: p.formattedSalesAmount.isNotEmpty
              ? p.formattedSalesAmount
              : _money(p.salesAmount),
          progress: top <= 0 ? 0 : (p.salesAmount / top).clamp(0.0, 1.0),
          avatarUrl: p.avatar,
          subtitle: _subtitle(p),
        ),
    ];

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
          if (rows.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'No sales recorded yet',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...List.generate(rows.length, (i) {
              return Column(
                children: [
                  _PerformerRow(performer: rows[i]),
                  if (i < rows.length - 1) const SizedBox(height: 14),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// Role plus won-deal count, e.g. "Owner · 3 deals". Either half may be
  /// missing, so the separator is only added when both are present.
  static String? _subtitle(SalesPerformer p) {
    final role = p.role?.trim();
    final parts = [
      if (role != null && role.isNotEmpty) role,
      if (p.wonDealsCount > 0)
        '${p.wonDealsCount} ${p.wonDealsCount == 1 ? 'deal' : 'deals'}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Fallback only — the API normally supplies `formatted_sales_amount`.
  static String _money(double value) => value.abs() >= 1000
      ? '${(value / 1000).toStringAsFixed(1)}k'
      : value.toStringAsFixed(0);
}

class _Performer {
  final String name;
  final String amount;
  final double progress;
  final String? avatarUrl;
  final String? subtitle;

  const _Performer({
    required this.name,
    required this.amount,
    required this.progress,
    required this.avatarUrl,
    this.subtitle,
  });
}

Widget _avatarFallback() => Container(
      color: AppColors.primaryLight.withOpacity(0.2),
      child: const Icon(Icons.person, color: AppColors.primary, size: 22),
    );

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
            child: (performer.avatarUrl?.isNotEmpty ?? false)
                ? Image.network(
                    performer.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      performer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              if (performer.subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  performer.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
