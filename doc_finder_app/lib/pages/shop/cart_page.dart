import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_cart_service.dart';

const _orange = Color(0xFFF97316);

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _cart = LocalCartService.instance;

  @override
  void initState() {
    super.initState();
    _cart.init();
    _cart.addListener(_onChange);
  }

  @override
  void dispose() {
    _cart.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _cart.clear(); },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Your Cart${_cart.cartCount > 0 ? " (${_cart.cartCount})" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (items.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: _confirmClear),
        ],
      ),
      body: items.isEmpty ? _buildEmpty() : _buildCart(items),
      bottomNavigationBar: items.isEmpty ? null : _buildBottomBar(),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            Text('Add medicines or healthcare products to get started.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/pharmacy'),
              icon: const Icon(Icons.medication, size: 16),
              label: const Text('Browse Pharmacy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cart list ─────────────────────────────────────────────────────────────

  Widget _buildCart(List<LocalCartItem> items) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...items.map((it) => _buildCartItem(it)).toList(),
        const SizedBox(height: 8),
        _buildDeliveryOptions(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCartItem(LocalCartItem item) {
    final isMed = item.type == 'medicine';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: (item.image != null && item.image!.isNotEmpty)
                  ? Image.network(item.image!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(isMed ? Icons.medication : Icons.inventory_2_outlined, color: const Color(0xFFFFB87A)))
                  : Icon(isMed ? Icons.medication : Icons.inventory_2_outlined, color: const Color(0xFFFFB87A)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.category != null)
                              Text(item.category!.toUpperCase(),
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
                            Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            if (item.strength != null || item.form != null)
                              Text([item.strength, item.form].where((s) => s != null && s.isNotEmpty).join(' · '),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 18),
                        onPressed: () => _cart.removeItem(item.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Quantity stepper
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove, () => _cart.updateQuantity(item.id, item.quantity - 1)),
                            SizedBox(
                              width: 26,
                              child: Text('${item.quantity}', textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            _qtyBtn(Icons.add, () => _cart.updateQuantity(item.id, item.quantity + 1)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('KSh ${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          if (item.quantity > 1)
                            Text('KSh ${item.price.toStringAsFixed(0)} each',
                                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 13, color: Colors.grey[700]),
      ),
    );
  }

  // ── Delivery options ──────────────────────────────────────────────────────

  Widget _buildDeliveryOptions() {
    final options = [
      (DeliveryOption.standard, Icons.local_shipping_outlined, 'Standard Delivery',
        'KSh ${kStandardDeliveryFee.toStringAsFixed(0)} · Free above KSh ${kFreeDeliveryThreshold.toStringAsFixed(0)}'),
      (DeliveryOption.express, Icons.bolt, 'Express Delivery',
        'KSh ${kExpressDeliveryFee.toStringAsFixed(0)} · Within 2–4 hours'),
      (DeliveryOption.pickup, Icons.store_outlined, 'Pickup',
        'Free · Collect at our pharmacy'),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.local_shipping_outlined, size: 16, color: _orange),
              SizedBox(width: 6),
              Text('Delivery Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 10),
            ...options.map((opt) {
              final sel = _cart.deliveryOption == opt.$1;
              final isStandard = opt.$1 == DeliveryOption.standard;
              final free = isStandard && _cart.cartTotal >= kFreeDeliveryThreshold;
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
                      if (free)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
                          child: Text('Free!', style: TextStyle(color: Colors.green[700], fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (_cart.deliveryOption == DeliveryOption.standard && _cart.cartTotal < kFreeDeliveryThreshold)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Add KSh ${(kFreeDeliveryThreshold - _cart.cartTotal).toStringAsFixed(0)} more for free delivery.',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom checkout bar ───────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal (${_cart.cartCount})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text('KSh ${_cart.cartTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(_cart.deliveryFee == 0 ? 'Free' : 'KSh ${_cart.deliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _cart.deliveryFee == 0 ? Colors.green[700] : Colors.black87)),
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('KSh ${_cart.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _orange)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Proceed to Checkout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
