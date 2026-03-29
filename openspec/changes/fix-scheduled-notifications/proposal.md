# Proposal: Fix Scheduled Notifications on Android

## Why

Scheduled notifications are currently not appearing on the Android emulator. This is a critical issue for a To-Do list app that relies on reminders. The primary suspects are:
1. **Missing Exact Alarm Permission**: Android 12+ requires the `SCHEDULE_EXACT_ALARM` permission to be explicitly granted for exact alarms.
2. **Timezone Inconsistency**: Potential mismatch between system time and the `tz.local` used for scheduling.
3. **Silent Failures**: The current implementation lacks enough logging to diagnose failure points in the `zonedSchedule` process.

## Goals

- Ensure notifications fire reliably on Android 12, 13, and 14.
- Implement a robust permission check and request flow for exact alarms.
- Add comprehensive logging to the notification scheduling process.
- Verify and fix any timezone-related scheduling offsets.

## Impact

- **`lib/data/services/notification_service.dart`**: Major updates to initialization and scheduling logic.
- **`lib/ui/screens/home_screen.dart`**: Update permission checking flow to handle exact alarms.
- **`lib/ui/widgets/create_task_modal.dart`**: Improve user feedback if scheduling fails.
