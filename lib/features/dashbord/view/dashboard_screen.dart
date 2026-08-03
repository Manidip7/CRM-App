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
import '../../invoices/view/invoices_screen.dart';
import '../../projects/view/projects_screen.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../core/constants/bottom_nav_bar.dart';
import '../../../core/permissions/permissions.dart';
import '../model/dashboard_overview_model.dart';
import '../model/dashboard_section.dart';
import '../provider/dashboard_overview_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// The Overview tab. Every card is fed by the single
  /// `GET /dashboard/overview` request, so the whole tab shares one loading /
  /// error state and one pull-to-refresh.
  Widget _buildOverviewBody(WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(dashboardOverviewProvider.future),
            child: switch (overviewAsync) {
              // Only block the screen on the very first load; a refresh keeps
              // the previous numbers on screen behind the spinner.
              AsyncValue(:final value?) => _buildOverviewContent(value),
              AsyncError(:final error) => _buildErrorState(ref, error),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewContent(DashboardOverview data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          LeadsSummaryCard.fromCounter(data.leadsCounter),
          const SizedBox(height: 16),
          StatCardsRow(stats: data.overview),
          const SizedBox(height: 16),
          LeadFunnelCard(funnel: data.leadFunnel),
          const SizedBox(height: 16),
          SourceDistributionCard.fromDistribution(data.sourceDistribution),
          const SizedBox(height: 16),
          ResponseRateCard(rate: data.responseRate),
          const SizedBox(height: 16),
          LeadToWonTrendCard(trend: data.leadToWonTrend),
          const SizedBox(height: 16),
          TopSalesPerformersCard(performers: data.topSalesPerformers),
          const SizedBox(height: 16),
          RevenueForecastCard(forecast: data.revenueForecast),
          const SizedBox(height: 16),
          LossReasonsCard(reasons: data.lossReasons),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  /// Scrollable so pull-to-refresh still works when the first load failed.
  Widget _buildErrorState(WidgetRef ref, Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load the dashboard.';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.red, size: 40),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(dashboardOverviewProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label:
                      Text('Retry', style: GoogleFonts.poppins(fontSize: 14)),
                ),
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
    final perms = ref.watch(permissionsProvider);

    // Second line of defence. The drawer and bottom bar already hide sections
    // this role can't view, but the selected index can also survive a
    // permission change (or arrive from a future deep link), so re-check it
    // here rather than trusting the entry point.
    final section = DashboardSection.byIndex(selectedNavIndex);
    if (section == null || !section.isVisibleTo(perms)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(),
        body: SafeArea(child: NoAccessView(label: section?.label)),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedNavIndex,
          onTap: (i) => ref.read(dashboardNavProvider.notifier).select(i),
        ),
      );
    }

    Widget body;
    switch (selectedNavIndex) {
      case 0:
        body = _buildOverviewBody(ref);
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
      case 7:
        body = const InvoicesScreen();
        break;
      case 8:
        body = const ProjectsScreen();
        break;
      default:
        body = _buildOverviewBody(ref);
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
