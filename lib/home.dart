import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure you added this to pubspec.yaml
import 'package:intl/intl.dart';
import 'dart:async';

// --- GLOBAL THEME ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFaucetOpen = true; // or false depending on your default
  bool _isProcessing = false;
  bool _timerActive = false; 
  Duration _selectedDuration = const Duration(minutes: 5); 

  final List<String> _titles = ["Control Panel", "Results", "Faucet Timer", "Account"];

  late AnimationController _progressController;

  final _nameEditController = TextEditingController();
  final _phoneEditController = TextEditingController();
  final _addressEditController = TextEditingController();
  Timer? _countdownTimer; 
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isFaucetOpen = !_isFaucetOpen;
            _isProcessing = false;
          });
          _progressController.reset();
          _showFeedback();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _nameEditController.dispose();
    _phoneEditController.dispose();
    _addressEditController.dispose();
    super.dispose();
  }

  void _handleFaucetTap() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _progressController.forward();
  }

  void _showFeedback() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFaucetOpen ? "✅ Faucet Opened" : "🛑 Faucet Closed"),
        backgroundColor: _isFaucetOpen ? Colors.blueAccent : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

// 1. Show the Picker
void _showDurationPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Select Duration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListWheelScrollView(
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => _selectedDuration = Duration(minutes: (index + 1) * 5));
              },
              children: List.generate(12, (index) => Text("${(index + 1) * 5} Minutes")),
            ),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Set Time"))
        ],
      ),
    ),
  );
}

// 2. Start Timer & Update Firebase
void _startFaucetTimer() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  setState(() {
    _timerActive = true;
    _isFaucetOpen = true;
    _remainingTime = _selectedDuration;
  });

  // 1. Update Firebase
  await FirebaseFirestore.instance.collection('sensor_data').doc(uid).update({
    'isFaucetOpen': true,
    'timerActive': true,
    'shutOffTime': DateTime.now().add(_selectedDuration).toIso8601String(),
  });

  // 2. Start the ticking countdown for the UI
  _countdownTimer?.cancel(); // Clear any old timer
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_remainingTime.inSeconds > 0) {
      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    } else {
      _cancelTimer(); // Auto-close when hits zero
    }
  });
}

void _cancelTimer() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  _countdownTimer?.cancel(); // STOPS the ticking immediately

  setState(() {
    _timerActive = false;
    _isFaucetOpen = false;
    _remainingTime = Duration.zero;
  });

  await FirebaseFirestore.instance.collection('sensor_data').doc(uid).update({
    'isFaucetOpen': false,
    'timerActive': false,
    'shutOffTime': null,
  });
}



  // --- NAVIGATION LOGIC ---
  Widget _getBody() {
    switch (_currentIndex) {
      case 0: return _buildDashboardView();
      case 1: return _buildResultsView(); // Now points to the Analytics
      case 2: return _buildTimerView();
      case 3: return _buildAccountManagementView();
      default: return _buildDashboardView();
    }
  }

  // --- 1. DASHBOARD VIEW (Original Restored) ---
  Widget _buildDashboardView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('sensor_data').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error syncing data"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        double ph = (data['ph'] ?? 7.0).toDouble();
        double waterLevel = (data['waterLevel'] ?? 0.0).toDouble();
        int cleanliness = (data['cleanliness'] ?? 0).toInt();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressController.value,
                                strokeWidth: 10,
                                backgroundColor: Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isFaucetOpen ? Colors.redAccent : Colors.blueAccent,
                                ),
                              );
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleFaucetTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isProcessing ? Colors.grey.shade800 : (_isFaucetOpen ? Colors.blueAccent : Colors.redAccent),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isFaucetOpen ? Colors.blue : Colors.red).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                )
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                            ),
                            child: Icon(
                              _isProcessing ? Icons.hourglass_bottom : (_isFaucetOpen ? Icons.water_drop : Icons.block_flipped),
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isProcessing ? "SYNCING..." : (_isFaucetOpen ? "FAUCET OPEN" : "FAUCET CLOSED"),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isProcessing ? Colors.grey : (_isFaucetOpen ? Colors.blueAccent : Colors.redAccent),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text("System Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard(
                    "pH Level", ph.toStringAsFixed(1), Icons.science_outlined, 
                    ph >= 6.5 && ph <= 8.5 ? Colors.green : Colors.orange, 
                    ph > 7.5 ? "Alkaline" : ph < 6.5 ? "Acidic" : "Optimal",
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PHHistoryScreen())),
                  ),
                  _buildStatCard(
                    "Cleanliness", "$cleanliness%", Icons.cleaning_services_outlined, 
                    cleanliness >= 80 ? Colors.green : Colors.orange, 
                    cleanliness >= 80 ? "Clean" : "Needs Filtering",
                    () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildWaterLevelCard(waterLevel, () => setState(() => _currentIndex = 1)),
              const SizedBox(height: 20),
              const Text("Quick Controls", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActionTile(Icons.timer, "Set Faucet Timer", "Automate flow", () => setState(() => _currentIndex = 2)),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  // --- 2. RESULTS VIEW (New Live Analytics) ---
  Widget _buildResultsView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
            .collection('sensor_logs')
            .where('userId', isEqualTo: uid)
            .where('type', isEqualTo: 'ph')
            .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Live Analytics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildMiniGraphCard("pH Trend", Colors.blueAccent, snapshot.data?.docs ?? []),
              const SizedBox(height: 20),
              _buildMiniGraphCard("Purity (%)", Colors.orangeAccent, snapshot.data?.docs ?? []),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniGraphCard(String title, Color color, List<QueryDocumentSnapshot> docs) {
    List<FlSpot> spots = docs.asMap().entries.map((e) {
      double val = (e.value.data() as Map<String, dynamic>)['value']?.toDouble() ?? 0.0;
      return FlSpot(e.key.toDouble(), val);
    }).toList().reversed.toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTimerView() {
  return SingleChildScrollView( // Prevents overflow on small screens
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.timer_outlined,
          size: 100,
          color: _timerActive ? Colors.orange : Colors.blueAccent,
        ),
        const SizedBox(height: 40),
        Text(
          _timerActive ? "Remaining Time" : "Set Timer Duration",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        
        // --- THE ROULETTE CARD ---
        Container(
          height: 180, // Increased height for better scrolling
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _timerActive 
                  ? Colors.orange.withOpacity(0.3) 
                  : Colors.blueAccent.withOpacity(0.1)
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: _timerActive
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 54, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.orange,
                        fontFamily: 'monospace' // Keeps numbers steady
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "REMAINING",
                      style: TextStyle(
                        letterSpacing: 2, 
                        color: Colors.grey, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                )
              : ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005, // Adds a slight 3D curve effect
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      // Correctly maps index 0 to 5 mins, index 1 to 10 mins, etc.
                      _selectedDuration = Duration(minutes: (index + 1) * 5);
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 12, // 5 to 60 minutes
                    builder: (context, index) {
                      final minutes = (index + 1) * 5;
                      final isSelected = _selectedDuration.inMinutes == minutes;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
                          ),
                          child: Text("$minutes Minutes"),
                        ),
                      );
                    },
                  ),
                ),
        ),
        
        const SizedBox(height: 50),
        
        // --- BUTTON ---
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _timerActive ? _cancelTimer : _startFaucetTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _timerActive ? Colors.redAccent : Colors.blueAccent,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              _timerActive ? "STOP TIMER" : "START TIMER",
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

  // --- 4. ACCOUNT VIEW (Original Restored) ---
  Widget _buildAccountManagementView() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        String name = data['name'] ?? "User Name";
        String email = data['email'] ?? user?.email ?? "";
        String? profilePic = data['profilePic'];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                    child: profilePic == null ? const Icon(Icons.person, size: 60, color: Colors.blueAccent) : null,
                  ),
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: const CircleAvatar(radius: 18, backgroundColor: Colors.blueAccent, child: Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              _buildInfoTile(Icons.phone, "Phone", data['phone'] ?? "Not set", Colors.blue),
              _buildInfoTile(Icons.location_on, "Address", data['address'] ?? "Not set", Colors.orange),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showEditProfileSheet(data),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Edit Profile Details"),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
      },
    );
  }

  // --- PROFILE LOGIC ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ref = FirebaseStorage.instance.ref().child('user_profiles').child('$uid.jpg');
    
    await ref.putFile(File(image.path));
    final url = await ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'profilePic': url});
  }

  void _showEditProfileSheet(Map<String, dynamic> currentData) {
    _nameEditController.text = currentData['name'] ?? "";
    _phoneEditController.text = currentData['phone'] ?? "";
    _addressEditController.text = currentData['address'] ?? "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _nameEditController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _phoneEditController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: _addressEditController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': _nameEditController.text,
                  'phone': _phoneEditController.text,
                  'address': _addressEditController.text,
                });
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS (Restored) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String status, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLevelCard(double level, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Water Tank Level", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(level * 100).toInt()}%", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: level, minHeight: 10, borderRadius: BorderRadius.circular(10), backgroundColor: Colors.blue.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation(Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(_titles[_currentIndex], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(child: _getBody()),
          if (_currentIndex != 3) _buildBottomStatusCard(),
        ],
      ),
    );
  }

  Widget _buildBottomStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF2D3436), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi, color: Colors.blueAccent, size: 18),
          SizedBox(width: 10),
          Text("System Connected", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(child: Center(child: Text("SenSink", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
          _drawerItem(Icons.dashboard, "Control Panel", 0),
          _drawerItem(Icons.water_drop, "Results", 1),
          _drawerItem(Icons.timer, "Faucet Timer", 2),
          _drawerItem(Icons.account_circle, "Account", 3),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Logout"), onTap: () => FirebaseAuth.instance.signOut()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _currentIndex == index ? Colors.blueAccent : Colors.grey),
      title: Text(title),
      selected: _currentIndex == index,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

// --- UPDATED FULL SCREEN ANALYTICS CLASS ---
class PHHistoryScreen extends StatelessWidget {
  const PHHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("pH Level Analytics", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sensor_logs')
            .where('userId', isEqualTo: uid)
            .where('type', isEqualTo: 'ph')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data?.docs ?? [];
          if (logs.isEmpty) return const Center(child: Text("No records found."));
          List<FlSpot> spots = logs.asMap().entries.map((e) {
            double val = (e.value.data() as Map<String, dynamic>)['value']?.toDouble() ?? 0.0;
            return FlSpot(e.key.toDouble(), val);
          }).toList().reversed.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // THE FULL SCREEN GRAPH CARD
                Container(
                  height: 300,
                  padding: const EdgeInsets.fromLTRB(10, 20, 25, 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Align(alignment: Alignment.centerLeft, child: Text("History Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 15),
                // THE LOGS LIST
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var data = logs[index].data() as Map<String, dynamic>;
                    double value = (data['value'] ?? 0.0).toDouble();
                    DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _getColor(value).withOpacity(0.1), child: Icon(Icons.science, color: _getColor(value))),
                        title: Text("pH: ${value.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('yMMMd').add_jm().format(date)),
                        trailing: Text(_getStatus(value), style: TextStyle(color: _getColor(value), fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColor(double val) => (val < 6.5 || val > 8.5) ? Colors.orange : Colors.green;
  String _getStatus(double val) => (val < 6.5) ? "ACIDIC" : (val > 8.5) ? "ALKALINE" : "OPTIMAL";
}