// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/pages/dasboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xyvra_health/models/api_config.dart';

class EmailConfirmationPage extends StatefulWidget {
  final String email; // Add email parameter to know which email to verify

  const EmailConfirmationPage({Key? key, required this.email})
      : super(key: key);

  @override
  _EmailConfirmationPageState createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty || _codeController.text.length != 4) {
      _showMessage('Please enter a valid 4-digit code', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'verification_code': _codeController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Email verified successfully!', isError: false);
        // Navigate to dashboard after successful verification
        Future.delayed(Duration(seconds: 1), () {
          context.go('/dashboard');
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => DashboardPage(),
          //   ),
          // );
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Verification failed';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error: $e');
      _showMessage('Network error. Please check your connection and try again.',
          isError: true);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      setState(() {
        _isResending = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Verification code resent to your email', isError: false);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to resend code';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.first[0];
        }

        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      debugPrint('Error: $e');
      _showMessage('Network error. Please check your connection and try again.',
          isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008faf),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: height * .1),
                Image.asset(
                  'assets/images/logo_outline.png',
                  height: 100,
                ),
                SizedBox(height: 10),
                Text(
                  "MediSasa",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Enter the 4-digit code sent to ${widget.email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),
                _buildCodeInputField(),
                SizedBox(height: 20),
                _buildVerifyButton(),
                SizedBox(height: 20),
                _buildResendCodeText(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInputField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Verification Code",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(fontSize: 24, letterSpacing: 2),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: "",
              hintText: "----",
              hintStyle: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                letterSpacing: 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _verifyCode,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.shade200,
              offset: Offset(2, 4),
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _isLoading
                ? [Colors.grey, Colors.grey]
                : [Color(0xFF008faf), Color(0xFF008faf)],
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Verifying...',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Verify',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendCodeText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        GestureDetector(
          onTap: _isResending ? null : _resendCode,
          child: _isResending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  "Resend",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0389F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
