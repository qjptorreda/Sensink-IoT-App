import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<String> _titles = ["Control Panel", "Results", "Faucet Timer", "Account"];

  // Controllers for editing profile
  final _nameEditController = TextEditingController();
  final _phoneEditController = TextEditingController();
  final _addressEditController = TextEditingController();

  // --- PROFILE IMAGE UPLOAD ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      File file = File(image.path);
      String uid = FirebaseAuth.instance.currentUser!.uid;

      try {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref('profile_pics/$uid.jpg')
            .putFile(file);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profilePic': downloadUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated!")),
          );
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
      }
    }
  }

  // --- EDIT PROFILE SHEET ---
  void _showEditProfileSheet(Map<String, dynamic> currentData) {
    _nameEditController.text = currentData['name'] ?? "";
    _phoneEditController.text = currentData['phone'] ?? "";
    _addressEditController.text = currentData['address'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildEditField(_nameEditController, "Full Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildEditField(_phoneEditController, "Phone Number", Icons.phone_outlined),
            const SizedBox(height: 15),
            _buildEditField(_addressEditController, "Address", Icons.location_on_outlined),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': _nameEditController.text.trim(),
                  'phone': _phoneEditController.text.trim(),
                  'address': _addressEditController.text.trim(),
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Update Information", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        title: Text(_titles[_currentIndex], style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardView(),
                _buildResultsView(),
                _buildTimerView(),
                _buildAccountManagementView(),
              ],
            ),
          ),
          if (_currentIndex != 3) _buildBottomStatusCard(),
        ],
      ),
    );
  }

  // --- DASHBOARD VIEW ---
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
        int cleanliness = data['cleanliness'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  _buildStatCard("pH Level", ph.toStringAsFixed(1), Icons.science, 
                      ph >= 6.5 && ph <= 8.5 ? Colors.green : Colors.orange, 
                      ph > 7.5 ? "Alkaline" : ph < 6.5 ? "Acidic" : "Optimal"),
                  _buildStatCard("Cleanliness", "$cleanliness%", Icons.auto_awesome, 
                      Colors.blueAccent, cleanliness > 80 ? "Crystal Clear" : "Filtering..."),
                ],
              ),
              const SizedBox(height: 20),
              _buildWaterLevelCard(waterLevel),
              const SizedBox(height: 25),
              const Text("Quick Controls", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActionTile(Icons.refresh, "Run Manual Test", "Recalibrate sensors now"),
              _buildActionTile(Icons.notifications_active_outlined, "Alert Thresholds", "Set pH warnings"),
            ],
          ),
        );
      },
    );
  }

  // --- ACCOUNT VIEW ---
  Widget _buildAccountManagementView() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        String name = data['name'] ?? "No Name";
        String email = data['email'] ?? user?.email ?? "No Email";
        String? profilePic = data['profilePic'];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Account Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("View and update your personal information.", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 25),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                            child: profilePic == null ? const Icon(Icons.person, size: 55, color: Colors.blueAccent) : null,
                          ),
                          Positioned(
                            bottom: 2, right: 2,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _showEditProfileSheet(data),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit Profile"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoTile(Icons.person_outline, "Full Name", name, Colors.blue),
              _buildInfoTile(Icons.alternate_email, "Username", data['username'] ?? "N/A", Colors.teal),
              _buildInfoTile(Icons.phone_outlined, "Phone Number", data['phone'] ?? "N/A", Colors.deepPurple),
              _buildInfoTile(Icons.location_on_outlined, "Address", data['address'] ?? "N/A", Colors.orange),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // --- HELPERS ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 18, child: Icon(icon, color: color, size: 20)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
          Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWaterLevelCard(double level) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Water Tank Level", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(level * 100).toInt()}%", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: level, minHeight: 10, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Widget _buildResultsView() => const Center(child: Text("Detailed Results View"));
  Widget _buildTimerView() => const Center(child: Text("Faucet Timer View"));

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
      child: Column(children: [
        const DrawerHeader(child: Center(child: Text("SenSink", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
        _drawerItem(Icons.dashboard, "Control Panel", 0),
        _drawerItem(Icons.water_drop, "Results", 1),
        _drawerItem(Icons.timer, "Faucet Timer", 2),
        _drawerItem(Icons.account_circle, "Account", 3),
        const Spacer(),
        ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () => FirebaseAuth.instance.signOut()),
        const SizedBox(height: 20),
      ]),
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