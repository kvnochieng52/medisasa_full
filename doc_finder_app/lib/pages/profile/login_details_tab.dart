import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginDetailsTab extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onSave;

  const LoginDetailsTab({
    Key? key,
    required this.profileData,
    required this.onDataChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  _LoginDetailsTabState createState() => _LoginDetailsTabState();
}

class _LoginDetailsTabState extends State<LoginDetailsTab> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildSuccessBox() {
    final userType = widget.profileData['userType'];
    final isServiceProvider = userType == 'serviceProvider';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isServiceProvider ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isServiceProvider
              ? Colors.orange.shade200
              : Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isServiceProvider ? Colors.orange : Colors.green)
                .withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isServiceProvider ? Icons.hourglass_empty : Icons.check_circle,
            color: isServiceProvider
                ? Colors.orange.shade600
                : Colors.green.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isServiceProvider
                ? 'Profile Pending Preview'
                : 'Details Updated Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isServiceProvider
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isServiceProvider
                ? 'Your service provider profile has been submitted and is currently pending preview. You will be notified once the verification process is complete.'
                : 'Your profile details have been successfully updated. You can now access all features of the platform.',
            style: TextStyle(
              fontSize: 14,
              color: isServiceProvider
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add debug print to check if function is called
      print('Proceeding to dashboard...');

      // Simulate a brief loading state
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      // Try multiple navigation approaches
      print('Attempting navigation to dashboard...');

      // Method 1: Using context.go (your current approach)
      if (mounted) {
        // Use push for navigation to dashboard
        context.push('/dashboard');
      }

      // Alternative Method 2: Using context.pushReplacement (uncomment if context.go fails)
      // if (context.mounted) {
      //   context.pushReplacement('/dashboard');
      //   print('Navigation attempted with context.pushReplacement');
      // }

      // Alternative Method 3: Using Navigator (uncomment if GoRouter fails)
      // Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      print('Error during navigation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset loading state after a delay if still mounted
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Registration Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Name: ${widget.profileData['name'] ?? 'Not provided'}'),
                Text('Email: ${widget.profileData['email'] ?? 'Not provided'}'),
                Text(
                    'User Type: ${widget.profileData['userType'] == 'serviceProvider' ? 'Service Provider/Doctor' : 'User'}'),
                if (widget.profileData['userType'] == 'serviceProvider') ...[
                  Text(
                      'License No: ${widget.profileData['licenseNumber'] ?? 'Not provided'}'),
                  if (widget.profileData['selectedSpecializations'] != null &&
                      (widget.profileData['selectedSpecializations'] as List)
                          .isNotEmpty)
                    Text(
                        'Specializations: ${(widget.profileData['selectedSpecializations'] as List).length} selected'),
                ],
              ],
            ),
          ),

          // Success Box
          _buildSuccessBox(),

          const Spacer(),

          // Go to Dashboard Button
          ElevatedButton(
            onPressed: !_isLoading ? _proceedToDashboard : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008faf),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading Dashboard...',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  )
                : const Text(
                    'Go to Dashboard',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
