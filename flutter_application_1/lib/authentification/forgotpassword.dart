import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      );
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorMessage;
  String? successMessage;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
// Update the resetPassword method to verify email existence first
Future<void> resetPassword() async {
  if (formKey.currentState!.validate()) {
    setState(() {
      errorMessage = null;
      successMessage = null;
      isLoading = true;
    });

    final email = emailController.text.trim();
    
    try {
      // Check if the email exists first by trying to sign in with invalid credentials
      // This approach is more secure than fetching user data
      try {
        // We'll use fetchSignInMethodsForEmail which returns a list of methods without signing in
        List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        
        // If the list is empty, no account exists with this email
        if (methods.isEmpty) {
          setState(() {
            errorMessage = 'No account exists with this email. Please check the email address or create a new account.';
            isLoading = false;
          });
          return; // Exit the function
        }
      } catch (e) {
        // If this check fails, continue with password reset anyway
        print("Error checking email existence: $e");
      }
      
      // If we get here, either the email exists or the check failed
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Show success message
      setState(() {
        successMessage = 'Password reset email sent to $email';
        isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getMessageFromErrorCode(e.code);
        isLoading = false;
      });
      print("Reset password error: ${e.code} - ${e.message}");
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred";
        isLoading = false;
      });
      print("Unknown reset password error: $e");
    }
  }
}
// Update the error message for user-not-found with more helpful guidance
String _getMessageFromErrorCode(String errorCode) {
  switch (errorCode) {
    case 'user-not-found':
      return 'No account exists with this email. Please check the email address or create a new account.';
    case 'invalid-email':
      return 'Invalid email address format.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    default:
      return 'An error occurred. Please try again.';
  }
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Column(
        children: [
          // Top curved container with logo
          ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              height: screenHeight * 0.3,
              width: double.infinity,
              color: const Color(0xFFFDCB00), // Yellow background
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logomaroc2030.png',
                      height: 221,
                      width: 440,
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Reset password form content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Enter your email address and we will send you instructions to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (successMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            successMessage!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF065d67),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF065d67),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'RESET PASSWORD',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: const Color(0xFF065d67),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for the curved bottom edge
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    // First curve (left side)
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 15,
    );

    // Second curve (right side)
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 30,
      size.width,
      size.height,
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}