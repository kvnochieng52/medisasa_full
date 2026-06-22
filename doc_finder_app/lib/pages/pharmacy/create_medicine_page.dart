import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/medicine_service.dart';
import '../../models/medicine/medicine_model.dart';
import '../../models/medicine/medicine_category_model.dart';
import '../../auth_service.dart';

class CreateMedicinePage extends StatefulWidget {
  final Medicine? medicine; // For editing existing medicine
  
  const CreateMedicinePage({Key? key, this.medicine}) : super(key: key);

  @override
  _CreateMedicinePageState createState() => _CreateMedicinePageState();
}

class _CreateMedicinePageState extends State<CreateMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicineNumberController = TextEditingController();
  final _costController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _strengthController = TextEditingController();
  final _formController = TextEditingController();
  final _quantityController = TextEditingController();
  final _conditionsController = TextEditingController();
  
  bool _requiresPrescription = false;
  File? _medicineImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  List<MedicineCategory> _categories = [];
  List<MedicineSubcategory> _subcategories = [];
  MedicineCategory? _selectedCategory;
  MedicineSubcategory? _selectedSubcategory;

  // Facility selection
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _facilities = [];
  Map<String, dynamic>? _selectedFacility;
  bool _isLoadingFacilities = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFacilities();
    if (widget.medicine != null) {
      _initializeWithMedicine(widget.medicine!);
    } else {
      _quantityController.text = '0';
      _costController.text = '0.00';
    }
  }

  void _initializeWithMedicine(Medicine medicine) {
    _nameController.text = medicine.name;
    _descriptionController.text = medicine.description ?? '';
    _medicineNumberController.text = medicine.medicineNumber;
    _costController.text = medicine.cost.toString();
    _manufacturerController.text = medicine.manufacturer ?? '';
    _strengthController.text = medicine.strength ?? '';
    _formController.text = medicine.form ?? '';
    _quantityController.text = medicine.quantityAvailable.toString();
    _conditionsController.text = medicine.conditions?.join(', ') ?? '';
    _requiresPrescription = medicine.requiresPrescription;
    _existingImageUrl = medicine.imageUrl.isNotEmpty ? medicine.imageUrl : null;
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await MedicineService.getCategories();
      setState(() {
        _categories = categories;
        if (widget.medicine != null) {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == widget.medicine!.categoryId,
            orElse: () => categories.first,
          );
          _loadSubcategories(_selectedCategory!.id);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoadingFacilities = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/facilities',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _facilities = List<Map<String, dynamic>>.from(responseData['data']);
            // Auto-select first facility if available
            if (_facilities.isNotEmpty && _selectedFacility == null) {
              _selectedFacility = _facilities.first;
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load facilities')),
        );
      }
    } catch (e) {
      debugPrint('Error loading facilities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error loading facilities')),
      );
    }

    setState(() {
      _isLoadingFacilities = false;
    });
  }

  Future<void> _loadSubcategories(int categoryId) async {
    try {
      final subcategories = await MedicineService.getSubcategories(categoryId);
      setState(() {
        _subcategories = subcategories;
        if (widget.medicine != null && widget.medicine!.subcategoryId != null) {
          try {
            _selectedSubcategory = subcategories.firstWhere(
              (sub) => sub.id == widget.medicine!.subcategoryId,
            );
          } catch (e) {
            _selectedSubcategory = subcategories.isNotEmpty ? subcategories.first : null;
          }
        } else {
          _selectedSubcategory = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subcategories: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _medicineImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a facility')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final conditions = _conditionsController.text
          .split(',')
          .map((condition) => condition.trim())
          .where((condition) => condition.isNotEmpty)
          .toList();

      Medicine savedMedicine;
      
      if (widget.medicine == null) {
        // Create new medicine
        savedMedicine = await MedicineService.createMedicine(
          name: _nameController.text,
          description: _descriptionController.text,
          medicineNumber: _medicineNumberController.text,
          cost: double.parse(_costController.text),
          categoryId: _selectedCategory!.id,
          subcategoryId: _selectedSubcategory?.id,
          manufacturer: _manufacturerController.text,
          strength: _strengthController.text,
          form: _formController.text,
          quantityAvailable: int.parse(_quantityController.text),
          requiresPrescription: _requiresPrescription,
          conditions: conditions.isNotEmpty ? conditions : null,
          image: _medicineImage,
        );
      } else {
        // Update existing medicine
        savedMedicine = await MedicineService.updateMedicine(
          id: widget.medicine!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          medicineNumber: _medicineNumberController.text,
          cost: double.parse(_costController.text),
          categoryId: _selectedCategory!.id,
          subcategoryId: _selectedSubcategory?.id,
          manufacturer: _manufacturerController.text,
          strength: _strengthController.text,
          form: _formController.text,
          quantityAvailable: int.parse(_quantityController.text),
          requiresPrescription: _requiresPrescription,
          conditions: conditions.isNotEmpty ? conditions : null,
          image: _medicineImage,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medicine == null ? 'Medicine created successfully!' : 'Medicine updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            // Navigate to my medicines page instead of just popping
            context.push('/my-medicines');
          }
        });
      }
    } catch (e) {
      print('=== MEDICINE CREATION ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: ${e.toString()}');
      print('==============================');
      
      if (mounted) {
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Validation Error'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(e.toString()),
                    const SizedBox(height: 16),
                    Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Name: ${_nameController.text}'),
                    Text('Medicine Number: ${_medicineNumberController.text}'),
                    Text('Cost: ${_costController.text}'),
                    Text('Category ID: ${_selectedCategory?.id}'),
                    Text('Subcategory ID: ${_selectedSubcategory?.id}'),
                    Text('Quantity: ${_quantityController.text}'),
                    Text('Requires Prescription: $_requiresPrescription'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed - check console for details'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Error Details'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _medicineNumberController.dispose();
    _costController.dispose();
    _manufacturerController.dispose();
    _strengthController.dispose();
    _formController.dispose();
    _quantityController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Add Medicine' : 'Edit Medicine'),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            TextButton(
              onPressed: _saveMedicine,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medicine Image',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _medicineImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _medicineImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                SizedBox(height: 8),
                                                Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Tap to add medicine image', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Medicine Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medicine name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Medicine Number
                      TextFormField(
                        controller: _medicineNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Number *',
                          hintText: 'Unique identifier for the medicine',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medicine number';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the medicine',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Cost
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost (KSh) *',
                          border: OutlineInputBorder(),
                          prefixText: 'KSh ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter cost';
                          }
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Please enter a valid cost';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category and Subcategory
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      DropdownButtonFormField<MedicineCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                            _selectedSubcategory = null;
                            _subcategories = [];
                          });
                          if (category != null) {
                            _loadSubcategories(category.id);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subcategory Dropdown
                      DropdownButtonFormField<MedicineSubcategory>(
                        value: _selectedSubcategory,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          border: OutlineInputBorder(),
                        ),
                        items: _subcategories.map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory.name),
                          );
                        }).toList(),
                        onChanged: (subcategory) {
                          setState(() {
                            _selectedSubcategory = subcategory;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Facility Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Facility',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Facility Dropdown
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedFacility,
                        decoration: const InputDecoration(
                          labelText: 'Select Facility *',
                          hintText: 'Choose the facility for this medicine',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        isExpanded: true,
                        items: _facilities.map((facility) {
                          return DropdownMenuItem(
                            value: facility,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  facility['facility_name'] ?? 'Unknown Facility',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (facility['facility_location'] != null)
                                  Text(
                                    facility['facility_location'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (facility) {
                          setState(() {
                            _selectedFacility = facility;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a facility';
                          }
                          return null;
                        },
                      ),

                      if (_isLoadingFacilities) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading facilities...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_facilities.isEmpty && !_isLoadingFacilities) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                   size: 16,
                                   color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No facilities found. Please create a facility first.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Additional Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Manufacturer
                      TextFormField(
                        controller: _manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Strength and Form in a row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _strengthController,
                              decoration: const InputDecoration(
                                labelText: 'Strength',
                                hintText: 'e.g., 500mg',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _formController,
                              decoration: const InputDecoration(
                                labelText: 'Form',
                                hintText: 'e.g., Tablet',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quantity Available
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Available *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null || int.parse(value) < 0) {
                            return 'Please enter a valid quantity';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Conditions
                      TextFormField(
                        controller: _conditionsController,
                        decoration: const InputDecoration(
                          labelText: 'Conditions Treated',
                          hintText: 'Separate with commas (e.g., headache, fever, pain)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Requires Prescription Switch
                      SwitchListTile(
                        title: const Text('Requires Prescription'),
                        subtitle: const Text('Check if this medicine requires a prescription'),
                        value: _requiresPrescription,
                        onChanged: (value) {
                          setState(() {
                            _requiresPrescription = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button (Bottom)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.medicine == null ? 'Create Medicine' : 'Update Medicine',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}