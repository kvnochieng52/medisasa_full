import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/find_facility/facility_results_page.dart';

class ModernFacilityFinder extends StatefulWidget {
  const ModernFacilityFinder({Key? key}) : super(key: key);

  @override
  _ModernFacilityFinderState createState() => _ModernFacilityFinderState();
}

class _ModernFacilityFinderState extends State<ModernFacilityFinder> {
  final _locationController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _conditionsController = TextEditingController();

  String? selectedSpecialization;
  bool _isSymptomsExpanded = false;
  bool _isConditionsExpanded = false;
  bool _isSpecializationExpanded = false;
  bool _isLoading = false;

  List<String> _selectedSymptoms = [];
  List<String> _selectedConditions = [];
  List<Map<String, dynamic>> _allSymptoms = [];
  List<Map<String, dynamic>> _allConditions = [];
  List<Map<String, dynamic>> _allSpecializations = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadSymptoms();
    await _loadConditions();
    await _loadSpecializations();
  }

  Future<void> _loadSymptoms() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/symptoms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _allSymptoms = (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading symptoms: $e');
    }
  }

  Future<void> _loadConditions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conditions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _allConditions = (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading conditions: $e');
    }
  }

  Future<void> _loadSpecializations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/specializations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _allSpecializations = (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading specializations: $e');
      // Fallback to hardcoded specializations
      setState(() {
        _allSpecializations = [
          {'id': 1, 'specialization_name': 'General Care'},
          {'id': 2, 'specialization_name': 'Cardiologist'},
          {'id': 3, 'specialization_name': 'Dermatologist'},
          {'id': 4, 'specialization_name': 'Pediatrician'},
          {'id': 5, 'specialization_name': 'Orthopedic'},
          {'id': 6, 'specialization_name': 'Dentist'},
        ];
      });
    }
  }

  void _getCurrentLocation() {
    setState(() {
      _locationController.text = 'Nairobi, Kenya';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location set to: Nairobi, Kenya'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<String> _parseCommaSeparatedInput(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _searchFacilities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final symptoms = _parseCommaSeparatedInput(_symptomsController.text);
      final conditions = _parseCommaSeparatedInput(_conditionsController.text);

      final searchData = {
        'location': _locationController.text.trim(),
        'symptoms': symptoms,
        'diseases': conditions,
        'specialty': selectedSpecialization,
      };

      print('Searching facilities with data: $searchData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/public-facilities/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(searchData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Facility search response: $data');

        if (data['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacilityResultsPage(
                selectedSpecialty: selectedSpecialization,
                selectedLocation: _locationController.text.trim(),
                selectedSymptoms: symptoms,
                selectedDiseases: conditions,
                searchResults: data['data'] != null
                    ? (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList()
                    : [],
              ),
            ),
          );
        } else {
          _showErrorMessage('Search failed: ${data['message']}');
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Search error: $e');
      _showErrorMessage('Network error. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find a Hospital',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008faf),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF008faf), Color(0xFFe8f5f7)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildLocationField(),
              const SizedBox(height: 20),
              _buildExpandableSection(
                title: 'Symptoms',
                isExpanded: _isSymptomsExpanded,
                onToggle: () => setState(() => _isSymptomsExpanded = !_isSymptomsExpanded),
                child: _buildSymptomsField(),
              ),
              const SizedBox(height: 16),
              _buildExpandableSection(
                title: 'Conditions',
                isExpanded: _isConditionsExpanded,
                onToggle: () => setState(() => _isConditionsExpanded = !_isConditionsExpanded),
                child: _buildConditionsField(),
              ),
              const SizedBox(height: 16),
              _buildExpandableSection(
                title: 'Specialization',
                isExpanded: _isSpecializationExpanded,
                onToggle: () => setState(() => _isSpecializationExpanded = !_isSpecializationExpanded),
                child: _buildSpecializationDropdown(),
              ),
              const SizedBox(height: 32),
              _buildSearchButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF008faf).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF008faf),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Your Hospital',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search by location, symptoms, or specialization',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF008faf), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter city, area, or hospital name',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF008faf)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF008faf)),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Use current location',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF008faf), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008faf).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForSection(title),
                      color: const Color(0xFF008faf),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF008faf),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  IconData _getIconForSection(String title) {
    switch (title) {
      case 'Symptoms':
        return Icons.sick;
      case 'Conditions':
        return Icons.healing;
      case 'Specialization':
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }

  Widget _buildSymptomsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _symptomsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter symptoms separated by commas (e.g., headache, fever, nausea)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008faf), width: 2),
            ),
          ),
        ),
        if (_allSymptoms.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Common symptoms:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _allSymptoms.take(6).map((symptom) {
              return GestureDetector(
                onTap: () {
                  final currentText = _symptomsController.text;
                  final newText = currentText.isEmpty
                      ? symptom['name']
                      : '$currentText, ${symptom['name']}';
                  _symptomsController.text = newText;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008faf).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF008faf).withOpacity(0.3)),
                  ),
                  child: Text(
                    symptom['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF008faf),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildConditionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _conditionsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter conditions separated by commas (e.g., diabetes, hypertension)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008faf), width: 2),
            ),
          ),
        ),
        if (_allConditions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Common conditions:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _allConditions.take(6).map((condition) {
              return GestureDetector(
                onTap: () {
                  final currentText = _conditionsController.text;
                  final newText = currentText.isEmpty
                      ? condition['name']
                      : '$currentText, ${condition['name']}';
                  _conditionsController.text = newText;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008faf).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF008faf).withOpacity(0.3)),
                  ),
                  child: Text(
                    condition['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF008faf),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecializationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSpecialization,
      onChanged: (newValue) {
        setState(() {
          selectedSpecialization = newValue;
        });
      },
      decoration: InputDecoration(
        hintText: 'Select a specialization (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008faf), width: 2),
        ),
      ),
      items: _allSpecializations.map((spec) {
        return DropdownMenuItem<String>(
          value: spec['specialization_name'],
          child: Text(spec['specialization_name']),
        );
      }).toList(),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008faf), Color(0xFF005f7a)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008faf).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _searchFacilities,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Find Hospitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
    _symptomsController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }
}