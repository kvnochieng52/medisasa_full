// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/groups/your_groups/your_groups.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  final TextEditingController _groupTagsController = TextEditingController();
  final TextEditingController _groupLocationController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingCategories = false;
  bool _isLoadingSubCategories = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];

  // Simplified category selection - just store IDs
  int? _selectedCategoryId;
  List<int> _selectedSubCategoryIds = [];

  File? _groupImage;
  File? _coverImage;

  // Group privacy settings
  String _groupPrivacy = 'public';
  bool _requireApprovalToJoin = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _groupTagsController.dispose();
    _groupLocationController.dispose();
    super.dispose();
  }

  // Load all categories - simple API call
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/group-categories',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _categories =
                List<Map<String, dynamic>>.from(responseData['data'] ?? []);
          });
        }
      } else {
        _showMessage('Failed to load categories', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _showMessage('Network error loading categories', isError: true);
    }

    setState(() {
      _isLoadingCategories = false;
    });
  }

  // Load subcategories for selected category - simple filtering by category_id
  Future<void> _loadSubCategories(int categoryId) async {
    setState(() {
      _isLoadingSubCategories = true;
      _subCategories = [];
      _selectedSubCategoryIds = [];
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/group-subcategories?category_id=$categoryId',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _subCategories =
                List<Map<String, dynamic>>.from(responseData['data'] ?? []);
          });
        }
      } else {
        _showMessage('Failed to load subcategories', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      _showMessage('Network error loading subcategories', isError: true);
    }

    setState(() {
      _isLoadingSubCategories = false;
    });
  }

  Future<void> _createGroup() async {
    // Validation
    if (_groupNameController.text.isEmpty ||
        _groupDescriptionController.text.isEmpty ||
        _groupLocationController.text.isEmpty) {
      _showMessage('Please fill in all required fields', isError: true);
      return;
    }

    if (_selectedCategoryId == null) {
      _showMessage('Please select a category', isError: true);
      return;
    }

    if (_selectedSubCategoryIds.isEmpty) {
      _showMessage('Please select at least one subcategory', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First create the group
      final groupResponse = await _authService.authenticatedRequest(
        'POST',
        '/groups',
        body: {
          'group_name': _groupNameController.text,
          'group_description': _groupDescriptionController.text,
          'group_location': _groupLocationController.text,
          'group_tags': _groupTagsController.text.isEmpty
              ? null
              : _groupTagsController.text,
          'group_privacy': _groupPrivacy,
          'require_approval': _requireApprovalToJoin,
          'category_id': _selectedCategoryId,
          'subcategory_ids': _selectedSubCategoryIds,
        },
      );

      if (groupResponse.statusCode == 200 || groupResponse.statusCode == 201) {
        final groupData = jsonDecode(groupResponse.body);

        if (groupData['success'] == true && groupData['group'] != null) {
          final groupId = groupData['group']['id'];

          // Upload images if selected
          if (_groupImage != null) {
            await _uploadGroupImage(groupId);
          }

          if (_coverImage != null) {
            await _uploadGroupCoverImage(groupId);
          }

          _showMessage('Group created successfully!', isError: false);

          // Navigate back after successful creation
          // Future.delayed(const Duration(seconds: 1), () {
          //   GoRouter.of(context).go('/your-groups');
          // });

          //Future.delayed(const Duration(seconds: 1), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => YourGroupsPage()),
            // This removes all previous routes
          );
          // });
        } else {
          String errorMessage =
              groupData['message'] ?? 'Failed to create group';
          _showMessage(errorMessage, isError: true);
        }
      } else {
        final errorData = jsonDecode(groupResponse.body);
        String errorMessage = 'Failed to create group';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      _showMessage('Network error. Please check your connection and try again.',
          isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _uploadGroupImage(int groupId) async {
    if (_groupImage == null) return;

    try {
      final result = await _authService.authenticatedSingleFileUpload(
        '/upload-group-image',
        _groupImage!,
        fileFieldName: 'group_image',
        additionalFields: {
          'group_id': groupId.toString(),
        },
      );

      if (!result['success']) {
        debugPrint('Failed to upload group image: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error uploading group image: $e');
    }
  }

  Future<void> _uploadGroupCoverImage(int groupId) async {
    if (_coverImage == null) return;

    try {
      final result = await _authService.authenticatedSingleFileUpload(
        '/upload-group-cover-image',
        _coverImage!,
        fileFieldName: 'cover_image',
        additionalFields: {
          'group_id': groupId.toString(),
        },
      );

      if (!result['success']) {
        debugPrint('Failed to upload group cover image: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error uploading group cover image: $e');
    }
  }

  Future<void> _pickImage({required bool isGroupImage}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isGroupImage ? 512 : 1024,
        maxHeight: isGroupImage ? 512 : 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isGroupImage) {
            _groupImage = File(pickedFile.path);
          } else {
            _coverImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showMessage('Error picking image: $e', isError: true);
    }
  }

  void _removeImage({required bool isGroupImage}) {
    setState(() {
      if (isGroupImage) {
        _groupImage = null;
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

  void _selectCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadSubCategories(categoryId);
  }

  void _toggleSubCategory(int subCategoryId) {
    setState(() {
      if (_selectedSubCategoryIds.contains(subCategoryId)) {
        _selectedSubCategoryIds.remove(subCategoryId);
      } else {
        _selectedSubCategoryIds.add(subCategoryId);
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
          'New Group',
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
                  "Create New Group",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField(
                    "Group Name*", Icons.group, false, _groupNameController),
                _buildTextField("Group Location*", Icons.location_on, false,
                    _groupLocationController),
                _buildTextField(
                    "Tags (optional)", Icons.tag, false, _groupTagsController),
                _buildTextAreaField("Group Description*", Icons.description,
                    _groupDescriptionController),
                SizedBox(height: 20),
                _buildPrivacySection(),
                SizedBox(height: 20),
                _buildImageUploadSection(),
                SizedBox(height: 20),
                _buildCategoriesSection(),
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
              suffixIcon: Icon(icon, color: Colors.black54),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
              suffixIcon: Icon(icon, color: Colors.black54),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Privacy Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            children: [
              RadioListTile<String>(
                title: Text('Public'),
                subtitle: Text('Anyone can see and join this group'),
                value: 'public',
                groupValue: _groupPrivacy,
                onChanged: (value) => setState(() => _groupPrivacy = value!),
                activeColor: Color(0xFF008faf),
              ),
              RadioListTile<String>(
                title: Text('Private'),
                subtitle: Text('Only members can see group content'),
                value: 'private',
                groupValue: _groupPrivacy,
                onChanged: (value) => setState(() => _groupPrivacy = value!),
                activeColor: Color(0xFF008faf),
              ),
              RadioListTile<String>(
                title: Text('Closed'),
                subtitle: Text('Invite only, completely private'),
                value: 'closed',
                groupValue: _groupPrivacy,
                onChanged: (value) => setState(() => _groupPrivacy = value!),
                activeColor: Color(0xFF008faf),
              ),
              SizedBox(height: 10),
              CheckboxListTile(
                title: Text('Require approval to join'),
                subtitle: Text('New members need admin approval'),
                value: _requireApprovalToJoin,
                onChanged: (value) =>
                    setState(() => _requireApprovalToJoin = value!),
                activeColor: Color(0xFF008faf),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Images',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildImageUploadCard(
                title: 'Group Image',
                subtitle: 'Square image recommended',
                image: _groupImage,
                onTap: () => _pickImage(isGroupImage: true),
                onRemove: () => _removeImage(isGroupImage: true),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildImageUploadCard(
                title: 'Cover Image',
                subtitle: 'Landscape image recommended',
                image: _coverImage,
                onTap: () => _pickImage(isGroupImage: false),
                onRemove: () => _removeImage(isGroupImage: false),
              ),
            ),
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
                    child: Image.file(image, fit: BoxFit.cover),
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
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Color(0xFF008faf), size: 32),
                    SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Categories*',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 10),
          _buildMainCategorySelection(),
          SizedBox(height: 20),
          if (_selectedCategoryId != null) _buildSubCategorySelection(),
        ],
      ),
    );
  }

  Widget _buildMainCategorySelection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xfff3f3f4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Main Category:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700),
          ),
          SizedBox(height: 15),
          _isLoadingCategories
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFF008faf)))
              : _categories.isEmpty
                  ? Text('No categories available',
                      style: TextStyle(color: Colors.grey.shade600))
                  : Column(
                      children: _categories.map((category) {
                        final isSelected =
                            _selectedCategoryId == category['id'];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _selectCategory(category['id']),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(0xFF008faf)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Color(0xFF008faf)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      category['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildSubCategorySelection() {
    return Container(
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
              Icon(Icons.subdirectory_arrow_right,
                  color: Color(0xFF008faf), size: 20),
              SizedBox(width: 8),
              Text(
                'Select Subcategories:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
            ],
          ),
          SizedBox(height: 15),
          _isLoadingSubCategories
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFF008faf)))
              : _subCategories.isEmpty
                  ? Text('No subcategories available',
                      style: TextStyle(color: Colors.grey.shade600))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedSubCategoryIds.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: Text(
                              '${_selectedSubCategoryIds.length} selected',
                              style: TextStyle(
                                color: Color(0xFF008faf),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _subCategories.map((subCategory) {
                            final isSelected = _selectedSubCategoryIds
                                .contains(subCategory['id']);
                            return GestureDetector(
                              onTap: () =>
                                  _toggleSubCategory(subCategory['id']),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.check_circle,
                                            color: Colors.white, size: 14),
                                      ),
                                    Text(
                                      subCategory['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _createGroup,
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
                  Text('Creating Group...',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              )
            : Text('Create Group',
                style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
    );
  }
}
