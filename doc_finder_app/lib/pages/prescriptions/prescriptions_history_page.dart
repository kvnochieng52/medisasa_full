import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/prescription.dart';
import '../../services/prescription_service.dart';
import 'lab_prescription_detail_page.dart';
import 'medication_prescription_detail_page.dart';
import 'new_lab_prescription_page.dart';
import 'new_medication_prescription_page.dart';
import 'new_radiology_prescription_page.dart';
import 'radiology_prescription_detail_page.dart';

class PrescriptionsHistoryPage extends StatefulWidget {
  const PrescriptionsHistoryPage({Key? key}) : super(key: key);

  @override
  State<PrescriptionsHistoryPage> createState() => _PrescriptionsHistoryPageState();
}

class _PrescriptionsHistoryPageState extends State<PrescriptionsHistoryPage>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF008faf);
  static const _purple = Color(0xFF8b5cf6);
  static const _rose = Color(0xFFf43f5e);

  late TabController _tabController;
  bool _loading = true;
  String? _error;
  bool _isDoctor = false;

  List<MedicationPrescription> _medication = [];
  List<LabPrescription> _lab = [];
  List<RadiologyPrescription> _radiology = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Rebuild so the FAB label / colour reflect the currently active tab.
      if (mounted) setState(() {});
    });
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
        PrescriptionService.listRadiology(),
      ]);
      if (!mounted) return;
      setState(() {
        _medication = results[0] as List<MedicationPrescription>;
        _lab = results[1] as List<LabPrescription>;
        _radiology = results[2] as List<RadiologyPrescription>;
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

  void _openNew(int tabIndex) async {
    Widget page;
    switch (tabIndex) {
      case 0:
        page = const NewMedicationPrescriptionPage();
        break;
      case 1:
        page = const NewLabPrescriptionPage();
        break;
      case 2:
      default:
        page = const NewRadiologyPrescriptionPage();
        break;
    }
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
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
            Tab(text: 'Radiology', icon: Icon(Icons.medical_information)),
          ],
        ),
      ),
      floatingActionButton: _isDoctor
          ? Builder(builder: (context) {
              final tab = _tabController.index;
              final label = tab == 0
                  ? 'New medication Rx'
                  : tab == 1
                      ? 'New lab order'
                      : 'New radiology order';
              final color = tab == 0 ? _brand : tab == 1 ? _purple : _rose;
              return FloatingActionButton.extended(
                onPressed: () => _openNew(tab),
                backgroundColor: color,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(label, style: const TextStyle(color: Colors.white)),
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
                    _RadiologyList(items: _radiology, isDoctor: _isDoctor, onRefresh: _load),
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

class _RadiologyList extends StatelessWidget {
  final List<RadiologyPrescription> items;
  final bool isDoctor;
  final Future<void> Function() onRefresh;

  const _RadiologyList({required this.items, required this.isDoctor, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyView(
        icon: Icons.medical_information_outlined,
        title: 'No radiology orders',
        subtitle: isDoctor
            ? 'Tap the button below to order imaging.'
            : 'Your provider will share radiology orders here.',
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
            color: const Color(0xFFf43f5e),
            icon: Icons.medical_information,
            chips: rx.items.take(3).map((it) => it.studyName).toList(),
            subtitle: isDoctor ? (rx.patientEmail ?? '—') : rx.patientName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadiologyPrescriptionDetailPage(prescriptionId: rx.id),
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
