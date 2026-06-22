import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_appointment_booking.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_profile_page.dart';
import 'package:xyvra_health/services/doctor_favorite_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorResultsPage extends StatefulWidget {
  final String? selectedSpecialty;
  final String? selectedLocation;
  final List<String> selectedSymptoms;
  final List<String> selectedDiseases;
  final List<Map<String, dynamic>>? searchResults;

  const DoctorResultsPage({
    Key? key,
    this.selectedSpecialty,
    this.selectedLocation,
    this.selectedSymptoms = const [],
    this.selectedDiseases = const [],
    this.searchResults,
  }) : super(key: key);

  @override
  _DoctorResultsPageState createState() => _DoctorResultsPageState();
}

class _DoctorResultsPageState extends State<DoctorResultsPage> {
  List<Map<String, dynamic>> doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  final DoctorFavoriteService _favoriteService = DoctorFavoriteService();
  Map<int, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.searchResults != null) {
      // Use provided search results
      setState(() {
        doctors = widget.searchResults!;
        _isLoading = false;
      });
      _loadFavoriteStatus();
    } else {
      // Load doctors from API
      _loadDoctors();
    }
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestBody = <String, dynamic>{};

      if (widget.selectedSpecialty != null && widget.selectedSpecialty!.isNotEmpty) {
        requestBody['specialty'] = widget.selectedSpecialty!;
      }

      if (widget.selectedLocation != null && widget.selectedLocation!.isNotEmpty) {
        requestBody['location'] = widget.selectedLocation!;
      }

      if (widget.selectedSymptoms.isNotEmpty) {
        requestBody['symptoms'] = widget.selectedSymptoms;
      }

      if (widget.selectedDiseases.isNotEmpty) {
        requestBody['diseases'] = widget.selectedDiseases;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctors/search'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            doctors = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoading = false;
          });
          _loadFavoriteStatus();
        } else {
          setState(() {
            _errorMessage = 'Failed to load doctors';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not launch dialer"),
        ),
      );
    }
  }

  Future<void> _loadFavoriteStatus() async {
    for (final doctor in doctors) {
      final doctorId = doctor['id'] as int;
      try {
        final isFavorited = await _favoriteService.isFavorited(doctorId);
        setState(() {
          _favoriteStatus[doctorId] = isFavorited;
        });
      } catch (e) {
        // Ignore error for individual checks
        setState(() {
          _favoriteStatus[doctorId] = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(int doctorId) async {
    try {
      final result = await _favoriteService.toggleFavorite(doctorId);
      setState(() {
        _favoriteStatus[doctorId] = result['is_favorited'] == true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Favorite status updated'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Doctors',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDoctors,
                        child: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008faf),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : doctors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008faf),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Search criteria summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[100],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Found ${doctors.length} doctor${doctors.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.selectedSpecialty != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Specialty: ${widget.selectedSpecialty}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              if (widget.selectedLocation != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Location: ${widget.selectedLocation}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Doctor list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return _buildDoctorCard(doctor);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final doctorId = doctor['id'] as int;
    final isFavorited = _favoriteStatus[doctorId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: doctor['profile_image'] != null
                      ? NetworkImage(doctor['profile_image'])
                      : const AssetImage('assets/images/doctor.png') as ImageProvider,
                  radius: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (doctor['specialties'] as List).join(', '),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor['location'] ?? 'Location not specified',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (doctor['rating'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor['rating']}/5',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFavorite(doctorId),
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                  tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doctor['bio'] ?? 'Experienced medical professional',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorProfilePage(
                                doctorId: doctor['id'],
                                doctorData: doctor,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person, size: 18),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorAppointmentBooking(doctor: doctor),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Book Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008faf),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (doctor['telephone'] != null)
                      OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(doctor['telephone']),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF008faf),
                          side: const BorderSide(color: Color(0xFF008faf)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}