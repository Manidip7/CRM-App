import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../Opportunities/provider/opportunity_detail_provider.dart';
import 'lead_call_logs_card.dart';

/// The Lead Details "Call Logs" section, on the Opportunity Details screen.
///
/// An opportunity's calls are its lead's calls: the CRM stores call logs
/// against the lead (`call_logs` on `GET /leads/{id}`, written by
/// `POST /leads/{id}/call-logs`), and an opportunity carries the `lead_id` it
/// was converted from. So this resolves that id from the opportunity detail and
/// then renders the very same [LeadCallLogsCard] — identical list rows, count
/// badge, "Log Call" button and refresh.
///
/// ```dart
/// OpportunityCallLogsCard(opportunityId: opp.id)
/// ```
class OpportunityCallLogsCard extends ConsumerWidget {
  final String opportunityId;

  const OpportunityCallLogsCard({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(opportunityDetailBundleProvider(opportunityId));
    void refresh() =>
        ref.invalidate(opportunityDetailBundleProvider(opportunityId));

    return bundle.when(
      loading: () => CallLogsCardFrame(
        onRefresh: refresh,
        child: const CallLogsLoading(),
      ),
      error: (error, _) => CallLogsCardFrame(
        onRefresh: refresh,
        child: Column(
          children: [
            CallLogsNote(
              icon: Icons.cloud_off_rounded,
              text: error is ApiException
                  ? error.message
                  : 'Could not load call logs.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
      data: (detail) {
        final leadId = detail.leadId;
        // Nothing to attach calls to — an opportunity created without a lead.
        if (leadId == null) {
          return CallLogsCardFrame(
            onRefresh: refresh,
            child: const CallLogsNote(
              icon: Icons.link_off_rounded,
              text: 'This opportunity has no linked lead, so there are no '
                  'call logs to show.',
            ),
          );
        }
        return LeadCallLogsCard(leadId: '$leadId');
      },
    );
  }
}
