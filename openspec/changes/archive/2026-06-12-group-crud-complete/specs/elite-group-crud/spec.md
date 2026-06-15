## ADDED Requirements

### Requirement: Admin can edit group metadata from the UI

The system SHALL expose a dedicated flow (sheet or screen) from the group context that allows a user who is a group admin to update `name`, `icon`, and `color` for that group, persisting through the existing Firestore update path.

#### Scenario: Admin opens edit from group detail

- **WHEN** a user who is in the group's `admins` opens the group detail and chooses "Edit group" (or equivalent)
- **THEN** the user can change name, icon, and color and save successfully for non-personal and personal groups where policy allows

#### Scenario: Non-admin cannot access edit

- **WHEN** a user who is only a member (not admin) attempts to open the edit flow
- **THEN** the action is not available or is disabled

### Requirement: Owner or admin can delete a non-personal group

The system SHALL allow deletion of a group document when the group is not personal (`isPersonal` is not true) and the authenticated user is either the `ownerId` or listed in `admins`, with a mandatory confirmation step in the UI.

#### Scenario: Admin deletes collaborative group

- **WHEN** an admin confirms delete on a group with `isPersonal == false`
- **THEN** the group document is removed and the user is navigated away (e.g. back to group list)

#### Scenario: Personal group cannot be deleted via this flow

- **WHEN** the group has `isPersonal == true`
- **THEN** the delete action is not offered or the server/rules reject the operation with a clear error

#### Scenario: Confirmation before delete

- **WHEN** the user chooses to delete a group
- **THEN** the app shows a confirmation dialog warning that the group will be removed (and that associated tasks may become inaccessible to members)

### Requirement: Firestore rules allow admin delete for non-personal groups

The system SHALL enforce via Firestore Security Rules that `delete` on `groups/{groupId}` is allowed only if the group is not personal and `request.auth.uid` is a group admin (including owner per existing admin invariant).

#### Scenario: Non-admin cannot delete

- **WHEN** a member who is not in `admins` attempts to delete the group document
- **THEN** the operation is denied

#### Scenario: Personal group delete denied

- **WHEN** any user attempts to delete a group with `isPersonal == true`
- **THEN** the operation is denied
