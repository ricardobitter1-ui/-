# Specification: Groups and Tasks Ownership

## Requirements

### Requirement: Group Representation
Every task group must be represented by a `GroupModel` in Firestore.

### Requirement: Task Ownership
Every `TaskModel` must include an `ownerId` and a `groupId`.

### Requirement: Default Group Creation
The first login of a user must trigger the creation of a group named "Pessoal".

## Scenarios

### Scenario: Creating a New Task
- **WHEN** the user creates a task.
- **THEN** it must be saved with the `ownerId` of the current user.
- **AND** it must be assigned a `groupId` (defaulting to "Pessoal" if unspecified).

### Scenario: First-time Login
- **WHEN** the user logs in for the first time.
- **THEN** the `AuthService` checks for any groups owned by the user.
- **AND** if none exist, initializes the "Pessoal" group in the `groups` collection.
