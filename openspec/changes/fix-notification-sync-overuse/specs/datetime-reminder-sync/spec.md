# Specification: Datetime Reminder Sync

## ADDED Requirements

### Requirement: Single concurrent sync

The system MUST NOT run more than one datetime reminder sync operation at a time. Additional sync requests during an in-flight sync MUST be coalesced into at most one follow-up sync after the current run completes.

#### Scenario: Stream emits while sync is running

- **WHEN** the tasks stream emits a new task list while a reminder sync is already in progress
- **THEN** the system queues a single coalesced sync to run after the current sync finishes
- **AND** the system does not start a second parallel sync

### Requirement: Debounced incremental sync from stream

The system MUST debounce stream-driven reminder sync requests by at least 300 ms before executing an incremental sync.

#### Scenario: Rapid stream emissions on app open

- **WHEN** the tasks stream emits multiple times within 300 ms during initial load
- **THEN** the system performs at most one incremental sync for that burst

### Requirement: Fingerprint-based skip

The system MUST maintain an in-memory fingerprint per task for reminder-relevant fields and MUST skip `syncTaskDatetimeReminders` when the fingerprint is unchanged since the last successful sync for that task.

#### Scenario: Unrelated task update

- **WHEN** a task without datetime reminders is updated in Firestore
- **THEN** the system does not re-sync datetime reminders for tasks whose fingerprint did not change

#### Scenario: Reminder-relevant task update

- **WHEN** a datetime-reminder task's due date, completion state, recurrence, or pending-repeat configuration changes
- **THEN** the system re-syncs reminders only for that task (or includes it in the next coalesced incremental sync)

### Requirement: Stream listener registration

The main shell MUST register the tasks stream listener exactly once using `listenManual` after the first frame, following the same pattern as `PendingInviteCoordinator`.

#### Scenario: Widget rebuild

- **WHEN** the main shell widget rebuilds due to navigation or state changes
- **THEN** the system does not register additional duplicate stream listeners

### Requirement: Surgical sync on explicit mutations

When a user creates, edits, completes, or deletes a task through UI or voice pipeline, the system MUST schedule a surgical sync for the affected task via the coordinator without requiring a full-list re-sync of every datetime task.

#### Scenario: Save task from form

- **WHEN** the user saves a task with datetime reminder from the task form
- **THEN** the coordinator syncs reminders for that task only
