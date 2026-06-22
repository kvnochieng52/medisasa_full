import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/medicine_service.dart';
import '../../models/medicine/medicine_model.dart';
import '../../models/medicine/medicine_category_model.dart';
import 'create_medicine_page.dart';

class MyMedicinesPage extends StatefulWidget {
  const MyMedicinesPage({Key? key}) : super(key: key);

  @override
  _MyMedicinesPageState createState() => _MyMedicinesPageState();
}

class _MyMedicinesPageState extends State<MyMedicinesPage> {
  List<Medicine> _medicines = [];
  List<MedicineCategory> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  MedicineCategory? _selectedCategory;
  String _selectedStatus = 'all'; // all, active, inactive, low_stock, out_of_stock
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadMedicines();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await MedicineService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _loadMedicines({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _medicines.clear();
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool? inStock;
      if (_selectedStatus == 'in_stock') {
        inStock = true;
      } else if (_selectedStatus == 'out_of_stock') {
        inStock = false;
      }

      final response = await MedicineService.getMedicines(
        page: _currentPage,
        perPage: 15,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategory?.id,
        inStock: inStock,
        sortBy: 'name',
        sortOrder: 'asc',
      );

      setState(() {
        if (refresh) {
          _medicines = response.medicines;
        } else {
          _medicines.addAll(response.medicines);
        }
        _hasMore = response.pagination?.currentPage != null && 
                   response.pagination!.currentPage < response.pagination!.lastPage;
        _isLoading = false;
      });

      // Filter by additional status options
      if (_selectedStatus == 'low_stock') {
        _medicines = _medicines.where((medicine) => 
          medicine.quantityAvailable > 0 && medicine.quantityAvailable <= 5).toList();
      } else if (_selectedStatus == 'active') {
        _medicines = _medicines.where((medicine) => medicine.isActive).toList();
      } else if (_selectedStatus == 'inactive') {
        _medicines = _medicines.where((medicine) => !medicine.isActive).toList();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _loadMedicines();
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "${medicine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MedicineService.deleteMedicine(medicine.id);
        setState(() {
          _medicines.removeWhere((m) => m.id == medicine.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medicine: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCategoryChanged(MedicineCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadMedicines(refresh: true);
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadMedicines(refresh: true);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadMedicines(refresh: true);
  }

  Color _getStatusColor(Medicine medicine) {
    if (!medicine.isActive) return Colors.grey;
    if (medicine.quantityAvailable <= 0) return Colors.red;
    if (medicine.quantityAvailable <= 5) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(Medicine medicine) {
    if (!medicine.isActive) return 'INACTIVE';
    if (medicine.quantityAvailable <= 0) return 'OUT OF STOCK';
    if (medicine.quantityAvailable <= 5) return 'LOW STOCK';
    return 'IN STOCK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/create-medicine');
              if (result != null) {
                _loadMedicines(refresh: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _onSearchChanged();
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Category Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MedicineCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<MedicineCategory>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.name),
                            );
                          }),
                        ],
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                          DropdownMenuItem(value: 'low_stock', child: Text('Low Stock')),
                          DropdownMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
                        ],
                        onChanged: (value) {
                          if (value != null) _onStatusChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Medicine List
          Expanded(
            child: _isLoading && _medicines.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _medicines.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadMedicines(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _medicines.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _medicines.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildMedicineCard(_medicines[index]);
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
            Icons.medication_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your pharmacy inventory!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push('/create-medicine');
              if (result != null) {
                _loadMedicines(refresh: true);
              }
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Your First Medicine', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(medicine),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(medicine),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await context.push('/edit-medicine', extra: medicine);
                      if (result != null) {
                        _loadMedicines(refresh: true);
                      }
                    } else if (value == 'delete') {
                      _deleteMedicine(medicine);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Medicine Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine Image
                if (medicine.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      medicine.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.medication, color: Colors.grey),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication, color: Colors.grey),
                  ),
                
                const SizedBox(width: 16),
                
                // Medicine Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Name
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Medicine Number
                      Text(
                        'MED#: ${medicine.medicineNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category
                      if (medicine.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            medicine.category!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Price and Stock
                      Row(
                        children: [
                          Text(
                            medicine.formattedCost,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Stock: ${medicine.quantityAvailable}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Additional Info
            if (medicine.manufacturer != null || medicine.strength != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (medicine.manufacturer != null) ...[
                    Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      medicine.manufacturer!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (medicine.manufacturer != null && medicine.strength != null)
                    const SizedBox(width: 16),
                  if (medicine.strength != null) ...[
                    Icon(Icons.science, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      medicine.strength!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Prescription requirement
            if (medicine.requiresPrescription) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Prescription Required',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}