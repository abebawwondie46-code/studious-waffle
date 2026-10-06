import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedVideoFile;
  bool _isLoading = false;

  // ከስልኩ ጋለሪ ቪዲዮ መምረጫ
  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideoFile = File(video.path);
      });
    }
  }

  // ቪዲዮውን ወደ Supabase Storage እና Database የመጫን ሂደት
  Future<void> _uploadVideo() async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ መጀመሪያ ቪዲዮ ይምረጡ! (Please select a video)')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ የቪዲዮውን ርዕስ ይጻፉ! (Please enter a title)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = 'videos/$fileName';

      // 1. ቪዲዮውን ወደ Supabase Storage መስቀል
      await supabase.storage.from('videos').upload(
            filePath,
            _selectedVideoFile!,
            fileOptions: const FileOptions(upsert: false),
          );

      // 2. የፋይሉን የፐብሊክ ሊንክ (Public URL) ማግኘት
      final videoUrl = supabase.storage.from('videos').getPublicUrl(filePath);

      // 3. መረጃውን በ videos ሠንጠረዥ (Table) ውስጥ መመዝገብ
      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': videoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ቪዲዮው በተሳካ ሁኔታ ተጭኗል! (Video uploaded successfully!)')),
      );

      // ፎርሙን ማጽዳት
      _titleController.clear();
      setState(() {
        _selectedVideoFile = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('የተፈጠረው ስህተት: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Video', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Recommended video length: 30 to 60 seconds for best engagement.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // የርዕስ ማስገቢያ ሳጥን
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter video title...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // የጋለሪ ቪዲዮ መምረጫ ቁልፍ (Picker Box)
              GestureDetector(
                onTap: _pickVideoFromGallery,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Center(
                    child: _selectedVideoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.video_library, color: Colors.redAccent, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select video from gallery',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 30),
                              SizedBox(width: 10),
                              Text(
                                'Video Selected Successfully!',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // የመጫኛ (Upload) ቁልፍ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _uploadVideo,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Upload Video',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
