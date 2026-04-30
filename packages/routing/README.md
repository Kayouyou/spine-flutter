# routing

GoRouter setup with RouteModule pattern.

## Architecture

```dart
// Create a route module
class MyRouteModule extends RouteModule {
  MyRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/my-page',
        builder: (context, state) => MyPage(),
      ),
    ];
  }
}

// Register in router
routes: [...MyRouteModule(ctx).build()],
```

RouteContext bundles dependencies for route modules.
Add your repositories to RouteContext as needed.
