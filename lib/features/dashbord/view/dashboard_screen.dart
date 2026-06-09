import 'package:crm_app/features/Leads/view/leads_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/dashboard_provider.dart';
import '../../Opportunities/view/OpportunitiesScreen.dart';
import '../widgets/LeadsSummaryCard.dart';
import '../widgets/lead_funnel_card.dart';
import '../widgets/lead_to_won_trend_card.dart';
import '../widgets/loss_reasons_card.dart';
import '../widgets/response_rate_card.dart';
import '../widgets/revenue_forecast_card.dart';
import '../widgets/source_distribution_card.dart';
import '../widgets/stat_cards_row.dart';
import '../widgets/app_drawer.dart';
import '../widgets/top_bar.dart';
import '../widgets/top_sales_performers_card.dart';
import '../../task/view/TaskScreen.dart';
import '../../followups/view/follow_ups_screen.dart';
import '../../quotations/view/quotations_screen.dart';
import '../../customers/view/customers_screen.dart';
import '../../../core/utils/AppColors.dart';
import '../../../core/constants/bottom_nav_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNavIndex = ref.watch(dashboardNavProvider);
    Widget body;
    switch (selectedNavIndex) {
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
      case 4:
        body = const FollowUpsScreen();
        break;
      case 5:
        body = const QuotationsScreen();
        break;
      case 6:
        body = const CustomersScreen();
        break;
      default:
        body = _buildOverviewBody();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedNavIndex,
        onTap: (i) => ref.read(dashboardNavProvider.notifier).select(i),
      ),
    );
  }
}
