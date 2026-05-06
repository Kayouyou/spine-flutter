# Learnings - UI Lifecycle Patterns

## LifecycleMixin (RouteAware)
- Created `lifecycle_mixin.dart` with `LifecycleMixin<T extends StatefulWidget>` 
- Mixes on `State<T>` and implements `RouteAware`
- Provides 4 callbacks: `onPageEnter`, `onPageLeave`, `onPageCovered`, `onPageRevealed`
- Auto-subscribes/unsubscribes via `AppRouteObserver` singleton
- Tests pass with 2 widget tests verifying `onPageEnter` callback and observer lifecycle

## Pre-existing Issues Fixed
- `app_lifecycle_mixin.dart`: Missing `AppExitResponse` and `PredictiveBackEvent` imports (from `dart:ui` and `package:flutter/services.dart`), missing `AppLifecycleState.detached` in switch
- `full_lifecycle_mixin.dart`: Same missing imports and switch case
- Both mixins also needed default overrides for `handleStartBackGesture`, `handleUpdateBackGestureProgress`, `handleCommitBackGesture`, `handleCancelBackGesture`, and `didRequestAppExit`
- Note: `AppExitResponse` from `dart:ui` and `PredictiveBackEvent` from `package:flutter/services.dart` need explicit imports (not automatically available through `package:flutter/material.dart`)
