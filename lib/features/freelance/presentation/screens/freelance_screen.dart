import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

// =====================
// Models
// =====================
class FreelanceClient {
  final String id;
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String? country;
  final String? notes;
  final DateTime addedAt;

  const FreelanceClient({
    required this.id,
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.country,
    this.notes,
    required this.addedAt,
  });

  factory FreelanceClient.fromMap(Map<String, dynamic> m, String id) =>
      FreelanceClient(
        id: id, uid: m['uid'] ?? '', name: m['name'] ?? '',
        email: m['email'], phone: m['phone'], company: m['company'],
        country: m['country'], notes: m['notes'],
        addedAt: m['addedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['addedAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid, 'name': name, 'email': email, 'phone': phone,
        'company': company, 'country': country, 'notes': notes,
        'addedAt': addedAt.millisecondsSinceEpoch,
      };
}

class FreelanceInvoice {
  final String id;
  final String uid;
  final String clientId;
  final String clientName;
  final String invoiceNumber;
  final List<InvoiceItem> items;
  final double taxPercent;
  final String currency;
  final String status; // 'draft', 'sent', 'paid', 'overdue'
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;

  const FreelanceInvoice({
    required this.id,
    required this.uid,
    required this.clientId,
    required this.clientName,
    required this.invoiceNumber,
    required this.items,
    this.taxPercent = 0,
    this.currency = 'USD',
    this.status = 'draft',
    required this.issueDate,
    required this.dueDate,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get taxAmount => subtotal * (taxPercent / 100);
  double get total => subtotal + taxAmount;

  String get formattedTotal =>
      '${currency} ${NumberFormat('#,##0.00').format(total)}';

  factory FreelanceInvoice.fromMap(Map<String, dynamic> m, String id) =>
      FreelanceInvoice(
        id: id, uid: m['uid'] ?? '', clientId: m['clientId'] ?? '',
        clientName: m['clientName'] ?? '',
        invoiceNumber: m['invoiceNumber'] ?? '',
        items: (m['items'] as List? ?? [])
            .map((i) => InvoiceItem.fromMap(i))
            .toList(),
        taxPercent: (m['taxPercent'] ?? 0).toDouble(),
        currency: m['currency'] ?? 'USD',
        status: m['status'] ?? 'draft',
        issueDate: DateTime.fromMillisecondsSinceEpoch(m['issueDate'] ?? 0),
        dueDate: DateTime.fromMillisecondsSinceEpoch(m['dueDate'] ?? 0),
        notes: m['notes'],
      );

  Map<String, dynamic> toMap() => {
        'uid': uid, 'clientId': clientId, 'clientName': clientName,
        'invoiceNumber': invoiceNumber,
        'items': items.map((i) => i.toMap()).toList(),
        'taxPercent': taxPercent, 'currency': currency, 'status': status,
        'issueDate': issueDate.millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'notes': notes,
      };

  String get statusEmoji {
    switch (status) {
      case 'paid': return '✅';
      case 'sent': return '📤';
      case 'overdue': return '⚠️';
      default: return '📝';
    }
  }

  Color statusColor(bool isDark) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'sent': return Colors.blue;
      case 'overdue': return Colors.red;
      default: return isDark ? AppTheme.gray : AppTheme.lightGray;
    }
  }
}

class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final String unit; // 'hours', 'items', 'fixed'

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.unit = 'hours',
  });

  double get total => quantity * unitPrice;

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        description: m['description'] ?? '',
        quantity: (m['quantity'] ?? 1).toDouble(),
        unitPrice: (m['unitPrice'] ?? 0).toDouble(),
        unit: m['unit'] ?? 'hours',
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unit': unit,
      };
}

// =====================
// Provider
// =====================
final freelanceClientsProvider = StreamProvider<List<FreelanceClient>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('fl_clients')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => FreelanceClient.fromMap(d.data(), d.id)).toList());
});

final freelanceInvoicesProvider = StreamProvider<List<FreelanceInvoice>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('fl_invoices')
      .orderBy('issueDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => FreelanceInvoice.fromMap(d.data(), d.id)).toList());
});

final freelanceControllerProvider =
    StateNotifierProvider<FreelanceController, AsyncValue<void>>((ref) {
  return FreelanceController(ref);
});

class FreelanceController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  FreelanceController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> addClient(FreelanceClient client) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('fl_clients')
        .doc(client.id).set(client.toMap());
  }

  Future<void> deleteClient(String id) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('fl_clients').doc(id).delete();
  }

  Future<void> addInvoice(FreelanceInvoice invoice) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('fl_invoices')
        .doc(invoice.id).set(invoice.toMap());
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('fl_invoices')
        .doc(invoiceId).update({'status': status});
  }

  Future<void> deleteInvoice(String id) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('fl_invoices').doc(id).delete();
  }

  String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${(now.millisecond % 1000).toString().padLeft(3, '0')}';
  }
}

// =====================
// Freelance Screen
// =====================
class FreelanceScreen extends ConsumerStatefulWidget {
  const FreelanceScreen({super.key});

  @override
  ConsumerState<FreelanceScreen> createState() => _FreelanceScreenState();
}

class _FreelanceScreenState extends ConsumerState<FreelanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoicesAsync = ref.watch(freelanceInvoicesProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('// business manager',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Freelance',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ]),
                GestureDetector(
                  onTap: () {
                    if (_tabCtrl.index == 0) _showAddClient(context, isDark);
                    else if (_tabCtrl.index == 1) _showAddInvoice(context, isDark);
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                      border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                    ),
                    child: Icon(Icons.add, size: 20, color: isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 12),

          // Revenue Summary
          invoicesAsync.when(
            data: (invoices) {
              final paid = invoices.where((i) => i.status == 'paid').fold(0.0, (s, i) => s + i.total);
              final pending = invoices.where((i) => i.status == 'sent').fold(0.0, (s, i) => s + i.total);
              final overdue = invoices.where((i) => i.status == 'overdue').fold(0.0, (s, i) => s + i.total);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _RevStat(label: 'Earned', value: '\$${paid.toStringAsFixed(0)}',
                        color: Colors.green, isDark: isDark),
                    _RevStat(label: 'Pending', value: '\$${pending.toStringAsFixed(0)}',
                        color: Colors.blue, isDark: isDark),
                    _RevStat(label: 'Overdue', value: '\$${overdue.toStringAsFixed(0)}',
                        color: Colors.red, isDark: isDark),
                  ]),
                ),
              ).animate().fadeIn(delay: 100.ms);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabCtrl,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,

                labelColor: isDark ? AppTheme.black : AppTheme.white,
                unselectedLabelColor: isDark ? AppTheme.gray : AppTheme.lightGray,

                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),

                labelStyle: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                tabs: const [Tab(text: 'CLIENTS'), Tab(text: 'INVOICES'), Tab(text: 'OVERVIEW')],
            ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ClientsTab(isDark: isDark),
                _InvoicesTab(isDark: isDark),
                _FreelanceOverviewTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClient(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final countryCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        blur: 20,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                  color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
          const SizedBox(height: 20),
          Text('Add Client', style: TextStyle(fontFamily: 'Syne', fontSize: 20,
              fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 16),
          GlassTextField(controller: nameCtrl, hintText: 'Client name *'),
          const SizedBox(height: 10),
          GlassTextField(controller: emailCtrl, hintText: 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          GlassTextField(controller: companyCtrl, hintText: 'Company'),
          const SizedBox(height: 10),
          GlassTextField(controller: countryCtrl, hintText: 'Country'),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Add Client',
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final client = FreelanceClient(
                id: const Uuid().v4(), uid: ref.read(currentUserProvider)?.uid ?? '',
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                company: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                country: countryCtrl.text.trim().isEmpty ? null : countryCtrl.text.trim(),
                addedAt: DateTime.now(),
              );
              await ref.read(freelanceControllerProvider.notifier).addClient(client);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }

  void _showAddInvoice(BuildContext context, bool isDark) {
    final clients = ref.read(freelanceClientsProvider).asData?.value ?? [];
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client first!')));
      return;
    }

    String? selectedClientId = clients.first.id;
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    String currency = 'USD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
              const SizedBox(height: 20),
              Text('New Invoice', style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                  fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 16),

              // Client select
              GlassCard(padding: EdgeInsets.zero,
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: selectedClientId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                      color: isDark ? AppTheme.white : AppTheme.black),
                  items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setS(() => selectedClientId = v),
                ))),
              const SizedBox(height: 10),
              GlassTextField(controller: descCtrl, hintText: 'Service description'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GlassTextField(controller: qtyCtrl, hintText: 'Hours/Qty',
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: GlassTextField(controller: priceCtrl, hintText: 'Unit price',
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (final c in ['USD', 'EUR', 'GBP', 'EGP'])
                  Expanded(child: GestureDetector(
                    onTap: () => setS(() => currency = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: currency == c
                            ? (isDark ? AppTheme.white : AppTheme.black)
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                      ),
                      child: Center(child: Text(c, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                          color: currency == c ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.silver : AppTheme.gray)))),
                    ),
                  )),
              ]),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Create Invoice',
                onPressed: () async {
                  if (selectedClientId == null || descCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  final client = clients.firstWhere((c) => c.id == selectedClientId);
                  final qty = double.tryParse(qtyCtrl.text) ?? 1;
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final ctrl = ref.read(freelanceControllerProvider.notifier);

                  final invoice = FreelanceInvoice(
                    id: const Uuid().v4(),
                    uid: ref.read(currentUserProvider)?.uid ?? '',
                    clientId: client.id,
                    clientName: client.name,
                    invoiceNumber: ctrl.generateInvoiceNumber(),
                    items: [InvoiceItem(description: descCtrl.text.trim(), quantity: qty, unitPrice: price)],
                    currency: currency,
                    issueDate: DateTime.now(),
                    dueDate: DateTime.now().add(const Duration(days: 30)),
                  );

                  await ctrl.addInvoice(invoice);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ]),
          ),
        );
      }),
    );
  }
}

// =====================
// Clients Tab
// =====================
class _ClientsTab extends ConsumerWidget {
  final bool isDark;
  const _ClientsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(freelanceClientsProvider);

    return clientsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(
          color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clients) {
        if (clients.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('👤', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No clients yet', style: TextStyle(fontFamily: 'Syne', fontSize: 18,
                fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
            const SizedBox(height: 6),
            Text('// tap + to add your first client',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          ]).animate().fadeIn());
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: clients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = clients[i];
            return Dismissible(
              key: Key(c.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ref.read(freelanceControllerProvider.notifier).deleteClient(c.id),
              background: Container(alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.red)),
              child: GlassCard(
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                    child: Center(child: Text(c.name[0].toUpperCase(),
                        style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.white : AppTheme.black)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                        fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
                    if (c.company != null) Text(c.company!, style: TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    if (c.email != null) Text(c.email!, style: TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ])),
                  if (c.country != null) Text(c.country!,
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]),
              ).animate().fadeIn(delay: (i * 50).ms),
            );
          },
        );
      },
    );
  }
}

// =====================
// Invoices Tab
// =====================
class _InvoicesTab extends ConsumerWidget {
  final bool isDark;
  const _InvoicesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(freelanceInvoicesProvider);

    return invoicesAsync.when(
      loading: () => Center(child: CircularProgressIndicator(
          color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🧾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No invoices yet', style: TextStyle(fontFamily: 'Syne', fontSize: 18,
                fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
            const SizedBox(height: 6),
            Text('// create your first invoice',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          ]).animate().fadeIn());
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final inv = invoices[i];
            return Dismissible(
              key: Key(inv.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ref.read(freelanceControllerProvider.notifier).deleteInvoice(inv.id),
              background: Container(alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.red)),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(inv.statusEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(inv.clientName, style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                          fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
                      Text(inv.invoiceNumber, style: TextStyle(fontFamily: 'JetBrainsMono',
                          fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(inv.formattedTotal, style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                          fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                            color: inv.statusColor(isDark).withOpacity(0.12)),
                        child: Text(inv.status.toUpperCase(), style: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700,
                            color: inv.statusColor(isDark))),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 12,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray),
                    const SizedBox(width: 4),
                    Text('Due: ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    const Spacer(),
                    // Quick status update
                    if (inv.status == 'draft' || inv.status == 'sent')
                      GestureDetector(
                        onTap: () => ref.read(freelanceControllerProvider.notifier)
                            .updateInvoiceStatus(inv.id, inv.status == 'draft' ? 'sent' : 'paid'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: Colors.green.withOpacity(0.12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(inv.status == 'draft' ? 'Mark Sent' : 'Mark Paid',
                              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                                  color: Colors.green, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ]),
              ).animate().fadeIn(delay: (i * 50).ms),
            );
          },
        );
      },
    );
  }
}

// =====================
// Overview Tab
// =====================
class _FreelanceOverviewTab extends ConsumerWidget {
  final bool isDark;
  const _FreelanceOverviewTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(freelanceInvoicesProvider).asData?.value ?? [];
    final clients = ref.watch(freelanceClientsProvider).asData?.value ?? [];

    final paid = invoices.where((i) => i.status == 'paid');
    final totalEarned = paid.fold(0.0, (s, i) => s + i.total);
    final avgInvoice = paid.isNotEmpty ? totalEarned / paid.length : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Business Overview', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
            const SizedBox(height: 16),
            _OvRow(label: 'Total Clients', value: '${clients.length}', isDark: isDark),
            _OvRow(label: 'Total Invoices', value: '${invoices.length}', isDark: isDark),
            _OvRow(label: 'Total Earned', value: '\$${totalEarned.toStringAsFixed(2)}', isDark: isDark, highlight: true),
            _OvRow(label: 'Avg Invoice Value', value: '\$${avgInvoice.toStringAsFixed(2)}', isDark: isDark),
            _OvRow(label: 'Paid Invoices', value: '${paid.length}/${invoices.length}', isDark: isDark),
          ]),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Top clients
        if (clients.isNotEmpty)
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Top Clients', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                  fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 12),
              ...clients.take(5).map((c) {
                final clientTotal = invoices
                    .where((i) => i.clientId == c.id && i.status == 'paid')
                    .fold(0.0, (s, i) => s + i.total);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                        child: Center(child: Text(c.name[0].toUpperCase(),
                            style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.white : AppTheme.black)))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c.name, style: TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 13, color: isDark ? AppTheme.white : AppTheme.black))),
                    Text('\$${clientTotal.toStringAsFixed(0)}',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                  ]),
                );
              }),
            ]),
          ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _OvRow extends StatelessWidget {
  final String label, value;
  final bool isDark, highlight;
  const _OvRow({required this.label, required this.value, required this.isDark, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: highlight ? Colors.green : (isDark ? AppTheme.white : AppTheme.black))),
      ]),
    );
  }
}

class _RevStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _RevStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 20,
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
    ]);
  }
}