# key_value_storage

Hive + SharedPreferences wrapper.

## Usage

```dart
final storage = KeyValueStorage();
await storage.putString('key', 'value');
final value = await storage.getString('key');
```

See `PreferencesService` for typed preference access.
