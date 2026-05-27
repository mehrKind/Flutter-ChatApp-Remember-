import 'package:flutter/material.dart';
import 'package:remember/services/routes.dart';
import 'package:remember/services/storage_service.dart';


class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    //   add delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final accessToken = await StorageService.getAccessToken();

    Navigator.pushReplacementNamed(
        context,
        accessToken != null ? AppRoutes.chatList : AppRoutes.signUpPage);
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the navigation bar
    double bottomPadding = MediaQuery
        .of(context)
        .padding
        .bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(), // Pushes content to center
            Center(
              child: Image.asset('assets/images/icons/logo.png', width: 96),
            ),
            const Spacer(), // Pushes text to bottom
            Padding(
              padding: EdgeInsets.only(bottom: 20 + bottomPadding),
              // Add bottom padding
              child: const Text(
                "Mehraban",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}