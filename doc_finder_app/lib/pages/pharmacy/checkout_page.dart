import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth_service.dart';
import '../../services/local_cart_service.dart';

const _orange = Color(0xFFF97316);

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  State<CheckOutPage> createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  final _cart = LocalCartService.instance;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _notesCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cart.init();
    _cart.addListener(_onChange);
    _prefillFromUser();
  }

  @override
  void dispose() {
    _cart.removeListener(_onChange);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  void _prefillFromUser() {
    try {
      final u = AuthService().user;
      if (u != null) {
        _nameCtrl.text  = u['name']?.toString() ?? '';
        _phoneCtrl.text = u['telephone']?.toString() ?? u['phone']?.toString() ?? '';
      }
    } catch (_) {/* ignore */}
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    _cart.setOrderDetails(OrderDetails(
      fullName: _nameCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
      address:  _addressCtrl.text.trim(),
      city:     _cityCtrl.text.trim(),
      notes:    _notesCtrl.text.trim(),
    ));
    context.push('/checkout/payment');
  }

  @override
  Widget build(BuildContext context) {
    if (_cart.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pharmacy');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildBreadcrumbs(),
            const SizedBox(height: 12),
            _buildContact(),
            const SizedBox(height: 12),
            _buildDeliveryMethod(),
            const SizedBox(height: 12),
            if (_cart.deliveryOption != DeliveryOption.pickup) ...[
              _buildAddress(),
              const SizedBox(height: 12),
            ],
            _buildNotes(),
            const SizedBox(height: 12),
            _buildSummary(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBreadcrumbs() {
    Widget step(String label, {bool active = false, bool past = false}) => Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: active ? FontWeight.bold : FontWeight.w500,
        color: active ? _orange : past ? Colors.grey[700] : Colors.grey[400],
      ),
    );
    Widget sep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
    );
    return Row(children: [step('Cart', past: true), sep(), step('Delivery', active: true), sep(), step('Payment')]);
  }

  // ── Contact ───────────────────────────────────────────────────────────────

  Widget _buildContact() {
    return _sectionCard(
      icon: Icons.person_outline,
      title: 'Contact Details',
      child: Column(
        children: [
          _textField(_nameCtrl, 'Full Name *', 'e.g. John Mwangi',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: 10),
          _textField(_phoneCtrl, 'Phone Number *', '+254 7XX XXX XXX',
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        ],
      ),
    );
  }

  // ── Delivery method ───────────────────────────────────────────────────────

  Widget _buildDeliveryMethod() {
    final options = [
      (DeliveryOption.standard, Icons.local_shipping_outlined, 'Standard Delivery', '1–3 business days'),
      (DeliveryOption.express,  Icons.bolt,                    'Express Delivery',  '2–4 hours'),
      (DeliveryOption.pickup,   Icons.store_outlined,          'Pickup',            'Same day'),
    ];

    double feeFor(DeliveryOption o) {
      if (o == DeliveryOption.pickup) return 0;
      if (o == DeliveryOption.express) return kExpressDeliveryFee;
      return _cart.cartTotal >= kFreeDeliveryThreshold ? 0 : kStandardDeliveryFee;
    }

    return _sectionCard(
      icon: Icons.local_shipping_outlined,
      title: 'Delivery Method',
      child: Column(
        children: options.map((opt) {
          final sel = _cart.deliveryOption == opt.$1;
          final fee = feeFor(opt.$1);
          return GestureDetector(
            onTap: () => _cart.setDeliveryOption(opt.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFFFF3E8) : Colors.white,
                border: Border.all(color: sel ? _orange : Colors.grey[200]!, width: sel ? 1.5 : 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 18, color: sel ? _orange : Colors.grey[400]),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFFFE2C8) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(opt.$2, size: 16, color: sel ? _orange : Colors.grey[600]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.$3, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                            color: sel ? _orange : Colors.grey[800])),
                        Text(opt.$4, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(fee == 0 ? 'Free' : 'KSh ${fee.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                          color: fee == 0 ? Colors.green[700] : Colors.black87)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Address ───────────────────────────────────────────────────────────────

  Widget _buildAddress() {
    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Delivery Address',
      child: Column(
        children: [
          _textField(_addressCtrl, 'Street / Estate *', 'e.g. Westlands, Tom Mboya Street',
              validator: (v) => (_cart.deliveryOption != DeliveryOption.pickup && (v == null || v.trim().isEmpty)) ? 'Required' : null),
          const SizedBox(height: 10),
          _textField(_cityCtrl, 'City / Town', 'e.g. Nairobi'),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotes() {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: 'Order Notes (optional)',
      child: TextFormField(
        controller: _notesCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Special instructions, landmarks, gate code…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  Widget _buildSummary() {
    return _sectionCard(
      icon: Icons.receipt_long,
      title: 'Order Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._cart.items.map((it) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E8), borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: (it.image != null && it.image!.isNotEmpty)
                      ? Image.network(it.image!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(it.type == 'medicine' ? Icons.medication : Icons.inventory_2_outlined, size: 18, color: const Color(0xFFFFB87A)))
                      : Icon(it.type == 'medicine' ? Icons.medication : Icons.inventory_2_outlined, size: 18, color: const Color(0xFFFFB87A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Qty: ${it.quantity}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text('KSh ${(it.price * it.quantity).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
          const Divider(height: 16),
          _kv('Subtotal (${_cart.cartCount})', 'KSh ${_cart.cartTotal.toStringAsFixed(0)}'),
          _kv('Delivery', _cart.deliveryFee == 0 ? 'Free' : 'KSh ${_cart.deliveryFee.toStringAsFixed(0)}',
              valueColor: _cart.deliveryFee == 0 ? Colors.green[700] : null),
          const Divider(height: 16),
          _kv('Total', 'KSh ${_cart.grandTotal.toStringAsFixed(0)}', bold: true, valueColor: _orange),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontSize: bold ? 14 : 12, color: bold ? Colors.black87 : Colors.grey[600],
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(v, style: TextStyle(fontSize: bold ? 15 : 12, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: _orange),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController c, String label, String hint,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue to Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
