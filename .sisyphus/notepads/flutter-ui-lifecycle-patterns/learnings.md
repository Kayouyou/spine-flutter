# Learnings - Flutter UI Lifecycle Patterns

## Task 2: AppScaffold Widget

- AppScaffold uses a `StatelessWidget` with an `assert` to enforce either `title` or `appBar` is provided — no `if` checks needed at build time.
- Two modes: simple (`title`) creates a `CustomAppBar` internally; advanced (`appBar`) accepts any `PreferredSizeWidget`.
- `showBackButton` only applies in simple mode (when title is used). For custom appBar, the caller controls back button behavior.
- Pre-commit hooks run `flutter analyze` and unit tests — all passed without issues.
- The `effectiveAppBar` pattern (local variable) avoids repeating the ternary/?? in the Scaffold constructor.
