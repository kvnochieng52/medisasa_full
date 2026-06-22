// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class EditFacilityPage extends StatefulWidget {
  const EditFacilityPage({Key? key, required this.facilityId, this.title})
      : super(key: key);

  final int facilityId;
  final String? title;

  @override
  _EditFacilityPageState createState() => _EditFacilityPageState();
}

class _EditFacilityPageState extends State<EditFacilityPage> {
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

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isLoadingSpecialties = false;
  bool _isLoadingFacilityTypes = false;
  bool _isLoadingFacilityLevels = false;
  bool _isLoadingInsurances = false;
  List<Map<String, dynamic>> _specialties = [];
  List<int> _selectedSpecialtyIds = [];
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
  String? _existingLogoUrl;
  String? _existingCoverUrl;

  @override
  void initState() {
    super.initState();
    _loadFacilityData();
    _loadSpecialties();
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
    super.dispose();
  }

  Future<void> _loadFacilityData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/facilities/${widget.facilityId}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final facilityData = responseData['data'];

          setState(() {
            _facilityNameController.text = facilityData['facility_name'] ?? '';
            _facilityProfileController.text =
                facilityData['facility_profile'] ?? '';
            _facilityEmailController.text =
                facilityData['facility_email'] ?? '';
            _facilityPhoneController.text =
                facilityData['facility_phone'] ?? '';
            _facilityLocationController.text =
                facilityData['facility_location'] ?? '';
            _facilityWebsiteController.text =
                facilityData['facility_website'] ?? '';
            _existingLogoUrl = facilityData['logo_url'];
            _existingCoverUrl = facilityData['cover_image_url'];

            // Load existing specialties
            if (facilityData['specialties'] != null) {
              _selectedSpecialtyIds = List<int>.from(facilityData['specialties']
                  .map((s) => s['id'] ?? s['specialization_id'])
                  .toList());
            }

            // Load existing facility type
            if (facilityData['facility_type'] != null) {
              _selectedFacilityTypeId = facilityData['facility_type']['id'];
            }

            // Load existing facility level
            if (facilityData['facility_level'] != null) {
              _selectedFacilityLevelId = facilityData['facility_level']['id'];
            }

            // Load existing insurances
            if (facilityData['insurances'] != null) {
              _selectedInsuranceIds = List<int>.from(
                  facilityData['insurances'].map((i) => i['id']).toList());
              _acceptsInsurance = _selectedInsuranceIds.isNotEmpty;
            }
          });
        }
      } else {
        _showMessage('Failed to load facility data', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading facility data: $e');
      _showMessage('Network error loading facility data', isError: true);
    }

    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _loadSpecialties() async {
    setState(() {
      _isLoadingSpecialties = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/specializations/active-for-facility',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _specialties =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showMessage('Failed to load specialties', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading specialties: $e');
      _showMessage('Network error loading specialties', isError: true);
    }

    setState(() {
      _isLoadingSpecialties = false;
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
            _insurances = List<Map<String, dynamic>>.from(responseData['data']);
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

  Future<void> _updateFacility() async {
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
      _showMessage('Please select a hospital level for hospitals',
          isError: true);
      return;
    }

    if (_selectedSpecialtyIds.isEmpty) {
      _showMessage('Please select at least one specialty', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the facility
      final facilityResponse = await _authService.authenticatedRequest(
        'PUT',
        '/facilities/${widget.facilityId}',
        body: {
          'facility_name': _facilityNameController.text,
          'facility_profile': _facilityProfileController.text,
          'facility_email': _facilityEmailController.text,
          'facility_phone': _facilityPhoneController.text,
          'facility_location': _facilityLocationController.text,
          'facility_website': _facilityWebsiteController.text.isEmpty
              ? null
              : _facilityWebsiteController.text,
          'facility_type_id': _selectedFacilityTypeId,
          'facility_level_id': _selectedFacilityLevelId,
          'accepts_insurance': _acceptsInsurance,
          'insurance_ids': _acceptsInsurance ? _selectedInsuranceIds : [],
        },
      );

      if (facilityResponse.statusCode == 200 ||
          facilityResponse.statusCode == 201) {
        final facilityData = jsonDecode(facilityResponse.body);

        if (facilityData['success'] == true) {
          // Update the facility specialties
          await _updateFacilitySpecialties(widget.facilityId);

          // Upload new images if selected
          if (_logoImage != null) {
            await _uploadFacilityLogo(widget.facilityId);
          }

          if (_coverImage != null) {
            await _uploadFacilityCoverImage(widget.facilityId);
          }

          _showMessage('Facility updated successfully!', isError: false);

          // Navigate back after successful update
          Future.delayed(const Duration(seconds: 1), () {
            GoRouter.of(context).go('/your-facilities');
          });
        } else {
          String errorMessage =
              facilityData['message'] ?? 'Failed to update facility';
          _showMessage(errorMessage, isError: true);
        }
      } else {
        final errorData = jsonDecode(facilityResponse.body);
        String errorMessage = 'Failed to update facility';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error updating facility: $e');
      _showMessage('Network error. Please check your connection and try again.',
          isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateFacilitySpecialties(int facilityId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/save-facility-specialties',
        body: {
          'facility_id': facilityId,
          'specialty_ids': _selectedSpecialtyIds,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Failed to update facility specialties');
      }
    } catch (e) {
      debugPrint('Error updating facility specialties: $e');
    }
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

  void _toggleSpecialty(int specialtyId) {
    setState(() {
      if (_selectedSpecialtyIds.contains(specialtyId)) {
        _selectedSpecialtyIds.remove(specialtyId);
      } else {
        _selectedSpecialtyIds.add(specialtyId);
      }
    });
  }

  // void _toggleSpecialty(int specialtyId) {
  //   setState(() {
  //     if (_selectedSpecialtyIds.contains(specialtyId)) {
  //       _selectedSpecialtyIds.remove(specialtyId);
  //     } else {
  //       _selectedSpecialtyIds.add(specialtyId);
  //     }
  //   });
  // }

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

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF008faf),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: Text(
            'Edit Facility',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF008faf),
              ),
              SizedBox(height: 16),
              Text(
                'Loading facility data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'Edit Facility',
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
                  "Edit Facility",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField("Facility Name*", Icons.business, false,
                    _facilityNameController),
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
                _buildSpecialtiesSection(),
                SizedBox(height: 20),
                _buildInsuranceSection(),
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
              existingImageUrl: _existingLogoUrl,
              onTap: () => _pickImage(isLogo: true),
              onRemove: () => _removeImage(isLogo: true),
            )),
            SizedBox(width: 15),
            Expanded(
                child: _buildImageUploadCard(
              title: 'Cover Image',
              subtitle: 'Landscape image recommended',
              image: _coverImage,
              existingImageUrl: _existingCoverUrl,
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
    String? existingImageUrl,
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
      child: (image != null ||
              (existingImageUrl != null && existingImageUrl.isNotEmpty))
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: image != null
                        ? Image.file(
                            image,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            existingImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                              );
                            },
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
                // Add tap functionality to change image
                Positioned.fill(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.edit,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                      ),
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

  Widget _buildSpecialtiesSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facility Specialties*',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          _isLoadingSpecialties
              ? Container(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008faf),
                    ),
                  ),
                )
              : _specialties.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xfff3f3f4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'No specialties available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xfff3f3f4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Select specialties for this facility:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _specialties.map((specialty) {
                              final isSelected = _selectedSpecialtyIds
                                  .contains(specialty['id']);
                              return GestureDetector(
                                onTap: () => _toggleSpecialty(specialty['id']),
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
                                    specialty['specialization_name'] ??
                                        'Unknown',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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
                          _selectedFacilityLevelId =
                              null; // Reset hospital level when facility type changes
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              ]
                            : _insurances.map((insurance) {
                                final insuranceId = insurance['id'] as int;
                                final isSelected =
                                    _selectedInsuranceIds.contains(insuranceId);
                                return GestureDetector(
                                  onTap: () =>
                                      _toggleInsuranceCompany(insuranceId),
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

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _updateFacility,
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
                    'Updating Facility...',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Update Facility',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
