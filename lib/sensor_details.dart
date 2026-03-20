import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';

class PHHistoryScreen extends StatelessWidget {
  const PHHistoryScreen({super.key});

  // --- HELPER FUNCTIONS (NOW INSIDE THE CLASS) ---
  Color _getColor(double value) {
    if (value >= 6.5 && value <= 8.5) return const Color(0xFF4CAF50); // Green
    if (value < 6.5) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String _getStatus(double value) {
    if (value >= 6.5 && value <= 8.5) return "Optimal";
    if (value < 6.5) return "Acidic";
    return "Alkaline";
  }

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
          if (snapshot.hasError) {
            return Center(child: Text("Index needed or Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data?.docs ?? [];
          if (logs.isEmpty) return const Center(child: Text("No records found in sensor_logs."));

          try {
            // Latest reading for the top card
            double currentPH = (logs.first.data() as Map<String, dynamic>)['value']?.toDouble() ?? 0.0;

            // Graph Data
            List<FlSpot> spots = logs.asMap().entries.map((e) {
              double val = (e.value.data() as Map<String, dynamic>)['value']?.toDouble() ?? 0.0;
              return FlSpot(e.key.toDouble(), val);
            }).toList().reversed.toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. COMPARISON CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem("Current pH", currentPH.toStringAsFixed(1)),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildSummaryItem("Target pH", "7.0"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. GRAPH
                  const Text("pH Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.only(right: 20, top: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: LineChart(LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: _getColor(currentPH),
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: _getColor(currentPH).withOpacity(0.1)),
                        ),
                      ],
                    )),
                  ),
                  const SizedBox(height: 30),

                  // 3. HISTORY LIST
                  const Text("Previous Readings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      var data = logs[index].data() as Map<String, dynamic>;
                      double value = (data['value'] ?? 0.0).toDouble();
                      var ts = data['timestamp'];
                      DateTime date = ts is Timestamp ? ts.toDate() : DateTime.now();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(value).withOpacity(0.1),
                            child: Icon(Icons.science, color: _getColor(value), size: 18),
                          ),
                          title: Text("${value.toStringAsFixed(1)} pH", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(date)),
                          trailing: Text(_getStatus(value), style: TextStyle(color: _getColor(value), fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          } catch (e) {
            return Center(child: Text("Data parsing error: $e"));
          }
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class CleanlinessDetailScreen extends StatelessWidget {
  const CleanlinessDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Cleanliness")), body: const Center(child: Text("Details...")));
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Analytics Dashboard"));
}