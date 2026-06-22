import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/appointments/doctor_appointments_page.dart';
import 'package:xyvra_health/auth_service.dart';
import 'package:intl/intl.dart';

class AppointmentSummaryWidget extends StatefulWidget {
  final int? doctorId;

  const AppointmentSummaryWidget({
    Key? key,
    this.doctorId,
  }) : super(key: key);

  @override
  _AppointmentSummaryWidgetState createState() => _AppointmentSummaryWidgetState();
}

class _AppointmentSummaryWidgetState extends State<AppointmentSummaryWidget> {
  List<Map<String, dynamic>> todaysAppointments = [];
  bool _isLoading = true;
  int totalAppointments = 0;
  int pendingAppointments = 0;
  int confirmedAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointmentsSummary();
  }

  Future<void> _loadAppointmentsSummary() async {
    setState(() {
      _isLoading = true;
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
        }
      }

      if (doctorId != null) {
        url = '${ApiConfig.baseUrl}/doctors/$doctorId/appointments';
      } else {
        url = '${ApiConfig.baseUrl}/appointments';
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
          List<Map<String, dynamic>> allAppointments;

          if (data['data'] is Map && data['data']['data'] != null) {
            allAppointments = (data['data']['data'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          } else {
            allAppointments = (data['data'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }

          // Filter today's appointments
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todaysAppts = allAppointments.where((appointment) =>
              appointment['appointment_date'] == today).toList();

          // Calculate statistics
          final total = allAppointments.length;
          final pending = allAppointments.where((a) => a['status'] == 'pending').length;
          final confirmed = allAppointments.where((a) => a['status'] == 'confirmed').length;

          setState(() {
            todaysAppointments = todaysAppts;
            totalAppointments = total;
            pendingAppointments = pending;
            confirmedAppointments = confirmed;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading appointments summary: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF008faf).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note,
                  color: Color(0xFF008faf),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Appointments Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorAppointmentsPage(
                          doctorId: widget.doctorId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF008faf),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008faf)),
                ),
              ),
            )
          else ...[
            // Statistics Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      totalAppointments.toString(),
                      Icons.event,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      pendingAppointments.toString(),
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Confirmed',
                      confirmedAppointments.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Today's Appointments
            if (todaysAppointments.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Today\'s Appointments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaysAppointments.length > 3 ? 3 : todaysAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = todaysAppointments[index];
                  return _buildAppointmentItem(appointment);
                },
              ),
              if (todaysAppointments.length > 3)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '+ ${todaysAppointments.length - 3} more appointments today',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ] else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No appointments scheduled for today',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    Color statusColor;

    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    String timeString = appointment['appointment_time'];
    if (timeString.contains('T')) {
      final dateTime = DateTime.parse(timeString);
      timeString = DateFormat('HH:mm').format(dateTime);
    } else if (timeString.contains(':') && timeString.length >= 5) {
      timeString = timeString.substring(0, 5);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['patient_name'] ?? 'Unknown Patient',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}