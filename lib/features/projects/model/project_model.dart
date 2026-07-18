import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

/// Lifecycle state of a project. Colours map onto the shared [AppColors]
/// palette so cards/badges stay visually consistent with the rest of the app.
enum ProjectStatus {
  planning,
  inProgress,
  onHold,
  completed;

  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return AppColors.primaryLight;
      case ProjectStatus.inProgress:
        return const Color(0xFFF5A623); // amber
      case ProjectStatus.onHold:
        return AppColors.textSecondary;
      case ProjectStatus.completed:
        return AppColors.green;
    }
  }

  bool get isCompleted => this == ProjectStatus.completed;
}

/// How a project is billed to the customer.
enum BillingType {
  fixed,
  hourly,
  retainer,
  milestone;

  String get label {
    switch (this) {
      case BillingType.fixed:
        return 'Fixed Price';
      case BillingType.hourly:
        return 'Hourly';
      case BillingType.retainer:
        return 'Retainer';
      case BillingType.milestone:
        return 'Milestone';
    }
  }
}

/// A single project shown on the Projects screen.
class ProjectModel {
  final String id;
  final String name;
  final String customer;
  final ProjectStatus status;
  final List<String> members;

  /// Null when the project has no deadline set — the API leaves `deadline`
  /// null until one is chosen.
  final DateTime? deadline;

  final int pendingTasks;
  final BillingType billingType;
  final double totalRate;
  final double estimatedHours;
  final DateTime? startDate;

  /// When the project record was created (`created_at`), shown as "Date Created"
  /// on the detail screen.
  final DateTime? createdAt;

  final List<String> tags;
  final String description;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.customer,
    required this.status,
    required this.members,
    this.deadline,
    this.pendingTasks = 0,
    this.billingType = BillingType.fixed,
    this.totalRate = 0,
    this.estimatedHours = 0,
    this.startDate,
    this.createdAt,
    this.tags = const [],
    this.description = '',
  });

  /// Builds a [ProjectModel] from one `data[]` item of `GET /projects`.
  ///
  /// The customer arrives as a nested object; `members` as an array of user
  /// objects. Nullable columns (`deadline`, `total_rate`, `estimated_hours`,
  /// `tags`, `description`) all fall back to sensible empties so one sparse row
  /// can't break the list.
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return ProjectModel(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      customer: (customer is Map ? customer['name'] as String? : null) ?? '',
      status: _statusFromName(json['status'] as String?),
      members: _namesFrom(json['members']),
      deadline: _parseDate(json['deadline']),
      // Not part of the list payload today; the aggregate lives in `meta`.
      pendingTasks: (json['pending_tasks'] as num?)?.toInt() ?? 0,
      billingType: _billingFromName(json['billing_type'] as String?),
      totalRate: (json['total_rate'] as num?)?.toDouble() ?? 0,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0,
      startDate: _parseDate(json['start_date']),
      createdAt: _parseDate(json['created_at']),
      tags: _tagsFrom(json['tags']),
      description: json['description'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Compares names ignoring case and separators, so "In Progress",
  /// "in_progress" and "inProgress" all land on the same enum value.
  static String _normalise(String v) =>
      v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static ProjectStatus _statusFromName(String? value) {
    if (value == null) return ProjectStatus.planning;
    final key = _normalise(value);
    for (final s in ProjectStatus.values) {
      if (_normalise(s.label) == key || s.name.toLowerCase() == key) return s;
    }
    return ProjectStatus.planning;
  }

  /// The backend spells the fixed type "Fixed Rate"; the enum's own label says
  /// "Fixed Price", so match on both rather than on the label alone.
  static BillingType _billingFromName(String? value) {
    if (value == null) return BillingType.fixed;
    final key = _normalise(value);
    if (key == 'fixedrate' || key == 'fixedprice' || key == 'fixed') {
      return BillingType.fixed;
    }
    for (final b in BillingType.values) {
      if (_normalise(b.label) == key || b.name.toLowerCase() == key) return b;
    }
    return BillingType.fixed;
  }

  /// Member names from an array of user objects (`{ id, name }`), tolerating a
  /// plain array of strings.
  static List<String> _namesFrom(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final e in value)
        if (e is Map && (e['name'] as String?)?.trim().isNotEmpty == true)
          e['name'] as String
        else if (e is String && e.trim().isNotEmpty)
          e,
    ];
  }

  /// Tags as an array, or as a comma-separated string.
  static List<String> _tagsFrom(dynamic value) {
    if (value is List) {
      return [
        for (final t in value)
          if (t != null && '$t'.trim().isNotEmpty) '$t'.trim(),
      ];
    }
    if (value is String) {
      return value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }
    return const [];
  }

  /// True when the deadline has passed and the project is not yet completed.
  /// A project with no deadline is never overdue.
  bool get isOverdue =>
      !status.isCompleted &&
      deadline != null &&
      deadline!.isBefore(DateTime.now());

  /// Two-letter avatar initials derived from the project name.
  String get displayInitials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '#';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? customer,
    ProjectStatus? status,
    List<String>? members,
    DateTime? deadline,
    int? pendingTasks,
    BillingType? billingType,
    double? totalRate,
    double? estimatedHours,
    DateTime? startDate,
    DateTime? createdAt,
    List<String>? tags,
    String? description,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      customer: customer ?? this.customer,
      status: status ?? this.status,
      members: members ?? this.members,
      deadline: deadline ?? this.deadline,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      billingType: billingType ?? this.billingType,
      totalRate: totalRate ?? this.totalRate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }
}

/// Aggregate figures shown in the summary row above the project list.
class ProjectSummary {
  final int totalProjects;
  final int totalPendingTasks;
  final int uncompletedProjects;

  const ProjectSummary({
    required this.totalProjects,
    required this.totalPendingTasks,
    required this.uncompletedProjects,
  });

  static const empty = ProjectSummary(
    totalProjects: 0,
    totalPendingTasks: 0,
    uncompletedProjects: 0,
  );

  /// Reads the `meta` block of `GET /projects`. These are server-side totals
  /// across every project, not just the page in hand, so they can't be derived
  /// from the loaded list.
  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      totalPendingTasks: (json['total_pending_tasks'] as num?)?.toInt() ?? 0,
      uncompletedProjects: (json['uncompleted_projects'] as num?)?.toInt() ?? 0,
    );
  }
}
