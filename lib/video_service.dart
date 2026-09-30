import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. ቪዲዮዎችን ከ Supabase ማምጣት
  Future<List<Map<String, dynamic>>> fetchVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // 2. ቪዲዮ እና የቴምፕሌት ዳታ መጫን (One-Tap Publish)
  Future<void> publishVideoWithTemplate({
    required File videoFile,
    required String title,
    required String category,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';

      // ወደ Storage ማቀበል
      await _supabase.storage.from('MEDIA').upload(fileName, videoFile);

      // Public URL ማግኘት
      final videoUrl = _supabase.storage.from('MEDIA').getPublicUrl(fileName);

      // ወደ Database መዝገብ ማስገባት
      await _supabase.from('videos').insert({
        'title': title,
        'category': category,
        'video_url': videoUrl,
        'is_template': true,
        'template_data': templateData,
      });
    } catch (e) {
      rethrow;
    }
  }
}
