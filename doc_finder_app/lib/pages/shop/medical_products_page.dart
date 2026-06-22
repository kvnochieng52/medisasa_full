import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xyvra_health/models/medical_product/medical_product_model.dart';
import 'package:xyvra_health/services/medical_product_service.dart';
import 'package:xyvra_health/services/cart_service.dart';

class MedicalProductsPage extends StatefulWidget {
  const MedicalProductsPage({Key? key}) : super(key: key);

  @override
  _MedicalProductsPageState createState() => _MedicalProductsPageState();
}

class _MedicalProductsPageState extends State<MedicalProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MedicalProduct> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  int _currentPage = 1;
  String? _selectedCategory;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _lastSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadProducts(reset: true),
        _loadCategories(),
      ]);
    } catch (e) {
      _showErrorMessage('Failed to load data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    try {
      if (reset) {
        _currentPage = 1;
        _hasMoreData = true;
      } else {
        _currentPage++;
      }

      String? searchTerm;
      if (_searchController.text.isNotEmpty) {
        searchTerm = _searchController.text.trim();
      }

      final response = await MedicalProductService.getAvailableProducts(
        page: _currentPage,
        search: searchTerm,
        category: _selectedCategory,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (reset) {
            _products = response.data!.products;
          } else {
            _products.addAll(response.data!.products);
          }

          _hasMoreData = response.data!.pagination?.hasMorePages ?? false;
        });
      } else {
        _showErrorMessage(response.message);
      }
    } catch (e) {
      _showErrorMessage('Failed to load products: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    setState(() {
      _isLoadingMore = true;
    });

    await _loadProducts();

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await MedicalProductService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      _showErrorMessage('Failed to load categories: $e');
    }
  }

  void _onSearchChanged() {
    // Debounce search
    final currentText = _searchController.text;
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && _searchController.text == currentText && currentText != _lastSearchTerm) {
        _lastSearchTerm = currentText;
        _performSearch();
      }
    });
  }

  void _performSearch() {
    _loadProducts(reset: true);
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    _performSearch();
  }

  void _onSortChanged() {
    _performSearch();
  }

  Future<void> _addToCart(MedicalProduct product) async {
    try {
      await CartService.addToCart(
        medicineId: product.id,
        quantity: 1,
      );
      _showSuccessMessage('${product.name} added to cart');
    } catch (e) {
      _showErrorMessage('Failed to add to cart: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF008faf),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              context.go('/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medical products...',
            prefixIcon: Icon(Icons.search, color: Color(0xFF008faf)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (_) => _onSearchChanged(),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                )),
              ],
              onChanged: _onCategoryChanged,
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('Sort', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                PopupMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                PopupMenuItem(value: 'cost_asc', child: Text('Price (Low to High)')),
                PopupMenuItem(value: 'cost_desc', child: Text('Price (High to Low)')),
                PopupMenuItem(value: 'stock_quantity_desc', child: Text('Stock (High to Low)')),
                PopupMenuItem(value: 'expiry_date_asc', child: Text('Expiry Date (Soon to Late)')),
              ],
              onSelected: (value) {
                final parts = value.split('_');
                setState(() {
                  _sortBy = parts[0];
                  _sortOrder = parts[1];
                });
                _onSortChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(MedicalProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProductImage(product)),
            SizedBox(height: 8),
            Text(
              product.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (product.manufacturer != null) ...[
              SizedBox(height: 4),
              Text(
                'By ${product.manufacturer}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4),
            Text(
              product.formattedCost,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008faf),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Batch: ${product.batchNo}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.availabilityStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (product.isLowStock) ...[
                  SizedBox(width: 4),
                  Icon(Icons.warning, color: Colors.orange, size: 12),
                ],
              ],
            ),
            if (product.needsPrescription) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Prescription Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (product.isExpired) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (product.isExpiringSoon) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Expiring Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            Spacer(),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: product.isAvailable && !product.isExpired
                        ? () => _addToCart(product)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008faf),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showProductDetails(product),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF008faf),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(MedicalProduct product) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: product.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.medical_services, color: Colors.grey[400]),
              ),
            )
          : Icon(Icons.medical_services, color: Colors.grey[400]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(MedicalProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.medical_services, color: Colors.grey[400]),
                            ),
                          )
                        : Icon(Icons.medical_services, color: Colors.grey[400]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.manufacturer != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'By ${product.manufacturer}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Text(
                          product.formattedCost,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008faf),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Batch Number', product.batchNo),
                      _buildDetailRow('Category', product.category),
                      if (product.stockQuantity > 0)
                        _buildDetailRow('Stock', '${product.stockQuantity} ${product.unitOfMeasure}'),
                      if (product.dosageForm != null)
                        _buildDetailRow('Dosage Form', product.dosageForm!),
                      if (product.strength != null)
                        _buildDetailRow('Strength', product.strength!),
                      if (product.expiryDate != null)
                        _buildDetailRow('Expiry Date', '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}'),
                      if (product.description != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(product.description!),
                      ],
                      if (product.conditions != null && product.conditions!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Treats Conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.conditions!.map((condition) =>
                            Chip(
                              label: Text(condition),
                              backgroundColor: Colors.blue[50],
                            ),
                          ).toList(),
                        ),
                      ],
                      if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: product.ingredients!.map((ingredient) =>
                            Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text('• $ingredient'),
                            ),
                          ).toList(),
                        ),
                      ],
                      if (product.usageInstructions != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Usage Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(product.usageInstructions!),
                      ],
                      if (product.storageConditions != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Storage Conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(product.storageConditions!),
                      ],
                      if (product.sideEffects != null && product.sideEffects!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Side Effects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: product.sideEffects!.map((effect) =>
                            Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text('• $effect'),
                            ),
                          ).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: product.isAvailable && !product.isExpired ? () {
                    Navigator.pop(context);
                    _addToCart(product);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008faf),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    product.isExpired ? 'Expired Product' :
                    !product.isAvailable ? 'Out of Stock' : 'Add to Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}