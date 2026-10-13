import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _darkMode = true;
  bool _privateAccount = false;
  bool _isLoadingPassword = false;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load preferences from SharedPreferences & Supabase
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _privateAccount = prefs.getBool('private_account') ?? false;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final profileData = await supabase
            .from('profiles')
            .select('is_private, push_notifications_enabled, email_notifications_enabled')
            .eq('id', userId)
            .maybeSingle();

        if (profileData != null) {
          setState(() {
            _privateAccount = profileData['is_private'] ?? _privateAccount;
            _pushNotifications = profileData['push_notifications_enabled'] ?? _pushNotifications;
            _emailNotifications = profileData['email_notifications_enabled'] ?? _emailNotifications;
          });
        }
      }
    } catch (_) {}

    setState(() {
      _isLoadingPreferences = false;
    });
  }

  // Save preference to Local Storage and Supabase
  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        String column = '';
        if (key == 'private_account') column = 'is_private';
        if (key == 'push_notifications') column = 'push_notifications_enabled';
        if (key == 'email_notifications') column = 'email_notifications_enabled';

        if (column.isNotEmpty) {
          await supabase.from('profiles').update({column: value}).eq('id', userId);
        }
      }
    } catch (_) {}
  }

  // Logout Logic
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showDialogMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2575FC))),
          ),
        ],
      ),
    );
  }

  // Action: Account Information Dialog
  Future<void> _showAccountInfoDialog() async {
    final user = supabase.auth.currentUser;
    String email = user?.email ?? 'No Email';
    String fullName = 'Community Creator';
    String phone = 'Not provided';

    try {
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('full_name, phone_number')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          fullName = profile['full_name'] ?? fullName;
          phone = profile['phone_number'] ?? phone;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, 'Full Name', fullName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2575FC))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2575FC), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // Action: Password Reset Link
  Future<void> _handlePasswordReset() async {
    final userEmail = supabase.auth.currentUser?.email;

    if (userEmail == null || userEmail.isEmpty) {
      _showDialogMessage('Error', 'No registered email found for this account.');
      return;
    }

    setState(() {
      _isLoadingPassword = true;
    });

    try {
      await supabase.auth.resetPasswordForEmail(userEmail);
      setState(() {
        _isLoadingPassword = false;
      });
      if (!mounted) return;
      _showDialogMessage(
        'Password Reset Sent',
        'A password reset link has been sent to $userEmail. Please check your inbox.',
      );
    } catch (e) {
      setState(() {
        _isLoadingPassword = false;
      });
      if (!mounted) return;
      _showDialogMessage(
        'Password Reset Error',
        'Failed to send password reset email. Please try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoadingPreferences
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account'),
                  _buildSettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Account Information',
                    subtitle: 'Manage your profile and phone details',
                    onTap: _showAccountInfoDialog,
                  ),
                  _buildSettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: _isLoadingPassword ? 'Sending reset link...' : 'Update your login password',
                    onTap: _isLoadingPassword ? null : _handlePasswordReset,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Notifications'),
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts for new likes and comments',
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _updatePreference('push_notifications', val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Push Notifications Enabled' : 'Push Notifications Disabled'),
                          backgroundColor: val ? Colors.green : Colors.grey,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    subtitle: 'Receive monthly updates and news',
                    value: _emailNotifications,
                    onChanged: (val) {
                      setState(() => _emailNotifications = val);
                      _updatePreference('email_notifications', val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Email Notifications Enabled' : 'Email Notifications Disabled'),
                          backgroundColor: val ? Colors.green : Colors.grey,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Privacy & Preferences'),
                  _buildSwitchTile(
                    icon: Icons.security_rounded,
                    title: 'Private Account',
                    subtitle: 'Only approved followers can see your posts',
                    value: _privateAccount,
                    onChanged: (val) {
                      setState(() => _privateAccount = val);
                      _updatePreference('private_account', val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Account set to Private' : 'Account set to Public'),
                          backgroundColor: val ? Colors.indigo : Colors.grey,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Enable or disable dark appearance',
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() => _darkMode = val);
                      _updatePreference('dark_mode', val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Dark Mode Enabled' : 'Light Mode Enabled'),
                          backgroundColor: Colors.blueAccent,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('About & Support'),
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About App',
                    subtitle: 'Version 1.0.0 • VibeShare Community',
                    onTap: () {
                      _showDialogMessage(
                        'About VibeShare',
                        'VibeShare Community App v1.0.0\nDesigned for community creators, video sharing, and interactive engagement. Built with Flutter & Supabase.',
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center & Feedback',
                    subtitle: 'Get support or send feedback',
                    onTap: () {
                      _showDialogMessage(
                        'Help Center & Feedback',
                        'Need assistance? Reach out to our support team at support@vibeshare.com or visit our community portal.',
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policies',
                    onTap: () {
                      _showDialogMessage(
                        'Privacy Policy',
                        'Your privacy is important to us. All user data, media, and credentials are strictly encrypted and stored using Supabase cloud infrastructure.',
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF16161A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text('Are you sure you want to log out from your account?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _signOut();
                                },
                                child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16161A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2575FC),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF2575FC),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    );
  }
}
