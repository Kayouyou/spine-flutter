## ADDED Requirements

### Requirement: ThemeCubit manages theme state
A ThemeCubit SHALL manage current theme mode (light/dark/system) and emit state changes.

#### Scenario: Initial theme from storage
- **WHEN** ThemeCubit is created
- **THEN** cubit loads saved theme from KeyValueStorage

#### Scenario: Theme state emission
- **WHEN** theme changes to dark mode
- **THEN** cubit emits ThemeState with ThemeMode.dark

### Requirement: Theme switch widget reflects state
Theme toggle switch SHALL reflect current theme state and allow user to change.

#### Scenario: Switch shows current state
- **WHEN** current theme is dark
- **THEN** switch is in ON position

#### Scenario: User toggles to light mode
- **WHEN** user toggles switch from ON to OFF
- **THEN** ThemeCubit.setTheme(ThemeMode.light) is called

### Requirement: MaterialApp uses dynamic theme
MyApp SHALL rebuild with new theme when ThemeCubit state changes.

#### Scenario: Theme rebuild
- **WHEN** ThemeCubit emits new ThemeState
- **THEN** MaterialApp.theme updates to match state.mode

#### Scenario: Dark theme applied
- **WHEN** ThemeState.mode is ThemeMode.dark
- **THEN** MaterialApp uses appDarkTheme

### Requirement: Theme persists across sessions
Selected theme SHALL persist in KeyValueStorage and restore on app launch.

#### Scenario: Theme saved on change
- **WHEN** user changes theme
- **THEN** KeyValueStorage.put('theme_mode', mode.name) is called

#### Scenario: Theme restored on launch
- **WHEN** app launches AND storage has saved theme
- **THEN** ThemeCubit initializes with saved mode