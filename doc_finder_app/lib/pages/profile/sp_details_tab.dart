import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';

class ServiceProviderDetailsTab extends StatefulWidget {
  final String? userType;
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onSave;

  const ServiceProviderDetailsTab({
    Key? key,
    required this.userType,
    required this.profileData,
    required this.onDataChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  _ServiceProviderDetailsTabState createState() =>
      _ServiceProviderDetailsTabState();
}

class _ServiceProviderDetailsTabState extends State<ServiceProviderDetailsTab> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _professionalBioController =
      TextEditingController();

  List<dynamic> _specializations = [];
  List<int> _selectedSpecializations = [];
  List<File> _certificateDocuments = [];
  List<dynamic> _existingCertificates = [];
  List<File> _idDocuments = [];
  List<dynamic> _existingIdDocuments = [];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/user-profile',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final userData = data['user'];

          // Load specializations
          _specializations = data['specializations'] ?? [];

          // Load user's existing specializations
          final userSpecializations = data['user_specializations'] ?? [];
          _selectedSpecializations = userSpecializations
              .map<int>((spec) => spec['specialization_id'] as int)
              .toList();

          // Load existing documents (only active ones)
          _existingCertificates = (data['user_documents'] ?? [])
              .where((doc) =>
                  doc['document_type'] == 'certificate' &&
                  (doc['is_active'] == 1 || doc['is_active'] == '1'))
              .toList();
          _existingIdDocuments = (data['user_ids'] ?? [])
              .where((doc) =>
                  doc['document_type'] == 'id' &&
                  (doc['is_active'] == 1 || doc['is_active'] == '1'))
              .toList();

          // Fill form fields with user data
          if (userData['licence_number'] != null) {
            _licenseNumberController.text =
                userData['licence_number'].toString();
          }

          if (userData['professional_bio'] != null) {
            _professionalBioController.text =
                userData['professional_bio'].toString();
          }

          // Update parent component with loaded data
          _updateData();
        }
      } else {
        print('Failed to load service provider data: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load service provider data'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading service provider data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _professionalBioController.dispose();
    super.dispose();
  }

  void _updateData() {
    final data = {
      'licenseNumber': _licenseNumberController.text,
      'professionalBio': _professionalBioController.text,
      'selectedSpecializations': _selectedSpecializations,
      'certificateDocuments':
          _certificateDocuments.map((file) => file.path).toList(),
      'idDocuments': _idDocuments.map((file) => file.path).toList(),
    };
    widget.onDataChanged(data);
  }

  Future<void> _pickDocuments(String documentType) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  _getImages(ImageSource.gallery, documentType);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _getImages(ImageSource.camera, documentType);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Document'),
                onTap: () {
                  _getPDFDocument(documentType);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImages(ImageSource source, String documentType) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (documentType == 'certificate') {
          _certificateDocuments.add(File(image.path));
        } else if (documentType == 'id') {
          _idDocuments.add(File(image.path));
        }
      });
      _updateData();
    }
  }

  Future<void> _getPDFDocument(String documentType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        if (documentType == 'certificate') {
          _certificateDocuments.add(file);
        } else if (documentType == 'id') {
          _idDocuments.add(file);
        }
      });
      _updateData();
    }
  }

  void _removeDocument(int index, String documentType) {
    setState(() {
      if (documentType == 'certificate') {
        _certificateDocuments.removeAt(index);
      } else if (documentType == 'id') {
        _idDocuments.removeAt(index);
      }
    });
    _updateData();
  }

  Future<void> _deleteExistingDocument(
      int documentId, String documentType) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: const Text(
              'Are you sure you want to delete this document? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '/user-document/$documentId',
      );

      if (response.statusCode == 200) {
        setState(() {
          if (documentType == 'certificate') {
            _existingCertificates.removeWhere((doc) => doc['id'] == documentId);
          } else if (documentType == 'id') {
            _existingIdDocuments.removeWhere((doc) => doc['id'] == documentId);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to delete document');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSpecialization(int specializationId) {
    setState(() {
      if (_selectedSpecializations.contains(specializationId)) {
        _selectedSpecializations.remove(specializationId);
      } else {
        _selectedSpecializations.add(specializationId);
      }
    });
    _updateData();
  }

  Future<void> _uploadDocuments() async {
    try {
      // Upload certificate documents
      for (File document in _certificateDocuments) {
        await _authService.authenticatedSingleFileUpload(
          '/upload-user-document',
          document,
          additionalFields: {
            'user_id': _authService.user?['id']?.toString() ?? '',
            'document_type': 'certificate',
          },
          fileFieldName: 'document',
        );
      }

      // Upload ID documents
      for (File document in _idDocuments) {
        await _authService.authenticatedSingleFileUpload(
          '/upload-user-document',
          document,
          additionalFields: {
            'user_id': _authService.user?['id']?.toString() ?? '',
            'document_type': 'id',
          },
          fileFieldName: 'document',
        );
      }

      // Clear local files after successful upload
      setState(() {
        _certificateDocuments.clear();
        _idDocuments.clear();
      });
    } catch (e) {
      throw Exception('Error uploading documents: $e');
    }
  }

  Future<void> _saveServiceProviderDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload documents first
      if (_certificateDocuments.isNotEmpty || _idDocuments.isNotEmpty) {
        await _uploadDocuments();
      }

      // Save service provider details
      final result = await _authService.authenticatedRequest(
        'POST',
        '/save-service-provider-details',
        body: {
          'licence_number': _licenseNumberController.text,
          'professional_bio': _professionalBioController.text,
          'specializations': _selectedSpecializations,
          'account_type': 2, // Service provider type
        },
      );

      if (result.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service provider details saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload data to show newly uploaded documents
        await _loadData();
        widget.onSave();
      } else {
        final responseData = jsonDecode(result.body);
        throw Exception(responseData['message'] ??
            'Failed to save service provider details');
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

  Widget _buildSpecializationDropdown() {
    // Get selected specialization names for display
    List<String> selectedNames = _specializations
        .where((spec) => _selectedSpecializations.contains(spec['id']))
        .map((spec) => spec['specialization_name'].toString())
        .toList();

    String displayText = selectedNames.isEmpty
        ? 'Select Specializations'
        : selectedNames.length == 1
            ? selectedNames.first
            : '${selectedNames.length} specializations selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specializations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showSpecializationDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedNames.isEmpty
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (selectedNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedNames.map((name) {
              final spec = _specializations.firstWhere(
                (s) => s['specialization_name'] == name,
              );
              return Chip(
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () => _toggleSpecialization(spec['id']),
                deleteIcon: const Icon(Icons.close, size: 16),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showSpecializationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Specializations'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: _specializations.length,
                  itemBuilder: (context, index) {
                    final specialization = _specializations[index];
                    final isSelected =
                        _selectedSpecializations.contains(specialization['id']);

                    return CheckboxListTile(
                      title: Text(
                        specialization['specialization_name'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        specialization['specialization_description'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _toggleSpecialization(specialization['id']);
                        });
                        setState(() {}); // Update main widget state too
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedSpecializations.clear();
                    });
                    setState(() {});
                    _updateData();
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateData();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentThumbnail(String documentPath, VoidCallback onDelete,
      {bool isLocal = false}) {
    final String fileName = documentPath.split('/').last.toLowerCase();

    final webUrl = ApiConfig.webUrl;
    final _serverImageUrl = '$webUrl/storage/$documentPath';

    print('_serverImageUrl: $_serverImageUrl');

    final bool isImage = fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif');
    final bool isPdf = fileName.endsWith('.pdf');

    return GestureDetector(
      onTap: () {
        if (isPdf && !isLocal) {
          _previewPDF(_serverImageUrl);
        } else if (isImage) {
          _previewImage(documentPath, isLocal: isLocal);
        }
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage
                  ? isLocal
                      ? Image.file(
                          File(documentPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultThumbnail(Icons.broken_image);
                          },
                        )
                      : Image.network(
                          _serverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultThumbnail(Icons.broken_image);
                          },
                        )
                  : _buildDefaultThumbnail(Icons.picture_as_pdf),
            ),
          ),
          // Preview indicator
          if ((isPdf && !isLocal) || isImage)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isImage ? 'Tap to view' : 'Tap to preview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewImage(String imagePath, {bool isLocal = false}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: isLocal
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.network(
                            '${ApiConfig.webUrl}/storage/$imagePath',
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pinch to zoom • Drag to pan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _previewPDF(String pdfUrl) async {
    try {
      final Uri url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open PDF document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDefaultThumbnail(IconData icon) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        icon,
        size: 60,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildDocumentSection(String title, List<File> documents,
      List<dynamic> existing, String documentType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Existing documents
        if (existing.isNotEmpty) ...[
          const Text('Uploaded Documents:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: existing.length,
            itemBuilder: (context, index) {
              final doc = existing[index];
              return _buildDocumentThumbnail(
                doc['document_path'] ?? '',
                () => _deleteExistingDocument(doc['id'], documentType),
                isLocal: false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // New documents to upload
        if (documents.isNotEmpty) ...[
          const Text('New Documents to Upload:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final file = documents[index];
              return _buildDocumentThumbnail(
                file.path,
                () => _removeDocument(index, documentType),
                isLocal: true,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton.icon(
          onPressed: () => _pickDocuments(documentType),
          icon: const Icon(Icons.add, color: Colors.white),
          label:
              Text('Add ${title}', style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 70, 70, 70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
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
            // License Number
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                border: OutlineInputBorder(),
                helperText: 'Enter your professional license number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your license number';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 16.0),

            // Professional Bio
            TextFormField(
              controller: _professionalBioController,
              decoration: const InputDecoration(
                labelText: 'Professional Bio',
                border: OutlineInputBorder(),
                helperText: 'Tell us about your professional experience',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your professional bio';
                }
                return null;
              },
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 24.0),

            // Specializations
            _buildSpecializationDropdown(),
            const SizedBox(height: 24.0),

            // Certificate Documents
            _buildDocumentSection(
              'Professional Certificates',
              _certificateDocuments,
              _existingCertificates,
              'certificate',
            ),
            const SizedBox(height: 24.0),

            // ID Documents
            _buildDocumentSection(
              'ID Documents',
              _idDocuments,
              _existingIdDocuments,
              'id',
            ),
            const SizedBox(height: 32.0),

            // Save Button
            ElevatedButton(
              onPressed: !_isSaving ? _saveServiceProviderDetails : null,
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
                      'Save Service Provider Details',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
