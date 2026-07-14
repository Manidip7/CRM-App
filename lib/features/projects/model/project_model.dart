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
  final DateTime deadline;
  final int pendingTasks;
  final BillingType billingType;
  final double totalRate;
  final double estimatedHours;
  final DateTime? startDate;
  final List<String> tags;
  final String description;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.customer,
    required this.status,
    required this.members,
    required this.deadline,
    this.pendingTasks = 0,
    this.billingType = BillingType.fixed,
    this.totalRate = 0,
    this.estimatedHours = 0,
    this.startDate,
    this.tags = const [],
    this.description = '',
  });

  /// True when the deadline has passed and the project is not yet completed.
  bool get isOverdue =>
      !status.isCompleted && deadline.isBefore(DateTime.now());

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

  factory ProjectSummary.from(List<ProjectModel> projects) {
    var pending = 0;
    var uncompleted = 0;
    for (final p in projects) {
      pending += p.pendingTasks;
      if (!p.status.isCompleted) uncompleted++;
    }
    return ProjectSummary(
      totalProjects: projects.length,
      totalPendingTasks: pending,
      uncompletedProjects: uncompleted,
    );
  }
}
