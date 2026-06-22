// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:xyvra_health/models/api_config.dart';

class YourFacilitiesPage extends StatefulWidget {
  const YourFacilitiesPage({Key? key}) : super(key: key);

  @override
  _YourFacilitiesPageState createState() => _YourFacilitiesPageState();
}

class _YourFacilitiesPageState extends State<YourFacilitiesPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _filteredFacilities = [];

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
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
            _filteredFacilities = _facilities;
          });
        }
      } else {
        _showMessage('Failed to load facilities', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading facilities: $e');
      _showMessage('Network error loading facilities', isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterFacilities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFacilities = _facilities;
      } else {
        _filteredFacilities = _facilities.where((facility) {
          final name =
              facility['facility_name']?.toString().toLowerCase() ?? '';
          final location =
              facility['facility_location']?.toString().toLowerCase() ?? '';
          final email =
              facility['facility_email']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              location.contains(searchQuery) ||
              email.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _deleteFacility(int facilityId, String facilityName) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Facility'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  facilityName,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final response = await _authService.authenticatedRequest(
          'DELETE',
          '/facilities/$facilityId',
        );

        if (response.statusCode == 200) {
          _showMessage('Facility deleted successfully', isError: false);
          _loadFacilities();
        } else {
          _showMessage('Failed to delete facility', isError: true);
        }
      } catch (e) {
        debugPrint('Error deleting facility: $e');
        _showMessage('Network error deleting facility', isError: true);
      }
    }
  }

  void _showFacilityMenu(BuildContext context, Map<String, dynamic> facility) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      facility['facility_name'] ?? 'Unknown Facility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildMenuOption(
                      icon: Icons.edit_outlined,
                      title: 'Edit Facility',
                      subtitle: 'Modify facility information',
                      color: Color(0xFF008faf),
                      onTap: () {
                        Navigator.pop(context); // Close the menu/dialog
                        // Navigate to edit facility page
                        context.goNamed(
                          'edit-facility',
                          pathParameters: {
                            'facilityId': facility['id'].toString(),
                          },
                          queryParameters: {
                            'title':
                                facility['facility_name'] ?? 'Edit Facility',
                          },
                        );
                      },
                    ),
                    // SizedBox(height: 12),
                    // _buildMenuOption(
                    //   icon: Icons.visibility_outlined,
                    //   title: 'View Details',
                    //   subtitle: 'See complete facility information',
                    //   color: Colors.green,
                    //   onTap: () {
                    //     Navigator.pop(context); // Close the menu/dialog
                    //     context.goNamed(
                    //       'facility-details',
                    //       pathParameters: {
                    //         'facilityId': facility['id'].toString(),
                    //       },
                    //     );
                    //   },
                    // ),
                    SizedBox(height: 12),
                    _buildMenuOption(
                      icon: Icons.delete_outline,
                      title: 'Delete Facility',
                      subtitle: 'Permanently remove this facility',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteFacility(
                          facility['id'] ?? 0,
                          facility['facility_name'] ?? 'Unknown Facility',
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final String baseUrl = ApiConfig.webUrl;
    return '$baseUrl/storage/$imagePath';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final DateTime date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Your Facilities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadFacilities,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF008faf), Color(0xFF006d85)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFacilities,
                decoration: InputDecoration(
                  hintText: 'Search facilities...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            _filterFacilities('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF008faf)),
                        SizedBox(height: 16),
                        Text(
                          'Loading facilities...',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _filteredFacilities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadFacilities,
                        color: Color(0xFF008faf),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredFacilities.length,
                          itemBuilder: (context, index) {
                            return _buildCompactFacilityCard(
                                _filteredFacilities[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/new-facility').then((_) {
            _loadFacilities();
          });
        },
        backgroundColor: Color(0xFF008faf),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Facility', style: TextStyle(color: Colors.white)),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF008faf).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Color(0xFF008faf),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No facilities found'
                : 'No facilities yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first facility to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/new-facility').then((_) {
                  _loadFacilities();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008faf),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 4,
              ),
              icon: Icon(Icons.add),
              label: Text('Create Facility', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactFacilityCard(Map<String, dynamic> facility) {
    final String name = facility['facility_name'] ?? 'Unknown Facility';
    final String location = facility['facility_location'] ?? 'Unknown Location';
    final String? logoPath = facility['facility_logo'];
    final String createdAt = _formatDate(facility['created_at']);
    final int isActive = facility['is_active'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showFacilityMenu(context, facility),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: logoPath != null && logoPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _buildImageUrl(logoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultLogo(size: 50);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF008faf),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildDefaultLogo(size: 50),
                ),

                SizedBox(width: 16),

                // Facility info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Status and menu
                Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive == 1
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive == 1 ? 'Active' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive == 1 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF008faf).withOpacity(0.1),
      ),
      child: Icon(
        Icons.business,
        size: size * 0.5,
        color: Color(0xFF008faf),
      ),
    );
  }
}
