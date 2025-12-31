import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile/editprofile.dart';
import 'package:flutter_application_1/profile/my_bookings_screen.dart';
import 'package:flutter_application_1/profile/notification_settings_screen.dart';
import 'package:flutter_application_1/support/support_chatbot.dart';
import 'package:flutter_application_1/authentification/login_page.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = true;
  String _fullName = '';
  String? _profileImageBase64;
  String _email = '';
  String _country = '';

  // App theme colors
  final Color primaryColor = const Color(0xFFFDCB00); // Yellow/Gold
  final Color secondaryColor = const Color(0xFF065d67); // Teal
  final Color accentColor = const Color(0xFF8C4843); // Reddish brown

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Set email from Firebase Auth
        _email = user.email ?? '';

        // Fetch additional data from Firestore
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userData.exists) {
          final data = userData.data()!;
          setState(() {
            _fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
            _profileImageBase64 = data['profileImageBase64'];
            _country = data['country'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: secondaryColor))
              : Stack(
                children: [
                  // Single background image for entire screen
                  Container(
                    height:
                        MediaQuery.of(context).size.height *
                        0.2, // Adjust height as needed
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/banner2030.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Content starts here
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: AppBar().preferredSize.height + 20,
                        ), // Add padding to account for AppBar
                        // Profile Header with card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(top: 16, bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Profile image
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: secondaryColor,
                                        width: 3,
                                      ),
                                    ),
                                    child:
                                        _profileImageBase64 != null
                                            ? CircleAvatar(
                                              radius: 40,
                                              backgroundImage: MemoryImage(
                                                base64Decode(
                                                  _profileImageBase64!,
                                                ),
                                              ),
                                            )
                                            : CircleAvatar(
                                              radius: 40,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              child: Icon(
                                                Icons.person,
                                                size: 40,
                                                color: secondaryColor,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fullName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _email,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: secondaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Account Section
                        _buildSectionTitle('Account'),
                        _buildListTile(
                          icon: Icons.attach_money,
                          title: 'Payment Options',
                          onTap: () {},
                        ),
                        _buildListTile(
                          icon: Icons.language,
                          title: 'Country',
                          subtitle: _country,
                          onTap: () {},
                        ),
                        _buildListTile(
                          icon: Icons.notifications,
                          title: 'Notification Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.person,
                          title: 'Edit Profile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        const Divider(),

                        // General Section
                        _buildSectionTitle('General'),
                        _buildListTile(
                          icon: Icons.help_outline,
                          title: 'Support Chatbox',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const SupportChatbotScreen(),
                              ),
                            );
                          },
                        ),
                        // Replace Terms of Service with My Bookings
                        _buildListTile(
                          icon: Icons.calendar_today,
                          title: 'My Bookings',
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const MyBookingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.share,
                          title: 'Invite Friends',
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),

                        // Sign Out Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                               Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                               ),
                                  (route) => false, 
                            );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: secondaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
      onTap: onTap,
    );
  }
}
