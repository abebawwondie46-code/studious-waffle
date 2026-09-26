import 'package:flutter/material.dart';
import 'tiktok_feed_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad Creator & TikTok Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const TikTokFeedScreen(), // መነሻ ገጹን ወደ Feed ለወጥነው
    );
  }
}
