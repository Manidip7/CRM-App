import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/customer_model.dart';
import '../provider/customers_api_provider.dart';
import '../provider/customers_provider.dart';

/// Full customer profile: contact info, address, and a tabbed section that
/// switches between Contract, Won Products and History List. Created-at /
/// created-by audit details sit at the bottom.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Always open on the Contract tab for a freshly opened customer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDetailTabProvider.notifier).select(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(customerDetailTabProvider);
    // Load the full profile from GET /customers/{id}. Until it arrives, show the
    // list row we were handed as a placeholder so the screen isn't blank.
    final async = ref.watch(customerDetailProvider(widget.customer.id));
    final c = async.value ?? widget.customer;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context, c),
            if (async.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),
            if (async.hasError && !async.isLoading) _buildErrorBanner(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _buildProfileCard(c),
                  const SizedBox(height: 14),
                  _buildAddressCard(c),
                  const SizedBox(height: 14),
                  _buildSectionTabs(tab),
                  const SizedBox(height: 14),
                  if (tab == 0)
                    _buildContactsCard(c)
                  else if (tab == 1)
                    _buildWonProductsCard(c)
                  else
                    _buildHistoryCard(c),
                  const SizedBox(height: 14),
                  _buildAuditCard(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thin inline banner shown when the detail fetch fails; the placeholder data
  /// from the list stays visible underneath. Tapping retries the request.
  Widget _buildErrorBanner() {
    return GestureDetector(
      onTap: () =>
          ref.invalidate(customerDetailProvider(widget.customer.id)),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load latest details. Tap to retry.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.red),
              ),
            ),
            const Icon(Icons.refresh_rounded, size: 16, color: AppColors.red),
          ],
        ),
      ),
    );
  }

  /// Horizontal segmented tabs that pick which related section is shown.
  /// Styled like the Lead Details tab bar (Information / Timeline / Notes):
  /// a rounded pill bar with a tinted indicator behind the selected label.
  Widget _buildSectionTabs(int selected) {
    const labels = ['Contacts', 'Won Products', 'History'];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(customerDetailTabProvider.notifier).select(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar(BuildContext context, CustomerModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            'Customer Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Edit — opens a sheet that PUTs to /customers/{id}.
          GestureDetector(
            onTap: () => _openEditSheet(c),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the edit sheet pre-filled with [c]. On a successful save it refreshes
  /// the detail (so the screen updates) and the list already refreshed itself.
  Future<void> _openEditSheet(CustomerModel c) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCustomerSheet(customer: c),
    );
    if (saved == true && mounted) {
      ref.invalidate(customerDetailProvider(widget.customer.id));
    }
  }

  // ── Profile ──
  Widget _buildProfileCard(CustomerModel c) {
    final accent = c.status.color;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    c.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            c.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _tag(c.status.label, accent),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _infoRow(Icons.email_outlined, 'Email', c.email),
          const SizedBox(height: 12),
          _infoRow(Icons.phone_outlined, 'Phone', c.phone),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, 'Location', c.location),
          const SizedBox(height: 12),
          _infoRow(Icons.payments_outlined, 'Total Value', c.valueLabel),
        ],
      ),
    );
  }

  // ── Address Details ──
  Widget _buildAddressCard(CustomerModel c) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.map_outlined, 'Address Details'),
          const SizedBox(height: 14),
          _infoRow(Icons.home_outlined, 'Street', _orDash(c.street)),
          const SizedBox(height: 12),
          _infoRow(Icons.location_city_outlined, 'City', _orDash(c.city)),
          const SizedBox(height: 12),
          _infoRow(Icons.flag_outlined, 'State', _orDash(c.state)),
          const SizedBox(height: 12),
          _infoRow(
            Icons.markunread_mailbox_outlined,
            'Postal Code',
            _orDash(c.postalCode),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.public_rounded, 'Country', _orDash(c.country)),
        ],
      ),
    );
  }

  // ── Contacts ──
  Widget _buildContactsCard(CustomerModel c) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(Icons.contacts_outlined, 'Contacts'),
              const Spacer(),
              _countBadge(c.contacts.length),
            ],
          ),
          const SizedBox(height: 8),
          if (c.contacts.isEmpty)
            _emptyHint('No contacts yet')
          else
            ...List.generate(c.contacts.length, (i) {
              final isLast = i == c.contacts.length - 1;
              return _contactRow(c.contacts[i], isLast);
            }),
        ],
      ),
    );
  }

  Widget _contactRow(CustomerContact contact, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    contact.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name.isEmpty ? '—' : contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 8),
                          _tag('Primary', AppColors.green),
                        ],
                      ],
                    ),
                    if (contact.designation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.designation,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (contact.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.email_outlined, 'Email', contact.email),
          ],
          if (contact.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, 'Phone', contact.phone),
          ],
          if (!isLast) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
          ],
        ],
      ),
    );
  }

  // ── Contract ──
  // ignore: unused_element
  Widget _buildContractCard(CustomerModel c) {
    final contract = c.contract;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.description_outlined, 'Contract'),
          const SizedBox(height: 14),
          if (contract == null)
            _emptyHint('No contract on file')
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _tag(
                  contract.active ? 'Active' : 'Expired',
                  contract.active ? AppColors.green : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.tag_rounded, 'Number', contract.number),
            const SizedBox(height: 12),
            _infoRow(
              Icons.event_available_outlined,
              'Start',
              _date(contract.startDate),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.event_busy_outlined, 'End', _date(contract.endDate)),
            const SizedBox(height: 12),
            _infoRow(Icons.payments_outlined, 'Value', _money(contract.value)),
          ],
        ],
      ),
    );
  }

  // ── Won Products ──
  Widget _buildWonProductsCard(CustomerModel c) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(Icons.emoji_events_outlined, 'Won Products'),
              const Spacer(),
              _countBadge(c.wonProducts.length),
            ],
          ),
          const SizedBox(height: 8),
          if (c.wonProducts.isEmpty)
            _emptyHint('No products yet')
          else
            ...c.wonProducts.map((p) => _productRow(p)),
        ],
      ),
    );
  }

  Widget _productRow(WonProduct p) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 17,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Qty: ${p.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(p.amount),
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── History ──
  Widget _buildHistoryCard(CustomerModel c) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(Icons.history_rounded, 'History List'),
              const Spacer(),
              _countBadge(c.history.length),
            ],
          ),
          const SizedBox(height: 4),
          if (c.history.isEmpty)
            _emptyHint('No activity yet')
          else
            ...List.generate(c.history.length, (i) {
              final isLast = i == c.history.length - 1;
              return _historyRow(c.history[i], isLast);
            }),
        ],
      ),
    );
  }

  Widget _historyRow(HistoryEntry e, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 12, bottom: isLast ? 0 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _date(e.date),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${e.by}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Created at / by ──
  Widget _buildAuditCard(CustomerModel c) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _auditItem(
              Icons.calendar_today_rounded,
              'Created at',
              _date(c.createdAt),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          Expanded(
            child: _auditItem(
              Icons.person_outline_rounded,
              'Created by',
              c.createdBy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Shared building blocks
  // ─────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
      ),
    );
  }

  String _orDash(String v) => v.trim().isEmpty ? '—' : v;

  static String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  String _date(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─────────────────────────────────────────────
//  Edit Customer sheet
// ─────────────────────────────────────────────

/// Bottom sheet to edit a customer's core fields. Pre-fills from [customer] and
/// submits `{ name, email, phone, address }` to `PUT /customers/{id}` through
/// [customersApiProvider]. Pops `true` on success so the caller can refresh.
class _EditCustomerSheet extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const _EditCustomerSheet({required this.customer});

  @override
  ConsumerState<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<_EditCustomerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  /// Detail parsing uses '—' as a placeholder for empty fields; strip it so the
  /// inputs start blank rather than with a dash.
  String _clean(String v) => v.trim() == '—' ? '' : v.trim();

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c.name);
    _email = TextEditingController(text: _clean(c.email));
    _phone = TextEditingController(text: _clean(c.phone));
    // The backend `address` maps onto CustomerModel.street.
    _address = TextEditingController(text: c.street);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerEditSubmittingProvider.notifier).set(false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(customerEditSubmittingProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Edit Customer',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _field('Name', _name, Icons.person_outline_rounded),
            _field('Email', _email, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            _field('Phone', _phone, Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            _field('Address', _address, Icons.location_on_outlined,
                maxLines: 2),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: _border(AppColors.divider),
              enabledBorder: _border(AppColors.divider),
              focusedBorder: _border(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('Name is required', isError: true);
      return;
    }

    final submitting = ref.read(customerEditSubmittingProvider.notifier);
    submitting.set(true);

    final error = await ref.read(customersApiProvider.notifier).updateCustomer(
          widget.customer.id,
          name: name,
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );

    if (!mounted) return;
    submitting.set(false);

    if (error != null) {
      _toast(error, isError: true);
      return;
    }

    Navigator.pop(context, true);
    _toast('$name updated');
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
