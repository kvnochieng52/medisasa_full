import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/support_group/support_group_results_page.dart';

class ModernSupportGroupFinder extends StatefulWidget {
  const ModernSupportGroupFinder({Key? key}) : super(key: key);

  @override
  _ModernSupportGroupFinderState createState() => _ModernSupportGroupFinderState();
}

class _ModernSupportGroupFinderState extends State<ModernSupportGroupFinder> {
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  final _tagsController = TextEditingController();

  List<Map<String, dynamic>> _selectedCategories = [];
  List<String> _selectedTags = [];
  List<Map<String, dynamic>> _allCategories = [];

  bool _isCategoriesExpanded = false;
  bool _isTagsExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/support-groups/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allCategories = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _toggleCategory(Map<String, dynamic> category) {
    setState(() {
      final existingIndex = _selectedCategories.indexWhere((item) => item['id'] == category['id']);
      if (existingIndex >= 0) {
        _selectedCategories.removeAt(existingIndex);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _searchGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final searchData = {
        'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        'search': _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        'categories': _selectedCategories.map((cat) => cat['id']).toList(),
        'tags': _selectedTags,
      };

      print('Searching groups with data: $searchData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/support-groups/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(searchData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportGroupResultsPage(
                selectedCategories: _selectedCategories.map((cat) => cat['name'].toString()).toList(),
                selectedLocation: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
                selectedTags: _selectedTags,
                searchTerm: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
                searchResults: List<Map<String, dynamic>>.from(data['data']),
              ),
            ),
          );
        } else {
          _showErrorSnackBar('No groups found matching your criteria');
        }
      } else {
        _showErrorSnackBar('Failed to search groups. Please try again.');
      }
    } catch (e) {
      print('Error searching groups: $e');
      _showErrorSnackBar('Network error. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Support Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF008faf), Color(0xFF00a3c4)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Find Your Support Community',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with others who understand your journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Term Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.search, color: Color(0xFF008faf)),
                        SizedBox(width: 8),
                        Text(
                          'Search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by group name or description...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF008faf)),
                        SizedBox(width: 8),
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter city or area (e.g., Nairobi, Westlands)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categories Section
            Card(
              elevation: 2,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCategoriesExpanded = !_isCategoriesExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.category, color: Color(0xFF008faf)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Support Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                          ),
                          if (_selectedCategories.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008faf),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedCategories.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _isCategoriesExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF008faf),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isCategoriesExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select the type of support you\'re looking for:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7f8c8d),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allCategories.map((category) {
                              final isSelected = _selectedCategories.any((item) => item['id'] == category['id']);
                              return FilterChip(
                                label: Text(category['name']),
                                selected: isSelected,
                                onSelected: (_) => _toggleCategory(category),
                                selectedColor: const Color(0xFF008faf).withOpacity(0.2),
                                checkmarkColor: const Color(0xFF008faf),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF008faf) : null,
                                  fontWeight: isSelected ? FontWeight.w600 : null,
                                ),
                              );
                            }).toList(),
                          ),
                          if (_selectedCategories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Selected Categories:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedCategories.map((category) {
                                return Chip(
                                  label: Text(category['name']),
                                  onDeleted: () => _toggleCategory(category),
                                  backgroundColor: const Color(0xFF008faf).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF008faf),
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tags Section
            Card(
              elevation: 2,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isTagsExpanded = !_isTagsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.label, color: Color(0xFF008faf)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tags & Keywords',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                          ),
                          if (_selectedTags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008faf),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedTags.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _isTagsExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF008faf),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isTagsExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add keywords to refine your search:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7f8c8d),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagsController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., support, recovery, wellness',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.tag),
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addTag,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008faf),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          if (_selectedTags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Selected Tags:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedTags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchGroups,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008faf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const Row(
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
                          SizedBox(width: 12),
                          Text('Searching...'),
                        ],
                      )
                    : const Text(
                        'Find Support Groups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Browse All Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    final response = await http.get(
                      Uri.parse('${ApiConfig.baseUrl}/support-groups/public'),
                      headers: {'Content-Type': 'application/json'},
                    );

                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      if (data['success']) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupportGroupResultsPage(
                              selectedCategories: [],
                              selectedLocation: null,
                              selectedTags: [],
                              searchTerm: null,
                              searchResults: List<Map<String, dynamic>>.from(data['data']),
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    _showErrorSnackBar('Error loading groups');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008faf),
                  side: const BorderSide(color: Color(0xFF008faf)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Browse All Support Groups',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _searchController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}