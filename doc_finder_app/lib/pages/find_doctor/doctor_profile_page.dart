import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_appointment_booking.dart';
import 'package:xyvra_health/widgets/rating_display_widget.dart';
import 'package:xyvra_health/widgets/rating_form_widget.dart';

class DoctorProfilePage extends StatelessWidget {
  final int? doctorId;
  final Map<String, dynamic>? doctorData;

  const DoctorProfilePage({
    Key? key,
    this.doctorId,
    this.doctorData,
    // Legacy support - for backwards compatibility
    @Deprecated('Use doctorData instead') Map<String, dynamic>? doctor,
  }) : super(key: key);

  // Legacy constructor for backwards compatibility
  const DoctorProfilePage.legacy({
    Key? key,
    required Map<String, dynamic> doctor,
  }) : doctorId = null,
       doctorData = doctor,
       super(key: key);

  // Getter to handle doctorId from data if not provided directly
  int? get _effectiveDoctorId => doctorId ?? doctorData?['id'];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showRatingForm(BuildContext context) {
    if (_effectiveDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor ID not available for rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingFormWidget(
          rateableType: 'doctor',
          rateableId: _effectiveDoctorId!,
          rateableName: doctorData?['name'] ?? 'Doctor',
          onRatingSubmitted: () {
            // Refresh the page or show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for your rating!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = doctorData ?? {};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Doctor Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF008faf),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF008faf),
                      const Color(0xFF008faf).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60), // Account for app bar
                    CircleAvatar(
                      backgroundImage: doctor['profile_image'] != null
                          ? NetworkImage(doctor['profile_image'])
                          : const AssetImage('assets/images/doctor.png') as ImageProvider,
                      radius: 60,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      doctor['name'] ?? 'Doctor Name',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (doctor['specialties'] as List? ?? []).join(', '),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and Location Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Color(0xFF008faf), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        doctor['location'] ?? 'Location not specified',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (doctor['rating'] != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${doctor['rating']}/5',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Rating',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
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
                  ),

                  const SizedBox(height: 16),

                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        doctor['bio'] ?? 'Experienced medical professional committed to providing quality healthcare.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Specialties Section
                  if (doctor['specialties'] != null && (doctor['specialties'] as List).isNotEmpty) ...[
                    const Text(
                      'Specialties',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (doctor['specialties'] as List).map((specialty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008faf).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF008faf).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                specialty.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF008faf),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Availability Section
                  if (doctor['availability'] != null && (doctor['availability'] as List).isNotEmpty) ...[
                    const Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (doctor['availability'] as List).map((time) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                time.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact Information
                  if (doctor['telephone'] != null) ...[
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFF008faf)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                doctor['telephone'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _makePhoneCall(doctor['telephone']),
                              icon: const Icon(Icons.call, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ratings Section
                  if (_effectiveDoctorId != null) ...[
                    RatingDisplayWidget(
                      rateableType: 'doctor',
                      rateableId: _effectiveDoctorId!,
                      showAddRatingButton: true,
                      rateableName: doctor['name'],
                      onAddRating: () => _showRatingForm(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (doctor['telephone'] != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(doctor['telephone']),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF008faf),
                    side: const BorderSide(color: Color(0xFF008faf)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_effectiveDoctorId != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingForm(context),
                  icon: const Icon(Icons.star_border),
                  label: const Text('Rate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[700],
                    side: BorderSide(color: Colors.amber[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorAppointmentBooking(doctor: doctor),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Book Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008faf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}