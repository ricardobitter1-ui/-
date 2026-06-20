# Design: Robust Notification System

## Context
Scheduled notifications are failing on Android 12+ emulators. The current implementation uses `zonedSchedule` but lacks explicit permission handling for exact alarms and detail-oriented logging.

## Goals
- Fix the notification firing issue by correctly requesting and verifying `SCHEDULE_EXACT_ALARM`.
- Improve diagnostic capabilities through structured logging.
- Ensure timezone consistency across the app.

## Proposed Changes

### 1. `NotificationService` Enhancement
- **Explicit Channel Initialization**: Move channel creation to a more explicit phase if necessary.
- **Exact Alarm Check**: Use `canScheduleExactNotifications()` (available in `flutter_local_notifications`) to verify permission before scheduling.
- **Logging**: Add logs for:
  - Permission status.
  - Calculated `TZDateTime`.
  - Result of `zonedSchedule`.

### 2. UI Updates
- **`HomeScreen`**: Update the permission sheet to handle cases where the app needs to redirect a user to system settings for "Alarms & Reminders".
- **`CreateTaskModal`**: Add a validation/error state if scheduling fails, rather than just catching the error silently.

## Risks / Trade-offs
- **User Friction**: Redirecting users to system settings for exact alarms is a bit disruptive, but necessary for functionality on modern Android.
- **Battery Impact**: Using exact alarms while idle has a minor battery impact, but is required for "exact time" reminders.
