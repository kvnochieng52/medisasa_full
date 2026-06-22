// ignore_for_file: prefer_const_constructors

import 'package:xyvra_health/app_router.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/pages/reset_password/new_password_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  bool _showCodeInput = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Please enter your email address', isError: true);
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/send-reset-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Reset code sent to your email', isError: false);
        setState(() {
          _codeSent = true;
          _showCodeInput = true;
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to send reset code';

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
        Uri.parse(ApiConfig.baseUrl + '/verify-reset-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _codeController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Verification successful!', isError: false);
        // Navigate to new password page after successful verification
        Future.delayed(Duration(seconds: 1), () {
          context.go(
              '/new-password?email=${_emailController.text}&code=${_codeController.text}');
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) =>
          //         NewPasswordPage(email: _emailController.text.trim()),
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
        title: Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
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
                  _showCodeInput ? "Enter Verification Code" : "Reset Password",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _showCodeInput
                      ? "We sent a verification code to:\n${_emailController.text}"
                      : "Enter your email address to receive a reset code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),
                if (!_showCodeInput) _buildEmailInputField(),
                if (_showCodeInput) _buildCodeInputField(),
                SizedBox(height: 20),
                _buildActionButton(),
                SizedBox(height: 20),
                if (_showCodeInput) _buildResendCodeText(),
                if (_showCodeInput)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showCodeInput = false;
                        _codeSent = false;
                        _codeController.clear();
                      });
                    },
                    child: Text(
                      'Change Email',
                      style: TextStyle(
                        color: Color(0xFF0389F6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                // Login link added here
                _buildLoginLink(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInputField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Email Address",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Enter your email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              fillColor: Color(0xfff3f3f4),
              filled: true,
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
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

  Widget _buildActionButton() {
    return GestureDetector(
      onTap:
          _isLoading ? null : (_showCodeInput ? _verifyCode : _sendResetCode),
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
                    _showCodeInput ? 'Verifying...' : 'Sending...',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                _showCodeInput ? 'Verify Code' : 'Send Reset Code',
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
          onTap: _isLoading ? null : _sendResetCode,
          child: Text(
            "Resend",
            style: TextStyle(
              fontSize: 14,
              color: _isLoading ? Colors.grey : Color(0xFF0389F6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // New method for login link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Remember your password? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Navigate back to login page
            context.go(
                '/login'); // Adjust the route path according to your app router
          },
          child: Text(
            "Login",
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
