## ADDED Requirements

### Requirement: Domain models have unit tests
Each domain model class SHALL have a corresponding test file covering fromJson/toJson, boundary values, and equality.

#### Scenario: User model serialization
- **WHEN** test runs `User.fromJson(json)` and `user.toJson()`
- **THEN** round-trip produces identical data

#### Scenario: User model boundary values
- **WHEN** test constructs User with empty name or null fields
- **THEN** model handles gracefully without throwing

### Requirement: Domain exceptions have exhaustive tests
Each DomainException subclass SHALL have tests covering construction, message, and pattern matching.

#### Scenario: NetworkException construction
- **WHEN** test creates `NetworkException('message', statusCode: 500)`
- **THEN** exception.message equals 'message' AND statusCode equals 500

#### Scenario: Sealed class exhaustive matching
- **WHEN** test uses switch expression on DomainException
- **THEN** all subclasses are covered (no default case needed)

### Requirement: UseCases have mock-based tests
Each UseCase SHALL have tests using mocktail to verify Repository interaction.

#### Scenario: GetUserUseCase calls repository
- **WHEN** test executes `usecase.execute()`
- **THEN** mock UserRepository.getCurrentUser is called once

#### Scenario: UseCase propagates exception
- **WHEN** mock repository throws `UnauthorizedException`
- **THEN** usecase.execute throws same exception

### Requirement: Domain test coverage target
Domain layer test coverage SHALL reach 100% for models, exceptions, and usecases.

#### Scenario: Coverage measurement
- **WHEN** `flutter test --coverage` runs on test/unit/domain/
- **THEN** lcov.info shows domain/ coverage >= 100%