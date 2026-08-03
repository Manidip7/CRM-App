/// Models for `GET /api/v1/dashboard/overview`.
///
/// One response feeds every card on the Overview tab, so this file mirrors the
/// `data` object section by section. Plain immutable classes with manual
/// `fromJson`, matching the rest of the project's model style — every field
/// falls back to a safe default so one odd value can't blank the whole
/// dashboard.
library;

import 'package:flutter/material.dart';

class DashboardOverview {
  final LeadsCounter leadsCounter;
  final OverviewStats overview;
  final LeadFunnel leadFunnel;
  final SourceDistribution sourceDistribution;
  final ResponseRate responseRate;
  final LeadToWonTrend leadToWonTrend;
  final List<SalesPerformer> topSalesPerformers;
  final RevenueForecast revenueForecast;
  final List<LossReason> lossReasons;

  const DashboardOverview({
    required this.leadsCounter,
    required this.overview,
    required this.leadFunnel,
    required this.sourceDistribution,
    required this.responseRate,
    required this.leadToWonTrend,
    required this.topSalesPerformers,
    required this.revenueForecast,
    required this.lossReasons,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      leadsCounter: LeadsCounter.fromJson(_obj(json['leads_counter'])),
      overview: OverviewStats.fromJson(_obj(json['overview'])),
      leadFunnel: LeadFunnel.fromJson(_obj(json['lead_funnel'])),
      sourceDistribution:
          SourceDistribution.fromJson(_obj(json['source_distribution'])),
      responseRate: ResponseRate.fromJson(_obj(json['response_rate'])),
      leadToWonTrend: LeadToWonTrend.fromJson(_obj(json['lead_to_won_trend'])),
      topSalesPerformers: _list(json['top_sales_performers'])
          .map(SalesPerformer.fromJson)
          .toList(growable: false),
      revenueForecast: RevenueForecast.fromJson(_obj(json['revenue_forecast'])),
      lossReasons: _list(json['loss_reasons'])
          .map(LossReason.fromJson)
          .toList(growable: false),
    );
  }
}

/// `leads_counter` — the T / W / M / TOTAL strip at the top.
class LeadsCounter {
  final int today;
  final int week;
  final int month;
  final int total;

  const LeadsCounter({
    this.today = 0,
    this.week = 0,
    this.month = 0,
    this.total = 0,
  });

  factory LeadsCounter.fromJson(Map<String, dynamic> json) => LeadsCounter(
        today: _int(json['today']),
        week: _int(json['week']),
        month: _int(json['month']),
        total: _int(json['total']),
      );
}

/// `overview` — the two headline stat cards.
class OverviewStats {
  final int totalLeads;

  /// Signed percentage change, e.g. `-75` for a 75% drop.
  final double totalLeadsGrowthPercentage;
  final double winRatePercentage;
  final double winRateChangePercentage;

  const OverviewStats({
    this.totalLeads = 0,
    this.totalLeadsGrowthPercentage = 0,
    this.winRatePercentage = 0,
    this.winRateChangePercentage = 0,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) => OverviewStats(
        totalLeads: _int(json['total_leads']),
        totalLeadsGrowthPercentage:
            _double(json['total_leads_growth_percentage']),
        winRatePercentage: _double(json['win_rate_percentage']),
        winRateChangePercentage: _double(json['win_rate_change_percentage']),
      );
}

/// `lead_funnel`.
class LeadFunnel {
  final int totalInPipeline;
  final List<FunnelStage> stages;

  const LeadFunnel({this.totalInPipeline = 0, this.stages = const []});

  /// The last stage is "Won" by convention, so its share of the first stage is
  /// the conversion rate shown in the header badge.
  int get conversionRatePercentage {
    if (stages.length < 2) return 0;
    final entered = stages.first.count;
    if (entered == 0) return 0;
    return ((stages.last.count / entered) * 100).round();
  }

  factory LeadFunnel.fromJson(Map<String, dynamic> json) => LeadFunnel(
        totalInPipeline: _int(json['total_in_pipeline']),
        stages: _list(json['stages'])
            .map(FunnelStage.fromJson)
            .toList(growable: false),
      );
}

class FunnelStage {
  final String label;
  final int count;
  final double percentage;

  /// Parsed from the API's `"#7370f6"`; `null` if it sent nothing usable, in
  /// which case the widget falls back to its own palette.
  final Color? color;

  const FunnelStage({
    required this.label,
    this.count = 0,
    this.percentage = 0,
    this.color,
  });

  factory FunnelStage.fromJson(Map<String, dynamic> json) => FunnelStage(
        label: json['label'] as String? ?? '',
        count: _int(json['count']),
        percentage: _double(json['percentage']),
        color: parseHexColor(json['color']),
      );
}

/// `source_distribution`.
class SourceDistribution {
  final int totalLeads;
  final List<SourceSlice> sources;

  const SourceDistribution({this.totalLeads = 0, this.sources = const []});

  factory SourceDistribution.fromJson(Map<String, dynamic> json) =>
      SourceDistribution(
        totalLeads: _int(json['total_leads']),
        sources: _list(json['sources'])
            .map(SourceSlice.fromJson)
            .toList(growable: false),
      );
}

class SourceSlice {
  final String name;
  final int count;
  final double percentage;
  final Color? color;

  const SourceSlice({
    required this.name,
    this.count = 0,
    this.percentage = 0,
    this.color,
  });

  factory SourceSlice.fromJson(Map<String, dynamic> json) => SourceSlice(
        name: json['name'] as String? ?? '',
        count: _int(json['count']),
        percentage: _double(json['percentage']),
        color: parseHexColor(json['color']),
      );
}

/// `response_rate` — the semi-donut gauge and its two metrics.
class ResponseRate {
  final double averageSpeedPercentage;
  final double under1hPercentage;
  final double targetPercentage;

  const ResponseRate({
    this.averageSpeedPercentage = 0,
    this.under1hPercentage = 0,
    this.targetPercentage = 0,
  });

  factory ResponseRate.fromJson(Map<String, dynamic> json) => ResponseRate(
        averageSpeedPercentage: _double(json['average_speed_percentage']),
        under1hPercentage: _double(json['under_1h_percentage']),
        targetPercentage: _double(json['target_percentage']),
      );
}

/// `lead_to_won_trend` — the line chart.
class LeadToWonTrend {
  final double avgConversionDays;
  final double changeVsLastMonthPercentage;
  final List<TrendPoint> trendPoints;

  const LeadToWonTrend({
    this.avgConversionDays = 0,
    this.changeVsLastMonthPercentage = 0,
    this.trendPoints = const [],
  });

  factory LeadToWonTrend.fromJson(Map<String, dynamic> json) => LeadToWonTrend(
        avgConversionDays: _double(json['avg_conversion_days']),
        changeVsLastMonthPercentage:
            _double(json['change_vs_last_month_percentage']),
        trendPoints: _list(json['trend_points'])
            .map(TrendPoint.fromJson)
            .toList(growable: false),
      );
}

class TrendPoint {
  final String day;
  final double value;

  const TrendPoint({required this.day, this.value = 0});

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        day: json['day'] as String? ?? '',
        value: _double(json['value']),
      );
}

/// One row of `top_sales_performers`.
class SalesPerformer {
  final int userId;
  final String name;
  final String? avatar;
  final String? role;
  final double salesAmount;

  /// The backend's own display string, e.g. `"$0.0k"`. Preferred over
  /// formatting [salesAmount] locally so the currency matches the web app.
  final String formattedSalesAmount;
  final int wonDealsCount;

  const SalesPerformer({
    this.userId = 0,
    required this.name,
    this.avatar,
    this.role,
    this.salesAmount = 0,
    this.formattedSalesAmount = '',
    this.wonDealsCount = 0,
  });

  factory SalesPerformer.fromJson(Map<String, dynamic> json) => SalesPerformer(
        userId: _int(json['user_id']),
        name: json['name'] as String? ?? '',
        avatar: json['avatar'] as String?,
        role: json['role'] as String?,
        salesAmount: _double(json['sales_amount']),
        formattedSalesAmount: json['formatted_sales_amount'] as String? ?? '',
        wonDealsCount: _int(json['won_deals_count']),
      );
}

/// `revenue_forecast` — the grouped bar chart.
class RevenueForecast {
  final double totalPipeline;
  final double weightedForecast;
  final List<ForecastMonth> forecastByMonth;

  const RevenueForecast({
    this.totalPipeline = 0,
    this.weightedForecast = 0,
    this.forecastByMonth = const [],
  });

  factory RevenueForecast.fromJson(Map<String, dynamic> json) =>
      RevenueForecast(
        totalPipeline: _double(json['total_pipeline']),
        weightedForecast: _double(json['weighted_forecast']),
        forecastByMonth: _list(json['forecast_by_month'])
            .map(ForecastMonth.fromJson)
            .toList(growable: false),
      );
}

class ForecastMonth {
  final String month;
  final double pipeline;
  final double weighted;

  const ForecastMonth({
    required this.month,
    this.pipeline = 0,
    this.weighted = 0,
  });

  factory ForecastMonth.fromJson(Map<String, dynamic> json) => ForecastMonth(
        month: json['month'] as String? ?? '',
        pipeline: _double(json['pipeline']),
        weighted: _double(json['weighted']),
      );
}

/// One row of `loss_reasons`.
///
/// The sample response returns an empty array, so the exact key names are
/// unconfirmed — [fromJson] accepts the plausible spellings (`label` / `reason`
/// / `name`, and `percentage` / `percent`) rather than guessing one and
/// silently rendering blanks once the array fills up.
class LossReason {
  final String label;
  final int count;
  final double percentage;

  const LossReason({
    required this.label,
    this.count = 0,
    this.percentage = 0,
  });

  factory LossReason.fromJson(Map<String, dynamic> json) => LossReason(
        label: (json['label'] ?? json['reason'] ?? json['name']) as String? ??
            '',
        count: _int(json['count']),
        percentage: _double(json['percentage'] ?? json['percent']),
      );
}

// ── Parsing helpers ──────────────────────────────────────────────────────────

/// Turns `"#7370f6"` / `"7370f6"` / `"#ff7370f6"` into a [Color]. Returns
/// `null` for anything it can't read, so callers can fall back to their own
/// palette instead of rendering a wrong colour.
Color? parseHexColor(dynamic value) {
  if (value is! String) return null;
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}

Map<String, dynamic> _obj(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

int _int(dynamic value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
