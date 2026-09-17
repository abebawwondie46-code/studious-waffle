import 'package:flutter/material.dart';

// --- 1. Account Screen ---
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Account', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Personal Info',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.white),
            title: const Text('Email', style: TextStyle(color: Colors.white)),
            subtitle: const Text('user@example.com', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Security',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.white),
            title: const Text('Change Password', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// --- 2. Notification Screen ---
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _pushNotifications = true;
  bool _likesNotifications = true;
  bool _commentsNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            activeColor: const Color(0xFFFF2B55),
            title: const Text('Pause All Push Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Temporarily mute all alerts', style: TextStyle(color: Colors.grey)),
            value: !_pushNotifications,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = !value;
              });
            },
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Activity Alerts',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            activeColor: const Color(0xFFFF2B55),
            title: const Text('Likes & Reactions', style: TextStyle(color: Colors.white)),
            value: _likesNotifications,
            onChanged: (bool value) {
              setState(() {
                _likesNotifications = value;
              });
            },
          ),
          SwitchListTile(
            activeColor: const Color(0xFFFF2B55),
            title: const Text('Comments', style: TextStyle(color: Colors.white)),
            value: _commentsNotifications,
            onChanged: (bool value) {
              setState(() {
                _commentsNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

// --- 3. Privacy Screen ---
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isPrivateAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            activeColor: const Color(0xFFFF2B55),
            title: const Text('Private Account', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Only approved followers can see your posts', style: TextStyle(color: Colors.grey)),
            value: _isPrivateAccount,
            onChanged: (bool value) {
              setState(() {
                _isPrivateAccount = value;
              });
            },
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Interactions',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.white),
            title: const Text('Blocked Accounts', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.white),
            title: const Text('Hidden Comments', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
