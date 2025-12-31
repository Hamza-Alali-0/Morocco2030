import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/signup_page.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/profile/profileinfo.dart';

import 'package:flutter_application_1/authentification/forgotpassword.dart';

class LoginPage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const LoginPage());
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool isLoading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


// Update the signInWithEmailAndPassword method
Future<void> signInWithEmailAndPassword() async {
  if (formKey.currentState!.validate()) {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if user has completed their profile
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (mounted) {
        if (userDoc.exists && userDoc.data()?['hasCompletedProfile'] == true) {
          // User has already filled out their profile, navigate to home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyHomePage()),
            (route) => false,
          );
        } else {
          // User has not filled out their profile, navigate to profile info page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ProfileInfoPage()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // ...existing error handling code...
        setState(() {
          errorMessage = _getMessageFromErrorCode(e.code);
        });
        print("Login error: ${e.code} - ${e.message}");
      } catch (e) {
        setState(() {
          errorMessage = "An unexpected error occurred";
        });
        print("Unknown login error: $e");
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }
Future<void> signInWithGoogle() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    // Configure GoogleSignIn to show account picker every time
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
      signInOption: SignInOption.standard, // This forces the account picker
      hostedDomain: null, // null = any domain can sign in
    );
    
    // Sign out first to ensure the account picker is shown
    await googleSignIn.signOut();
    
    // Trigger Google sign-in flow with account picker
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // User canceled the sign-in
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Obtain auth details from request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create credential for Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in with Firebase
    await FirebaseAuth.instance.signInWithCredential(credential);

   final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (mounted) {
      if (userDoc.exists && userDoc.data()?['hasCompletedProfile'] == true) {
        // User has already filled out their profile, navigate to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
      } else {
        // User has not filled out their profile, navigate to profile info page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileInfoPage()),
          (route) => false,
        );
      }
    }
  } catch (e) {
    setState(() {
      errorMessage = "Google sign-in failed. Please try again.";
    });
    print("Google sign-in error: $e");
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = "Please enter your email to reset password";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Failed to send reset email";
      });
    }
  }

  String _getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user has been disabled.';
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

          // Login form content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Welcome ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !showPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      
                      // Forgot Password link
                    Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.push(context, ForgotPasswordPage.route());
    },
    child: Text(
      'Forgot Password?',
      style: TextStyle(
        color: const Color(0xFF065d67),
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),
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
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF065d67),
                              ),
                            )
                          : ElevatedButton(
                            onPressed: signInWithEmailAndPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF065d67),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: signInWithGoogle,
                        icon: FaIcon(
                          FontAwesomeIcons.google,
                          size: 24,
                          color: const Color(0xFF065d67),
                        ),
                        label: const Text(
                          'Sign in with Google',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, SignUpPage.route());
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Don\'t have an account? ',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF065d67),
                                ),
                              ),
                            ],
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