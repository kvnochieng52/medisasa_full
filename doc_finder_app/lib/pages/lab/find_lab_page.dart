import 'package:xyvra_health/pages/find_doctor/doctor_list_page.dart';
import 'package:xyvra_health/pages/find_hospital/hospital_list_page.dart';
import 'package:xyvra_health/pages/lab/lab_list_page.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

enum LabServiceType { lab, radiology, both }

class FindLabPage extends StatefulWidget {
  final LabServiceType serviceType;
  const FindLabPage({Key? key, this.serviceType = LabServiceType.both}) : super(key: key);

  @override
  _FindLabPageState createState() => _FindLabPageState();
}

class _FindLabPageState extends State<FindLabPage> {
  String? selectedSpecialty;
  String? selectedCounty;
  String? selectedLocation;
  String? hospitalName; // Variable to store the hospital name
  List<String> selectedSymptoms = [];
  List<String> selectedDiseases = [];
  bool useCurrentLocation = true; // New variable for the checkbox
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> specialties = [
    'General Care',
    'Cardiologist',
    'Dentist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic'
  ];

  final List<String> counties = ['Nairobi', 'Kisumu', 'Mombasa'];
  final List<String> locations = ['Karen', 'Runda', 'Muthaiga'];

  // List of symptoms and diseases
  final List<Map<String, dynamic>> tests = [
    {'name': 'Complete Blood Count (CBC)', 'id': 'cbc'},
    {'name': 'Lipid Panel', 'id': 'lipid_panel'},
    {'name': 'Blood Glucose Test', 'id': 'blood_glucose'},
    {'name': 'Liver Function Test (LFT)', 'id': 'lft'},
    {'name': 'Urinalysis', 'id': 'urinalysis'},
    {'name': 'Urine Culture', 'id': 'urine_culture'},
    {'name': 'Thyroid Function Test', 'id': 'thyroid_function'},
    {'name': 'MRI', 'id': 'mri'},
    {'name': 'X-ray', 'id': 'x_ray'},
    {'name': 'Biopsy', 'id': 'biopsy'},
    {'name': 'Fecal Occult Blood Test', 'id': 'fobt'},
    {'name': 'Pulmonary Function Test (PFT)', 'id': 'pft'},
    {'name': 'Allergy Test', 'id': 'allergy_test'},
    {'name': 'Electrocardiogram (ECG/EKG)', 'id': 'ecg'},
    {'name': 'Bone Density Test (DEXA)', 'id': 'dexa'},
  ];

  final List<Map<String, dynamic>> scanning = [
    {'name': 'MRI (Magnetic Resonance Imaging)', 'id': 'mri'},
    {'name': 'CT Scan (Computed Tomography)', 'id': 'ct_scan'},
    {'name': 'Ultrasound', 'id': 'ultrasound'},
    {'name': 'X-ray', 'id': 'x_ray'},
    {'name': 'Mammogram', 'id': 'mammogram'},
    {'name': 'Bone Density Scan (DEXA)', 'id': 'dexa'},
    {'name': 'PET Scan (Positron Emission Tomography)', 'id': 'pet_scan'},
    {'name': 'Echocardiogram', 'id': 'echocardiogram'},
    {'name': 'Fluoroscopy', 'id': 'fluoroscopy'},
    {'name': 'Angiography', 'id': 'angiography'},
  ];

  // Placeholder for the current location (you can replace this with actual logic to get the user's location)
  String currentLocation = 'Karen, Nairobi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serviceType == LabServiceType.lab
              ? 'Find Lab'
              : widget.serviceType == LabServiceType.radiology
                  ? 'Find Radiology'
                  : 'Find Lab/Radiology',
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf), // Set the app bar color
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text("Use my current location"),
              value: useCurrentLocation,
              onChanged: (bool? value) {
                setState(() {
                  useCurrentLocation = value!;
                  if (useCurrentLocation) {
                    selectedCounty =
                        null; // Reset county when using current location
                    selectedLocation =
                        null; // Reset location when using current location
                  }
                });
              },
            ),
            if (!useCurrentLocation) ...[
              const Text(
                'County',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedCounty,
                onChanged: (newValue) {
                  setState(() {
                    selectedCounty = newValue;
                  });
                },
                items: counties.map((county) {
                  return DropdownMenuItem<String>(
                    value: county,
                    child: Text(county),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a county',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedLocation,
                onChanged: (newValue) {
                  setState(() {
                    selectedLocation = newValue;
                  });
                },
                items: locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a location',
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.location_pin, // Use the appropriate icon
                    color: Colors.red, // You can change the color as needed
                  ),
                  const SizedBox(
                      width: 8), // Add some space between the icon and text
                  Text(
                    'Current Location: $currentLocation', // Show current location
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Test to be conducted?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField(
              items: tests
                  .map((disease) =>
                      MultiSelectItem(disease['id'], disease['name']))
                  .toList(),
              title: const Text("Select Tests"),
              buttonText: const Text("Choose Tests"),
              initialValue: selectedDiseases,
              onConfirm: (values) {
                setState(() {
                  selectedDiseases = List<String>.from(values);
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Colors.blue.shade100,
                textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.black), // Set text color for visibility
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scanning to be conducted?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField(
              items: scanning
                  .map((symptom) =>
                      MultiSelectItem(symptom['id'], symptom['name']))
                  .toList(),
              title: const Text("Select Scanning"),
              buttonText: const Text("Choose Scanning"),
              initialValue: selectedSymptoms,
              onConfirm: (values) {
                setState(() {
                  selectedSymptoms = List<String>.from(values);
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Colors.blue.shade100,
                textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.black), // Set text color for visibility
              ),
            ),
            const SizedBox(height: 24),

            // Add the Hospital Name TextField here

            Center(
              child: SizedBox(
                width: double.infinity, // Makes the button take the full width
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LabListPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF008faf),
                      foregroundColor: Colors.white),
                  child: const Text('Search Lab/Radiology'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
