import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xyvra_health/models/medicine/medicine_model.dart';
import 'package:xyvra_health/models/medicine/medicine_category_model.dart';
import 'package:xyvra_health/models/medical_product/medical_product_model.dart';
import 'package:xyvra_health/services/medicine_service.dart';
import 'package:xyvra_health/services/medical_product_service.dart';
import 'package:xyvra_health/services/cart_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MedicineShopPage extends StatefulWidget {
  const MedicineShopPage({Key? key}) : super(key: key);

  @override
  _MedicineShopPageState createState() => _MedicineShopPageState();
}

class _MedicineShopPageState extends State<MedicineShopPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Medicine> _medicines = [];
  List<MedicalProduct> _medicalProducts = [];
  List<MedicineCategory> _categories = [];
  List<String> _productCategories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  int _currentPage = 1;
  String _searchType = 'name'; // name, symptom, condition
  String? _selectedCategory;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  bool _showMedicalProducts = true; // Toggle between medicines and medical products

  // Prescription upload variables
  File? _selectedPrescriptionFile;
  String? _prescriptionFileName;

  // Consent checkbox variable
  bool _hasConsentedToTerms = false;

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
        _loadMoreMedicines();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_showMedicalProducts) {
        await Future.wait([
          _loadMedicalProducts(reset: true),
          _loadProductCategories(),
        ]);
      } else {
        await Future.wait([
          _loadMedicines(reset: true),
          _loadCategories(),
        ]);
      }
    } catch (e) {
      _showErrorMessage('Failed to load data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMedicines({bool reset = false}) async {
    try {
      if (reset) {
        _currentPage = 1;
        _hasMoreData = true;
      }

      String? searchTerm;
      if (_searchController.text.isNotEmpty) {
        searchTerm = _searchController.text.trim();
      }

      final response = await MedicineService.getMedicines(
        page: _currentPage,
        search: searchTerm,
        categoryId: _selectedCategory != null ? int.tryParse(_selectedCategory!) : null,
        inStock: true,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        if (reset) {
          _medicines = response.medicines;
        } else {
          _medicines.addAll(response.medicines);
        }

        _hasMoreData = response.pagination != null ?
            _currentPage < response.pagination!.lastPage : false;

        if (!reset) {
          _currentPage++;
        }
      });
    } catch (e) {
      _showErrorMessage('Failed to load medicines: $e');
    }
  }

  Future<void> _loadMoreMedicines() async {
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    if (_showMedicalProducts) {
      await _loadMedicalProducts();
    } else {
      await _loadMedicines();
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMedicalProducts({bool reset = false}) async {
    try {
      if (reset) {
        _currentPage = 1;
        _hasMoreData = true;
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
            _medicalProducts = response.data!.products;
          } else {
            _medicalProducts.addAll(response.data!.products);
          }

          _hasMoreData = response.data!.pagination?.hasMorePages ?? false;

          if (!reset) {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to load medical products: $e');
    }
  }

  Future<void> _loadProductCategories() async {
    try {
      final categories = await MedicalProductService.getCategories();
      setState(() {
        _productCategories = categories;
      });
    } catch (e) {
      _showErrorMessage('Failed to load product categories: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await MedicineService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      _showErrorMessage('Failed to load categories: $e');
    }
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _performSearch();
      }
    });
  }

  void _performSearch() {
    setState(() {
      _currentPage = 1;
    });
    if (_showMedicalProducts) {
      _loadMedicalProducts(reset: true);
    } else {
      _loadMedicines(reset: true);
    }
  }

  void _toggleProductType() {
    setState(() {
      _showMedicalProducts = !_showMedicalProducts;
      _selectedCategory = null;
      _currentPage = 1;
    });
    _loadInitialData();
  }

  void _onSearchTypeChanged(String? newType) {
    if (newType != null && newType != _searchType) {
      setState(() {
        _searchType = newType;
      });
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    }
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

  Future<void> _pickPrescriptionFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPrescriptionFile = File(result.files.single.path!);
          _prescriptionFileName = result.files.single.name;
        });
        _showSuccessMessage('Prescription document selected: ${result.files.single.name}');
      }
    } catch (e) {
      _showErrorMessage('Error picking prescription file: $e');
    }
  }

  void _removePrescriptionFile() {
    setState(() {
      _selectedPrescriptionFile = null;
      _prescriptionFileName = null;
    });
  }

  Future<void> _addToCart(dynamic item) async {
    // Check consent first
    if (!_hasConsentedToTerms) {
      _showConsentRequiredDialog();
      return;
    }

    // Check if item requires prescription
    bool requiresPrescription = false;
    if (item is Medicine) {
      requiresPrescription = item.needsPrescription;
    } else if (item is MedicalProduct) {
      requiresPrescription = item.needsPrescription;
    }

    // Only show dialog if prescription is REQUIRED but not uploaded
    // For optional prescriptions, allow adding to cart without prescription
    if (requiresPrescription && _selectedPrescriptionFile == null) {
      _showPrescriptionRequiredDialog(item);
      return;
    }

    try {
      int itemId;
      String itemName;

      if (item is Medicine) {
        itemId = item.id;
        itemName = item.name;
      } else if (item is MedicalProduct) {
        itemId = item.id;
        itemName = item.name;
      } else {
        throw Exception('Invalid item type');
      }

      await CartService.addToCart(
        medicineId: itemId,
        quantity: 1,
      );
      _showSuccessMessage('$itemName added to cart');

      // Clear prescription file after successful add to cart
      if (_selectedPrescriptionFile != null) {
        _removePrescriptionFile();
      }
    } catch (e) {
      _showErrorMessage('Failed to add to cart: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrescriptionRequiredDialog(dynamic item) {
    String itemName = '';
    if (item is Medicine) {
      itemName = item.name;
    } else if (item is MedicalProduct) {
      itemName = item.name;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prescription Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$itemName requires a valid prescription.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please upload your prescription document:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Document must be in PDF format',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      '• Ensure prescription is valid and legible',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      '• Prescription must be from a licensed doctor',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _pickPrescriptionFile();
              },
              icon: Icon(Icons.upload_file, size: 18),
              label: Text('Upload Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008faf),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConsentRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consent Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm your consent before proceeding.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You must confirm that you:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Are 18 years of age or older',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      '• Have read and agreed to our Terms & Conditions',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      '• Understand the responsibility of purchasing medications',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Scroll to consent section (optional UX improvement)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008faf),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('I Understand'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showMedicalProducts ? 'Medical Products' : 'Medicine/Products Shop',
                   style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF008faf),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showMedicalProducts ? Icons.medication : Icons.medical_services),
            onPressed: _toggleProductType,
            tooltip: _showMedicalProducts ? 'Switch to Medicines' : 'Switch to Medical Products',
          ),
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
          _buildProductTypeIndicator(),
          _buildSearchSection(),
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
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
                      hintText: _getSearchHint(),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF008faf)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => _onSearchChanged(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF008faf),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: Colors.white),
                  onPressed: () => _showFilterDialog(),
                ),
              ),
            ],
          ),
          if (!_showMedicalProducts) ...[
            SizedBox(height: 12),
            _buildSearchTypeSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSearchTypeChip('name', 'Name', Icons.medication),
          SizedBox(width: 8),
          _buildSearchTypeChip('symptom', 'Symptom', Icons.healing),
          SizedBox(width: 8),
          _buildSearchTypeChip('condition', 'Condition', Icons.local_hospital),
        ],
      ),
    );
  }

  Widget _buildSearchTypeChip(String type, String label, IconData icon) {
    final isSelected = _searchType == type;
    return GestureDetector(
      onTap: () => _onSearchTypeChanged(type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF008faf) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF008faf) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(
            _showMedicalProducts ? Icons.medical_services : Icons.medication,
            color: Color(0xFF008faf),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            _showMedicalProducts ? 'Medical Products' : 'Medicines',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF008faf),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: _toggleProductType,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF008faf),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Switch to ${_showMedicalProducts ? 'Medicines' : 'Medical Products'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'All Categories',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_showMedicalProducts)
                  ..._productCategories.map((category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
                else
                  ..._categories.map((category) => DropdownMenuItem<String>(
                    value: category.id.toString(),
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
              ],
              onChanged: _onCategoryChanged,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            flex: 1,
            child: Container(
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
                      Icon(Icons.sort, color: Colors.grey[600], size: 18),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Sort',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                PopupMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                PopupMenuItem(value: 'cost_asc', child: Text('Price (Low to High)')),
                PopupMenuItem(value: 'cost_desc', child: Text('Price (High to Low)')),
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
        ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_showMedicalProducts) {
      if (_medicalProducts.isEmpty && !_isLoading) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _medicalProducts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _medicalProducts.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = _medicalProducts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildMedicalProductRowCard(product),
          );
        },
      );
    } else {
      if (_medicines.isEmpty && !_isLoading) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _medicines.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _medicines.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final medicine = _medicines[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildMedicineRowCard(medicine),
          );
        },
      );
    }
  }

  Widget _buildMedicineRowCard(Medicine medicine) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicineImage(medicine),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (medicine.manufacturer != null)
                    Text(
                      'By ${medicine.manufacturer}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    medicine.formattedCost,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008faf),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: medicine.isAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          medicine.availabilityStatus,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (medicine.needsPrescription) ...[
                        SizedBox(width: 8),
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
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (medicine.conditions != null && medicine.conditions!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: medicine.conditions!.take(3).map((condition) =>
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            condition,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton(
                  onPressed: medicine.isAvailable ? () => _addToCart(medicine) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008faf),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showMedicineDetails(medicine),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF008faf),
                      fontSize: 12,
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

  Widget _buildMedicalProductRowCard(MedicalProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicalProductImage(product),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (product.manufacturer != null)
                    Text(
                      'By ${product.manufacturer}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    product.formattedCost,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008faf),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Batch: ${product.batchNo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
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
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (product.isLowStock) ...[
                        SizedBox(width: 4),
                        Icon(Icons.warning, color: Colors.orange, size: 12),
                      ],
                      if (product.needsPrescription) ...[
                        SizedBox(width: 8),
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
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                          fontSize: 10,
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton(
                  onPressed: product.isAvailable && !product.isExpired
                      ? () => _addToCart(product)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008faf),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showMedicalProductDetails(product),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF008faf),
                      fontSize: 12,
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

  Widget _buildMedicineCard(Medicine medicine) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildMedicineImage(medicine)),
            SizedBox(height: 8),
            Text(
              medicine.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (medicine.manufacturer != null) ...[
              SizedBox(height: 4),
              Text(
                'By ${medicine.manufacturer}',
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
              medicine.formattedCost,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008faf),
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: medicine.isAvailable ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                medicine.availabilityStatus,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (medicine.needsPrescription) ...[
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
            Spacer(),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: medicine.isAvailable ? () => _addToCart(medicine) : null,
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
                  onPressed: () => _showMedicineDetails(medicine),
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

  Widget _buildMedicalProductCard(MedicalProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildMedicalProductImage(product)),
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
                  onPressed: () => _showMedicalProductDetails(product),
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

  Widget _buildMedicalProductImage(MedicalProduct product) {
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

  Widget _buildMedicineImage(Medicine medicine) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: medicine.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                medicine.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.medication, color: Colors.grey[400]),
              ),
            )
          : Icon(Icons.medication, color: Colors.grey[400]),
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
            'No medicines found',
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

  String _getSearchHint() {
    if (_showMedicalProducts) {
      return 'Search medical products by name, batch number, or category...';
    } else {
      switch (_searchType) {
        case 'symptom':
          return 'Search by symptom (e.g., headache, fever)';
        case 'condition':
          return 'Search by condition (e.g., diabetes, hypertension)';
        default:
          return 'Search medicine by name';
      }
    }
  }

  void _showFilterDialog() {
    // Show advanced filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advanced Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('More filter options coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(Medicine medicine) {
    // Reset consent and prescription for new item
    setState(() {
      _hasConsentedToTerms = false;
      _selectedPrescriptionFile = null;
      _prescriptionFileName = null;
    });

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
              // Handle bar
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

              // Header with image and basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: medicine.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              medicine.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.medication, color: Colors.grey[400]),
                            ),
                          )
                        : Icon(Icons.medication, color: Colors.grey[400]),
                  ),
                  SizedBox(width: 16),

                  // Medicine info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (medicine.manufacturer != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'By ${medicine.manufacturer}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Text(
                          medicine.formattedCost,
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

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (medicine.description != null) ...[
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(medicine.description!),
                        SizedBox(height: 16),
                      ],
                      if (medicine.conditions != null && medicine.conditions!.isNotEmpty) ...[
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
                          children: medicine.conditions!.map((condition) =>
                            Chip(
                              label: Text(condition),
                              backgroundColor: Colors.blue[50],
                            ),
                          ).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                      // Always show prescription upload section
                      _buildPrescriptionUploadSection(medicine.needsPrescription),
                      SizedBox(height: 16),

                      // Consent checkbox
                      _buildConsentCheckbox(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Fixed Add to Cart button at bottom
              Container(
                padding: EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: medicine.isAvailable && _hasConsentedToTerms ? () {
                      Navigator.pop(context);
                      _addToCart(medicine);
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
                      !medicine.isAvailable ? 'Out of Stock' :
                      !_hasConsentedToTerms ? 'Confirm Consent Required' : 'Add to Cart',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalProductDetails(MedicalProduct product) {
    // Reset consent and prescription for new item
    setState(() {
      _hasConsentedToTerms = false;
      _selectedPrescriptionFile = null;
      _prescriptionFileName = null;
    });

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
                      // Always show prescription upload section
                      SizedBox(height: 16),
                      _buildPrescriptionUploadSection(product.needsPrescription),
                      SizedBox(height: 16),

                      // Consent checkbox
                      _buildConsentCheckbox(),
                    ],
                  ),
                ),
              ),

              // Fixed Add to Cart button at bottom
              Container(
                padding: EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: product.isAvailable && !product.isExpired && _hasConsentedToTerms ? () {
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
                      !product.isAvailable ? 'Out of Stock' :
                      !_hasConsentedToTerms ? 'Confirm Consent Required' : 'Add to Cart',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCheckbox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasConsentedToTerms ? Colors.green[300]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: _hasConsentedToTerms ? Colors.green[600] : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Age & Terms Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _hasConsentedToTerms ? Colors.green[800] : Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasConsentedToTerms = !_hasConsentedToTerms;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: _hasConsentedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _hasConsentedToTerms = value ?? false;
                      });
                    },
                    activeColor: Color(0xFF008faf),
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'I confirm that I am ',
                        ),
                        TextSpan(
                          text: '18+ years old',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008faf),
                          ),
                        ),
                        TextSpan(
                          text: ' and have read and agreed to the ',
                        ),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008faf),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(
                          text: ' for purchasing medications.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_hasConsentedToTerms) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This confirmation is required to proceed with your purchase.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionUploadSection(bool isRequired) {
    final Color primaryColor = isRequired ? Colors.orange[700]! : Colors.blue[700]!;
    final Color backgroundColor = isRequired ? Colors.orange[50]! : Colors.blue[50]!;
    final Color borderColor = isRequired ? Colors.orange[200]! : Colors.blue[200]!;
    final Color textColor = isRequired ? Colors.orange[800]! : Colors.blue[800]!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRequired ? Icons.medical_services : Icons.note_add,
                color: primaryColor,
                size: 20
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRequired ? 'Prescription Required' : 'Prescription Upload (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (!isRequired)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Text(
                    'OPTIONAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            isRequired
              ? 'This medication requires a valid prescription from a licensed physician.'
              : 'Upload your prescription if you have one. This helps us verify your medication needs.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          if (_selectedPrescriptionFile == null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file, size: 32, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'Upload Prescription (PDF)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to select PDF document',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickPrescriptionFile,
                icon: Icon(Icons.upload_file, size: 18),
                label: Flexible(
                  child: Text(
                    'Select Prescription PDF',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008faf),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription Uploaded',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _prescriptionFileName ?? 'Prescription document',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removePrescriptionFile,
                    icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ],
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