import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_config.dart';
import '../models/prescription.dart';

class PrescriptionService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------- Medication ----------

  static Future<List<MedicationPrescription>> listMedication() async {
    final res = await http.get(Uri.parse('$_baseUrl/prescriptions/medication?per_page=50'),
        headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load prescriptions');
    }
    final body = json.decode(res.body);
    final raw = body['data'];
    final list = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return list.map((e) => MedicationPrescription.fromJson(e)).toList();
  }

  static Future<MedicationPrescription> getMedication(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/prescriptions/medication/$id'),
        headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load prescription');
    }
    final body = json.decode(res.body);
    return MedicationPrescription.fromJson(body['data']);
  }

  static Future<MedicationPrescription> createMedication({
    int? appointmentId,
    String? clinicName,
    String? clinicAddress,
    required String patientName,
    String? patientEmail,
    String? patientPhone,
    String? patientDob,
    int? patientAge,
    String? diagnosis,
    String? notes,
    required List<MedicationItem> items,
  }) async {
    final payload = {
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (clinicName != null && clinicName.isNotEmpty) 'clinic_name': clinicName,
      if (clinicAddress != null && clinicAddress.isNotEmpty) 'clinic_address': clinicAddress,
      'patient_name': patientName,
      if (patientEmail != null && patientEmail.isNotEmpty) 'patient_email': patientEmail,
      if (patientPhone != null && patientPhone.isNotEmpty) 'patient_phone': patientPhone,
      if (patientDob != null && patientDob.isNotEmpty) 'patient_dob': patientDob,
      if (patientAge != null) 'patient_age': patientAge,
      if (diagnosis != null && diagnosis.isNotEmpty) 'diagnosis': diagnosis,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/prescriptions/medication'),
      headers: await _headers(jsonBody: true),
      body: json.encode(payload),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to save prescription');
    }
    return MedicationPrescription.fromJson(json.decode(res.body)['data']);
  }

  static Future<void> emailMedication(int id, {String? email}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/prescriptions/medication/$id/email'),
      headers: await _headers(jsonBody: true),
      body: json.encode({if (email != null && email.isNotEmpty) 'email': email}),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to send email');
    }
  }

  static Future<File> downloadMedicationPdf(int id, String filename) async {
    return _downloadPdf('/prescriptions/medication/$id/pdf', filename);
  }

  // ---------- Lab ----------

  static Future<List<LabPrescription>> listLab() async {
    final res = await http.get(Uri.parse('$_baseUrl/prescriptions/lab?per_page=50'),
        headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load lab orders');
    }
    final body = json.decode(res.body);
    final raw = body['data'];
    final list = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return list.map((e) => LabPrescription.fromJson(e)).toList();
  }

  static Future<LabPrescription> getLab(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/prescriptions/lab/$id'),
        headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load lab order');
    }
    final body = json.decode(res.body);
    return LabPrescription.fromJson(body['data']);
  }

  static Future<LabPrescription> createLab({
    int? appointmentId,
    String? clinicName,
    String? clinicAddress,
    required String patientName,
    String? patientEmail,
    String? patientPhone,
    String? patientDob,
    int? patientAge,
    String? clinicalInformation,
    String? notes,
    required List<LabItem> items,
  }) async {
    final payload = {
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (clinicName != null && clinicName.isNotEmpty) 'clinic_name': clinicName,
      if (clinicAddress != null && clinicAddress.isNotEmpty) 'clinic_address': clinicAddress,
      'patient_name': patientName,
      if (patientEmail != null && patientEmail.isNotEmpty) 'patient_email': patientEmail,
      if (patientPhone != null && patientPhone.isNotEmpty) 'patient_phone': patientPhone,
      if (patientDob != null && patientDob.isNotEmpty) 'patient_dob': patientDob,
      if (patientAge != null) 'patient_age': patientAge,
      if (clinicalInformation != null && clinicalInformation.isNotEmpty)
        'clinical_information': clinicalInformation,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/prescriptions/lab'),
      headers: await _headers(jsonBody: true),
      body: json.encode(payload),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to save lab order');
    }
    return LabPrescription.fromJson(json.decode(res.body)['data']);
  }

  static Future<void> emailLab(int id, {String? email}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/prescriptions/lab/$id/email'),
      headers: await _headers(jsonBody: true),
      body: json.encode({if (email != null && email.isNotEmpty) 'email': email}),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to send email');
    }
  }

  static Future<File> downloadLabPdf(int id, String filename) async {
    return _downloadPdf('/prescriptions/lab/$id/pdf', filename);
  }

  // ---------- Shared ----------

  static Future<File> _downloadPdf(String path, String filename) async {
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to download PDF (${res.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(res.bodyBytes, flush: true);
    return file;
  }
}
