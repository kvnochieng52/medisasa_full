import 'package:xyvra_health/pages/call_doctor/call_widget.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_list_page.dart';
import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:flutter/material.dart';

class ScheduleAppointmentSectionWidget extends StatelessWidget {
  const ScheduleAppointmentSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0), // Even smaller outer padding
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Reduced inner padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 13, // Smaller title
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No appointments',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FindDoctorPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Book', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008faf),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallWidget(
                              doctorName: 'Dr. Stanley Wahome',
                              doctorImage:
                                  'assets/images/Dr.-Stanley-Wahome.png',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_call,
                          color: Colors.red, size: 16),
                      label:
                          const Text('Video', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
