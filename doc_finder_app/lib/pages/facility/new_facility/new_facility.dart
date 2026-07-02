// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class NewFacilityPage extends StatefulWidget {
  const NewFacilityPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _NewFacilityPageState createState() => _NewFacilityPageState();
}

class _NewFacilityPageState extends State<NewFacilityPage> {
  final TextEditingController _facilityNameController = TextEditingController();
  final TextEditingController _facilityProfileController =
      TextEditingController();
  final TextEditingController _facilityEmailController =
      TextEditingController();
  final TextEditingController _facilityPhoneController =
      TextEditingController();
  final TextEditingController _facilityLocationController =
      TextEditingController();
  final TextEditingController _facilityWebsiteController =
      TextEditingController();
  final TextEditingController _facilityNumberController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingFacilityServices = false;
  bool _isLoadingFacilityTypes = false;
  bool _isLoadingFacilityLevels = false;
  bool _isLoadingInsurances = false;
  // Catalogue of services (reference list) the SP picks from.
  List<Map<String, dynamic>> _facilityServices = [];
  // Services the SP has added to THIS facility (with title/description/amount).
  List<Map<String, dynamic>> _offeredServices = [];
  List<Map<String, dynamic>> _facilityTypes = [];
  List<Map<String, dynamic>> _facilityLevels = [];
  List<Map<String, dynamic>> _insurances = [];

  // Facility type and level fields
  int? _selectedFacilityTypeId;
  int? _selectedFacilityLevelId;

  // Insurance fields
  bool _acceptsInsurance = false;
  List<int> _selectedInsuranceIds = [];



  File? _logoImage;
  File? _coverImage;

  @override
  void initState() {
    super.initState();
    _loadFacilityServices();
    _loadFacilityTypes();
    _loadFacilityLevels();
    _loadInsurances();
  }

  @override
  void dispose() {
    _facilityNameController.dispose();
    _facilityProfileController.dispose();
    _facilityEmailController.dispose();
    _facilityPhoneController.dispose();
    _facilityLocationController.dispose();
    _facilityWebsiteController.dispose();
    _facilityNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadFacilityServices() async {
    setState(() {
      _isLoadingFacilityServices = true;
    });

    // /facility-services is a public endpoint — call it directly instead of
    // via authenticatedRequest so a stale/missing token doesn't block loading.
    final url = '${ApiConfig.baseUrl}/facility-services';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('facility-services GET $url -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _facilityServices =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        } else {
          _showMessage(
              'Services list returned no data (${responseData['message'] ?? 'unknown'})',
              isError: true);
        }
      } else {
        _showMessage('Failed to load services (HTTP ${response.statusCode})',
            isError: true);
      }
    } catch (e) {
      debugPrint('Error loading facility services from $url: $e');
      _showMessage('Network error loading services: $e', isError: true);
    }

    setState(() {
      _isLoadingFacilityServices = false;
    });
  }

  Future<void> _loadFacilityTypes() async {
    setState(() {
      _isLoadingFacilityTypes = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facility-types'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _facilityTypes =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showMessage('Failed to load facility types', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading facility types: $e');
      _showMessage('Network error loading facility types', isError: true);
    }

    setState(() {
      _isLoadingFacilityTypes = false;
    });
  }

  Future<void> _loadFacilityLevels() async {
    setState(() {
      _isLoadingFacilityLevels = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facility-levels'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _facilityLevels =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showMessage('Failed to load facility levels', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading facility levels: $e');
      _showMessage('Network error loading facility levels', isError: true);
    }

    setState(() {
      _isLoadingFacilityLevels = false;
    });
  }

  Future<void> _loadInsurances() async {
    setState(() {
      _isLoadingInsurances = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/insurances'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _insurances =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showMessage('Failed to load insurances', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading insurances: $e');
      _showMessage('Network error loading insurances', isError: true);
    }

    setState(() {
      _isLoadingInsurances = false;
    });
  }

  Future<void> _createFacility() async {
    if (_facilityNameController.text.isEmpty ||
        _facilityProfileController.text.isEmpty ||
        _facilityEmailController.text.isEmpty ||
        _facilityPhoneController.text.isEmpty ||
        _facilityLocationController.text.isEmpty ||
        _selectedFacilityTypeId == null) {
      _showMessage('Please fill in all required fields', isError: true);
      return;
    }

    // Check if hospital level is required for hospitals
    final selectedFacilityType = _facilityTypes.firstWhere(
      (type) => type['id'] == _selectedFacilityTypeId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedFacilityType.isNotEmpty &&
        selectedFacilityType['name'] == 'Hospitals' &&
        _selectedFacilityLevelId == null) {
      _showMessage('Please select a hospital level for hospitals', isError: true);
      return;
    }

    // Services are optional but each row must have a title if present.
    for (final s in _offeredServices) {
      final title = (s['title'] ?? '').toString().trim();
      if (title.isEmpty) {
        _showMessage('Each service needs a title', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First create the facility (services go along in the same call)
      final facilityResponse = await _authService.authenticatedRequest(
        'POST',
        '/save-facility',
        body: {
          'facility_name': _facilityNameController.text,
          'facility_profile': _facilityProfileController.text,
          'facility_email': _facilityEmailController.text,
          'facility_phone': _facilityPhoneController.text,
          'facility_location': _facilityLocationController.text,
          'facility_website': _facilityWebsiteController.text.isEmpty
              ? null
              : _facilityWebsiteController.text,
          'accepts_insurance': _acceptsInsurance,
          'insurance_ids':
              _acceptsInsurance ? _selectedInsuranceIds : [],
          'facility_type_id': _selectedFacilityTypeId,
          'facility_level_id': _selectedFacilityLevelId,
          'facility_number': _facilityNumberController.text,
          'services': _offeredServices.map((s) {
            final rawAmount = (s['amount'] ?? '').toString().trim();
            return {
              'facility_service_id': s['facility_service_id'],
              'title': (s['title'] ?? '').toString().trim(),
              'description': (s['description'] ?? '').toString().trim().isEmpty
                  ? null
                  : (s['description'] ?? '').toString().trim(),
              'amount': rawAmount.isEmpty ? null : double.tryParse(rawAmount),
            };
          }).toList(),
        },
      );

      if (facilityResponse.statusCode == 200 ||
          facilityResponse.statusCode == 201) {
        final facilityData = jsonDecode(facilityResponse.body);

        if (facilityData['success'] == true &&
            facilityData['facility'] != null) {
          final facilityId = facilityData['facility']['id'];

          // Upload images if selected
          if (_logoImage != null) {
            await _uploadFacilityLogo(facilityId);
          }

          if (_coverImage != null) {
            await _uploadFacilityCoverImage(facilityId);
          }

          _showMessage('Facility created successfully!', isError: false);

          // Navigate back after successful creation
          Future.delayed(const Duration(seconds: 1), () {
            GoRouter.of(context).go('/your-facilities');
          });
        } else {
          String errorMessage =
              facilityData['message'] ?? 'Failed to create facility';
          _showMessage(errorMessage, isError: true);
        }
      } else {
        final errorData = jsonDecode(facilityResponse.body);
        String errorMessage = 'Failed to create facility';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error creating facility: $e');
      _showMessage('Network error. Please check your connection and try again.',
          isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Services helpers
  void _addServiceFromCatalogue(int? id) {
    if (id == null) return;
    if (_offeredServices.any((s) => s['facility_service_id'] == id)) return;
    final ref = _facilityServices.firstWhere(
      (s) => s['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (ref.isEmpty) return;
    setState(() {
      _offeredServices.add({
        'facility_service_id': id,
        'title': ref['name'] ?? '',
        'description': ref['description'] ?? '',
        'amount': '',
      });
    });
  }

  void _addCustomService() {
    setState(() {
      _offeredServices.add({
        'facility_service_id': null,
        'title': '',
        'description': '',
        'amount': '',
      });
    });
  }

  void _updateService(int idx, String key, String value) {
    setState(() {
      _offeredServices[idx][key] = value;
    });
  }

  void _removeService(int idx) {
    setState(() {
      _offeredServices.removeAt(idx);
    });
  }

  Future<void> _uploadFacilityLogo(int facilityId) async {
    if (_logoImage == null) return;

    try {
      final result = await _authService.authenticatedSingleFileUpload(
        '/upload-facility-logo',
        _logoImage!,
        fileFieldName: 'logo',
        additionalFields: {
          'facility_id': facilityId.toString(),
        },
      );

      if (!result['success']) {
        debugPrint('Failed to upload facility logo: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error uploading facility logo: $e');
    }
  }

  Future<void> _uploadFacilityCoverImage(int facilityId) async {
    if (_coverImage == null) return;

    try {
      final result = await _authService.authenticatedSingleFileUpload(
        '/upload-facility-cover-image',
        _coverImage!,
        fileFieldName: 'cover_image',
        additionalFields: {
          'facility_id': facilityId.toString(),
        },
      );

      if (!result['success']) {
        debugPrint('Failed to upload facility cover image: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error uploading facility cover image: $e');
    }
  }

  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isLogo ? 512 : 1024,
        maxHeight: isLogo ? 512 : 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _logoImage = File(pickedFile.path);
          } else {
            _coverImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showMessage('Error picking image: $e', isError: true);
    }
  }

  void _removeImage({required bool isLogo}) {
    setState(() {
      if (isLogo) {
        _logoImage = null;
      } else {
        _coverImage = null;
      }
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _toggleInsuranceCompany(int insuranceId) {
    setState(() {
      if (_selectedInsuranceIds.contains(insuranceId)) {
        _selectedInsuranceIds.remove(insuranceId);
      } else {
        _selectedInsuranceIds.add(insuranceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'New Facility',
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                Image.asset(
                  'assets/images/logo_outline.png',
                  height: 80,
                ),
                SizedBox(height: 10),
                Text(
                  "Create New Facility",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField("Facility Name*", Icons.business, false,
                    _facilityNameController),
                _buildTextField("MFL code", Icons.numbers, false,
                    _facilityNumberController),
                _buildFacilityTypeDropdown(),
                _buildHospitalLevelDropdown(),
                _buildTextField("Facility Email*", Icons.email, false,
                    _facilityEmailController),
                _buildTextField("Facility Phone*", Icons.phone, false,
                    _facilityPhoneController),
                _buildTextField("Facility Website", Icons.web, false,
                    _facilityWebsiteController),
                _buildTextField("Facility Location*", Icons.location_on, false,
                    _facilityLocationController),
                _buildTextAreaField("Facility Profile/Description*",
                    Icons.description, _facilityProfileController),
                SizedBox(height: 20),
                _buildImageUploadSection(),
                SizedBox(height: 20),
                _buildServicesSection(),
                SizedBox(height: 20),
                _buildInsuranceSection(),
                SizedBox(height: 30),
                _buildCreateButton(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, bool obscureText,
      TextEditingController controller) {
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
            textAlign: TextAlign.start,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: label.replaceAll('*', ''),
              suffixIcon: Icon(
                icon,
                color: Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, String? selectedValue,
      List<String> items, Function(String?) onChanged) {
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.0,
              ),
              color: Color(0xfff3f3f4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                hint: Text(
                  label.replaceAll('*', ''),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                isExpanded: true,
                icon: Icon(icon, color: Colors.black54),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 15),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityTypeDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Facility Type*",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.0,
              ),
              color: Color(0xfff3f3f4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: _isLoadingFacilityTypes
                ? Container(
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedFacilityTypeId,
                      hint: Text(
                        "Select Facility Type",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      isExpanded: true,
                      items: _facilityTypes.map((facilityType) {
                        return DropdownMenuItem<int>(
                          value: facilityType['id'] as int,
                          child: Text(
                            facilityType['name'] as String,
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFacilityTypeId = value;
                          _selectedFacilityLevelId = null; // Reset hospital level when facility type changes
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalLevelDropdown() {
    // Only show hospital level dropdown for "Hospitals" facility type
    final selectedFacilityType = _facilityTypes.firstWhere(
      (type) => type['id'] == _selectedFacilityTypeId,
      orElse: () => <String, dynamic>{},
    );

    if (_selectedFacilityTypeId == null ||
        selectedFacilityType.isEmpty ||
        selectedFacilityType['name'] != 'Hospitals') {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Hospital Level*",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.0,
              ),
              color: Color(0xfff3f3f4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: _isLoadingFacilityLevels
                ? Container(
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedFacilityLevelId,
                      hint: Text(
                        "Select Hospital Level",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      isExpanded: true,
                      items: _facilityLevels.map((facilityLevel) {
                        return DropdownMenuItem<int>(
                          value: facilityLevel['id'] as int,
                          child: Text(
                            facilityLevel['name'] as String,
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFacilityLevelId = value;
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField(
      String label, IconData icon, TextEditingController controller) {
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
            textAlign: TextAlign.start,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: label.replaceAll('*', ''),
              suffixIcon: Icon(
                icon,
                color: Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
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
          'Facility Images',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
                child: _buildImageUploadCard(
              title: 'Logo',
              subtitle: 'Square image recommended',
              image: _logoImage,
              onTap: () => _pickImage(isLogo: true),
              onRemove: () => _removeImage(isLogo: true),
            )),
            SizedBox(width: 15),
            Expanded(
                child: _buildImageUploadCard(
              title: 'Cover Image',
              subtitle: 'Landscape image recommended',
              image: _coverImage,
              onTap: () => _pickImage(isLogo: false),
              onRemove: () => _removeImage(isLogo: false),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    File? image,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xfff3f3f4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: image != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: onRemove,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF008faf),
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServicesSection() {
    final availableCatalogue = _facilityServices.where((s) {
      return !_offeredServices.any((o) => o['facility_service_id'] == s['id']);
    }).toList();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services Offered',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pick services from the catalogue or add your own. Each service has a title, optional description and price.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          SizedBox(height: 10),

          if (_isLoadingFacilityServices)
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF008faf)),
              ),
            )
          else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color(0xfff3f3f4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<int>(
                isExpanded: true,
                underline: SizedBox.shrink(),
                hint: Text('Add from catalogue…'),
                value: null,
                items: availableCatalogue.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem<int>(
                    value: s['id'] as int,
                    child: Text(s['name'] ?? '', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (id) => _addServiceFromCatalogue(id),
              ),
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addCustomService,
              icon: Icon(Icons.add, color: Color(0xFF008faf)),
              label: Text(
                'Add custom service',
                style: TextStyle(color: Color(0xFF008faf), fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
            SizedBox(height: 10),

            if (_offeredServices.isEmpty)
              Text(
                'No services added yet.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
              )
            else
              ..._offeredServices.asMap().entries.map((entry) {
                final idx = entry.key;
                final svc = entry.value;
                final isCatalogue = svc['facility_service_id'] != null;
                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCatalogue
                                  ? Color(0xFF008faf).withOpacity(0.1)
                                  : Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isCatalogue ? 'Catalogue' : 'Custom',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCatalogue ? Color(0xFF008faf) : Colors.orange.shade800,
                              ),
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeService(idx),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: svc['title']?.toString() ?? '',
                        onChanged: (v) => _updateService(idx, 'title', v),
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: svc['amount']?.toString() ?? '',
                        onChanged: (v) => _updateService(idx, 'amount', v),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (KES)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: svc['description']?.toString() ?? '',
                        onChanged: (v) => _updateService(idx, 'description', v),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insurance Acceptance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color(0xfff3f3f4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _acceptsInsurance,
                      onChanged: (value) {
                        setState(() {
                          _acceptsInsurance = value;
                          if (!value) {
                            _selectedInsuranceIds.clear();
                          }
                        });
                      },
                      activeColor: Color(0xFF008faf),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This facility accepts insurance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_acceptsInsurance) ...[
                  SizedBox(height: 15),
                  Text(
                    'Select accepted insurance companies:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _isLoadingInsurances
                            ? [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              ]
                            : _insurances.map((insurance) {
                                final insuranceId = insurance['id'] as int;
                                final isSelected =
                                    _selectedInsuranceIds.contains(insuranceId);
                                return GestureDetector(
                                  onTap: () => _toggleInsuranceCompany(insuranceId),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFF008faf)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(0xFF008faf)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Text(
                                      insurance['name'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_selectedInsuranceIds.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF008faf).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Color(0xFF008faf).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF008faf),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedInsuranceIds.length} insurance ${_selectedInsuranceIds.length == 1 ? 'company' : 'companies'} selected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF008faf),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _createFacility,
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
                  Text(
                    'Creating Facility...',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Create Facility',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
