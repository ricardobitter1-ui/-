## ADDED Requirements

### Requirement: Assignee field on group tasks

The system SHALL support an `assigneeIds` field (list of UIDs) on tasks that have a non-null `groupId`.

#### Scenario: Task saved with assignees

- **WHEN** a member creates or updates a group task with `assigneeIds` listing one or more members
- **THEN** the task document persists `assigneeIds` when all assignees are members of that group

### Requirement: Assignees must be group members

The system SHALL reject `assigneeIds` containing any UID not present in the group's `members` array for that `groupId`.

#### Scenario: Non-member assignee rejected

- **WHEN** a member attempts to set `assigneeIds` including a UID outside `members`
- **THEN** the write is denied

### Requirement: Optional assignees

The system SHALL allow `assigneeIds` to be empty or absent (no responsible users) for group tasks.

#### Scenario: Task without assignees

- **WHEN** a member creates a group task with no `assigneeIds`
- **THEN** the create succeeds if other group task rules pass
