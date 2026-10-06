import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _captionController = TextEditingController(); // <--- ከቲል ወደ ኬፕሽን ተቀየረ
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedVideoFile;
  bool _isLoading = false;

  // Function to pick video from gallery
  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideoFile = File(video.path);
      });
    }
  }

  // Function to upload video to Supabase Storage and Database
  Future<void> _uploadVideo() async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first!')),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) { // <--- ማረጋገጫው ወደ caption ተቀየረ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a video caption!')),
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

      // 1. Upload video to Supabase Storage
      await supabase.storage.from('videos').upload(
            filePath,
            _selectedVideoFile!,
            fileOptions: const FileOptions(upsert: false),
          );

      // 2. Get public URL of the uploaded video
      final videoUrl = supabase.storage.from('videos').getPublicUrl(filePath);

      // 3. Insert record into videos table (ከ title ወደ caption ተቀየረ)
      await supabase.from('videos').insert({
        'caption': _captionController.text.trim(), // <--- እዚህ ጋር caption ሆነ
        'video_url': videoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );

      // Clear form fields
      _captionController.clear();
      setState(() {
        _selectedVideoFile = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
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
              // 1. Gallery Video Picker Box
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
                        ? const Icon(Icons.video_library, color: Colors.redAccent, size: 50)
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

             // 3. Caption TextField
             TextField(
               controller: _captionController, // <--- _captionController ተገናኘ
               style: const TextStyle(color: Colors.white),
               maxLines: 3,
               decoration: InputDecoration(
                 hintText: 'Caption',
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

              // 4. Upload Button
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
