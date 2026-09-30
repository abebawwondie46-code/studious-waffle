import 'dart:io';
import 'package:flutter/material.dart';
import 'video_service.dart';

class PosterEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? remixedTemplateData;

  const PosterEditorScreen({Key? key, this.remixedTemplateData}) : super(key: key);

  @override
  _PosterEditorScreenState createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final _titleController = TextEditingController();
  final _textContentController = TextEditingController();
  final VideoService _videoService = VideoService();
  
  bool _isPublishing = false;
  String _selectedCategory = 'ንግድ';
  Color _canvasColor = Colors.amber;

  @override
  void initState() {
    super.initState();
    // Remix ከተደረገ የነበረውን ዳታ መሙላት
    if (widget.remixedTemplateData != null) {
      _textContentController.text = widget.remixedTemplateData!['text'] ?? '';
      _titleController.text = "Remix - ${_textContentController.text}";
    } else {
      _textContentController.text = "የእርስዎ ማስታወቂያ ፅሁፍ";
    }
  }

  Future<void> _publish() async {
    setState(() => _isPublishing = true);

    try {
      // ማሳሰቢያ፦ እዚህ ጋር ከስልክ የወጣው/የተቀረጸው የቪዲዮ/ፖስተር ፋይል ይተካል
      // ለምሳሌ፡ File sampleFile = File(path);
      
      final templateData = {
        'text': _textContentController.text,
        'color': _canvasColor.value.toString(),
      };

      // ቪዲዮ ፋይል የመረጡበትን መስመር እዚህ ያስገቡ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ፖስተሩ/ቪዲዮው በተሳካ ሁኔታ ተፖስቷል!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ስህተት: $e')),
      );
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የማስታወቂያ ፈጠራ Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview Canvas
            Container(
              height: 250,
              width: double.infinity,
              color: _canvasColor,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Text(
                _textContentController.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textContentController,
              decoration: const InputDecoration(
                labelText: 'የማስታወቂያው ፅሁፍ (Text Content)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'የፖስቱ ርዕስ (Title)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publish,
                icon: const Icon(Icons.send),
                label: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ወደ Feed ስቀል (Publish)', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
