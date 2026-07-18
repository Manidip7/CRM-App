import 'dart:convert';

import 'package:crm_app/features/projects/model/project_detail_models.dart';
import 'package:crm_app/features/projects/model/project_model.dart';
import 'package:crm_app/features/projects/provider/project_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /projects/1` reply. Trimmed only by dropping repeated copies
/// of the same nested `user` object — every field the decoder reads is kept
/// exactly as the backend sends it.
const _response = '''
{
    "success": true,
    "data": {
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
        "customer": { "id": 11, "name": "Demo Lead 2 Opportunity" },
        "members": [
            {
                "id": 3,
                "name": "Kaushani Saha",
                "email": "kaushani@mindverge.in",
                "designation": "Pre-sales Manager",
                "avatar": null,
                "pivot": { "project_id": 1, "user_id": 3 }
            },
            {
                "id": 4,
                "name": "Aris Akhtar",
                "email": "aris@mindverge.in",
                "designation": "Pre-sales Manager",
                "avatar": null,
                "pivot": { "project_id": 1, "user_id": 4 }
            },
            {
                "id": 6,
                "name": "Pronoy",
                "email": "pronoy@mindverge.in",
                "designation": "Sales Executive",
                "avatar": null,
                "pivot": { "project_id": 1, "user_id": 6 }
            }
        ],
        "tasks": [
            {
                "id": 515,
                "taskable_type": "App\\\\Models\\\\Project",
                "taskable_id": 1,
                "title": "hbjdbui",
                "description": "dsud",
                "due_at": "2026-07-16T18:30:00.000000Z",
                "priority": "medium",
                "status": "backlog",
                "assigned_to": null,
                "created_at": "2026-07-17T08:41:30.000000Z",
                "assignee": null
            }
        ],
        "files": [
            {
                "id": 1,
                "project_id": 1,
                "user_id": 2,
                "file_name": "Quotation-QT-QSMZKE.pdf",
                "file_path": "project_files/rwlOGfswqhAk6Gd3McwgJiTH1M7wDvW2YCf1ZPyw.pdf",
                "file_type": "application/pdf",
                "file_size": 883524,
                "created_at": "2026-07-17T08:41:58.000000Z",
                "user": { "id": 2, "name": "Admin Owner" }
            }
        ],
        "notes": [
            {
                "id": 543,
                "notable_id": 1,
                "user_id": 2,
                "content": "vhv",
                "created_at": "2026-07-17T08:42:21.000000Z",
                "user": { "id": 2, "name": "Admin Owner" }
            }
        ],
        "activities": [
            {
                "id": 11250,
                "user_id": 2,
                "action": "Note Added",
                "description": "Added a new note.",
                "created_at": "2026-07-17T08:42:21.000000Z",
                "user": { "id": 2, "name": "Admin Owner" }
            },
            {
                "id": 11249,
                "user_id": 2,
                "action": "File Uploaded",
                "description": "Uploaded file: Quotation-QT-QSMZKE.pdf",
                "created_at": "2026-07-17T08:41:58.000000Z",
                "user": { "id": 2, "name": "Admin Owner" }
            },
            {
                "id": 11252,
                "user_id": null,
                "action": "updated",
                "description": "Task \\"hbjdbui\\" was updated",
                "created_at": "2026-07-17T03:20:04.000000Z",
                "user": null
            },
            {
                "id": 9797,
                "user_id": 2,
                "action": "Project Created",
                "description": "Project was created.",
                "created_at": "2026-07-10T06:50:10.000000Z",
                "user": { "id": 2, "name": "Admin Owner" }
            }
        ]
    },
    "meta": {
        "completed_tasks_count": 0,
        "total_tasks_count": 1,
        "project_progress_percentage": 0
    }
}
''';

ProjectDetailBundle get _bundle {
  final map = jsonDecode(_response) as Map<String, dynamic>;
  return ProjectDetailBundle.fromJson(
    (map['data'] as Map).cast<String, dynamic>(),
    meta: (map['meta'] as Map).cast<String, dynamic>(),
  );
}

void main() {
  group('ProjectDetailBundle.fromJson', () {
    test('reads the project from the same map as the tabs', () {
      final p = _bundle.project;
      expect(p.id, '1');
      expect(p.name, 'wfggh');
      expect(p.customer, 'Demo Lead 2 Opportunity');
      expect(p.status, ProjectStatus.inProgress);
      expect(p.billingType, BillingType.fixed);
      expect(p.createdAt, DateTime.parse('2026-07-10T06:50:10.000000Z'));
      expect(p.deadline, isNull);
    });

    test('reads every tab array', () {
      final b = _bundle;
      expect(b.members, hasLength(3));
      expect(b.tasks, hasLength(1));
      expect(b.files, hasLength(1));
      expect(b.notes, hasLength(1));
      expect(b.activities, hasLength(4));
    });
  });

  group('ProjectMember', () {
    test('maps the project team, keeping the id the assignee dropdown needs',
        () {
      final members = _bundle.members;

      expect(members.map((m) => m.id), [3, 4, 6]);
      expect(members.map((m) => m.name),
          ['Kaushani Saha', 'Aris Akhtar', 'Pronoy']);
      expect(members.first.designation, 'Pre-sales Manager');
      expect(members.last.designation, 'Sales Executive');
    });

    test('derives an avatar initial', () {
      expect(_bundle.members.first.initial, 'K');
      expect(const ProjectMember(id: 1, name: '').initial, '?');
    });

    test('project.members still exposes plain names for the list card', () {
      expect(_bundle.project.members,
          ['Kaushani Saha', 'Aris Akhtar', 'Pronoy']);
    });
  });

  group('ProjectProgress', () {
    test('uses the server percentage rather than counting tasks', () {
      final p = _bundle.progress;
      expect(p.completedTasks, 0);
      expect(p.totalTasks, 1);
      expect(p.percentage, 0);
      expect(p.fraction, 0.0);
    });

    test('fraction converts a percentage to a 0..1 bar value', () {
      const p = ProjectProgress(percentage: 45);
      expect(p.fraction, closeTo(0.45, 1e-9));
    });
  });

  group('ProjectTask', () {
    test('maps the real task, including the "backlog" status', () {
      final t = _bundle.tasks.single;
      expect(t.id, '515');
      expect(t.title, 'hbjdbui');
      expect(t.description, 'dsud');
      expect(t.priority, TaskPriority.medium);
      expect(t.state, TaskState.backlog);
      // assignee is null on this row.
      expect(t.assignedTo, isNull);
      expect(t.dueDate, DateTime.parse('2026-07-16T18:30:00.000000Z'));
    });

    test('maps the status vocabulary', () {
      expect(TaskState.fromName('open'), TaskState.open);
      expect(TaskState.fromName('in_progress'), TaskState.inProgress);
      expect(TaskState.fromName('done'), TaskState.done);
      expect(TaskState.fromName('completed'), TaskState.done);
      // Still understood so existing rows keep rendering correctly.
      expect(TaskState.fromName('backlog'), TaskState.backlog);
      // Unknown statuses read as open rather than being dropped.
      expect(TaskState.fromName('something_new'), TaskState.open);
      expect(TaskState.fromName(null), TaskState.open);
    });

    test('reads In Progress however it is spelled', () {
      for (final v in ['in_progress', 'In Progress', 'in progress', 'in-progress']) {
        expect(TaskState.fromName(v), TaskState.inProgress, reason: v);
      }
    });

    test('round-trips the status the backend stores', () {
      expect(TaskState.open.apiValue, 'open');
      expect(TaskState.inProgress.apiValue, 'in_progress');
      expect(TaskState.done.apiValue, 'done');
      expect(TaskState.backlog.apiValue, 'backlog');
      expect(TaskPriority.medium.apiValue, 'medium');
    });

    test('formats due_at as a plain date for the create endpoint', () {
      // This route takes "2026-07-25" — not the `yyyy-MM-dd HH:mm:ss` the lead
      // task route wants — and single digits must stay zero-padded.
      expect(ProjectTaskDraftNotifier.fmtDue(DateTime(2026, 7, 25)),
          '2026-07-25');
      expect(ProjectTaskDraftNotifier.fmtDue(DateTime(2026, 1, 5)),
          '2026-01-05');
    });

    test('only offers statuses the backend accepts', () {
      expect(TaskState.selectable,
          [TaskState.open, TaskState.inProgress, TaskState.done]);
      // `backlog` renders but must never be sent back.
      expect(TaskState.selectable, isNot(contains(TaskState.backlog)));
    });
  });

  group('ProjectFile', () {
    test('maps the real file', () {
      final f = _bundle.files.single;
      expect(f.id, '1');
      expect(f.name, 'Quotation-QT-QSMZKE.pdf');
      expect(f.sizeBytes, 883524);
      // 883524 B ≈ 862.8 KB, shown without a decimal once past 100.
      expect(f.readableSize, '863 KB');
      expect(f.mimeType, 'application/pdf');
      expect(f.uploadedBy, 'Admin Owner');
      expect(f.extension, 'pdf');
      expect(f.isImage, isFalse);
    });

    test('builds a download URL from the storage path', () {
      expect(
        _bundle.files.single.downloadUrl,
        'https://crm.mindverge.in/storage/'
        'project_files/rwlOGfswqhAk6Gd3McwgJiTH1M7wDvW2YCf1ZPyw.pdf',
      );
    });

    test('detects images by mime type as well as extension', () {
      final byMime = ProjectFile(
        id: '1',
        name: 'scan',
        mimeType: 'image/png',
        uploadedAt: DateTime(2026),
      );
      expect(byMime.isImage, isTrue);
    });
  });

  group('ProjectNote', () {
    test('maps the real note', () {
      final n = _bundle.notes.single;
      expect(n.id, '543');
      expect(n.content, 'vhv');
      expect(n.author, 'Admin Owner');
      expect(n.createdAt, DateTime.parse('2026-07-17T08:42:21.000000Z'));
    });
  });

  group('ProjectActivity', () {
    test('maps a human-labelled action', () {
      final a = _bundle.activities.first;
      expect(a.id, '11250');
      expect(a.action, 'Note Added');
      expect(a.label, 'Note Added');
      expect(a.description, 'Added a new note.');
      expect(a.user, 'Admin Owner');
    });

    test('title-cases a machine action and tolerates a null user', () {
      final updated =
          _bundle.activities.firstWhere((a) => a.action == 'updated');
      expect(updated.label, 'Updated');
      expect(updated.user, isNull);
      expect(updated.description, 'Task "hbjdbui" was updated');
    });

    test('derives an icon/colour for every action in the payload', () {
      // No action should fall through to the generic default.
      for (final a in _bundle.activities) {
        expect(a.icon, isNot(Icons.circle_notifications_outlined),
            reason: 'unmapped action: ${a.action}');
      }
    });
  });
}
