// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({Key? key}) : super(key: key);

  @override
  _MyProductsPageState createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String endpoint = '/medical-products';
      if (_searchQuery.isNotEmpty) {
        endpoint += '?search=${Uri.encodeComponent(_searchQuery)}';
      }

      final response = await _authService.authenticatedRequest('GET', endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(data['data']['products'] ?? []);
          });
        }
      } else {
        _showMessage('Failed to load products', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      _showMessage('Error loading products', isError: true);
    }

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadProducts();
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    final confirmed = await _showDeleteConfirmation(productName);
    if (!confirmed) return;

    try {
      final response = await _authService.authenticatedRequest('DELETE', '/medical-products/$productId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showMessage('Product deleted successfully', isError: false);
          await _loadProducts();
        } else {
          _showMessage(data['message'] ?? 'Failed to delete product', isError: true);
        }
      } else {
        _showMessage('Failed to delete product', isError: true);
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      _showMessage('Error deleting product', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String productName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadProducts();
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    return '${ApiConfig.baseUrl}/storage/medical_products/$imagePath';
  }

  String _getAvailabilityColor(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return '0xFF4CAF50'; // Green
      case 'low stock':
        return '0xFFFF9800'; // Orange
      case 'out of stock':
        return '0xFFF44336'; // Red
      case 'unavailable':
        return '0xFF9E9E9E'; // Grey
      default:
        return '0xFF2196F3'; // Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('My Products', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              context.push('/new-medical-product').then((_) => _loadProducts());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                fillColor: Colors.grey.shade100,
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF008faf)))
                : _products.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshProducts,
                        color: Color(0xFF008faf),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No products found' : 'No products yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start by adding your first medical product',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/new-medical-product').then((_) => _loadProducts());
              },
              icon: Icon(Icons.add),
              label: Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008faf),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final String imageUrl = _getImageUrl(product['photo']);
    final String availabilityStatus = product['availability_status'] ?? 'Unknown';
    final bool isExpired = product['is_expired'] ?? false;
    final int daysUntilExpiry = product['days_until_expiry'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/edit-medical-product', extra: product).then((_) => _loadProducts());
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.medical_services, color: Colors.grey.shade400);
                          },
                        ),
                      )
                    : Icon(Icons.medical_services, color: Colors.grey.shade400),
              ),
              SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'Unknown Product',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(int.parse(_getAvailabilityColor(availabilityStatus))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            availabilityStatus,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Batch Number and Cost
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Batch: ${product['batch_no'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Text(
                          product['formatted_cost'] ?? '₱0.00',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008faf),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),

                    // Stock Information
                    Row(
                      children: [
                        Icon(Icons.inventory, size: 14, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Text(
                          'Stock: ${product['stock_quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (product['manufacturer'] != null) ...[
                          SizedBox(width: 16),
                          Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product['manufacturer'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Expiry Warning
                    if (isExpired || (daysUntilExpiry > 0 && daysUntilExpiry <= 30)) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpired ? Icons.error : Icons.warning,
                              size: 14,
                              color: isExpired ? Colors.red : Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isExpired
                                  ? 'Expired'
                                  : 'Expires in $daysUntilExpiry days',
                              style: TextStyle(
                                fontSize: 11,
                                color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                onSelected: (String action) {
                  switch (action) {
                    case 'edit':
                      context.push('/edit-medical-product', extra: product).then((_) => _loadProducts());
                      break;
                    case 'delete':
                      _deleteProduct(
                        product['id'],
                        product['name'] ?? 'Unknown Product',
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}