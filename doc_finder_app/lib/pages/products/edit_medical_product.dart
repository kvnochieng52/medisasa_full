// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class EditMedicalProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditMedicalProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditMedicalProductPageState createState() => _EditMedicalProductPageState();
}

class _EditMedicalProductPageState extends State<EditMedicalProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _batchNoController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _stockQuantityController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _strengthController = TextEditingController();
  final TextEditingController _dosageFormController = TextEditingController();
  final TextEditingController _usageInstructionsController = TextEditingController();
  final TextEditingController _storageConditionsController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _unitOfMeasureController = TextEditingController();
  final TextEditingController _minimumStockLevelController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _categoriesLoading = true;
  bool _subcategoriesLoading = false;
  File? _newProductImage;
  String? _currentImageUrl;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubcategory;
  DateTime? _manufacturingDate;
  DateTime? _expiryDate;
  bool _needsPrescription = false;
  bool _isAvailable = true;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadCategories();
  }

  void _initializeFields() {
    final product = widget.product;

    _nameController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _batchNoController.text = product['batch_no'] ?? '';
    _costController.text = product['cost']?.toString() ?? '';
    _stockQuantityController.text = product['stock_quantity']?.toString() ?? '';
    _manufacturerController.text = product['manufacturer'] ?? '';
    _strengthController.text = product['strength'] ?? '';
    _dosageFormController.text = product['dosage_form'] ?? '';
    _usageInstructionsController.text = product['usage_instructions'] ?? '';
    _storageConditionsController.text = product['storage_conditions'] ?? '';
    _barcodeController.text = product['barcode'] ?? '';
    _weightController.text = product['weight']?.toString() ?? '';
    _unitOfMeasureController.text = product['unit_of_measure'] ?? '';
    _minimumStockLevelController.text = product['minimum_stock_level']?.toString() ?? '';
    _supplierController.text = product['supplier'] ?? '';
    _purchasePriceController.text = product['purchase_price']?.toString() ?? '';

    _needsPrescription = product['needs_prescription'] ?? false;
    _isAvailable = product['is_available'] ?? true;
    _status = product['status'] ?? 'active';

    // Handle dates
    if (product['manufacturing_date'] != null) {
      _manufacturingDate = DateTime.tryParse(product['manufacturing_date']);
    }
    if (product['expiry_date'] != null) {
      _expiryDate = DateTime.tryParse(product['expiry_date']);
    }

    // Handle image
    if (product['photo'] != null && product['photo'].isNotEmpty) {
      _currentImageUrl = '${ApiConfig.baseUrl}/storage/medical_products/${product['photo']}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _batchNoController.dispose();
    _costController.dispose();
    _stockQuantityController.dispose();
    _manufacturerController.dispose();
    _strengthController.dispose();
    _dosageFormController.dispose();
    _usageInstructionsController.dispose();
    _storageConditionsController.dispose();
    _barcodeController.dispose();
    _weightController.dispose();
    _unitOfMeasureController.dispose();
    _minimumStockLevelController.dispose();
    _supplierController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _authService.authenticatedRequest('GET', '/medical-product-categories');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data['data']);
            _categoriesLoading = false;
          });

          // Set selected category if it exists
          if (widget.product['category_id'] != null) {
            final categoryId = widget.product['category_id'];
            try {
              _selectedCategory = _categories.firstWhere(
                (cat) => cat['id'] == categoryId,
              );
            } catch (e) {
              _selectedCategory = null;
            }

            if (_selectedCategory != null) {
              await _loadSubcategories(categoryId);

              // Set selected subcategory if it exists
              if (widget.product['subcategory_id'] != null) {
                final subcategoryId = widget.product['subcategory_id'];
                try {
                  _selectedSubcategory = _subcategories.firstWhere(
                    (subcat) => subcat['id'] == subcategoryId,
                  );
                } catch (e) {
                  _selectedSubcategory = null;
                }
              }
            }
          }
        }
      } else {
        setState(() {
          _categoriesLoading = false;
        });
        _showMessage('Failed to load categories', isError: true);
      }
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
      debugPrint('Error loading categories: $e');
      _showMessage('Error loading categories', isError: true);
    }
  }

  Future<void> _loadSubcategories(int categoryId) async {
    setState(() {
      _subcategoriesLoading = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/medical-product-subcategories?category_id=$categoryId'
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _subcategories = List<Map<String, dynamic>>.from(data['data']);
            _subcategoriesLoading = false;
          });
        }
      } else {
        setState(() {
          _subcategoriesLoading = false;
        });
        _showMessage('Failed to load subcategories', isError: true);
      }
    } catch (e) {
      setState(() {
        _subcategoriesLoading = false;
      });
      debugPrint('Error loading subcategories: $e');
      _showMessage('Error loading subcategories', isError: true);
    }
  }

  Future<void> _updateProduct() async {
    // Validation
    if (_nameController.text.isEmpty ||
        _batchNoController.text.isEmpty ||
        _costController.text.isEmpty ||
        _stockQuantityController.text.isEmpty ||
        _selectedCategory == null) {
      _showMessage('Please fill in all required fields', isError: true);
      return;
    }

    // Validate cost
    double? cost = double.tryParse(_costController.text);
    if (cost == null || cost < 0) {
      _showMessage('Please enter a valid cost', isError: true);
      return;
    }

    // Validate stock quantity
    int? stockQuantity = int.tryParse(_stockQuantityController.text);
    if (stockQuantity == null || stockQuantity < 0) {
      _showMessage('Please enter a valid stock quantity', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'batch_no': _batchNoController.text,
        'category_id': _selectedCategory!['id'],
        'cost': cost,
        'stock_quantity': stockQuantity,
        'needs_prescription': _needsPrescription,
        'is_available': _isAvailable,
        'status': _status,
      };

      // Add optional fields
      if (_selectedSubcategory != null) {
        productData['subcategory_id'] = _selectedSubcategory!['id'];
      }
      if (_manufacturerController.text.isNotEmpty) {
        productData['manufacturer'] = _manufacturerController.text;
      }
      if (_strengthController.text.isNotEmpty) {
        productData['strength'] = _strengthController.text;
      }
      if (_dosageFormController.text.isNotEmpty) {
        productData['dosage_form'] = _dosageFormController.text;
      }
      if (_usageInstructionsController.text.isNotEmpty) {
        productData['usage_instructions'] = _usageInstructionsController.text;
      }
      if (_storageConditionsController.text.isNotEmpty) {
        productData['storage_conditions'] = _storageConditionsController.text;
      }
      if (_barcodeController.text.isNotEmpty) {
        productData['barcode'] = _barcodeController.text;
      }
      if (_weightController.text.isNotEmpty) {
        double? weight = double.tryParse(_weightController.text);
        if (weight != null) productData['weight'] = weight;
      }
      if (_unitOfMeasureController.text.isNotEmpty) {
        productData['unit_of_measure'] = _unitOfMeasureController.text;
      }
      if (_minimumStockLevelController.text.isNotEmpty) {
        int? minStock = int.tryParse(_minimumStockLevelController.text);
        if (minStock != null) productData['minimum_stock_level'] = minStock;
      }
      if (_supplierController.text.isNotEmpty) {
        productData['supplier'] = _supplierController.text;
      }
      if (_purchasePriceController.text.isNotEmpty) {
        double? purchasePrice = double.tryParse(_purchasePriceController.text);
        if (purchasePrice != null) productData['purchase_price'] = purchasePrice;
      }
      if (_manufacturingDate != null) {
        productData['manufacturing_date'] = _manufacturingDate!.toIso8601String().split('T')[0];
      }
      if (_expiryDate != null) {
        productData['expiry_date'] = _expiryDate!.toIso8601String().split('T')[0];
      }

      final response = await _authService.authenticatedMultipartRequest(
        'PUT',
        '/medical-products/${widget.product['id']}',
        fields: productData,
        files: _newProductImage != null ? {'photo': _newProductImage!} : null,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          _showMessage('Medical product updated successfully!', isError: false);

          // Navigate back after successful update
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          String errorMessage = responseData['message'] ?? 'Failed to update product';
          _showMessage(errorMessage, isError: true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to update product';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      _showMessage('Network error. Please check your connection and try again.', isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newProductImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showMessage('Error picking image: $e', isError: true);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isManufacturingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isManufacturingDate
          ? (_manufacturingDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isManufacturingDate) {
          _manufacturingDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Edit Medical Product',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                Text(
                  "Edit Medical Product",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),

                // Basic Information
                _buildTextField("Product Name*", Icons.medical_services, _nameController),
                _buildTextField("Batch Number*", Icons.qr_code, _batchNoController),
                _buildCategoryDropdown(),
                _buildSubcategoryDropdown(),
                _buildTextField("Cost*", Icons.attach_money, _costController, isNumeric: true),
                _buildTextField("Stock Quantity*", Icons.inventory, _stockQuantityController, isNumeric: true),

                // Optional Information
                _buildTextField("Manufacturer", Icons.business, _manufacturerController),
                _buildTextField("Strength", Icons.fitness_center, _strengthController),
                _buildTextField("Dosage Form", Icons.medication, _dosageFormController),
                _buildDateField("Manufacturing Date", _manufacturingDate, true),
                _buildDateField("Expiry Date", _expiryDate, false),

                // Additional Details
                _buildTextField("Barcode", Icons.qr_code_scanner, _barcodeController),
                _buildTextField("Weight", Icons.scale, _weightController, isNumeric: true),
                _buildTextField("Unit of Measure", Icons.straighten, _unitOfMeasureController),
                _buildTextField("Minimum Stock Level", Icons.warning, _minimumStockLevelController, isNumeric: true),
                _buildTextField("Supplier", Icons.local_shipping, _supplierController),
                _buildTextField("Purchase Price", Icons.shopping_cart, _purchasePriceController, isNumeric: true),

                _buildTextAreaField("Storage Conditions", Icons.storage, _storageConditionsController),
                _buildTextAreaField("Usage Instructions", Icons.description, _usageInstructionsController),
                _buildTextAreaField("Description", Icons.notes, _descriptionController),

                // Switches
                _buildSwitchField("Needs Prescription", _needsPrescription, (value) {
                  setState(() {
                    _needsPrescription = value;
                  });
                }),
                _buildSwitchField("Is Available", _isAvailable, (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                }),

                // Status Dropdown
                _buildStatusDropdown(),

                // Image Upload
                SizedBox(height: 20),
                _buildImageUploadSection(),

                SizedBox(height: 30),
                _buildUpdateButton(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumeric = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: controller,
            style: TextStyle(fontSize: 15),
            keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              hintText: label.replaceAll('*', ''),
              suffixIcon: Icon(icon, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField(String label, IconData icon, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: controller,
            style: TextStyle(fontSize: 15),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: label,
              suffixIcon: Icon(icon, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Product Category*',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          if (_categoriesLoading)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                color: Color(0xfff3f3f4),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008faf)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Loading categories...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else if (_categories.isEmpty)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade300),
                color: Colors.orange.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No categories available.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedCategory,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.category, color: Colors.black54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                fillColor: Color(0xfff3f3f4),
                filled: true,
              ),
              hint: Text('Select a category'),
              items: _categories.map((category) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: category,
                  child: Text(category['name'] ?? 'Unknown Category'),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _selectedSubcategory = null;
                });
                if (newValue != null) {
                  _loadSubcategories(newValue['id']);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Product Subcategory',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          if (_subcategoriesLoading)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                color: Color(0xfff3f3f4),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008faf)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Loading subcategories...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedSubcategory,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.subdirectory_arrow_right, color: Colors.black54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                fillColor: Color(0xfff3f3f4),
                filled: true,
              ),
              hint: Text('Select a subcategory (optional)'),
              items: _subcategories.map((subcategory) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: subcategory,
                  child: Text(subcategory['name'] ?? 'Unknown Subcategory'),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  _selectedSubcategory = newValue;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate, bool isManufacturingDate) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () => _selectDate(context, isManufacturingDate),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
                color: Color(0xfff3f3f4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"
                        : "Select $label",
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF008faf),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.info, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
            items: [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'discontinued', child: Text('Discontinued')),
              DropdownMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _status = newValue ?? 'active';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        SizedBox(height: 15),

        if (_newProductImage == null && _currentImageUrl == null)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Color(0xfff3f3f4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                    SizedBox(height: 10),
                    Text('Tap to add product image', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          )
        else
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF008faf), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _newProductImage != null
                      ? Image.file(_newProductImage!, fit: BoxFit.cover)
                      : Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.error, color: Colors.grey.shade400),
                            );
                          },
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _newProductImage = null;
                      _currentImageUrl = null;
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF008faf).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _updateProduct,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.shade200,
              offset: Offset(2, 4),
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _isLoading
                ? [Colors.grey, Colors.grey]
                : [Color(0xFF008faf), Color(0xFF008faf)],
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Updating Product...', style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              )
            : Text('Update Medical Product', style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
    );
  }
}