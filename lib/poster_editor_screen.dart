import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';

class PosterEditorScreen extends StatefulWidget {
  const PosterEditorScreen({Key? key}) : super(key: key);

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final GlobalKey _globalKey = GlobalKey();

  String _displayText = "የልጆችዎን ነገ ዛሬ ያሳምሩ";
  Color _textColor = Colors.white;
  Color _backgroundColor = const Color(0xFF1B5E20);
  double _fontSize = 26.0;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = _displayText;
  }

  Future<void> _captureAndSavePoster() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await imagePath.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ፖስተሩ ተቀምጧል: ${imagePath.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ስህተት ተከሰቷል: $e')),
      );
    }
  }

  void _pickColor({required bool isTextColor}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTextColor ? 'የጽሁፍ ቀለም ይምረጡ' : 'የጀርባ ቀለም ይምረጡ'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isTextColor ? _textColor : _backgroundColor,
            onColorChanged: (color) {
              setState(() {
                if (isTextColor) {
                  _textColor = color;
                } else {
                  _backgroundColor = color;
                }
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ጨርስ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ማስታወቂያ ኤዲተር'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _captureAndSavePoster,
            tooltip: 'ምስል አድርገህ አስቀምጥ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _displayText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: _fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          color: Colors.black45,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "የእርስዎ ብራንድ/Brand Name",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Icon(Icons.verified, color: Colors.amber, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'ማስታወቂያ ወይም ጽሁፍ እዚህ ይፃፉ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _displayText = text;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("መጠን: "),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14.0,
                          max: 48.0,
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickColor(isTextColor: true),
                        icon: Icon(Icons.color_lens, color: _textColor),
                        label: const Text('የጽሁፍ ቀለም'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickColor(isTextColor: false),
                        icon: Icon(Icons.format_color_fill, color: _backgroundColor),
                        label: const Text('የጀርባ ቀለም'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
