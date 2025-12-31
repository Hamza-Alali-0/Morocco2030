import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  
  bool _isLoading = true;
  bool _bookingNotifications = true;
  bool _promotionalNotifications = true;
  bool _eventNotifications = true;
  bool _tripNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data();
          final notificationSettings = data?['notificationSettings'] as Map<String, dynamic>?;
          
          if (notificationSettings != null) {
            setState(() {
              _bookingNotifications = notificationSettings['bookings'] ?? true;
              _promotionalNotifications = notificationSettings['promotional'] ?? true;
              _eventNotifications = notificationSettings['events'] ?? true;
              _tripNotifications = notificationSettings['trips'] ?? true;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'notificationSettings': {
                'bookings': _bookingNotifications,
                'promotional': _promotionalNotifications,
                'events': _eventNotifications,
                'trips': _tripNotifications,
              }
            });
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (e) {
      print('Error saving notification settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: secondaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage which notifications you receive',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildNotificationTile(
                    'Booking Updates',
                    'Get notified about your booking confirmations and changes',
                    _bookingNotifications,
                    (value) {
                      setState(() {
                        _bookingNotifications = value;
                      });
                    },
                  ),
                  const Divider(),
                  
                  _buildNotificationTile(
                    'Promotional Offers',
                    'Special deals, discounts and promotional offers',
                    _promotionalNotifications,
                    (value) {
                      setState(() {
                        _promotionalNotifications = value;
                      });
                    },
                  ),
                  const Divider(),
                  
                  _buildNotificationTile(
                    'Events and Activities',
                    'Updates about upcoming events and activities',
                    _eventNotifications,
                    (value) {
                      setState(() {
                        _eventNotifications = value;
                      });
                    },
                  ),
                  const Divider(),
                  
                  _buildNotificationTile(
                    'Trip Reminders',
                    'Get reminders about your upcoming trips',
                    _tripNotifications,
                    (value) {
                      setState(() {
                        _tripNotifications = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SAVE SETTINGS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildNotificationTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: secondaryColor,
    );
  }
}