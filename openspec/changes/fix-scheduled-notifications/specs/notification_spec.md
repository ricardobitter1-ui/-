# Specification: Android Scheduled Notifications

## Overview
This specification defines the requirements for scheduled local notifications on Android to ensure they fire at the exact time, even on modern Android versions (12, 13, 14).

## Requirements

### Requirement: Exact Alarm Permission
The application MUST verify if the `SCHEDULE_EXACT_ALARM` permission is granted before attempting to schedule an exact notification. If not granted, the app SHOULD guide the user to the system settings page.

### Requirement: Timezone-Aware Scheduling
All scheduled dates MUST be converted to `TZDateTime` using a reliably updated local timezone location. The logic SHOULD log the timezone and offset being used for audit purposes.

### Requirement: Diagnostic Logging
The notification service MUST log the following events to help with debugging:
- Initialization result.
- Permission states (PostNotifications and ExactAlarms).
- Scheduling success/error per task ID.
- Target `TZDateTime` versus current system time.

### Requirement: User Feedback on Failure
If a notification fails to schedule (e.g., due to background permission issues), the UI MUST show a snackbar or alert informing the user that the reminder might not fire.
