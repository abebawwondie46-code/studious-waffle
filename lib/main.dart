import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // የ Supabase ግንኙነት ማበጀት
  await Supabase.initialize(
    url: 'https://ycvycgdnnmlfaebtxvfl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljdnljZ2Rubm1sZmFlYnR4dmZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyOTk2MjAsImV4cCI6MjA5Njg3NTYyMH0.Os73HGXe4EOijqpBVHk9Bcm6uzZXkgZjWRoroV1m2gE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuanYngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
      ),
      home: const FeedScreen(),
    );
  }
}
