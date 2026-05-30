import 'package:crm_app/features/Leads/view/leads_screen.dart';
import 'package:flutter/material.dart';

import '../../Opportunities/view/OpportunitiesScreen.dart';
import '../widgets/LeadsSummaryCard.dart';
import '../widgets/lead_funnel_card.dart';
import '../widgets/lead_to_won_trend_card.dart';
import '../widgets/loss_reasons_card.dart';
import '../widgets/response_rate_card.dart';
import '../widgets/revenue_forecast_card.dart';
import '../widgets/source_distribution_card.dart';
import '../widgets/stat_cards_row.dart';
import '../widgets/top_bar.dart';
import '../widgets/top_sales_performers_card.dart';
import '../../task/view/TaskScreen.dart';
import '../../../core/utils/AppColors.dart';
import '../../../core/constants/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  int _selectedTimeFilter = 0;

  Widget _buildOverviewBody() {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const LeadsSummaryCard(
                  todayCount: 1,
                  weekCount: 2,
                  monthCount: 5,
                  totalCount: 5,
                ),
                const SizedBox(height: 16),
                const StatCardsRow(),
                const SizedBox(height: 16),
                const LeadFunnelCard(),
                const SizedBox(height: 16),
                const SourceDistributionCard(),
                const SizedBox(height: 16),
                const ResponseRateCard(),
                const SizedBox(height: 16),
                const LeadToWonTrendCard(),
                const SizedBox(height: 16),
                const TopSalesPerformersCard(),
                const SizedBox(height: 16),
                const RevenueForecastCard(),
                const SizedBox(height: 16),
                const LossReasonsCard(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedNavIndex) {
      case 0:
        body = _buildOverviewBody();
        break;
      case 1:
        body = LeadsScreen();
        break;
      case 2:
        body = const TaskScreen();
        break;
      case 3:
        body = OpportunitiesScreen();
        break;
      default:
        body = _buildOverviewBody();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: (i) => setState(() => _selectedNavIndex = i),
      ),
    );
  }
}
