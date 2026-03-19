import 'package:flutter/material.dart';

class PHHistoryScreen extends StatelessWidget {
  const PHHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("pH History")), body: const Center(child: Text("Logs...")));
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