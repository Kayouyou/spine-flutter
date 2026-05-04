## ADDED Requirements

### Requirement: Route guard intercepts protected paths
The routing system SHALL support optional authentication-based path interception. When enabled, unauthenticated users attempting to access protected paths SHALL be redirected to the login page.

#### Scenario: Unauthenticated user accesses protected path
- **WHEN** user is not logged in AND navigates to `/profile` or `/settings`
- **THEN** system redirects to `/login?redirect=/profile`

#### Scenario: Authenticated user accesses protected path
- **WHEN** user is logged in AND navigates to `/profile`
- **THEN** system allows navigation without redirect

#### Scenario: Route guard disabled
- **WHEN** `enableAuthGuard` is false
- **THEN** all paths are accessible regardless of auth state

### Requirement: Redirect preserves original destination
The redirect query parameter SHALL preserve the originally requested path for post-login navigation.

#### Scenario: Redirect path preserved in URL
- **WHEN** unauthenticated user navigates to `/settings/account`
- **THEN** redirect URL is `/login?redirect=/settings/account`

#### Scenario: Post-login navigation
- **WHEN** user logs in successfully AND redirect parameter exists
- **THEN** system navigates to the original destination path

### Requirement: Guard integrates with AuthManager
The route guard SHALL use AuthManager via DI to determine authentication state.

#### Scenario: Guard queries AuthManager
- **WHEN** route guard checks authentication
- **THEN** guard calls `sl<AuthManager>().isLoggedIn`

#### Scenario: AuthManager state change triggers re-check
- **WHEN** AuthManager.isLoggedIn changes from false to true
- **THEN** subsequent navigation does not trigger redirect