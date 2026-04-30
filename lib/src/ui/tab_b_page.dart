import 'package:flutter/material.dart';

/// Settings tab page
class TabBPage extends StatelessWidget {
  const TabBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InfoTile(label: 'Framework', value: 'Flutter'),
          _InfoTile(label: 'Architecture', value: 'Repository Pattern + GoRouter'),
          _InfoTile(label: 'Storage', value: 'Hive + SharedPreferences'),
          _InfoTile(label: 'HTTP', value: 'Dio'),
          _InfoTile(label: 'State', value: 'RxDart'),
          _InfoTile(label: 'UI Scale', value: 'flutter_screenutil'),
          SizedBox(height: 24),
          Text(
            'Start building your app by creating repositories and features:',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('make create-repo name=my_repository'),
          SizedBox(height: 4),
          Text('make create-feature name=my_feature'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(value),
        ],
      ),
    );
  }
}
