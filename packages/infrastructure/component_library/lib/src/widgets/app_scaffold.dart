import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

/// 统一页面结构 widget
///
/// 职责：封装 Scaffold + CustomAppBar，减少模板代码
/// 提供两种模式：
/// - 简单模式：传 title（默认 appBar）
/// - 高级模式：传 appBar（完全自定义 appBar）
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    super.key,
  }) : assert(
         title != null || appBar != null,
         'Either title or appBar must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = appBar ?? CustomAppBar(
      title: title!,
      actions: actions,
      showBackButton: showBackButton,
    );

    return Scaffold(
      appBar: effectiveAppBar,
      body: body,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
