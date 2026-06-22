import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/network_test_page.dart';
import 'dart:io';
import 'dart:convert';

class DebugInfoWidget extends StatelessWidget {
  const DebugInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 16),
              SizedBox(width: 4),
              Text(
                'DEBUG INFO',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ApiConfig.configInfo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _testConnection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text(
                    'Test Connection',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NetworkTestPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
                child: const Text(
                  'Debug',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _testConnection(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show testing message
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🔄 Testing connection...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      print('🔧 Testing connection to: ${ApiConfig.baseUrl}/test/health');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      client.badCertificateCallback = (cert, host, port) => true; // Accept all certificates for testing

      final uri = Uri.parse('${ApiConfig.baseUrl}/test/health');
      print('🌐 Full URL: $uri');

      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📱 Response Status: ${response.statusCode}');
      print('📝 Response Body: $responseBody');

      client.close();

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ API connection successful!\nStatus: ${response.statusCode}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Server error: ${response.statusCode}\nBody: ${responseBody.substring(0, 100)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Connection error: $e');

      if (!context.mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException')) {
        errorMessage = 'Network unreachable. Check WiFi and IP address.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Connection timeout. Server might be down.';
      } else if (errorMessage.contains('HandshakeException')) {
        errorMessage = 'SSL/Certificate error. Using HTTP should work.';
      }

      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ Connection failed:'),
              Text(errorMessage, style: const TextStyle(fontSize: 12)),
              Text('URL: ${ApiConfig.baseUrl}', style: const TextStyle(fontSize: 10)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}