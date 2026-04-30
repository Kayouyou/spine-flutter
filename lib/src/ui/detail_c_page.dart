import 'package:flutter/material.dart';

/// Detail page — pushed from Tab A, hides bottom navigation
class DetailCPage extends StatelessWidget {
  const DetailCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64),
            SizedBox(height: 16),
            Text('This is a detail page'),
            SizedBox(height: 8),
            Text(
              'Bottom navigation is hidden when pushing this page.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
