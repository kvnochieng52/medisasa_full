import 'package:flutter/material.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'dart:io';
import 'dart:convert';

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({Key? key}) : super(key: key);

  @override
  _NetworkTestPageState createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  List<String> testResults = [];
  bool isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Test', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${ApiConfig.baseUrl}'),
                    Text('Web URL: ${ApiConfig.webUrl}'),
                    Text('Config Info:\n${ApiConfig.configInfo}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isTesting ? null : _runAllTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008faf),
                      foregroundColor: Colors.white,
                    ),
                    child: isTesting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Run Network Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => testResults.clear()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: testResults.length,
                          itemBuilder: (context, index) {
                            final result = testResults[index];
                            final isError = result.startsWith('❌');
                            final isSuccess = result.startsWith('✅');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                result,
                                style: TextStyle(
                                  color: isError
                                      ? Colors.red
                                      : isSuccess
                                          ? Colors.green
                                          : Colors.black87,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addResult(String result) {
    setState(() {
      testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      isTesting = true;
      testResults.clear();
    });

    _addResult('🔄 Starting network tests...');

    // Test 1: Basic connectivity
    await _testBasicConnectivity();

    // Test 2: API health check
    await _testApiHealth();

    // Test 3: Test with different URLs
    await _testAlternativeUrls();

    setState(() {
      isTesting = false;
    });

    _addResult('✅ All tests completed');
  }

  Future<void> _testBasicConnectivity() async {
    _addResult('📡 Testing basic connectivity...');

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _addResult('✅ Internet connection: Working');
      } else {
        _addResult('❌ Internet connection: Failed');
      }
    } catch (e) {
      _addResult('❌ Internet connection: $e');
    }
  }

  Future<void> _testApiHealth() async {
    _addResult('🏥 Testing API health endpoint...');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      client.badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse('${ApiConfig.baseUrl}/test/health');
      _addResult('🌐 Testing URL: $uri');

      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      _addResult('📊 Response status: ${response.statusCode}');
      _addResult('📝 Response body: ${responseBody.substring(0, 100)}...');

      if (response.statusCode == 200) {
        _addResult('✅ API health check: Success');
      } else {
        _addResult('❌ API health check: Failed with status ${response.statusCode}');
      }
    } catch (e) {
      _addResult('❌ API health check failed: $e');
    }
  }

  Future<void> _testAlternativeUrls() async {
    _addResult('🔄 Testing alternative URLs...');

    final urls = [
      'https://medisasa.co.ke',
      'https://medisasa.co.ke/api',
      'https://medisasa.co.ke/api/test/health',
    ];

    for (final url in urls) {
      try {
        _addResult('🧪 Testing: $url');

        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        client.badCertificateCallback = (cert, host, port) => true;

        final uri = Uri.parse(url);
        final request = await client.getUrl(uri);
        final response = await request.close();

        client.close();

        _addResult('✅ $url: Status ${response.statusCode}');
      } catch (e) {
        _addResult('❌ $url: Failed - $e');
      }
    }
  }
}