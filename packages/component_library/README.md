# component_library

Theme system for Flutter apps.

## Usage

```dart
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final theme = OVSTheme.of(context);
    return Container(
      color: theme.colors.background,
      child: Text('Hello', style: theme.textStyles.body),
    );
  }
}
```
