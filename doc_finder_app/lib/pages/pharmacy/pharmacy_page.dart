import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/medicine/medicine_model.dart';
import '../../models/medical_product/medical_product_model.dart';
import '../../services/medicine_service.dart';
import '../../services/medical_product_service.dart';
import '../../services/local_cart_service.dart';

const _orange = Color(0xFFF97316);
const _orangeDark = Color(0xFFEA580C);

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({Key? key}) : super(key: key);

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';

  List<Medicine>       _medicines = [];
  List<MedicalProduct> _products  = [];
  bool _loadingMeds = true;
  bool _loadingProds = true;
  String? _medsError;
  String? _prodsError;

  final _cart = LocalCartService.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _cart.init();
    _cart.addListener(_onCartChanged);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    try {
      final res = await MedicineService.getMedicines(perPage: 100);
      if (mounted) setState(() { _medicines = res.medicines; _loadingMeds = false; });
    } catch (e) {
      if (mounted) setState(() { _medsError = e.toString(); _loadingMeds = false; });
    }
    try {
      final res = await MedicalProductService.getMedicalProducts(perPage: 100);
      if (mounted) setState(() { _products = res.data?.products ?? []; _loadingProds = false; });
    } catch (e) {
      if (mounted) setState(() { _prodsError = e.toString(); _loadingProds = false; });
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<Medicine> get _filteredMeds {
    if (_search.trim().isEmpty) return _medicines;
    final q = _search.toLowerCase();
    return _medicines.where((m) =>
      m.name.toLowerCase().contains(q) ||
      (m.category?.name.toLowerCase().contains(q) ?? false) ||
      (m.form?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<MedicalProduct> get _filteredProducts {
    if (_search.trim().isEmpty) return _products;
    final q = _search.toLowerCase();
    return _products.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.category.toLowerCase().contains(q)
    ).toList();
  }

  // ── Add to cart ───────────────────────────────────────────────────────────

  void _addMedicine(Medicine m) {
    _cart.addItem(LocalCartItem(
      id: 'med-${m.id}',
      type: 'medicine',
      name: m.name,
      price: m.cost,
      image: m.image,
      strength: m.strength,
      form: m.form,
      category: m.category?.name,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${m.name} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'View Cart', textColor: Colors.white, onPressed: () => context.push('/cart')),
      ),
    );
  }

  void _addProduct(MedicalProduct p) {
    _cart.addItem(LocalCartItem(
      id: 'prod-${p.id}',
      type: 'product',
      name: p.name,
      price: p.cost,
      image: p.imageUrl,
      category: p.category,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.name} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'View Cart', textColor: Colors.white, onPressed: () => context.push('/cart')),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (_cart.cartCount > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text('${_cart.cartCount}', textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: const Text('Pharmacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_orange, _orangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Medicines & Healthcare Products',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 10),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            decoration: InputDecoration(
                              hintText: 'What are you looking for?',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                              suffixIcon: _search.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tab,
                  labelColor: _orange,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: _orange,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.medication, size: 16),
                      const SizedBox(width: 6),
                      const Text('Medicines'),
                      const SizedBox(width: 4),
                      _countPill(_filteredMeds.length, _tab.index == 0),
                    ])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.inventory_2_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Products'),
                      const SizedBox(width: 4),
                      _countPill(_filteredProducts.length, _tab.index == 1),
                    ])),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _buildMedicinesGrid(),
            _buildProductsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _countPill(int n, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active ? _orange.withValues(alpha: 0.12) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$n', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? _orange : Colors.grey[500])),
    );
  }

  Widget _buildMedicinesGrid() {
    if (_loadingMeds) return const Center(child: CircularProgressIndicator(color: _orange));
    if (_medsError != null) return _buildError(_medsError!);
    final items = _filteredMeds;
    if (items.isEmpty) return _buildEmpty('No medicines found');

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildMedicineCard(items[i]),
    );
  }

  Widget _buildProductsGrid() {
    if (_loadingProds) return const Center(child: CircularProgressIndicator(color: _orange));
    if (_prodsError != null) return _buildError(_prodsError!);
    final items = _filteredProducts;
    if (items.isEmpty) return _buildEmpty('No products found');

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildProductCard(items[i]),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _buildMedicineCard(Medicine m) {
    final inStock = m.quantityAvailable > 0;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _image(m.image),
                if (m.requiresPrescription)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.amber[600], borderRadius: BorderRadius.circular(4)),
                      child: const Text('Rx', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (!inStock)
                  Container(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Out of Stock', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((m.category?.name ?? 'Medicine').toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  if (m.strength != null || m.form != null)
                    Text([m.strength, m.form].where((s) => s != null && s.isNotEmpty).join(' · '),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  const Spacer(),
                  Text('KSh ${m.cost.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: inStock ? () => _addMedicine(m) : null,
                      icon: const Icon(Icons.shopping_cart, size: 13),
                      label: const Text('Add', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        disabledForegroundColor: Colors.grey[400],
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

  Widget _buildProductCard(MedicalProduct p) {
    final inStock = p.stockQuantity > 0 && p.isAvailable;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _image(p.imageUrl),
                if (p.isExpired)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Expired', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (!inStock)
                  Container(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: const Center(
                      child: Text('Out of Stock', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.category.toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  if (p.strength != null && p.strength!.isNotEmpty)
                    Text(p.strength!, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  const Spacer(),
                  Text('KSh ${p.cost.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: (inStock && !p.isExpired) ? () => _addProduct(p) : null,
                      icon: const Icon(Icons.shopping_cart, size: 13),
                      label: const Text('Add', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        disabledForegroundColor: Colors.grey[400],
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

  Widget _image(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFFFFF3E8),
        child: const Center(child: Icon(Icons.medication, size: 30, color: Color(0xFFFFB87A))),
      );
    }
    return Image.network(url, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFFFF3E8),
        child: const Center(child: Icon(Icons.medication, size: 30, color: Color(0xFFFFB87A))),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('Failed to load', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () { setState(() { _loadingMeds = true; _loadingProds = true; _medsError = null; _prodsError = null; }); _load(); },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
