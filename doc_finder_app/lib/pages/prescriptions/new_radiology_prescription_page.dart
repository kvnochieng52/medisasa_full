import 'package:flutter/material.dart';

import '../../models/prescription.dart';
import '../../services/prescription_service.dart';
import 'radiology_prescription_detail_page.dart';

class NewRadiologyPrescriptionPage extends StatefulWidget {
  final int? appointmentId;
  final String? patientName;
  final String? patientEmail;
  final String? patientPhone;

  const NewRadiologyPrescriptionPage({
    Key? key,
    this.appointmentId,
    this.patientName,
    this.patientEmail,
    this.patientPhone,
  }) : super(key: key);

  @override
  State<NewRadiologyPrescriptionPage> createState() => _NewRadiologyPrescriptionPageState();
}

class _NewRadiologyPrescriptionPageState extends State<NewRadiologyPrescriptionPage> {
  static const _rose = Color(0xFFf43f5e);

  final _formKey = GlobalKey<FormState>();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _patientName = TextEditingController();
  final _patientEmail = TextEditingController();
  final _patientPhone = TextEditingController();
  final _patientAge = TextEditingController();
  final _clinicalInfo = TextEditingController();
  final _notes = TextEditingController();
  String? _patientDob;
  String _patientSex = '';

  final List<_RadItemControllers> _items = [_RadItemControllers()];

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
    _clinicalInfo.dispose();
    _notes.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_RadItemControllers()));
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
      setState(() => _patientDob =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final items = _items
          .map((c) => RadiologyItem(
                studyName: c.study.text.trim(),
                modality: c.modality.isEmpty ? null : c.modality,
                bodyPart: c.bodyPart.text.trim().isEmpty ? null : c.bodyPart.text.trim(),
                side: c.side.isEmpty ? null : c.side,
                contrast: c.contrast,
                urgency: c.urgency,
                clinicalIndication:
                    c.indication.text.trim().isEmpty ? null : c.indication.text.trim(),
                notes: c.notes.text.trim().isEmpty ? null : c.notes.text.trim(),
              ))
          .toList();

      final rx = await PrescriptionService.createRadiology(
        appointmentId: widget.appointmentId,
        clinicName: _clinicName.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        patientName: _patientName.text.trim(),
        patientEmail: _patientEmail.text.trim(),
        patientPhone: _patientPhone.text.trim(),
        patientDob: _patientDob,
        patientAge: int.tryParse(_patientAge.text.trim()),
        patientSex: _patientSex.isEmpty ? null : _patientSex,
        clinicalInformation: _clinicalInfo.text.trim(),
        notes: _notes.text.trim(),
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Radiology order saved')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RadiologyPrescriptionDetailPage(prescriptionId: rx.id)),
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
        title: const Text('New Radiology Order', style: TextStyle(color: Colors.white)),
        backgroundColor: _rose,
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
                        child: Text(_patientDob ?? 'Tap to pick',
                            style: const TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _text(_patientAge, 'Age', keyboard: TextInputType.number)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: DropdownButtonFormField<String>(
                  initialValue: _patientSex.isEmpty ? null : _patientSex,
                  decoration: _inputDecoration('Sex'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _patientSex = v ?? ''),
                ),
              ),
            ]),
            _section('Clinical information', [
              _text(_clinicalInfo, 'Reason / clinical info', maxLines: 3),
            ]),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Studies',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
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
                        Text('#${i + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Spacer(),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () => _removeItem(i),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          ),
                      ],
                    ),
                    _text(c.study, 'Study name (e.g. Chest X-Ray)', required: true),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DropdownButtonFormField<String>(
                        initialValue: c.modality.isEmpty ? null : c.modality,
                        decoration: _inputDecoration('Modality'),
                        items: const [
                          DropdownMenuItem(value: 'X-Ray', child: Text('X-Ray')),
                          DropdownMenuItem(value: 'CT', child: Text('CT')),
                          DropdownMenuItem(value: 'MRI', child: Text('MRI')),
                          DropdownMenuItem(value: 'Ultrasound', child: Text('Ultrasound')),
                          DropdownMenuItem(value: 'Mammogram', child: Text('Mammogram')),
                          DropdownMenuItem(value: 'PET', child: Text('PET')),
                          DropdownMenuItem(value: 'DEXA', child: Text('DEXA')),
                          DropdownMenuItem(value: 'Fluoroscopy', child: Text('Fluoroscopy')),
                        ],
                        onChanged: (v) => setState(() => c.modality = v ?? ''),
                      ),
                    ),
                    _text(c.bodyPart, 'Body part / region'),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DropdownButtonFormField<String>(
                        initialValue: c.side.isEmpty ? null : c.side,
                        decoration: _inputDecoration('Side'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Not specified')),
                          DropdownMenuItem(value: 'left', child: Text('Left')),
                          DropdownMenuItem(value: 'right', child: Text('Right')),
                          DropdownMenuItem(value: 'bilateral', child: Text('Bilateral')),
                        ],
                        onChanged: (v) => setState(() => c.side = v ?? ''),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DropdownButtonFormField<String>(
                        initialValue: c.contrast,
                        decoration: _inputDecoration('Contrast'),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('No contrast')),
                          DropdownMenuItem(value: 'with', child: Text('With contrast')),
                          DropdownMenuItem(value: 'without', child: Text('Without contrast')),
                          DropdownMenuItem(value: 'oral', child: Text('Oral contrast')),
                        ],
                        onChanged: (v) => setState(() => c.contrast = v ?? 'none'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DropdownButtonFormField<String>(
                        initialValue: c.urgency,
                        decoration: _inputDecoration('Urgency'),
                        items: const [
                          DropdownMenuItem(value: 'routine', child: Text('Routine')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                          DropdownMenuItem(value: 'stat', child: Text('STAT')),
                        ],
                        onChanged: (v) => setState(() => c.urgency = v ?? 'routine'),
                      ),
                    ),
                    _text(c.indication, 'Clinical indication', maxLines: 2),
                    _text(c.notes, 'Notes', maxLines: 2),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add study'),
            ),
            const SizedBox(height: 16),
            _section('Additional notes', [
              _text(_notes, 'Notes', maxLines: 3),
            ]),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_submitting ? 'Saving…' : 'Save radiology order',
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose,
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFFf43f5e))),
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

class _RadItemControllers {
  final study = TextEditingController();
  String modality = '';
  final bodyPart = TextEditingController();
  String side = '';
  String contrast = 'none';
  String urgency = 'routine';
  final indication = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    study.dispose();
    bodyPart.dispose();
    indication.dispose();
    notes.dispose();
  }
}
