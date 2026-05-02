import 'package:flutter/material.dart';

/// RouteContext bundles dependencies for route modules.
class RouteContext {
  final GlobalKey<NavigatorState> navigatorKey;

  const RouteContext({required this.navigatorKey});
}
