import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreFeedScreen extends StatefulWidget {
  const ExploreFeedScreen({super.key});

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  final TextEditingController _postCaptionController = TextEditingController();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  bool _showColorPicker = false;
  Color _selectedBackgroundColor = Colors.black87;

  final List<Color> _backgroundColors = [
    Colors.black87,
    Colors.deepPurple.shade900,
    Colors.indigo.shade900,
    Colors.teal.shade900,
    Colors.brown.shade900,
    Colors.pink.shade900,
    Colors.orange.shade900,
    Colors.blueGrey.shade900,
    Colors.red.shade900,
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
