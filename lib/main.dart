import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/feed_screen.dart';
import 'screens/create_screen.dart'; // አዲሱ የቪዲዮ መፍጠሪያ ፋይል
import 'screens/profile_screen.dart'; // አዲሱ የፕሮፋይል ፋይል
import 'admin/admin_service.dart'; // <--- አዲሱን የአድሚን ሰርቪስ ፋይል እዚህ አስመጣን

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // የሱፓቤስ ማገናኛ ቁልፎችዎ በትክክል ተካትተዋል
  await Supabase.initialize(
    url: 'https://jhwjfnzqxfxbnzdvqrovk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impod2pmenF4ZnhibnpkdnFyb3ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2NTg3MTMsImV4cCI6MjEwODIzNDcxM30.yN7SWaJCuMEnGTSaSa4jf5eItuLUahyKKR2N3mjiYYk'
     );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ሦስቱን ዋና ዋና ስክሪኖች እዚህ በንጹህ መልኩ አካተናል
  final List<Widget> _screens = [
    const FeedScreen(),
    const CreateScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // አፕ ሲከፈት ከ Supabase የሰርቨር ቅንብሮችን (Maintenance mode እና Announcement) ማረጋገጥ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminService.checkAppStatus(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
