import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/prescription.dart';
import '../../services/prescription_service.dart';
import 'lab_prescription_detail_page.dart';
import 'medication_prescription_detail_page.dart';
import 'new_lab_prescription_page.dart';
import 'new_medication_prescription_page.dart';

class PrescriptionsHistoryPage extends StatefulWidget {
  const PrescriptionsHistoryPage({Key? key}) : super(key: key);

  @override
  State<PrescriptionsHistoryPage> createState() => _PrescriptionsHistoryPageState();
}

class _PrescriptionsHistoryPageState extends State<PrescriptionsHistoryPage>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF008faf);
  static const _purple = Color(0xFF8b5cf6);

  late TabController _tabController;
  bool _loading = true;
  String? _error;
  bool _isDoctor = false;

  List<MedicationPrescription> _medication = [];
  List<LabPrescription> _lab = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountType = prefs.getString('account_type') ?? prefs.getInt('account_type')?.toString();
      _isDoctor = accountType == '2';

      final results = await Future.wait([
        PrescriptionService.listMedication(),
        PrescriptionService.listLab(),
      ]);
      if (!mounted) return;
      setState(() {
        _medication = results[0] as List<MedicationPrescription>;
        _lab = results[1] as List<LabPrescription>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openNew(bool medication) async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            medication ? const NewMedicationPrescriptionPage() : const NewLabPrescriptionPage(),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Prescriptions', style: TextStyle(color: Colors.white)),
        backgroundColor: _brand,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Medication', icon: Icon(Icons.medication)),
            Tab(text: 'Lab orders', icon: Icon(Icons.biotech)),
          ],
        ),
      ),
      floatingActionButton: _isDoctor
          ? Builder(builder: (context) {
              final tab = _tabController.index;
              return FloatingActionButton.extended(
                onPressed: () => _openNew(tab == 0),
                backgroundColor: tab == 0 ? _brand : _purple,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  tab == 0 ? 'New medication Rx' : 'New lab order',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            })
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _MedicationList(items: _medication, isDoctor: _isDoctor, onRefresh: _load),
                    _LabList(items: _lab, isDoctor: _isDoctor, onRefresh: _load),
                  ],
                ),
    );
  }
}

class _MedicationList extends StatelessWidget {
  final List<MedicationPrescription> items;
  final bool isDoctor;
  final Future<void> Function() onRefresh;

  const _MedicationList({required this.items, required this.isDoctor, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyView(
        icon: Icons.medication_outlined,
        title: 'No medication prescriptions',
        subtitle: isDoctor
            ? 'Tap the button below to issue a medication Rx.'
            : 'Your provider will share prescriptions here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final rx = items[i];
          return _RxCard(
            title: isDoctor ? rx.patientName : rx.prescriberName,
            number: rx.prescriptionNumber,
            date: rx.issuedDate,
            color: const Color(0xFF008faf),
            icon: Icons.medication,
            chips: rx.items.take(3).map((it) => it.drugName).toList(),
            subtitle: isDoctor ? (rx.patientEmail ?? '—') : rx.patientName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationPrescriptionDetailPage(prescriptionId: rx.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LabList extends StatelessWidget {
  final List<LabPrescription> items;
  final bool isDoctor;
  final Future<void> Function() onRefresh;

  const _LabList({required this.items, required this.isDoctor, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyView(
        icon: Icons.biotech_outlined,
        title: 'No lab orders',
        subtitle: isDoctor
            ? 'Tap the button below to order tests.'
            : 'Your provider will share lab orders here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final rx = items[i];
          return _RxCard(
            title: isDoctor ? rx.patientName : rx.prescriberName,
            number: rx.prescriptionNumber,
            date: rx.issuedDate,
            color: const Color(0xFF8b5cf6),
            icon: Icons.biotech,
            chips: rx.items.take(3).map((it) => it.testName).toList(),
            subtitle: isDoctor ? (rx.patientEmail ?? '—') : rx.patientName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabPrescriptionDetailPage(prescriptionId: rx.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RxCard extends StatelessWidget {
  final String title;
  final String number;
  final String date;
  final Color color;
  final IconData icon;
  final List<String> chips;
  final String subtitle;
  final VoidCallback onTap;

  const _RxCard({
    required this.title,
    required this.number,
    required this.date,
    required this.color,
    required this.icon,
    required this.chips,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(number, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: chips
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(c, style: TextStyle(fontSize: 11, color: color)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Could not load prescriptions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008faf)),
            ),
          ],
        ),
      ),
    );
  }
}
