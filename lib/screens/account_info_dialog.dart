import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountInfoDialog {
  static Future<void> show(BuildContext context) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Controllers for editing
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    bool isLoading = true;
    bool isSaving = false;

    // Fetch initial data
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

    nameController.text = fullName;
    emailController.text = email;
    phoneController.text = phone;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16161A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.account_circle, color: Color(0xFF2575FC), size: 28),
                SizedBox(width: 10),
                Text('Account Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2575FC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setStateDialog(() {
                          isSaving = true;
                        });

                        try {
                          final newName = nameController.text.trim();
                          final newEmail = emailController.text.trim();
                          final newPhone = phoneController.text.trim();

                          // Supabase profiles ቴብል ላይ ማዘመን
                          await supabase.from('profiles').upsert({
                            'id': 1, // እንደ መዋቅርዎ መሠረት (ወይም auth user id)
                            'full_name': newName,
                            'email': newEmail,
                            'phone_number': newPhone,
                          });

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account information updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() {
                            isSaving = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update. Check your connection.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF2575FC), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A0A0C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
