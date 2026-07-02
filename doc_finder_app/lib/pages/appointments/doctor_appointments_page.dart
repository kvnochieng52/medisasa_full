import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/shared/subscription_gate.dart';
import 'package:xyvra_health/pages/prescriptions/new_lab_prescription_page.dart';
import 'package:xyvra_health/pages/prescriptions/new_medication_prescription_page.dart';
import 'package:xyvra_health/pages/prescriptions/new_radiology_prescription_page.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final int? doctorId;
  final String? doctorName;

  const DoctorAppointmentsPage({
    Key? key,
    this.doctorId,
    this.doctorName,
  }) : super(key: key);

  @override
  _DoctorAppointmentsPageState createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  DateTime? _selectedDate;

  final List<String> _statusOptions = [
    'all',
    'pending',
    'confirmed',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user from AuthService
      final authService = AuthService();
      final currentUser = authService.user;

      String url;
      int? doctorId = widget.doctorId;

      // If no doctorId provided in widget, try to get it from current user
      if (doctorId == null && currentUser != null) {
        // Check if current user is a doctor (account_type = 2) and get their ID
        if (currentUser['account_type'] == 2) {
          doctorId = currentUser['id'];
          print('Using current logged-in doctor ID: $doctorId');
        }
      }

      if (doctorId != null) {
        url = '${ApiConfig.baseUrl}/doctors/$doctorId/appointments';
        print('Fetching appointments for doctor ID: $doctorId from URL: $url');
      } else {
        url = '${ApiConfig.baseUrl}/appointments';
        print('Fetching all appointments from URL: $url');
      }

      // Use authenticated request if available
      http.Response response;
      if (authService.isAuthenticated) {
        response = await authService.authenticatedRequest('GET', doctorId != null ? '/doctors/$doctorId/appointments' : '/appointments');
      } else {
        response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            if (data['data'] is Map && data['data']['data'] != null) {
              // Paginated response
              appointments = (data['data']['data'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            } else {
              // Direct response
              appointments = (data['data'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load appointments';
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

  Future<void> _updateAppointmentStatus(int appointmentId, String newStatus) async {
    try {
      final authService = AuthService();

      http.Response response;
      if (authService.isAuthenticated) {
        response = await authService.authenticatedRequest(
          'PATCH',
          '/appointments/$appointmentId/status',
          body: {'status': newStatus}
        );
      } else {
        response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId/status'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'status': newStatus}),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAppointments(); // Refresh the list
        } else {
          _showErrorMessage(data['message'] ?? 'Failed to update appointment');
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('Network error: $e');
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

  String _getAppBarTitle() {
    if (widget.doctorName != null) {
      return 'Dr. ${widget.doctorName} - Appointments';
    }

    // Try to get current user's name from AuthService
    final authService = AuthService();
    final currentUser = authService.user;

    if (currentUser != null && currentUser['account_type'] == 2) {
      final doctorName = currentUser['name'] ?? 'Doctor';
      return 'Dr. $doctorName - Appointments';
    }

    return 'Doctor Appointments';
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    List<Map<String, dynamic>> filtered = appointments;

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((appointment) =>
          appointment['status'] == _selectedStatus).toList();
    }

    // Filter by date
    if (_selectedDate != null) {
      String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      filtered = filtered.where((appointment) =>
          appointment['appointment_date'] == selectedDateStr).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getConsultationTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'in_person':
        return 'In Person';
      case 'online':
        return 'Online';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSubscriptionBanner(),
          _buildFilterSection(),
          Expanded(
            child: _buildAppointmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    final m = SubscriptionManager();
    if (!m.isServiceProvider || !m.hasActiveSubscription) {
      return const SizedBox.shrink();
    }
    final limit = m.maxAppointmentsPerMonth;
    final limitText = limit != null ? '$limit appointments/month' : 'Unlimited appointments/month';
    final planName = m.planName ?? 'Active Plan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border(bottom: BorderSide(color: const Color(0xFF4F46E5).withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$planName · $limitText',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'all' ? 'All Status' : status.toUpperCase(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Date Filter'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
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
              onPressed: _loadAppointments,
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

    final filteredAppointments = _filteredAppointments;

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == 'all' && _selectedDate == null
                  ? 'No appointments found'
                  : 'No appointments match the selected filters',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    try {
      final appointmentDate = DateTime.parse(appointment['appointment_date']);
      final appointmentTime = appointment['appointment_time'];

      // Parse time - handle both string and full datetime formats
      String timeString = appointmentTime;
      if (appointmentTime.contains('T')) {
        final dateTime = DateTime.parse(appointmentTime);
        timeString = DateFormat('HH:mm').format(dateTime);
      } else if (appointmentTime.contains(':') && appointmentTime.length >= 5) {
        timeString = appointmentTime.substring(0, 5);
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: statusColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'APT-${appointment['id'].toString().padLeft(6, '0')}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Appointment details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient info
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF008faf),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment['patient_name'] ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date and time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF008faf),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(appointmentDate)} at $timeString',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7f8c8d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Consultation type
                  Row(
                    children: [
                      Icon(
                        appointment['consultation_type'] == 'online'
                            ? Icons.video_call
                            : Icons.local_hospital,
                        color: const Color(0xFF008faf),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getConsultationTypeText(appointment['consultation_type'] ?? 'in_person'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7f8c8d),
                        ),
                      ),
                    ],
                  ),

                  // Contact info
                  if (appointment['patient_email'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xFF008faf),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointment['patient_email'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7f8c8d),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (appointment['patient_telephone'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xFF008faf),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointment['patient_telephone'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7f8c8d),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Notes
                  if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7f8c8d),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment['notes'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Prescription shortcuts (visible for confirmed + completed appointments)
                  if (status == 'confirmed' || status == 'completed') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewMedicationPrescriptionPage(
                                  appointmentId: appointment['id'] is int
                                      ? appointment['id']
                                      : int.tryParse('${appointment['id']}'),
                                  patientName: appointment['patient_name'],
                                  patientEmail: appointment['patient_email'],
                                  patientPhone: appointment['patient_telephone'],
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.medication, size: 18, color: Color(0xFF008faf)),
                            label: const Text('Medication Rx', style: TextStyle(color: Color(0xFF008faf))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF008faf)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewLabPrescriptionPage(
                                  appointmentId: appointment['id'] is int
                                      ? appointment['id']
                                      : int.tryParse('${appointment['id']}'),
                                  patientName: appointment['patient_name'],
                                  patientEmail: appointment['patient_email'],
                                  patientPhone: appointment['patient_telephone'],
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.biotech, size: 18, color: Color(0xFF8b5cf6)),
                            label: const Text('Lab Order', style: TextStyle(color: Color(0xFF8b5cf6))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8b5cf6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewRadiologyPrescriptionPage(
                              appointmentId: appointment['id'] is int
                                  ? appointment['id']
                                  : int.tryParse('${appointment['id']}'),
                              patientName: appointment['patient_name'],
                              patientEmail: appointment['patient_email'],
                              patientPhone: appointment['patient_telephone'],
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.medical_information, size: 18, color: Color(0xFFf43f5e)),
                        label: const Text('Radiology Order', style: TextStyle(color: Color(0xFFf43f5e))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFf43f5e)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],

                  // Action buttons
                  if (status == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus(
                              appointment['id'],
                              'confirmed',
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus(
                              appointment['id'],
                              'cancelled',
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'confirmed') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateAppointmentStatus(
                          appointment['id'],
                          'completed',
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark as Completed'),
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
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback for any parsing errors
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Error displaying appointment: ${appointment['patient_name'] ?? 'Unknown'}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }
}