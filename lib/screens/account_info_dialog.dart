import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountInfoDialog {
  static Future<void> show(BuildContext context) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    String email = user?.email ?? 'No Email';
    String fullName = 'Community Creator';
    String phone = 'Not provided';

    try {
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('full_name, phone_number, email')
            .maybeSingle();

        if (profile != null) {
          fullName = profile['full_name'] ?? fullName;
          phone = profile['phone_number'] ?? phone;
          email = profile['email'] ?? email;
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.account_circle, color: Color(0xFF2575FC), size: 28),
            SizedBox(width: 10),
            Text('Account Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.person_rounded, 'Full Name', fullName),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_rounded, 'Email Address', email),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_rounded, 'Phone Number', phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2575FC), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2575FC).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2575FC), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
