import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdEditorScreen extends StatefulWidget {
  const AdEditorScreen({super.key});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stickerController = TextEditingController(text: '🔥🔥 ልዩ ቅናሽ!');

  Color _startColor = Colors.indigo;
  Color _endColor = Colors.blueAccent;
  File? _selectedVideo;
  bool _isUploading = false;

  final List<Color> _colorPalette = [
    Colors.indigo,
    Colors.blueAccent,
    Colors.purple,
    Colors.deepOrange,
    Colors.teal,
    Colors.pink,
    Colors.black,
    Colors.amber,
  ];

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _saveAd() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎን የማስታወቂያ ርዕስ ያስገቡ!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      String videoUrl = '';

      if (_selectedVideo != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        await supabase.storage.from('videos').upload(fileName, _selectedVideo!);
        videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);
      }

      final templateJson = {
        'colorStart': _startColor.value,
        'colorEnd': _endColor.value,
        'phone': _phoneController.text.trim(),
        'text': _textController.text.trim(),
        'sticker': _stickerController.text.trim(),
      };

      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': videoUrl,
        'template_json': templateJson,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ማስታወቂያው በትክክል ተለጥፏል!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _textController.clear();
        _phoneController.clear();
        setState(() {
          _selectedVideo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስህተት ተከሰቷል፡ $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('አዲስ ማስታወቂያ ፍጠር'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: _selectedVideo != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text('ቪዲዮ ተመርጧል፡ ${_selectedVideo!.path.split('/').last}', style: const TextStyle(color: Colors.white70)),
                          TextButton(onPressed: _pickVideo, child: const Text('ቅየሩ'))
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text('ቪዲዮ ለመምረጥ እዚህ ይጫኑ (ባዶ መተው ይቻላል)', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'የማስታወቂያው ርዕስ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'ዝርዝር ማብራሪያ / መልዕክት',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'የስልክ ቁጥር',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stickerController,
              decoration: InputDecoration(
                labelText: 'ስቲከር / ባጅ (ምሳሌ፡ 🔥 ልዩ ቅናሽ!)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 20),
            const Text('የጀርባ ቀለም ይምረጡ (ቪዲዮ ካልተመረጠ)፡', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorPalette.length,
                itemBuilder: (context, index) {
                  final color = _colorPalette[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _startColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _startColor == color ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _saveAd,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ማስታወቂያውን ለጥፍ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
