import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BasicDetailsTab extends StatefulWidget {
  final String? userType;
  final Function(String?) onUserTypeChanged;
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onSave;

  const BasicDetailsTab({
    Key? key,
    required this.userType,
    required this.onUserTypeChanged,
    required this.profileData,
    required this.onDataChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  _BasicDetailsTabState createState() => _BasicDetailsTabState();
}

class _BasicDetailsTabState extends State<BasicDetailsTab> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  DateTime? _selectedDate;
  String? _localUserType;
  String? _serverProfileImageUrl;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize local user type with widget value or default to 'user'
    _localUserType = widget.userType ?? 'user';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load data from widget.profileData first
    _nameController.text = widget.profileData['name'] ?? '';
    _emailController.text = widget.profileData['email'] ?? '';
    _telephoneController.text = widget.profileData['telephone'] ?? '';
    _idNumberController.text = widget.profileData['idNumber'] ?? '';
    _addressController.text = widget.profileData['address'] ?? '';
    _dateOfBirthController.text = widget.profileData['dateOfBirth'] ?? '';

    if (widget.profileData['selectedDate'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.profileData['selectedDate']);
      } catch (e) {
        print('Error parsing selectedDate: $e');
      }
    }

    // Fetch fresh user data from server
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/user-profile',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response is successful and extract user data
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data']['user'];

          // Fill in values if they're not already set in profileData
          if (_nameController.text.isEmpty && userData['name'] != null) {
            _nameController.text = userData['name'].toString();
          }

          if (_emailController.text.isEmpty && userData['email'] != null) {
            _emailController.text = userData['email'].toString();
          }

          if (_telephoneController.text.isEmpty &&
              userData['telephone'] != null) {
            _telephoneController.text = userData['telephone'].toString();
          }

          if (_idNumberController.text.isEmpty &&
              userData['id_number'] != null) {
            _idNumberController.text = userData['id_number'].toString();
          }

          if (_addressController.text.isEmpty && userData['address'] != null) {
            _addressController.text = userData['address'].toString();
          }

          // Handle date of birth
          if (_dateOfBirthController.text.isEmpty && userData['dob'] != null) {
            try {
              final dobString = userData['dob'].toString();
              if (dobString.isNotEmpty && dobString != 'null') {
                _selectedDate = DateTime.parse(dobString);
                _dateOfBirthController.text =
                    dobString.split(' ')[0]; // Get just the date part
              }
            } catch (e) {
              print('Error parsing date of birth: $e');
            }
          }

          // Handle profile image URL
          if (userData['profile_image'] != null) {
            final profileImagePath = userData['profile_image'].toString();
            if (profileImagePath.isNotEmpty && profileImagePath != 'null') {
              // Construct the full URL for the profile image

              final webUrl = ApiConfig.webUrl;
              _serverProfileImageUrl = '$webUrl/storage/$profileImagePath';
            }
          }

          // Set user type based on account_type
          String? serverUserType;
          if (userData['account_type'] != null) {
            final accountType =
                userData['account_type'].toString().toLowerCase();

            if (accountType == 'user') {
              serverUserType = 'user';
            } else if (accountType == 'serviceprovider' ||
                accountType == 'service_provider' ||
                accountType == 'doctor') {
              serverUserType = 'serviceProvider';
            }
          }

          // Set user type: server data takes priority, fallback to 'user'
          final finalUserType = serverUserType ?? 'user';

          setState(() {
            _localUserType = finalUserType;
          });

          // Notify parent widget about the user type change
          widget.onUserTypeChanged(finalUserType);

          // Update the data after loading from server
          _updateData();
        }
      } else {
        print('Failed to load user profile: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load profile data'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading user data from server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // If server call fails, ensure we have a default user type
      if (_localUserType == null) {
        setState(() {
          _localUserType = 'user';
        });
        widget.onUserTypeChanged('user');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0];
      });
      _updateData();
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      _updateData();
    }
  }

  void _onUserTypeChanged(String? newUserType) {
    setState(() {
      _localUserType = newUserType;
    });
    widget.onUserTypeChanged(newUserType);
  }

  void _updateData() {
    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text,
      'idNumber': _idNumberController.text,
      'address': _addressController.text,
      'dateOfBirth': _dateOfBirthController.text,
      'selectedDate': _selectedDate?.toIso8601String(),
      'profileImage': _profileImage?.path,
    };
    widget.onDataChanged(data);
  }

  ImageProvider _getProfileImageProvider() {
    if (_profileImage != null) {
      // Show local file if user just selected one
      return FileImage(_profileImage!);
    } else if (_serverProfileImageUrl != null &&
        _serverProfileImageUrl!.isNotEmpty) {
      // Show server image if available
      return NetworkImage(_serverProfileImageUrl!);
    } else {
      // Show default placeholder
      return const AssetImage('assets/images/passport.png');
    }
  }

  Widget? _getProfileImageChild() {
    if (_profileImage == null &&
        (_serverProfileImageUrl == null || _serverProfileImageUrl!.isEmpty)) {
      return const Icon(Icons.camera_alt, size: 30, color: Colors.white);
    }
    return null; // No overlay icon when image is present
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    try {
      // Use AuthService for file upload
      final result = await _authService.authenticatedSingleFileUpload(
        '/upload-profile-image',
        _profileImage!,
        additionalFields: {
          'user_id': _authService.user?['id']?.toString() ?? '',
        },
        fileFieldName: 'profile_image',
      );

      if (result['success']) {
        // Update the server profile image URL if returned in response
        if (result['data'] != null &&
            result['data']['profile_image_url'] != null) {
          setState(() {
            _serverProfileImageUrl = result['data']['profile_image_url'];
            _profileImage = null; // Clear local file since it's now on server
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBasicDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    _updateData();

    try {
      // Upload profile image if available
      if (_profileImage != null) {
        await _uploadProfileImage();
      }

      // Save basic details using AuthService
      final result = await _authService.authenticatedRequest(
        'POST',
        '/save-basic-details',
        body: {
          'name': _nameController.text,
          'email': _emailController.text,
          'telephone': _telephoneController.text,
          'idNumber': _idNumberController.text,
          'address': _addressController.text,
          'dateOfBirth': _dateOfBirthController.text,
          'userType': _localUserType,
        },
      );

      if (result.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Basic details saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onSave();
      } else {
        final responseData = jsonDecode(result.body);
        throw Exception(
            responseData['message'] ?? 'Failed to save basic details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            // User Type Selection
            const Text(
              'Set your profile as:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('User'),
                  value: 'user',
                  groupValue: _localUserType,
                  onChanged: _onUserTypeChanged,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                ),
                RadioListTile<String>(
                  title: const Text('Service Provider/Doctor'),
                  value: 'serviceProvider',
                  groupValue: _localUserType,
                  onChanged: _onUserTypeChanged,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Personal Information
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 16.0),

            // Date of Birth Field with Date Picker
            TextFormField(
              controller: _dateOfBirthController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your date of birth';
                }
                return null;
              },
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16.0),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 16.0),

            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 16.0),

            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your ID number';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 16.0),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 24.0),

            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _getProfileImageProvider(),
                  child: _getProfileImageChild(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            ElevatedButton(
              onPressed: _pickProfileImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 70, 70, 70),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: Text(
                (_profileImage != null ||
                        (_serverProfileImageUrl != null &&
                            _serverProfileImageUrl!.isNotEmpty))
                    ? 'Change Profile Picture'
                    : 'Upload Profile Picture',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24.0),

            // Save Button for Basic Details
            ElevatedButton(
              onPressed: _localUserType != null && !_isSaving
                  ? _saveBasicDetails
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008faf),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saving...',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    )
                  : const Text(
                      'Save Basic Details',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
