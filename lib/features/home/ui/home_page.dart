import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 首页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('骨架搭建完成', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('基础设施包已配置完成。'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/detail'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('打开详情页'),
            ),
          ],
        ),
      ),
    );
  }
}