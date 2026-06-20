# Tasks: Fix Scheduled Notifications

## 1. Notification Service Enhancements

- [x] 1.1 Update `NotificationService.initialize` to explicitly create the notification channel.
- [x] 1.2 Implement `canScheduleExactNotifications` check in `NotificationService.scheduleTaskReminder`.
- [x] 1.3 Add detailed logging for `TZDateTime` calculation and `zonedSchedule` execution.
- [x] 1.4 Refactor `requestPermission` to better handle the redirection to "Alarms & Reminders" settings.

## 2. UI Updates

- [x] 2.1 Update `HomeScreen._showPermissionSheet` to explain the "Exact Alarm" requirement for Android 12+.
- [x] 2.2 Add "Breadcrumb" logging to `CreateTaskModal._submit` for precise debugging.
- [x] 2.3 Reorder `_submit` logic to prioritize `scheduleTaskReminder` before `addTask`.
- [x] 2.4 Implement a "Quick Test" button/icon to verify notifications in 5 seconds.
- [x] 2.5 Ensure `Navigator.pop` is called promptly or with improved error handling if Firebase hangs.

## 3. Verification

- [ ] 3.1 Verify with logs that `tz.local` matches the emulator's system time.
- [ ] 3.2 Test scheduling a notification 1 minute in the future and verify it fires.
- [ ] 3.3 Test behavior when the "Exact Alarm" permission is denied.
