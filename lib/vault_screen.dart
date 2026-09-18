import 'package:flutter/material.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _isUnlocked = false;
  String _enteredPin = "";
  final String _correctPin = "1234"; // ነባሪ PIN Code (ተጠቃሚው ሊቀይረው ይችላል)
  String _errorMessage = "";

  // Mock Private Saved Videos
  final List<Map<String, String>> _privateVideos = [
    {"title": "የምስጢር ማስታወሻ ቪዲዮ", "duration": "02:15", "date": "Sep 12, 2026"},
    {"title": "Personal Vlog Draft", "duration": "05:40", "date": "Sep 15, 2026"},
    {"title": "Private Project Demo", "duration": "01:10", "date": "Sep 18, 2026"},
  ];

  void _onKeyPress(String value) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorMessage = "";
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = "";
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _correctPin) {
      setState(() {
        _isUnlocked = true;
        _errorMessage = "";
      });
    } else {
      setState(() {
        _errorMessage = "የተሳሳተ PIN Code ነው! እባክዎ ድጋሚ ይሞክሩ።";
        _enteredPin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        title: Text(
          _isUnlocked ? "Private Vault" : "Locked Vault",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121217),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isUnlocked
            ? [
                IconButton(
                  icon: const Icon(Icons.lock_rounded, color: Colors.pinkAccent),
                  onPressed: () {
                    setState(() {
                      _isUnlocked = false;
                      _enteredPin = "";
                    });
                  },
                )
              ]
            : null,
      ),
      body: _isUnlocked ? _buildVaultContent() : _buildPinPad(),
    );
  }

  // PIN Input Screen (የመቆለፊያ ገጽ)
  Widget _buildPinPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 70, color: Colors.pinkAccent),
          const SizedBox(height: 16),
          const Text(
            "የምስጢር ማከማቻ (Content Vault)",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "ለመክፈት የ 4-አሃዝ PIN Code ያስገቡ (ነባሪ: 1234)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // PIN Indicators (4 Dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              bool isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? Colors.pinkAccent : Colors.grey.shade800,
                  border: Border.all(color: Colors.pinkAccent, width: 1.5),
                ),
              );
            }),
          ),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],

          const SizedBox(height: 32),

          // Keypad Buttons Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              if (index == 9) {
                return const SizedBox.shrink(); // Empty left corner
              } else if (index == 10) {
                return _buildKeyButton("0", () => _onKeyPress("0"));
              } else if (index == 11) {
                return _buildKeyButton("⌫", _onDelete, isAction: true);
              } else {
                String val = (index + 1).toString();
                return _buildKeyButton(val, () => _onKeyPress(val));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isAction ? Colors.pinkAccent : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Unlocked Vault Screen (የተቆለፉ ቪዲዮዎች ዝርዝር)
  Widget _buildVaultContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Vault Unlocked", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("እነዚህ ቪዲዮዎች ለእርስዎ ብቻ የሚታዩ ናቸው።", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text("የተሸሸጉ ቪዲዮዎች (Protected Files)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        ..._privateVideos.map((video) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.pinkAccent),
              ),
              title: Text(video['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("${video['duration']} • Added: ${video['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.more_vert, color: Colors.grey),
            ),
          );
        }),
      ],
    );
  }
}
