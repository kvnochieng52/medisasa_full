// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/pages/groups/new_group/new_group.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:xyvra_health/models/api_config.dart';

class YourGroupsPage extends StatefulWidget {
  const YourGroupsPage({Key? key}) : super(key: key);

  @override
  _YourGroupsPageState createState() => _YourGroupsPageState();
}

class _YourGroupsPageState extends State<YourGroupsPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/groups',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _groups = List<Map<String, dynamic>>.from(responseData['data']);
            _filteredGroups = _groups;
          });
        } else {
          // Handle case where response is 200 but success is false
          final errorMessage =
              responseData['message'] ?? 'Unknown error occurred';
          debugPrint('API Error: $errorMessage');
          _showMessage('Failed to load groups: $errorMessage', isError: true);
        }
      } else {
        // Handle HTTP error responses
        String errorMessage = 'Failed to load groups';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If we can't decode the error response, use status code
          errorMessage =
              'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
        }

        debugPrint('HTTP Error ${response.statusCode}: ${response.body}');
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
      String errorMessage = 'Network error loading groups';

      // Provide more specific error messages based on exception type
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout - please try again';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response format';
      }

      _showMessage(errorMessage, isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _groups;
      } else {
        _filteredGroups = _groups.where((group) {
          final name = group['group_name']?.toString().toLowerCase() ?? '';
          final location =
              group['group_location']?.toString().toLowerCase() ?? '';
          final description =
              group['group_description']?.toString().toLowerCase() ?? '';
          final tags = group['group_tags']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              location.contains(searchQuery) ||
              description.contains(searchQuery) ||
              tags.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _deleteGroup(int groupId, String groupName) async {
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
              Text('Delete Group'),
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
                  groupName,
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
          '/groups/$groupId',
        );

        if (response.statusCode == 200) {
          _showMessage('Group deleted successfully', isError: false);
          _loadGroups();
        } else {
          _showMessage('Failed to delete group', isError: true);
        }
      } catch (e) {
        debugPrint('Error deleting group: $e');
        _showMessage('Network error deleting group', isError: true);
      }
    }
  }

  void _showGroupMenu(BuildContext context, Map<String, dynamic> group) {
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
                      group['group_name'] ?? 'Unknown Group',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildMenuOption(
                      icon: Icons.edit_outlined,
                      title: 'Edit Group',
                      subtitle: 'Modify group information',
                      color: Color(0xFF008faf),
                      onTap: () {
                        Navigator.pop(context); // Close the menu/dialog
                        // Navigate to edit group page
                        // context.goNamed(
                        //   'edit-group',
                        //   pathParameters: {
                        //     'groupId': group['id'].toString(),
                        //   },
                        //   queryParameters: {
                        //     'title': group['group_name'] ?? 'Edit Group',
                        //   },
                        // );
                      },
                    ),
                    SizedBox(height: 12),
                    _buildMenuOption(
                      icon: Icons.visibility_outlined,
                      title: 'View Details',
                      subtitle: 'See complete group information',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context); // Close the menu/dialog
                        context.goNamed(
                          'group-details',
                          pathParameters: {
                            'groupId': group['id'].toString(),
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    _buildMenuOption(
                      icon: Icons.people_outline,
                      title: 'Manage Members',
                      subtitle: 'View and manage group members',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        context.goNamed(
                          'group-members',
                          pathParameters: {
                            'groupId': group['id'].toString(),
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    _buildMenuOption(
                      icon: Icons.delete_outline,
                      title: 'Delete Group',
                      subtitle: 'Permanently remove this group',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteGroup(
                          group['id'] ?? 0,
                          group['group_name'] ?? 'Unknown Group',
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

  String _getPrivacyDisplay(String? privacy) {
    switch (privacy?.toLowerCase()) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'closed':
        return 'Closed';
      default:
        return 'Public';
    }
  }

  Color _getPrivacyColor(String? privacy) {
    switch (privacy?.toLowerCase()) {
      case 'public':
        return Colors.green;
      case 'private':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getPrivacyIcon(String? privacy) {
    switch (privacy?.toLowerCase()) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock_outline;
      case 'closed':
        return Icons.group_off_outlined;
      default:
        return Icons.public;
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
          'Your Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGroups,
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
                onChanged: _filterGroups,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            _filterGroups('');
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
                          'Loading groups...',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _filteredGroups.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadGroups,
                        color: Color(0xFF008faf),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) {
                            return _buildCompactGroupCard(
                                _filteredGroups[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewGroupPage(),
            ),
          ).then((_) {
            _loadGroups();
          });
        },
        backgroundColor: Color(0xFF008faf),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Group', style: TextStyle(color: Colors.white)),
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
              Icons.groups_outlined,
              size: 64,
              color: Color(0xFF008faf),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No groups found'
                : 'No groups yet',
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
                : 'Create your first group to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/new-group').then((_) {
                  _loadGroups();
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
              label: Text('Create Group', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactGroupCard(Map<String, dynamic> group) {
    final String name = group['group_name'] ?? 'Unknown Group';
    final String location = group['group_location'] ?? 'Unknown Location';
    final String description = group['group_description'] ?? '';
    final String? imagePath = group['group_image'];
    final String createdAt = _formatDate(group['created_at']);
    final String privacy = group['group_privacy'] ?? 'public';
    final bool requireApproval =
        group['require_approval'] == 1 || group['require_approval'] == true;

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
          onTap: () => _showGroupMenu(context, group),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _buildImageUrl(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultImage(size: 50);
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
                      : _buildDefaultImage(size: 50),
                ),

                SizedBox(width: 16),

                // Group info
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
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Privacy and menu
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPrivacyColor(privacy).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPrivacyIcon(privacy),
                            size: 12,
                            color: _getPrivacyColor(privacy),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getPrivacyDisplay(privacy),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getPrivacyColor(privacy),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (requireApproval) ...[
                      SizedBox(height: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Approval',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildDefaultImage({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF008faf).withOpacity(0.1),
      ),
      child: Icon(
        Icons.groups,
        size: size * 0.5,
        color: Color(0xFF008faf),
      ),
    );
  }
}
