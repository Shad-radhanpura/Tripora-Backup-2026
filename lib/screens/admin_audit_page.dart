import 'package:flutter/material.dart';

import '../models/saved_trip.dart' show formatDate;
import '../services/audit_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Admin: the most recent administrative actions, newest first. Read-only.
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  final _stream = AuditService.recent();

  static String _actionLabel(String action) => switch (action) {
    'support_reply' => 'Support reply',
    'support_status' => 'Support status',
    _ => action.replaceAll('_', ' '),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Audit log')),
      body: StreamBuilder<List<AuditEntry>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              error: snapshot.error,
              title: 'Could not load the audit log',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Loading audit log…');
          }
          final entries = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 900),
              child: entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No admin actions yet',
                      message:
                          'Support replies and status changes are recorded here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final actor = e.actorUid.length > 6
                            ? e.actorUid.substring(e.actorUid.length - 6)
                            : e.actorUid;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.palette.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _actionLabel(e.action),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatDate(e.createdAt, withTime: true),
                                    style: TextStyle(
                                      color: context.palette.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(e.summary),
                              const SizedBox(height: 4),
                              Text(
                                '${e.target} · admin …$actor',
                                style: TextStyle(
                                  color: context.palette.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}
