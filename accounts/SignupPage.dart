import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remember/services/routes.dart';
import 'package:remember/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:remember/services/storage_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

// 192.168.234.50
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 34),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/icons/logo.png',
                        width: 70,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // "Remember" Title
                    const Text(
                      "Remember",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 120),

                    // Welcome Text
                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9099AE),
                          fontSize: 17,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9099AE),
                          fontSize: 17,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      cursorColor: Colors.white,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9099AE),
                          fontSize: 17,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: const BorderSide(color: Color(0xFF8B8B8B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),


                    // Continue Button
                    GestureDetector(
                        onTap: () async {
                          final data = {
                            "username": _usernameController.text,
                            "password": _passwordController.text,
                            "phone_number": _phoneController.text,
                          };

                          bool success = await submitSignupData(data);
                          if (success) {
                            Navigator.pushReplacementNamed(context, AppRoutes.chatList);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Signup failed. Please try again."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFCB68FF),
                              Color(0xFF7431FF),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // const SizedBox(height: 30),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Container(
                    //         height: 1, // Height of the line
                    //         color: Color(0xFF9E9E9E), // Color of the line
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 8.0), // Space around the text
                    //       child: Text(
                    //         "Or",
                    //         style: TextStyle(
                    //           color: Color(0xFF9099AE),
                    //           fontSize: 18, // Adjust size as needed
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: Container(
                    //         height: 1, // Height of the line
                    //         color: Color(0xFF9E9E9E), // Color of the line
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 30),
                    // Row(
                    //   children: [
                    //     Expanded(child:
                    //     ElevatedButton(onPressed: () {
                    //       // Show an alert dialog when the button is pressed
                    //       showDialog(
                    //         context: context,
                    //         builder: (ctx) => AlertDialog(
                    //           title: const Text("Google"),
                    //           content: const Text("This section is under construction"),
                    //           actions: <Widget>[
                    //             TextButton(
                    //               onPressed: () {
                    //                 Navigator.of(ctx).pop();
                    //               },
                    //               child: const Text("Got it"),
                    //             ),
                    //           ],
                    //         ),
                    //       );
                    //     },
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Color(0xFF2A2F3A),
                    //           padding: const EdgeInsets.symmetric(vertical: 17),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(50),
                    //           ),
                    //         ),
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           spacing: 6.5,
                    //           children: [
                    //             Image.asset("assets/images/icons/Google.png",
                    //               width: 17, height: 17,),
                    //             Text("Continue with Google", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0, color: Colors.white),),
                    //           ],
                    //         )
                    //
                    //     ),
                    //     )
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> submitSignupData(Map<String, dynamic> data) async {
  final String url = api["register"]!;
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      // More robust checking of response structure
      if (responseBody.containsKey("data") &&
          responseBody["data"] is Map &&
          responseBody["data"]["tokens"] is Map &&
          responseBody["data"]["user_id"] != null) {

        final String token = responseBody["data"]["tokens"]["access"].toString();
        final String userId = responseBody["data"]["user_id"].toString();
        final String userPhoneNumber = responseBody["data"]["phone_number"].toString();

        // Save tokens and user ID
        await StorageService.saveAccessToken(token);
        await StorageService.saveUserId(userId);
        await StorageService.saveUserPhone(userPhoneNumber);

        return true;
      } else {
        if (kDebugMode) {
          print('Invalid response structure');
        }
        return false;
      }
    } else {
      // Handle specific error messages from server if available
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody.containsKey("error")) {
          if (kDebugMode) {
            print('Server error: ${errorBody["error"]}');
          }
        }
      } catch (_) {}

      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Exception during signup: $e');
    }
    return false;
  }
}