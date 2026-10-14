import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_info_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;

  const SettingsScreen({
    super.key,
    this.fullName = 'Community Creator',
    this.email = 'No Email',
    this.phone = 'Not provided',
  });

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

  // ኢንተርኔት ሲጠፋ ወይም የኔትወርክ ስህተት ሲኖር ማሳወቂያ ማሳያ Toast
  static void showNoInternetToast(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text('No internet connection! Please check your network.'),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

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
    } catch (e) {
      if (mounted) showNoInternetToast(context);
    }

    setState(() {
      _isLoadingPreferences = false;
    });
  }

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
    } catch (e) {
      if (mounted) showNoInternetToast(context);
    }
  }

  Future<void> _signOut() async {
    // 1. መጀመሪያ ማሳወቂያውን በማሳየት ስራ እንጀምራለን
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Successfully logged out!'),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 2),
      ),
    );

    // 2. ከ Supabase እና ዳታቤዝ ለመውጣት መሞከር
    try {
      await supabase.from('profiles').delete().match({'id': 1});
    } catch (_) {}

    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (mounted) showNoInternetToast(context);
    }

    // 3. ወደ Login ገጽ መቀየር
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

  Future<void> _handlePasswordReset() async {
    final userEmail = supabase.auth.currentUser?.email ?? widget.email;

    if (userEmail.isEmpty || userEmail == 'No Email') {
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
      if (mounted) showNoInternetToast(context);
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
                    onTap: () => AccountInfoDialog.show(
                      context: context,
                      fullName: widget.fullName,
                      email: widget.email,
                      phone: widget.phone,
                    ),
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
                    onChanged: (val) async {
                      setState(() => _pushNotifications = val);
                      await _updatePreference('push_notifications', val);
                      if (!mounted) return;
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
                    onChanged: (val) async {
                      setState(() => _emailNotifications = val);
                      await _updatePreference('email_notifications', val);
                      if (!mounted) return;
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
                    onChanged: (val) async {
                      setState(() => _privateAccount = val);
                      await _updatePreference('private_account', val);
                      if (!mounted) return;
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
                    onChanged: (val) async {
                      setState(() => _darkMode = val);
                      await _updatePreference('dark_mode', val);
                      if (!mounted) return;
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
                    subtitle: 'Version 1.0.0 • kuanyngne Community',
                    onTap: () {
                      _showDialogMessage(
                        'About VibeShare',
                        'kuanyngne Community App v1.0.0\n\n'
                        'Designed specifically for community creators, video sharing, and interactive engagement.\n\n'
                        '• Built with Flutter & Supabase\n'
                        '• Fast & Secure Media Sharing\n'
                        '• Developed for Creators',
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
                        'Need assistance or want to share feedback?\n\n'
                        '• Support Email: support@kuanyngne.com\n'
                        '• Community Portal: available 24/7\n\n'
                        'We are always here to help you grow your community!',
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
                        'Your privacy is our top priority.\n\n'
                        '• All user data, media, and credentials are encrypted.\n'
                        '• Securely stored using Supabase cloud infrastructure.\n'
                        '• We never share your personal information with third parties.',
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10, width: 0.5),
                    ),
                    child: ListTile(
                      onTap: () {
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
                      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.white70),
                      title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: const Text('Sign out from your account', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                  ),
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
