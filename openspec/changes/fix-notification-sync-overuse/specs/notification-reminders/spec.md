# Specification: Notification Reminders (efficiency delta)

## ADDED Requirements

### Requirement: Pending repeat interval preserved

The system MUST continue to honor the user-configured pending reminder repeat interval from Profile settings (including 1 hour) for datetime tasks that are not completed, without removing or altering the available interval options.

#### Scenario: Hourly pending repeat on single task

- **WHEN** the user has pending repeat set to 1 hour and a datetime task is overdue and not completed
- **THEN** the system continues to surface reminder notifications approximately every hour until the task is completed or the reminder is cancelled

#### Scenario: User changes repeat interval in Profile

- **WHEN** the user changes the pending repeat interval in Profile settings
- **THEN** the system re-syncs datetime reminders for all eligible tasks using the new interval

### Requirement: Efficient Android repeating alarm for pending repeat

On Android, when pending repeat is enabled, the system MUST use a single native repeating local notification alarm per scheduled occurrence (via `repeatIntervalMilliseconds`) instead of materializing every future repeat instant as a separate discrete `zonedSchedule` call until the next recurrence boundary.

#### Scenario: Recurring weekly task with hourly pending repeat

- **WHEN** a recurring datetime task has pending repeat enabled at 1 hour and the next calendar occurrence is days away
- **THEN** the system schedules one repeating alarm for the active occurrence on Android
- **AND** the system does not schedule hundreds or thousands of discrete hourly alarms for that occurrence window

### Requirement: Notification slot budget

The system MUST NOT schedule more than 48 notification slots per task ID across all future recurrence occurrences in a single sync pass.

#### Scenario: Many future recurrence occurrences

- **WHEN** a recurring task would require more than 48 future occurrence reminders
- **THEN** the system schedules at most the nearest 48 eligible occurrences and stops

### Requirement: Cached exact-alarm permission check

The system MUST cache the exact-alarm permission result for the duration of a single task reminder sync pass and MUST NOT invoke the platform permission check on every individual schedule call within that pass.

#### Scenario: Sync task with multiple occurrence slots

- **WHEN** the system syncs one task that schedules multiple occurrence slots
- **THEN** the exact-alarm permission is checked at most once per sync pass for that batch of schedule operations

### Requirement: Debug logging scope

Diagnostic notification logs MUST only be emitted in debug builds (`kDebugMode`). Per-alarm success logs in hot scheduling paths MUST NOT run in release builds. A single summary log per task sync MAY be emitted in debug builds.

#### Scenario: Release build idle app

- **WHEN** the app runs a reminder sync in release mode with the device idle
- **THEN** the system does not print per-alarm `DEBUG NOTIF` lines to the console

## MODIFIED Requirements

### Requirement: Diagnostic Logging

The notification service MUST log initialization and permission state in debug builds. During reminder sync, the service MUST log a per-task summary (task id, slots scheduled, duration) rather than one success line per individual alarm in tight loops.

#### Scenario: Debug sync of recurring task

- **WHEN** a debug build syncs a recurring task with pending repeat enabled
- **THEN** the console shows a summary for that task sync
- **AND** the console does not emit thousands of per-alarm success lines for one sync pass
