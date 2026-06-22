import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/prescription.dart';
import '../../services/prescription_service.dart';

class LabPrescriptionDetailPage extends StatefulWidget {
  final int prescriptionId;
  const LabPrescriptionDetailPage({Key? key, required this.prescriptionId}) : super(key: key);

  @override
  State<LabPrescriptionDetailPage> createState() => _LabPrescriptionDetailPageState();
}

class _LabPrescriptionDetailPageState extends State<LabPrescriptionDetailPage> {
  static const _purple = Color(0xFF8b5cf6);

  LabPrescription? _rx;
  bool _loading = true;
  String? _error;
  bool _downloading = false;
  bool _emailing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rx = await PrescriptionService.getLab(widget.prescriptionId);
      if (!mounted) return;
      setState(() {
        _rx = rx;
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

  Future<void> _downloadAndShare() async {
    if (_rx == null) return;
    setState(() => _downloading = true);
    try {
      final file = await PrescriptionService.downloadLabPdf(_rx!.id, _rx!.prescriptionNumber);
      await Share.shareXFiles([XFile(file.path)], text: 'Lab order ${_rx!.prescriptionNumber}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _emailDialog() async {
    final controller = TextEditingController(text: _rx?.patientEmail ?? '');
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send PDF by email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'patient@example.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || _rx == null) return;

    setState(() => _emailing = true);
    try {
      await PrescriptionService.emailLab(_rx!.id, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to $email')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _emailing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Lab Order', style: TextStyle(color: Colors.white)),
        backgroundColor: _purple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _downloading || _rx == null ? null : _downloadAndShare,
            icon: _downloading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share PDF',
          ),
          IconButton(
            onPressed: _emailing || _rx == null ? null : _emailDialog,
            icon: _emailing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.email, color: Colors.white),
            tooltip: 'Email PDF',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ),
                )
              : _buildBody(_rx!),
    );
  }

  Widget _buildBody(LabPrescription rx) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Order', [
          _kv('Number', rx.prescriptionNumber),
          _kv('Issued', rx.issuedDate),
        ]),
        _card('Prescriber', [
          _kv('Doctor', rx.prescriberName),
          _kv('Licence No.', rx.prescriberLicenceNumber),
          _kv('Phone', rx.prescriberPhone),
          _kv('Email', rx.prescriberEmail),
          if (rx.clinicName != null) _kv('Clinic', rx.clinicName),
          if (rx.clinicAddress != null) _kv('Clinic address', rx.clinicAddress),
        ]),
        _card('Patient', [
          _kv('Name', rx.patientName),
          _kv('Age', rx.patientAge?.toString()),
          _kv('DOB', rx.patientDob),
          _kv('Phone', rx.patientPhone),
          _kv('Email', rx.patientEmail),
        ]),
        if (rx.clinicalInformation != null && rx.clinicalInformation!.isNotEmpty)
          _card('Clinical information', [Text(rx.clinicalInformation!)]),
        _card('Tests ordered', [
          for (int i = 0; i < rx.items.length; i++) ...[
            _LabItemView(item: rx.items[i], index: i),
            if (i < rx.items.length - 1) const Divider(),
          ]
        ]),
        if (rx.notes != null && rx.notes!.isNotEmpty)
          _card('Notes', [Text(rx.notes!)]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF8b5cf6))),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabItemView extends StatelessWidget {
  final LabItem item;
  final int index;
  const _LabItemView({required this.item, required this.index});

  Color get _urgencyColor {
    switch (item.urgency) {
      case 'urgent':
        return Colors.amber.shade700;
      case 'stat':
        return Colors.redAccent;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${index + 1}. ${item.testName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _urgencyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item.urgency.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: _urgencyColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (item.specimenType != null && item.specimenType!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Specimen: ${item.specimenType}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.notes!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
