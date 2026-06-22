import 'package:flutter/material.dart';

import '../../models/prescription.dart';
import '../../services/prescription_service.dart';
import 'medication_prescription_detail_page.dart';

class NewMedicationPrescriptionPage extends StatefulWidget {
  final int? appointmentId;
  final String? patientName;
  final String? patientEmail;
  final String? patientPhone;

  const NewMedicationPrescriptionPage({
    Key? key,
    this.appointmentId,
    this.patientName,
    this.patientEmail,
    this.patientPhone,
  }) : super(key: key);

  @override
  State<NewMedicationPrescriptionPage> createState() => _NewMedicationPrescriptionPageState();
}

class _NewMedicationPrescriptionPageState extends State<NewMedicationPrescriptionPage> {
  static const _brand = Color(0xFF008faf);

  final _formKey = GlobalKey<FormState>();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _patientName = TextEditingController();
  final _patientEmail = TextEditingController();
  final _patientPhone = TextEditingController();
  final _patientAge = TextEditingController();
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  String? _patientDob;

  final List<_ItemControllers> _items = [_ItemControllers()];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _patientName.text = widget.patientName ?? '';
    _patientEmail.text = widget.patientEmail ?? '';
    _patientPhone.text = widget.patientPhone ?? '';
  }

  @override
  void dispose() {
    _clinicName.dispose();
    _clinicAddress.dispose();
    _patientName.dispose();
    _patientEmail.dispose();
    _patientPhone.dispose();
    _patientAge.dispose();
    _diagnosis.dispose();
    _notes.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemControllers()));
  void _removeItem(int i) {
    if (_items.length == 1) return;
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _patientDob = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final items = _items.map((c) => MedicationItem(
            drugName: c.drug.text.trim(),
            dosageForm: c.form.text.trim().isEmpty ? null : c.form.text.trim(),
            strength: c.strength.text.trim().isEmpty ? null : c.strength.text.trim(),
            frequency: c.frequency.text.trim().isEmpty ? null : c.frequency.text.trim(),
            route: c.route.text.trim().isEmpty ? null : c.route.text.trim(),
            duration: c.duration.text.trim().isEmpty ? null : c.duration.text.trim(),
            quantity: c.quantity.text.trim().isEmpty ? null : c.quantity.text.trim(),
            refills: int.tryParse(c.refills.text.trim()) ?? 0,
            instructions: c.instructions.text.trim().isEmpty ? null : c.instructions.text.trim(),
          )).toList();

      final rx = await PrescriptionService.createMedication(
        appointmentId: widget.appointmentId,
        clinicName: _clinicName.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        patientName: _patientName.text.trim(),
        patientEmail: _patientEmail.text.trim(),
        patientPhone: _patientPhone.text.trim(),
        patientDob: _patientDob,
        patientAge: int.tryParse(_patientAge.text.trim()),
        diagnosis: _diagnosis.text.trim(),
        notes: _notes.text.trim(),
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription saved')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MedicationPrescriptionDetailPage(prescriptionId: rx.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('New Medication Rx', style: TextStyle(color: Colors.white)),
        backgroundColor: _brand,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Clinic', [
              _text(_clinicName, 'Clinic name'),
              _text(_clinicAddress, 'Clinic address'),
            ]),
            _section('Patient', [
              _text(_patientName, 'Full name', required: true),
              _text(_patientEmail, 'Email', keyboard: TextInputType.emailAddress),
              _text(_patientPhone, 'Phone', keyboard: TextInputType.phone),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: _inputDecoration('Date of birth'),
                        child: Text(_patientDob ?? 'Tap to pick', style: const TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _text(_patientAge, 'Age', keyboard: TextInputType.number)),
                ],
              ),
            ]),
            _section('Clinical', [
              _text(_diagnosis, 'Diagnosis', maxLines: 3),
            ]),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Medications',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            ),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Spacer(),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () => _removeItem(i),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          ),
                      ],
                    ),
                    _text(c.drug, 'Drug name', required: true),
                    Row(children: [
                      Expanded(child: _text(c.form, 'Form')),
                      const SizedBox(width: 8),
                      Expanded(child: _text(c.strength, 'Strength')),
                    ]),
                    _text(c.frequency, 'Frequency'),
                    _text(c.route, 'Route'),
                    _text(c.duration, 'Duration'),
                    Row(children: [
                      Expanded(child: _text(c.quantity, 'Quantity')),
                      const SizedBox(width: 8),
                      Expanded(child: _text(c.refills, 'Refills', keyboard: TextInputType.number)),
                    ]),
                    _text(c.instructions, 'Instructions', maxLines: 2),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add medication'),
            ),
            const SizedBox(height: 16),
            _section('Additional notes', [
              _text(_notes, 'Notes', maxLines: 3),
            ]),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_submitting ? 'Saving…' : 'Save prescription', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF008faf))),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _text(
    TextEditingController c,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: _inputDecoration(label, required: required),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _ItemControllers {
  final drug = TextEditingController();
  final form = TextEditingController();
  final strength = TextEditingController();
  final frequency = TextEditingController();
  final route = TextEditingController(text: 'by mouth');
  final duration = TextEditingController();
  final quantity = TextEditingController();
  final refills = TextEditingController(text: '0');
  final instructions = TextEditingController();

  void dispose() {
    drug.dispose();
    form.dispose();
    strength.dispose();
    frequency.dispose();
    route.dispose();
    duration.dispose();
    quantity.dispose();
    refills.dispose();
    instructions.dispose();
  }
}
