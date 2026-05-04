## ADDED Requirements

### Requirement: FPS monitor service package
FPS monitoring SHALL be implemented as `performance` service package.

#### Scenario: Package structure
- **WHEN** performance package is created
- **THEN** package contains monitor/, report/, di/ directories

#### Scenario: DI registration
- **WHEN** setupDependencies runs
- **THEN** FpsMonitor registered as optional singleton

### Requirement: Frame time tracking
FpsMonitor SHALL track frame rendering times using Flutter's timing callback.

#### Scenario: Register timing callback
- **WHEN** FpsMonitor.start() is called
- **THEN** FlutterBinding.addTimingsCallback is registered

#### Scenario: Record frame time
- **WHEN** frame completes with duration
- **THEN** duration is added to frameTimes list

### Requirement: FPS drop detection
Monitor SHALL detect and report FPS drops below threshold (default 55fps).

#### Scenario: FPS drop detected
- **WHEN** frame takes > 18ms (below 55fps)
- **THEN** onFpsDrop callback is invoked with current FPS

#### Scenario: Threshold configurable
- **WHEN** FpsMonitor is created with threshold 30fps
- **THEN** drops below 30fps trigger callback

### Requirement: Performance report generation
Monitor SHALL generate summary report with average FPS, min FPS, and drop count.

#### Scenario: Generate report
- **WHEN** FpsMonitor.report() is called
- **THEN** returns FpsReport with avgFps, minFps, dropCount, duration

#### Scenario: Report logged
- **WHEN** report is generated
- **THEN** AppLogger.info logs summary

### Requirement: Monitor lifecycle management
Monitor SHALL support start/stop for controlled activation.

#### Scenario: Start monitoring
- **WHEN** FpsMonitor.start() called in launcher
- **THEN** callback registered, tracking active

#### Scenario: Stop monitoring
- **WHEN** FpsMonitor.stop() called
- **THEN** callback removed, tracking inactive

### Requirement: Debug/staging only activation
FPS monitoring SHALL only activate in debug and staging environments.

#### Scenario: Debug mode activates
- **WHEN** EnvironmentConfig.isDev or isStaging
- **THEN** FpsMonitor.start() is called

#### Scenario: Production mode disabled
- **WHEN** EnvironmentConfig.isProd
- **THEN** FpsMonitor is not started