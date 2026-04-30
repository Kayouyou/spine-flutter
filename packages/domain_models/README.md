# domain_models

Pure Dart data classes with fromJson/toJson.

## Conventions

- Each model class has `fromJson` factory and `toJson` method
- No business logic, no dependencies on Flutter
- See `lib/src/demo/` for examples

## Creating a new model

```dart
class MyModel {
  final String id;
  final String name;

  MyModel({required this.id, required this.name});

  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```
