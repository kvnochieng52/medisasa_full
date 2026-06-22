import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/api_config.dart';
import '../../services/local_cart_service.dart';

const _orange = Color(0xFFF97316);

enum _PayState { idle, initiating, polling, timeout, failed, success }
enum _PayMethod { card, mpesa }

const _pollIntervalSec = 5;
const _maxPolls = 36; // ~3 minutes

class PharmacyPaymentPage extends StatefulWidget {
  const PharmacyPaymentPage({Key? key}) : super(key: key);

  @override
  State<PharmacyPaymentPage> createState() => _PharmacyPaymentPageState();
}

class _PharmacyPaymentPageState extends State<PharmacyPaymentPage> {
  final _cart = LocalCartService.instance;
  _PayState  _state  = _PayState.idle;
  _PayMethod _method = _PayMethod.card;
  String?    _transToken;
  String?    _orderRef;
  String?    _paymentUrl;
  int        _pollCount = 0;
  Timer?     _pollTimer;

  @override
  void initState() {
    super.initState();
    _cart.init();
    _cart.addListener(_onChange);
    if (_cart.orderDetails == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/checkout');
      });
    }
  }

  @override
  void dispose() {
    _cart.removeListener(_onChange);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  // ── DPO Pay flow ──────────────────────────────────────────────────────────

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (_) { return null; }
  }

  Future<void> _initiatePayment() async {
    final od = _cart.orderDetails;
    if (od == null) return;

    setState(() => _state = _PayState.initiating);

    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'customer_name':    od.fullName,
        'customer_phone':   od.phone,
        'delivery_address': od.address,
        'delivery_city':    od.city,
        'delivery_option':  deliveryOptionToString(_cart.deliveryOption),
        'notes':            od.notes,
        'items': _cart.items.map((i) => {
          'id':       i.id,
          'type':     i.type,
          'name':     i.name,
          'price':    i.price,
          'quantity': i.quantity,
        }).toList(),
        'subtotal':       _cart.cartTotal,
        'delivery_fee':   _cart.deliveryFee,
        'total':          _cart.grandTotal,
        'payment_method': _method == _PayMethod.card ? 'card' : 'mpesa',
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pharmacy-orders'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'] as Map<String, dynamic>;
          _transToken = data['trans_token']?.toString();
          _orderRef   = data['order_ref']?.toString();
          _paymentUrl = data['payment_url']?.toString();

          if (_paymentUrl != null) {
            final uri = Uri.parse(_paymentUrl!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }

          setState(() { _state = _PayState.polling; _pollCount = 0; });
          _startPolling();
          return;
        }
      }

      final json = jsonDecode(response.body);
      _showError(json['message']?.toString() ?? 'Failed to initiate payment');
      setState(() => _state = _PayState.idle);
    } catch (e) {
      _showError('Network error. Please try again.');
      setState(() => _state = _PayState.idle);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: _pollIntervalSec), (_) async {
      _pollCount++;
      if (!mounted) return;
      setState(() {});

      if (_pollCount >= _maxPolls) {
        _stopPolling();
        setState(() => _state = _PayState.timeout);
        return;
      }

      if (_transToken == null) return;

      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/pharmacy-orders/verify/$_transToken'),
          headers: {'Accept': 'application/json'},
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final status = json['data']?['status']?.toString();
          if (status == 'paid') {
            _orderRef = json['data']?['order_ref']?.toString() ?? _orderRef;
            _stopPolling();
            _cart.clear();
            if (mounted) setState(() => _state = _PayState.success);
          } else if (status == 'failed' || status == 'cancelled') {
            _stopPolling();
            if (mounted) setState(() => _state = _PayState.failed);
          }
        }
      } catch (_) {/* network blip — keep polling */}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _reopenPayment() async {
    if (_paymentUrl == null) return;
    final uri = Uri.parse(_paymentUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _retry() {
    _stopPolling();
    setState(() { _state = _PayState.idle; _transToken = null; _pollCount = 0; });
  }

  void _checkStatus() {
    if (_transToken == null) return;
    setState(() { _state = _PayState.polling; _pollCount = 0; });
    _startPolling();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cart.orderDetails == null) return const SizedBox.shrink();

    if (_state == _PayState.success) return _buildSuccess();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildBreadcrumbs(),
          const SizedBox(height: 12),
          _buildDeliveryRecap(),
          const SizedBox(height: 12),
          _buildPaymentArea(),
          const SizedBox(height: 12),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    Widget step(String label, {bool active = false, bool past = false}) => Text(label,
      style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.w500,
        color: active ? _orange : past ? Colors.grey[700] : Colors.grey[400]));
    Widget sep() => Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]));
    return Row(children: [step('Cart', past: true), sep(), step('Delivery', past: true), sep(), step('Payment', active: true)]);
  }

  Widget _buildDeliveryRecap() {
    final od = _cart.orderDetails!;
    final label = _cart.deliveryOption == DeliveryOption.pickup ? 'Pickup'
                : _cart.deliveryOption == DeliveryOption.express ? 'Express' : 'Standard';
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
              const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (_state == _PayState.idle)
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Edit', style: TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 8),
            Text(od.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(od.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (od.address.isNotEmpty)
              Text('${od.address}${od.city.isNotEmpty ? ", ${od.city}" : ""}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('$label Delivery', style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentArea() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            if (_state == _PayState.idle) _buildIdle(),
            if (_state == _PayState.initiating) _buildInitiating(),
            if (_state == _PayState.polling) _buildPolling(),
            if (_state == _PayState.timeout) _buildTimeout(),
            if (_state == _PayState.failed) _buildFailed(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      children: [
        _paymentMethodTile(_PayMethod.card,  Icons.credit_card,         'Debit / Credit Card', 'Visa, Mastercard — secured via DPO Pay'),
        const SizedBox(height: 8),
        _paymentMethodTile(_PayMethod.mpesa, Icons.phone_android,       'M-Pesa',              'Pay via M-Pesa — secured via DPO Pay'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _initiatePayment,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Pay KSh ${_cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodTile(_PayMethod m, IconData icon, String label, String desc) {
    final sel = _method == m;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
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
              child: Icon(icon, size: 16, color: sel ? _orange : Colors.grey[600]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                      color: sel ? _orange : Colors.grey[800])),
                  Text(desc, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiating() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          CircularProgressIndicator(color: _orange),
          SizedBox(height: 12),
          Text('Opening payment page…', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Please wait while we set up your secure payment.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPolling() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFFFF3E8), shape: BoxShape.circle),
            child: const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _orange, strokeWidth: 3)),
          ),
          const SizedBox(height: 12),
          const Text('Waiting for Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Complete the payment in the browser tab that just opened.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Checking status… ($_pollCount/$_maxPolls)',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _pollCount / _maxPolls,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            minHeight: 4,
          ),
          const SizedBox(height: 10),
          if (_paymentUrl != null)
            TextButton.icon(
              onPressed: _reopenPayment,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Reopen payment page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: _orange),
            ),
          const Text("Don't close this app. We'll confirm automatically.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimeout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.amber[700], size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Taking Longer Than Expected', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('If you completed the payment, tap "Check Status" to confirm. Otherwise retry.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retry,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[300]!)),
                  child: const Text('Try Again', style: TextStyle(color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Check Status'),
                  style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailed() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.close, color: Colors.red[600], size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Payment Failed or Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Your payment was not completed. You can try again.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            ..._cart.items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text('${it.name} × ${it.quantity}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12))),
                  Text('KSh ${(it.price * it.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),
            const Divider(height: 14),
            _kv('Subtotal', 'KSh ${_cart.cartTotal.toStringAsFixed(0)}'),
            _kv('Delivery', _cart.deliveryFee == 0 ? 'Free' : 'KSh ${_cart.deliveryFee.toStringAsFixed(0)}',
                valueColor: _cart.deliveryFee == 0 ? Colors.green[700] : null),
            const Divider(height: 14),
            _kv('Total', 'KSh ${_cart.grandTotal.toStringAsFixed(0)}', bold: true, valueColor: _orange),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.verified_user, size: 14, color: Colors.green[600]),
                const SizedBox(width: 6),
                Expanded(child: Text('Secured payment via DPO Pay.', style: TextStyle(fontSize: 11, color: Colors.grey[700]))),
              ]),
            ),
          ],
        ),
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

  // ── Success ───────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                      child: Icon(Icons.check_circle, size: 50, color: Colors.green[500]),
                    ),
                    const SizedBox(height: 16),
                    const Text('Order Placed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Your payment was successful. We\'ll process your order right away.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                    if (_orderRef != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E8), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long, size: 16, color: _orange),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Reference', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                Text(_orderRef!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _orange)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/pharmacy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Continue Shopping', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
