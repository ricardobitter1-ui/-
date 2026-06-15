## ADDED Requirements

### Requirement: New-task notification to assignees

The system SHALL notify each user listed in `assigneeIds` when a group task is created (or when `assigneeIds` gains their UID), using server-triggered push (FCM), not client-written cross-user notification documents.

#### Scenario: Assignee receives push for new assignment

- **WHEN** a new task is created with `assigneeIds` containing user B
- **THEN** user B receives a push notification on a registered device if they have a valid FCM token stored

### Requirement: Due reminder notification to assignees

The system SHALL send reminder notifications for configured date/time reminders to each listed assignee (or to the policy-defined set of recipients), using server-side scheduling or event-driven dispatch aligned with task `dueDate` and reminder settings.

#### Scenario: Reminder fires for assignee

- **WHEN** a task has a datetime reminder and a future `dueDate` (or explicit reminder time per product rules)
- **THEN** each assignee with a valid token receives the reminder at the appropriate time

### Requirement: No client-side spoofing of peer pushes

The system SHALL NOT allow an authenticated client to directly enqueue or send push notifications to another user's devices except through validated server workflows tied to task or invite events.

#### Scenario: Client cannot write foreign notification queue

- **WHEN** user A attempts to create a notification record addressed to user B outside allowed schema and rules
- **THEN** the request is denied
