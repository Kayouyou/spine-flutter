import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home tab page
class TabAPage extends StatelessWidget {
  const TabAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Scaffold Ready',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Infrastructure packages are set up.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/detail-c'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Detail'),
            ),
          ],
        ),
      ),
    );
  }
}
