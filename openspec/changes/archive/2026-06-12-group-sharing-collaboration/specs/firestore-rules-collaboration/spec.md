## ADDED Requirements

### Requirement: Group document write restrictions

The system SHALL enforce that non-admin users cannot change group metadata fields reserved for admins (`name`, `icon`, `color`, `admins`, `members`) except through explicitly allowed invite-acceptance paths documented in `group-invites` spec.

#### Scenario: Non-member cannot update group

- **WHEN** an authenticated user who is not in `groups/{id}.members` attempts to update `groups/{id}`
- **THEN** the Firestore request is denied

#### Scenario: Member who is not admin cannot change membership

- **WHEN** a user who is in `members` but not in `admins` attempts to modify `members` or `admins`
- **THEN** the Firestore request is denied

### Requirement: Personal group isolation

The system SHALL deny invite creation and SHALL deny membership changes (other than system migration paths) for groups where `isPersonal == true`.

#### Scenario: Invite blocked for personal group

- **WHEN** any client attempts to create an invite document targeting a group with `isPersonal == true`
- **THEN** the Firestore request is denied

### Requirement: Group task read access

The system SHALL allow read access to a task with non-null `groupId` only if `request.auth.uid` is present in `groups/{groupId}.members`.

#### Scenario: Non-member cannot read group task

- **WHEN** a user not in the group's `members` list attempts to read `tasks/{taskId}` whose `groupId` references that group
- **THEN** the Firestore request is denied

### Requirement: Assignee list validity

The system SHALL deny create or update of a task that has non-empty `assigneeIds` unless every listed UID is a member of the task's `group` (when `groupId` is set).

#### Scenario: Invalid assignee rejected

- **WHEN** a user attempts to save a task with `assigneeIds` containing a UID not in the referenced group's `members`
- **THEN** the Firestore request is denied

### Requirement: FCM token documents are private

The system SHALL allow each user to read and write only their own FCM token storage path; the system SHALL deny clients from writing notification delivery records for other users.

#### Scenario: User cannot write another user's tokens

- **WHEN** user A attempts to write to user B's FCM token document path
- **THEN** the Firestore request is denied
