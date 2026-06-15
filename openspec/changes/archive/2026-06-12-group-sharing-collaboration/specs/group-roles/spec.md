## ADDED Requirements

### Requirement: Admin-only group settings and roster management

The system SHALL restrict editing of group display fields (`name`, `icon`, `color`) and changes to `members` and `admins` to users in `admins` (plus any owner-only operations defined by policy).

#### Scenario: Admin renames group

- **WHEN** an admin updates `name` on `groups/{id}`
- **THEN** the update is allowed if all other field changes comply with security rules

#### Scenario: Non-admin cannot remove member

- **WHEN** a member who is not in `admins` attempts to remove another member from `groups/{id}.members`
- **THEN** the operation is denied

### Requirement: All members may create group tasks

The system SHALL allow any user in `groups/{id}.members` to create tasks with `groupId == id` subject to assignee and field validation rules.

#### Scenario: Member creates task

- **WHEN** a member creates a task with valid `groupId` and `createdBy` equal to their UID
- **THEN** the create operation is allowed

### Requirement: Admin membership invariant

The system SHALL maintain `admins` as a subset of `members` and SHALL include `ownerId` in `admins` after group creation.

#### Scenario: Cannot set admin who is not a member

- **WHEN** an update would place a UID in `admins` that is not in `members`
- **THEN** the Firestore request is denied
