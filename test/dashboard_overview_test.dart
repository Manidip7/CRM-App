import 'dart:convert';

import 'package:crm_app/features/dashbord/model/dashboard_overview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The exact `GET /api/v1/dashboard/overview` response from the API, verbatim.
const _rawResponse = '''
{
    "status": "success",
    "message": "Dashboard Overview retrieved successfully",
    "data": {
        "leads_counter": { "today": 0, "week": 0, "month": 4, "total": 20 },
        "overview": {
            "total_leads": 20,
            "total_leads_growth_percentage": -75,
            "win_rate_percentage": 25,
            "win_rate_change_percentage": -25
        },
        "lead_funnel": {
            "total_in_pipeline": 16,
            "stages": [
                { "label": "New Leads", "count": 20, "percentage": 100, "color": "#7370f6" },
                { "label": "Contacted", "count": 20, "percentage": 100, "color": "#9759fa" },
                { "label": "Qualified", "count": 4, "percentage": 20, "color": "#3b82f6" },
                { "label": "Proposal Sent", "count": 2, "percentage": 10, "color": "#f59e0b" },
                { "label": "Negotiation", "count": 2, "percentage": 10, "color": "#10b981" },
                { "label": "Won", "count": 1, "percentage": 5, "color": "#059669" }
            ]
        },
        "source_distribution": {
            "total_leads": 20,
            "sources": [
                { "name": "Facebook", "count": 12, "percentage": 60, "color": "#1877F2" },
                { "name": "Manual", "count": 6, "percentage": 30, "color": "#64748b" },
                { "name": "Website", "count": 0, "percentage": 0, "color": "#6366f1" },
                { "name": "WhatsApp", "count": 0, "percentage": 0, "color": "#25D366" }
            ]
        },
        "response_rate": {
            "average_speed_percentage": 100,
            "under_1h_percentage": 90,
            "target_percentage": 90
        },
        "lead_to_won_trend": {
            "avg_conversion_days": 0.1,
            "change_vs_last_month_percentage": -12,
            "trend_points": [
                { "day": "Tue", "value": 0 },
                { "day": "Wed", "value": 0 },
                { "day": "Thu", "value": 50126.4 },
                { "day": "Fri", "value": 0 },
                { "day": "Sat", "value": 0 },
                { "day": "Sun", "value": 0 },
                { "day": "Mon", "value": 0 }
            ]
        },
        "top_sales_performers": [
            {
                "user_id": 2,
                "name": "Admin",
                "avatar": "https://ui-avatars.com/api/?name=Admin",
                "role": "Owner",
                "sales_amount": 0,
                "formatted_sales_amount": "\$0.0k",
                "won_deals_count": 0
            },
            {
                "user_id": 3,
                "name": "TestApp",
                "avatar": "https://ui-avatars.com/api/?name=TestApp",
                "role": "emp",
                "sales_amount": 0,
                "formatted_sales_amount": "\$0.0k",
                "won_deals_count": 0
            }
        ],
        "revenue_forecast": {
            "total_pipeline": 25176.2,
            "weighted_forecast": 22613.38,
            "forecast_by_month": [
                { "month": "Aug", "pipeline": 17623.34, "weighted": 15829.37 },
                { "month": "Sep", "pipeline": 25176.2, "weighted": 20352.04 },
                { "month": "Oct", "pipeline": 21399.77, "weighted": 21482.71 }
            ]
        },
        "loss_reasons": []
    }
}
''';

DashboardOverview _parse([String raw = _rawResponse]) {
  final envelope = (jsonDecode(raw) as Map).cast<String, dynamic>();
  return DashboardOverview.fromJson(
    (envelope['data'] as Map).cast<String, dynamic>(),
  );
}

void main() {
  group('DashboardOverview.fromJson — real response', () {
    late DashboardOverview data;

    setUp(() => data = _parse());

    test('leads_counter', () {
      expect(data.leadsCounter.today, 0);
      expect(data.leadsCounter.week, 0);
      expect(data.leadsCounter.month, 4);
      expect(data.leadsCounter.total, 20);
    });

    test('overview keeps negative growth signed', () {
      expect(data.overview.totalLeads, 20);
      expect(data.overview.totalLeadsGrowthPercentage, -75);
      expect(data.overview.winRatePercentage, 25);
      expect(data.overview.winRateChangePercentage, -25);
    });

    test('lead_funnel stages, colours and derived conversion rate', () {
      expect(data.leadFunnel.totalInPipeline, 16);
      expect(data.leadFunnel.stages, hasLength(6));

      final first = data.leadFunnel.stages.first;
      expect(first.label, 'New Leads');
      expect(first.count, 20);
      expect(first.color, const Color(0xFF7370F6));

      expect(data.leadFunnel.stages.last.label, 'Won');
      // 1 Won out of 20 that entered the funnel.
      expect(data.leadFunnel.conversionRatePercentage, 5);
    });

    test('source_distribution keeps each brand colour', () {
      expect(data.sourceDistribution.totalLeads, 20);
      expect(data.sourceDistribution.sources, hasLength(4));

      final facebook = data.sourceDistribution.sources.first;
      expect(facebook.name, 'Facebook');
      expect(facebook.count, 12);
      expect(facebook.percentage, 60);
      expect(facebook.color, const Color(0xFF1877F2));

      // Uppercase hex parses too.
      expect(data.sourceDistribution.sources.last.color,
          const Color(0xFF25D366));
    });

    test('response_rate', () {
      expect(data.responseRate.averageSpeedPercentage, 100);
      expect(data.responseRate.under1hPercentage, 90);
      expect(data.responseRate.targetPercentage, 90);
    });

    test('lead_to_won_trend keeps day order and fractional days', () {
      expect(data.leadToWonTrend.avgConversionDays, 0.1);
      expect(data.leadToWonTrend.changeVsLastMonthPercentage, -12);
      expect(data.leadToWonTrend.trendPoints, hasLength(7));
      expect(
        data.leadToWonTrend.trendPoints.map((p) => p.day),
        ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon'],
      );
      expect(data.leadToWonTrend.trendPoints[2].value, 50126.4);
    });

    test('top_sales_performers', () {
      expect(data.topSalesPerformers, hasLength(2));
      final admin = data.topSalesPerformers.first;
      expect(admin.userId, 2);
      expect(admin.name, 'Admin');
      expect(admin.role, 'Owner');
      expect(admin.salesAmount, 0);
      expect(admin.formattedSalesAmount, r'$0.0k');
      expect(admin.wonDealsCount, 0);
      expect(admin.avatar, contains('ui-avatars.com'));
    });

    test('revenue_forecast', () {
      expect(data.revenueForecast.totalPipeline, 25176.2);
      expect(data.revenueForecast.weightedForecast, 22613.38);
      expect(data.revenueForecast.forecastByMonth, hasLength(3));

      final aug = data.revenueForecast.forecastByMonth.first;
      expect(aug.month, 'Aug');
      expect(aug.pipeline, 17623.34);
      expect(aug.weighted, 15829.37);
    });

    test('empty loss_reasons parses to an empty list, not a crash', () {
      expect(data.lossReasons, isEmpty);
    });
  });

  group('Defensive parsing', () {
    test('a completely empty data object yields safe defaults', () {
      final data = DashboardOverview.fromJson(const {});

      expect(data.leadsCounter.total, 0);
      expect(data.overview.totalLeads, 0);
      expect(data.leadFunnel.stages, isEmpty);
      expect(data.leadFunnel.conversionRatePercentage, 0);
      expect(data.sourceDistribution.sources, isEmpty);
      expect(data.responseRate.averageSpeedPercentage, 0);
      expect(data.leadToWonTrend.trendPoints, isEmpty);
      expect(data.topSalesPerformers, isEmpty);
      expect(data.revenueForecast.forecastByMonth, isEmpty);
      expect(data.lossReasons, isEmpty);
    });

    test('numbers sent as strings still parse', () {
      final counter = LeadsCounter.fromJson(const {
        'today': '3',
        'week': '7',
        'month': 4,
        'total': '20',
      });
      expect(counter.today, 3);
      expect(counter.week, 7);
      expect(counter.total, 20);
    });

    test('a null or malformed section does not take down the rest', () {
      final data = DashboardOverview.fromJson(const {
        'leads_counter': null,
        'overview': 'unexpected',
        'lead_funnel': {'stages': 'not a list'},
        'top_sales_performers': {'not': 'a list'},
        'source_distribution': {
          'total_leads': 5,
          'sources': [
            {'name': 'Facebook', 'count': 5},
          ],
        },
      });

      expect(data.leadsCounter.total, 0);
      expect(data.overview.totalLeads, 0);
      expect(data.leadFunnel.stages, isEmpty);
      expect(data.topSalesPerformers, isEmpty);
      // The one well-formed section still comes through.
      expect(data.sourceDistribution.totalLeads, 5);
      expect(data.sourceDistribution.sources.single.name, 'Facebook');
      // A missing colour is null so the widget uses its own palette.
      expect(data.sourceDistribution.sources.single.color, isNull);
    });

    test('conversion rate does not divide by zero on an empty funnel', () {
      final funnel = LeadFunnel.fromJson(const {
        'stages': [
          {'label': 'New Leads', 'count': 0},
          {'label': 'Won', 'count': 0},
        ],
      });
      expect(funnel.conversionRatePercentage, 0);
    });

    test('loss reasons accept the alternate key spellings', () {
      expect(
        LossReason.fromJson(const {'reason': 'Pricing', 'percentage': 42})
            .label,
        'Pricing',
      );
      expect(
        LossReason.fromJson(const {'name': 'Competitor', 'percent': 28})
            .percentage,
        28,
      );
    });
  });

  group('parseHexColor', () {
    test('handles the shapes a backend might send', () {
      expect(parseHexColor('#7370f6'), const Color(0xFF7370F6));
      expect(parseHexColor('7370f6'), const Color(0xFF7370F6));
      expect(parseHexColor('#1877F2'), const Color(0xFF1877F2));
      expect(parseHexColor('#807370f6'), const Color(0x807370F6));
    });

    test('returns null for anything unusable', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('rebeccapurple'), isNull);
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor(0xFF0000), isNull);
    });
  });
}
