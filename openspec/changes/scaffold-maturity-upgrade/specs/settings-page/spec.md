## ADDED Requirements

### Requirement: Settings page as feature package
Settings functionality SHALL be implemented as `feature_settings` package following existing feature structure.

#### Scenario: Package structure follows convention
- **WHEN** feature_settings is created
- **THEN** package contains cubit/, repository/, ui/, di/, models/ directories

#### Scenario: DI registration
- **WHEN** `setupDependencies()` runs
- **THEN** `setupFeatureSettings(sl)` is called

### Requirement: Settings page displays configurable options
Settings page SHALL display theme switch, language selector, and other user preferences.

#### Scenario: Theme switch visible
- **WHEN** user opens settings page
- **THEN** theme toggle switch is displayed with current state

#### Scenario: Language selector visible
- **WHEN** user opens settings page
- **THEN** language dropdown shows available options (zh, en)

### Requirement: Settings changes persist immediately
User preference changes SHALL persist to KeyValueStorage immediately upon change.

#### Scenario: Theme change persists
- **WHEN** user toggles theme switch
- **THEN** ThemeCubit updates state AND KeyValueStorage saves preference

#### Scenario: Language change persists
- **WHEN** user selects different language
- **THEN** LocaleCubit updates state AND KeyValueStorage saves preference

### Requirement: Settings page navigation
Settings page SHALL be accessible via `/settings` route.

#### Scenario: Route definition
- **WHEN** routing package defines routes
- **THEN** `/settings` maps to SettingsPage widget

#### Scenario: Navigation from other pages
- **WHEN** user clicks settings icon in app bar
- **THEN** context.go('/settings') navigates to settings page