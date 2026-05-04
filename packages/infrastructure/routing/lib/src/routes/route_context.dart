import 'package:flutter/material.dart';
import 'package:auth/auth.dart';

/// RouteContext bundles dependencies for route modules.
class RouteContext {
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthManager? authManager;
  final bool enableAuthGuard;

  const RouteContext({
    required this.navigatorKey,
    this.authManager,
    this.enableAuthGuard = true,
  });
}
