import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

enum TaskStatus { overdue, dueToday, upcoming, completed }

extension TaskStatusName on TaskStatus {
  /// Label shown in the status dropdown and the card tag.
  String get label {
    switch (this) {
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.dueToday:
        return 'Due Today';
      case TaskStatus.upcoming:
        return 'Upcoming';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.overdue:
        return AppColors.red;
      case TaskStatus.dueToday:
        return AppColors.primary;
      case TaskStatus.upcoming:
        return AppColors.green;
      case TaskStatus.completed:
        return AppColors.textSecondary;
    }
  }
}

enum TaskPriority { high, medium, low }

extension TaskPriorityName on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.red;
      case TaskPriority.medium:
        return AppColors.primary;
      case TaskPriority.low:
        return AppColors.green;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String nextAction;
  final String remark;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignee;
  final String? leadName;

  TaskModel({
    required this.id,
    required this.title,
    required this.nextAction,
    required this.remark,
    required this.dueDate,
    required this.status,
    this.priority = TaskPriority.medium,
    this.assignee = 'Unassigned',
    this.leadName,
  });

  TaskModel copyWith({
    String? title,
    String? nextAction,
    String? remark,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignee,
    String? leadName,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      nextAction: nextAction ?? this.nextAction,
      remark: remark ?? this.remark,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      leadName: leadName ?? this.leadName,
    );
  }

  // Sample data
  static List<TaskModel> sampleTasks() {
    final now = DateTime.now();
    return [
      TaskModel(
        id: '1',
        title: 'Follow-up: websiyte',
        nextAction: 'Meeting',
        remark: 'ssssss',
        dueDate: DateTime(2025, 5, 22, 21, 28),
        status: TaskStatus.overdue,
        priority: TaskPriority.high,
        assignee: 'Rahul Sharma',
        leadName: 'websiyte',
      ),
      TaskModel(
        id: '2',
        title: 'Call: Acme Corp',
        nextAction: 'Phone Call',
        remark: 'Discuss Q3 proposal',
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
        status: TaskStatus.dueToday,
        priority: TaskPriority.high,
        assignee: 'Priya Nair',
        leadName: 'Acme Corp',
      ),
      TaskModel(
        id: '3',
        title: 'Demo: TechStart',
        nextAction: 'Product Demo',
        remark: 'Show new features',
        dueDate: DateTime(now.year, now.month, now.day, 14, 30),
        status: TaskStatus.dueToday,
        priority: TaskPriority.medium,
        assignee: 'Rahul Sharma',
        leadName: 'TechStart',
      ),
      TaskModel(
        id: '4',
        title: 'Proposal: GlobalNet',
        nextAction: 'Send Proposal',
        remark: 'Pricing finalized',
        dueDate: now.add(const Duration(days: 2)),
        status: TaskStatus.upcoming,
        priority: TaskPriority.medium,
        assignee: 'Amit Verma',
        leadName: 'GlobalNet',
      ),
      TaskModel(
        id: '5',
        title: 'Onboarding: Vertex',
        nextAction: 'Onboarding Call',
        remark: 'Welcome new client',
        dueDate: now.add(const Duration(days: 3)),
        status: TaskStatus.upcoming,
        priority: TaskPriority.low,
        assignee: 'Priya Nair',
        leadName: 'Vertex Inc',
      ),
      TaskModel(
        id: '6',
        title: 'Contract: BrightCo',
        nextAction: 'Sign Contract',
        remark: 'Legal reviewed',
        dueDate: now.subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        assignee: 'Amit Verma',
        leadName: 'BrightCo',
      ),
    ];
  }
}