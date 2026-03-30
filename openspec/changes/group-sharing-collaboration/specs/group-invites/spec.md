## ADDED Requirements

### Requirement: Invite acceptance before membership

The system SHALL NOT add a user to `groups/{id}.members` until an invite transitions to `accepted` by that same user (or equivalent server-validated flow).

#### Scenario: Pending invite does not grant task access

- **WHEN** a user has a `pending` invite for a group but is not in `members`
- **THEN** the user MUST NOT be able to read or write that group's tasks per security rules

### Requirement: Invite creation by admins only

The system SHALL allow creation of invite records only by users who are in `groups/{groupId}.admins` (or via trusted server functions).

#### Scenario: Non-admin cannot invite

- **WHEN** a group member who is not an admin attempts to create an invite for that group
- **THEN** the operation is denied unless performed by an authorized Cloud Function

### Requirement: Multi-channel invite compatibility

The system SHALL support attaching the same logical invite to in-app user pick, shareable link token, and email deep link without granting membership before acceptance.

#### Scenario: Link opens accept screen

- **WHEN** a recipient opens a valid invite link while authenticated as the invitee
- **THEN** the app shows accept/decline and only on accept updates membership per `Invite acceptance before membership`
