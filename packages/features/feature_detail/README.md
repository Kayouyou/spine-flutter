# Feature Detail

Detail feature module for the application.

## Structure

```
lib/
  src/
    cubit/           # State management (DetailCubit, DetailState)
    repository/      # Data layer (DetailRepository, DetailRepositoryImpl)
    ui/              # UI components (DetailPage)
    di/              # Dependency injection setup
    models/          # Feature-specific models
  feature_detail.dart  # Barrel file (public exports)
test/
  feature_detail_test.dart
```

## Usage

```dart
import 'package:feature_detail/feature_detail.dart';

// Setup DI
setupFeatureDetail(GetIt.instance);

// Use in routing
GoRoute(
  path: '/detail',
  builder: (context, state) => const DetailPage(),
)
```

## Dependencies

- `api` - API infrastructure
- `domain` - Domain models and exceptions
- `routing` - Navigation infrastructure
- `component_library` - Shared UI components
- `auth` - Authentication service