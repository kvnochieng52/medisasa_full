import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/auth_service.dart';

class DebugAppointmentsPage extends StatefulWidget {
  const DebugAppointmentsPage({Key? key}) : super(key: key);

  @override
  _DebugAppointmentsPageState createState() => _DebugAppointmentsPageState();
}

class _DebugAppointmentsPageState extends State<DebugAppointmentsPage> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Appointments'),
        backgroundColor: const Color(0xFF008faf),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testAuth,
              child: const Text('Test Authentication'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testAppointmentsAPI,
              child: const Text('Test Appointments API'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _debugInfo.isEmpty ? 'Click buttons above to test' : _debugInfo,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _testAuth() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing authentication...\n';
    });

    final authService = AuthService();

    setState(() {
      _debugInfo += 'Is Authenticated: ${authService.isAuthenticated}\n';
      _debugInfo += 'Token: ${authService.token}\n';
      _debugInfo += 'User: ${authService.user}\n';

      if (authService.user != null) {
        final user = authService.user!;
        _debugInfo += 'User ID: ${user['id']}\n';
        _debugInfo += 'User Name: ${user['name']}\n';
        _debugInfo += 'Account Type: ${user['account_type']}\n';
        _debugInfo += 'SP Approved: ${user['sp_approved']}\n';
      }
      _isLoading = false;
    });
  }

  void _testAppointmentsAPI() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing appointments API...\n';
    });

    try {
      final authService = AuthService();
      final currentUser = authService.user;

      int? doctorId;
      if (currentUser != null && currentUser['account_type'] == 2) {
        doctorId = currentUser['id'];
      }

      setState(() {
        _debugInfo += 'Doctor ID to use: $doctorId\n';
      });

      if (doctorId != null) {
        // Test with doctor ID
        String endpoint = '/doctors/$doctorId/appointments';
        setState(() {
          _debugInfo += 'Testing endpoint: $endpoint\n';
        });

        if (authService.isAuthenticated) {
          final response = await authService.authenticatedRequest('GET', endpoint);
          setState(() {
            _debugInfo += 'Response status: ${response.statusCode}\n';
            _debugInfo += 'Response body: ${response.body}\n';
          });
        } else {
          setState(() {
            _debugInfo += 'ERROR: Not authenticated\n';
          });
        }
      } else {
        setState(() {
          _debugInfo += 'ERROR: No doctor ID found\n';
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'ERROR: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
}