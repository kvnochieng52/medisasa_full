import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorAppointmentBooking extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorAppointmentBooking({Key? key, required this.doctor}) : super(key: key);

  @override
  _DoctorAppointmentBookingState createState() => _DoctorAppointmentBookingState();
}

class _DoctorAppointmentBookingState extends State<DoctorAppointmentBooking> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String _consultationType = 'in_person';
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots(_selectedDate);
  }

  Future<void> _loadAvailableSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/${widget.doctor['id']}/available-slots?date=${date.toIso8601String().split('T')[0]}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _availableSlots = List<String>.from(responseData['available_slots']);
          });
        }
      }
    } catch (e) {
      print('Error loading available slots: $e');
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedTime == null) {
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/appointments/book'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'doctor_id': widget.doctor['id'],
          'patient_name': _nameController.text,
          'patient_email': _emailController.text,
          'patient_telephone': _phoneController.text,
          'patient_location': _locationController.text,
          'appointment_date': _selectedDate.toIso8601String().split('T')[0],
          'appointment_time': _selectedTime,
          'consultation_type': _consultationType,
          'notes': _notesController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        _showSuccessDialog(responseData['response']['appointment_details']);
      } else if (response.statusCode == 409) {
        // Conflict - time slot already booked
        _showConflictDialog(responseData['response']);
      } else {
        _showErrorDialog(responseData['message'] ?? 'Failed to book appointment');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please check your connection and try again.');
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> appointmentDetails) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('Appointment Booked!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your appointment has been successfully booked with Dr. ${appointmentDetails['doctor']}.'),
              const SizedBox(height: 16),
              _buildDetailRow('Date:', appointmentDetails['date']),
              _buildDetailRow('Time:', appointmentDetails['time']),
              _buildDetailRow('Type:', appointmentDetails['type']),
              _buildDetailRow('Confirmation:', appointmentDetails['confirmation_number']),
              const SizedBox(height: 16),
              const Text(
                'You will receive a confirmation email shortly.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showConflictDialog(Map<String, dynamic> conflictInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning,
            color: Colors.orange,
            size: 64,
          ),
          title: const Text('Time Slot Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(conflictInfo['message']),
              if (conflictInfo['suggested_times'] != null) ...[
                const SizedBox(height: 16),
                const Text('Suggested alternative times:'),
                const SizedBox(height: 8),
                ...List<String>.from(conflictInfo['suggested_times']).map(
                  (time) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time),
                    title: Text(time),
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (conflictInfo['suggested_times'] != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadAvailableSlots(_selectedDate);
                },
                child: const Text('Refresh Times'),
              ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 64,
          ),
          title: const Text('Booking Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book with Dr. ${widget.doctor['name']}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.doctor['profile_image'] != null
                            ? NetworkImage(widget.doctor['profile_image'])
                            : const AssetImage('assets/images/doctor.png') as ImageProvider,
                        radius: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctor['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              (widget.doctor['specialties'] as List).join(', '),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                Text(
                                  widget.doctor['location'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Patient Information
              const Text(
                'Patient Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Your Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Consultation Type
              const Text(
                'Consultation Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('In-Person'),
                        ],
                      ),
                      value: 'in_person',
                      groupValue: _consultationType,
                      onChanged: (value) {
                        setState(() {
                          _consultationType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.video_call),
                          SizedBox(width: 8),
                          Text('Online'),
                        ],
                      ),
                      value: 'online',
                      groupValue: _consultationType,
                      onChanged: (value) {
                        setState(() {
                          _consultationType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDate, selectedDay)) {
                    setState(() {
                      _selectedDate = selectedDay;
                    });
                    _loadAvailableSlots(selectedDay);
                  }
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF008faf),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF008faf),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                ),
              ),

              const SizedBox(height: 24),

              // Time Selection
              const Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_isLoadingSlots)
                const Center(child: CircularProgressIndicator())
              else if (_availableSlots.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No available time slots for this date. Please select another date.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((time) {
                    final isSelected = _selectedTime == time;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF008faf) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF008faf) : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Notes
              const Text(
                'Additional Notes (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Any specific concerns or symptoms?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008faf),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Book Appointment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}