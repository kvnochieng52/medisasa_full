import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xyvra_health/widgets/rating_display_widget.dart';
import 'package:xyvra_health/widgets/rating_form_widget.dart';

class FacilityProfilePage extends StatelessWidget {
  final int? facilityId;
  final Map<String, dynamic>? facilityData;

  const FacilityProfilePage({
    Key? key,
    this.facilityId,
    this.facilityData,
    // Legacy support - for backwards compatibility
    @Deprecated('Use facilityData instead') Map<String, dynamic>? facility,
  }) : super(key: key);

  // Legacy constructor for backwards compatibility
  const FacilityProfilePage.legacy({
    Key? key,
    required Map<String, dynamic> facility,
  }) : facilityId = null,
       facilityData = facility,
       super(key: key);

  // Getter to handle facilityId from data if not provided directly
  int? get _effectiveFacilityId => facilityId ?? facilityData?['id'];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showRatingForm(BuildContext context) {
    if (_effectiveFacilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facility ID not available for rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingFormWidget(
          rateableType: 'facility',
          rateableId: _effectiveFacilityId!,
          rateableName: facilityData?['facility_name'] ?? 'Facility',
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
    final facility = facilityData ?? {};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Facility Header
          SliverAppBar(
            expandedHeight: 280,
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        facility['facility_name'] ?? 'Hospital Name',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (facility['facility_location'] != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              facility['facility_location'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  // About Section
                  const Text(
                    'About This Hospital',
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
                        facility['facility_profile'] ?? 'A healthcare facility committed to providing quality medical services to the community.',
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
                  if (facility['specialties'] != null && (facility['specialties'] as List).isNotEmpty) ...[
                    const Text(
                      'Medical Specialties',
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
                          children: (facility['specialties'] as List).map((specialty) {
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
                                specialty['specialization_name'] ?? specialty['name'] ?? 'Medical Service',
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

                  // Facility Type Section
                  if (facility['facility_type'] != null) ...[
                    const Text(
                      'Facility Type',
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
                            Icon(
                              Icons.business,
                              color: const Color(0xFF008faf),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                facility['facility_type']['name'] ?? 'Healthcare Facility',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2c3e50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Hospital Level Section (only for hospitals)
                  if (facility['facility_level'] != null) ...[
                    const Text(
                      'Hospital Level',
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
                            Icon(
                              Icons.local_hospital,
                              color: const Color(0xFF008faf),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                facility['facility_level']['name'] ?? 'General Hospital',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2c3e50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Insurance Acceptance Section
                  if (facility['insurances'] != null && (facility['insurances'] as List).isNotEmpty) ...[
                    const Text(
                      'Accepted Insurance',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: const Color(0xFF008faf),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'This facility accepts the following insurance:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2c3e50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (facility['insurances'] as List).map((insurance) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF008faf).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF008faf).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    insurance['name'] ?? 'Insurance Provider',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF008faf),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact Information Section
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone Contact
                  if (facility['facility_phone'] != null) ...[
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone, color: Colors.green),
                        ),
                        title: const Text(
                          'Phone',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(facility['facility_phone']),
                        trailing: IconButton(
                          onPressed: () => _makePhoneCall(facility['facility_phone']),
                          icon: const Icon(Icons.call, color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Email Contact
                  if (facility['facility_email'] != null) ...[
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008faf).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.email, color: Color(0xFF008faf)),
                        ),
                        title: const Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(facility['facility_email']),
                        trailing: IconButton(
                          onPressed: () => _sendEmail(facility['facility_email']),
                          icon: const Icon(Icons.send, color: Color(0xFF008faf)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Location Information
                  if (facility['facility_location'] != null) ...[
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.orange),
                        ),
                        title: const Text(
                          'Address',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(facility['facility_location']),
                        trailing: const Icon(Icons.map, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Additional Information
                  const Text(
                    'Additional Information',
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business, color: Color(0xFF008faf)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Facility Type',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Text('Hospital'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.green),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ratings Section
                  if (_effectiveFacilityId != null) ...[
                    RatingDisplayWidget(
                      rateableType: 'facility',
                      rateableId: _effectiveFacilityId!,
                      showAddRatingButton: true,
                      rateableName: facility['facility_name'],
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
            if (facility['facility_phone'] != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(facility['facility_phone']),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_effectiveFacilityId != null) ...[
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
            if (facility['facility_email'] != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendEmail(facility['facility_email']),
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
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
            if (facility['facility_phone'] == null && facility['facility_email'] == null) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Contact information not available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}