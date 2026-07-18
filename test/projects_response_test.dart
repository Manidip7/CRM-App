import 'dart:convert';

import 'package:crm_app/features/projects/model/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /projects` reply, kept verbatim so the decoder is tested
/// against the shape the backend actually sends — including the null columns
/// (`deadline`, `total_rate`, `tags`, `description`) and the empty members list.
const _response = '''
{
    "success": true,
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 1,
                "name": "wfggh",
                "customer_id": 11,
                "billing_type": "Fixed Rate",
                "status": "In Progress",
                "total_rate": null,
                "estimated_hours": null,
                "start_date": "2026-07-09T18:30:00.000000Z",
                "deadline": null,
                "tags": null,
                "description": null,
                "created_at": "2026-07-10T06:50:10.000000Z",
                "updated_at": "2026-07-10T06:50:10.000000Z",
                "deleted_at": null,
                "customer": {
                    "id": 11,
                    "name": "Demo Lead 2 Opportunity",
                    "email": null,
                    "phone": "9876543456"
                },
                "members": []
            }
        ],
        "first_page_url": "https://crm.mindverge.in/api/v1/projects?page=1",
        "from": 1,
        "last_page": 1,
        "next_page_url": null,
        "per_page": 15,
        "prev_page_url": null,
        "to": 1,
        "total": 1
    },
    "meta": {
        "total_projects": 1,
        "total_pending_tasks": 0,
        "uncompleted_projects": 1
    }
}
''';

Map<String, dynamic> get _firstProject {
  final map = jsonDecode(_response) as Map<String, dynamic>;
  final data = (map['data'] as Map)['data'] as List;
  return (data.first as Map).cast<String, dynamic>();
}

void main() {
  group('ProjectModel.fromJson', () {
    test('maps the real payload', () {
      final p = ProjectModel.fromJson(_firstProject);

      expect(p.id, '1');
      expect(p.name, 'wfggh');
      // Flattened out of the nested customer object.
      expect(p.customer, 'Demo Lead 2 Opportunity');
      expect(p.status, ProjectStatus.inProgress);
      // The backend spells this "Fixed Rate"; the enum's label says "Fixed Price".
      expect(p.billingType, BillingType.fixed);
      expect(p.startDate, DateTime.parse('2026-07-09T18:30:00.000000Z'));
      // Backs "Date Created" on the detail screen's Overview tab.
      expect(p.createdAt, DateTime.parse('2026-07-10T06:50:10.000000Z'));
      expect(p.members, isEmpty);
    });

    test('tolerates the null columns', () {
      final p = ProjectModel.fromJson(_firstProject);

      expect(p.deadline, isNull);
      expect(p.totalRate, 0);
      expect(p.estimatedHours, 0);
      expect(p.tags, isEmpty);
      expect(p.description, '');
      // Not in the list payload at all.
      expect(p.pendingTasks, 0);
    });

    test('a project with no deadline is never overdue', () {
      expect(ProjectModel.fromJson(_firstProject).isOverdue, isFalse);
    });

    test('reads status names in any casing/separator', () {
      ProjectStatus statusOf(String name) =>
          ProjectModel.fromJson({..._firstProject, 'status': name}).status;

      expect(statusOf('In Progress'), ProjectStatus.inProgress);
      expect(statusOf('in_progress'), ProjectStatus.inProgress);
      expect(statusOf('On Hold'), ProjectStatus.onHold);
      expect(statusOf('Completed'), ProjectStatus.completed);
      expect(statusOf('Planning'), ProjectStatus.planning);
    });

    test('reads members as user objects', () {
      final p = ProjectModel.fromJson({
        ..._firstProject,
        'members': [
          {'id': 1, 'name': 'Priya Sharma'},
          {'id': 2, 'name': 'Rahul Verma'},
        ],
      });
      expect(p.members, ['Priya Sharma', 'Rahul Verma']);
    });

    test('reads tags as an array or a comma-separated string', () {
      List<String> tagsOf(Object? tags) =>
          ProjectModel.fromJson({..._firstProject, 'tags': tags}).tags;

      expect(tagsOf(['crm', 'mobile']), ['crm', 'mobile']);
      expect(tagsOf('crm, mobile'), ['crm', 'mobile']);
      expect(tagsOf(null), isEmpty);
    });
  });

  group('ProjectSummary.fromJson', () {
    test('reads the meta totals', () {
      final map = jsonDecode(_response) as Map<String, dynamic>;
      final s = ProjectSummary.fromJson((map['meta'] as Map).cast());

      expect(s.totalProjects, 1);
      expect(s.totalPendingTasks, 0);
      expect(s.uncompletedProjects, 1);
    });
  });
}
