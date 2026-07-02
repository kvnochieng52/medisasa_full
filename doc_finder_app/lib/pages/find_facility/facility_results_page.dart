import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xyvra_health/pages/find_facility/facility_profile_page.dart';

/// Which quick-access filter, if any, is driving this results page.
/// Maps 1:1 to the web `/hospitals?type=lab|radiology`.
enum FacilityQuickFilter { lab, radiology }

class FacilityResultsPage extends StatefulWidget {
  final String? selectedSpecialty;
  final String? selectedLocation;
  final List<String> selectedSymptoms;
  final List<String> selectedDiseases;
  final List<Map<String, dynamic>>? searchResults;

  /// When set, loads approved facilities and filters them by facility type
  /// (primary) or offered service (fallback). Mirrors the web homepage
  /// Lab / Radiology buttons.
  final FacilityQuickFilter? quickFilter;

  const FacilityResultsPage({
    Key? key,
    this.selectedSpecialty,
    this.selectedLocation,
    this.selectedSymptoms = const [],
    this.selectedDiseases = const [],
    this.searchResults,
    this.quickFilter,
  }) : super(key: key);

  @override
  _FacilityResultsPageState createState() => _FacilityResultsPageState();
}

class _FacilityResultsPageState extends State<FacilityResultsPage> {
  List<Map<String, dynamic>> facilities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.searchResults != null) {
      // Use provided search results
      setState(() {
        facilities = widget.searchResults!;
        _isLoading = false;
      });
    } else if (widget.quickFilter != null) {
      _loadApprovedThenQuickFilter();
    } else {
      // Load facilities from API
      _loadFacilities();
    }
  }

  /// Load all approved facilities and filter by the requested quick filter
  /// (facility type primary, offered service fallback).
  Future<void> _loadApprovedThenQuickFilter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/public-facilities/approved?per_page=50'),
        headers: {'Accept': 'application/json'},
      );
      if (resp.statusCode != 200) {
        setState(() {
          _errorMessage = 'Server error: ${resp.statusCode}';
          _isLoading = false;
        });
        return;
      }
      final data = json.decode(resp.body);
      final list = (data['data'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final filtered = list.where((f) => _matchesQuickFilter(f, widget.quickFilter!)).toList();

      setState(() {
        facilities = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  bool _matchesQuickFilter(Map<String, dynamic> f, FacilityQuickFilter which) {
    final typeName = (f['facility_type']?['name'] ?? '').toString().toLowerCase();
    final services = (f['offered_services'] as List? ?? []);

    late final RegExp typeRegex;
    late final RegExp serviceRegex;
    switch (which) {
      case FacilityQuickFilter.lab:
        typeRegex    = RegExp(r'\blab', caseSensitive: false);
        serviceRegex = RegExp(r'\blab|patholog', caseSensitive: false);
        break;
      case FacilityQuickFilter.radiology:
        typeRegex    = RegExp(r'radiolog|imaging|diagnostic', caseSensitive: false);
        serviceRegex = RegExp(
          r'radiolog|imaging|\bx[- ]?ray\b|mri|ct scan|ultrasound|mammogram',
          caseSensitive: false,
        );
        break;
    }

    if (typeName.isNotEmpty && typeRegex.hasMatch(typeName)) return true;

    for (final s in services) {
      final title = (s['title'] ?? '').toString();
      final ref = s['service'];
      final refName = (ref is Map ? (ref['name'] ?? '') : '').toString();
      if (serviceRegex.hasMatch(title) || (refName.isNotEmpty && serviceRegex.hasMatch(refName))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestBody = <String, dynamic>{};

      if (widget.selectedLocation != null && widget.selectedLocation!.isNotEmpty) {
        requestBody['location'] = widget.selectedLocation;
      }

      if (widget.selectedSpecialty != null && widget.selectedSpecialty!.isNotEmpty) {
        requestBody['specialty'] = widget.selectedSpecialty;
      }

      if (widget.selectedSymptoms.isNotEmpty) {
        requestBody['symptoms'] = widget.selectedSymptoms;
      }

      if (widget.selectedDiseases.isNotEmpty) {
        requestBody['diseases'] = widget.selectedDiseases;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/public-facilities/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            facilities = (data['data'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No facilities found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorMessage('Could not launch phone dialer');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorMessage('Could not launch email app');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _titleForQuickFilter() {
    switch (widget.quickFilter) {
      case FacilityQuickFilter.lab:
        return 'Laboratory & Radiology';
      case FacilityQuickFilter.radiology:
        return 'Radiology';
      case null:
        return 'Hospitals${widget.selectedLocation != null ? ' in ${widget.selectedLocation}' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleForQuickFilter(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.quickFilter != null
                ? _loadApprovedThenQuickFilter
                : _loadFacilities,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.selectedSymptoms.isNotEmpty ||
              widget.selectedDiseases.isNotEmpty ||
              widget.selectedSpecialty != null)
            _buildSearchCriteria(),
          Expanded(
            child: _buildFacilitiesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCriteria() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Criteria:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.selectedSpecialty != null) ...[
            _buildCriteriaChip('Specialty: ${widget.selectedSpecialty}', Colors.blue),
          ],
          if (widget.selectedSymptoms.isNotEmpty) ...[
            _buildCriteriaChip('Symptoms: ${widget.selectedSymptoms.join(', ')}', Colors.orange),
          ],
          if (widget.selectedDiseases.isNotEmpty) ...[
            _buildCriteriaChip('Conditions: ${widget.selectedDiseases.join(', ')}', Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFacilitiesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008faf)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFacilities,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008faf),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (facilities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hospitals found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFacilities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          return _buildFacilityCard(facility);
        },
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF008faf),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility['facility_name'] ?? 'Unknown Hospital',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (facility['facility_location'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                facility['facility_location'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Facility Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile/Description
                if (facility['facility_profile'] != null && facility['facility_profile'].isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    facility['facility_profile'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7f8c8d),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Specialties
                if (facility['specialties'] != null && facility['specialties'].isNotEmpty) ...[
                  const Text(
                    'Specialties',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (facility['specialties'] as List).map((specialty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF008faf).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF008faf).withOpacity(0.3)),
                        ),
                        child: Text(
                          specialty['specialization_name'] ?? specialty['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF008faf),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Facility Type and Details
                Row(
                  children: [
                    if (facility['facility_type'] != null) ...[
                      Icon(
                        Icons.business,
                        color: const Color(0xFF008faf),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        facility['facility_type']['name'] ?? 'Healthcare Facility',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2c3e50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (facility['facility_type'] != null && facility['facility_level'] != null) ...[
                      const SizedBox(width: 16),
                    ],
                    if (facility['facility_level'] != null) ...[
                      Icon(
                        Icons.local_hospital,
                        color: const Color(0xFF008faf),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        facility['facility_level']['name'] ?? 'General',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2c3e50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (facility['facility_type'] != null || facility['facility_level'] != null) ...[
                  const SizedBox(height: 12),
                ],

                // Insurance Information
                if (facility['insurances'] != null && (facility['insurances'] as List).isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: const Color(0xFF008faf),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Accepts Insurance',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2c3e50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '(${(facility['insurances'] as List).length} providers)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Column(
                  children: [
                    // Profile Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FacilityProfilePage(
                                    facilityId: facility['id'],
                                    facilityData: facility,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.business, size: 18),
                            label: const Text('View Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF008faf),
                              side: const BorderSide(color: Color(0xFF008faf)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Contact Information
                    Row(
                      children: [
                        // Phone
                        if (facility['facility_phone'] != null) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(facility['facility_phone']),
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (facility['facility_phone'] != null && facility['facility_email'] != null)
                          const SizedBox(width: 8),

                        // Email
                        if (facility['facility_email'] != null) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _sendEmail(facility['facility_email']),
                              icon: const Icon(Icons.email, size: 18),
                              label: const Text('Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF008faf),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Contact Details Text (if no buttons available)
                if (facility['facility_phone'] == null && facility['facility_email'] == null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Contact information not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}