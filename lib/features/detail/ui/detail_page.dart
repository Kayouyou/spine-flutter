import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 详情页
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('详情页')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('详情页面', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}