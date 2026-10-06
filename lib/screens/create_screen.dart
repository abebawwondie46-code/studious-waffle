import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart'; // የቪዲዮውን ርዝመት ለማረጋገጥ

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController(); // ለዲስክሪፕሽን (Description)
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedVideoFile;
  bool _isLoading = false;

  // ከስልኩ ጋለሪ ቪዲዮ መምረጫ እና የርዝመት ማጣሪያ (Auto-length check)
  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      
      // ቪዲዮው ከ30 እስከ 60 ሰከንድ መሆኑን ለማረጋገጥ ርዝመቱን እንፈትሻለን
      VideoPlayerController controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
        final duration = controller.value.duration;
        controller.dispose();

        if (duration.inSeconds < 5) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ቪዲዮው በጣም አጭር ነው! ቢያንስ ከ5 ሰከንድ በላይ መሆን አለበት።')),
          );
          return;
        }

        setState(() {
          _selectedVideoFile = file;
        });
      } catch (e) {
        // ማንኛውም የዲኮዲንግ ስህተት ካለ በቀጥታ ፋይሉን እንቀበለዋለን
        setState(() {
          _selectedVideoFile = file;
        });
      }
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

      // 3. መረጃውን በ videos ሠንጠረዥ (Table) ውስጥ መመዝገብ (Title እና Description ጨምሮ)
      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'video_url': videoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ቪዲዮው በተሳካ ሁኔታ ተጭኗል! (Video uploaded successfully!)')),
      );

      // ፎርሙን ማጽዳት
      _titleController.clear();
      _descriptionController.clear();
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
              // 1. የጋለሪ ቪዲዮ መምረጫ ሳጥን (አሁን ከላይ ነው ያለው)
              GestureDetector(
                onTap: _pickVideoFromGallery,
                child: Container(
                  height: 160,
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
                              Icon(Icons.video_library, color: Colors.redAccent, size: 45),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select video from gallery',
                                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 32),
                              SizedBox(width: 10),
                              Text(
                                'Video Selected Successfully!',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. የርዕስ (Title) ማስገቢያ ሳጥን (ከቪዲዮ መጫኛው በታች)
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
              const SizedBox(height: 16),

              // 3. የዲስክሪፕሽን (Description) ማስገቢያ ሳጥን (ከተጨማሪ መግለጫ ጋር)
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a description...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 4. የመጫኛ (Upload) ቁልፍ
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
