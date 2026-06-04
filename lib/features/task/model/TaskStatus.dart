enum TaskStatus { overdue, dueToday, upcoming, completed }

class TaskModel {
  final String id;
  final String title;
  final String nextAction;
  final String remark;
  final DateTime dueDate;
  final TaskStatus status;
  final String? leadName;

  TaskModel({
    required this.id,
    required this.title,
    required this.nextAction,
    required this.remark,
    required this.dueDate,
    required this.status,
    this.leadName,
  });

  TaskModel copyWith({TaskStatus? status}) {
    return TaskModel(
      id: id,
      title: title,
      nextAction: nextAction,
      remark: remark,
      dueDate: dueDate,
      status: status ?? this.status,
      leadName: leadName,
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
        leadName: 'websiyte',
      ),
      TaskModel(
        id: '2',
        title: 'Call: Acme Corp',
        nextAction: 'Phone Call',
        remark: 'Discuss Q3 proposal',
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
        status: TaskStatus.dueToday,
        leadName: 'Acme Corp',
      ),
      TaskModel(
        id: '3',
        title: 'Demo: TechStart',
        nextAction: 'Product Demo',
        remark: 'Show new features',
        dueDate: DateTime(now.year, now.month, now.day, 14, 30),
        status: TaskStatus.dueToday,
        leadName: 'TechStart',
      ),
      TaskModel(
        id: '4',
        title: 'Proposal: GlobalNet',
        nextAction: 'Send Proposal',
        remark: 'Pricing finalized',
        dueDate: now.add(const Duration(days: 2)),
        status: TaskStatus.upcoming,
        leadName: 'GlobalNet',
      ),
      TaskModel(
        id: '5',
        title: 'Onboarding: Vertex',
        nextAction: 'Onboarding Call',
        remark: 'Welcome new client',
        dueDate: now.add(const Duration(days: 3)),
        status: TaskStatus.upcoming,
        leadName: 'Vertex Inc',
      ),
      TaskModel(
        id: '6',
        title: 'Contract: BrightCo',
        nextAction: 'Sign Contract',
        remark: 'Legal reviewed',
        dueDate: now.subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
        leadName: 'BrightCo',
      ),
    ];
  }
}