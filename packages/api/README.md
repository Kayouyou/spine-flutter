# api

HTTP client based on Dio, using mixin pattern for API modules.

## Architecture

```dart
// 1. Add a new API mixin
mixin MyApiMixin on ApiBase {
  Future<Map<String, dynamic>> getData() {
    return httpManager.fireInternal(
      path: '/api/my/data',
      method: HttpMethod.GET,
    );
  }
}

// 2. Register in Api class (packages/api/lib/src/api.dart)
class Api extends ApiBase with MyApiMixin, ... { }

// 3. Call from repository
final data = await api.getData();
```

## Demo

See `lib/src/modules/demo/demo_api.dart` for an example.
