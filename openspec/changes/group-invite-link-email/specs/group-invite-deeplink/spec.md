## ADDED Requirements

### Requirement: Shareable invite link

The system SHALL allow a group admin to copy or share a single URL that encodes a pending group invite using an unguessable **share token**, without exposing raw Firestore document IDs or Firebase Auth UIDs in the shared string.

#### Scenario: Admin copies invite link

- **WHEN** an admin chooses “Copy invite link” (or equivalent) on a collaborative group
- **THEN** a URL (e.g. custom scheme with token query parameter) is placed on the clipboard so a recipient can open the installed app

### Requirement: Deep link opens invite modal

The system SHALL handle the invite URL when the app launches or resumes: if the user is signed in, the app SHALL present a modal (or full-screen sheet) showing the group name, inviter display identifier, and **Accept** / **Decline** actions wired to the same acceptance logic as the profile inbox.

#### Scenario: Authenticated user opens valid pending invite link

- **WHEN** a signed-in user opens a valid pending invite link and is eligible under security rules to view that invite
- **THEN** the modal appears with group and inviter context and actions succeed or fail with clear errors

#### Scenario: Unauthenticated user opens invite link

- **WHEN** the user is not signed in
- **THEN** the app SHALL prompt sign-in or account creation and, after success, continue to the invite flow

### Requirement: Invite token security baseline

The system SHALL use an unguessable token in the URL; optional expiry MAY be documented in implementation. **Spark scope:** validation is performed with Firestore rules and client queries consistent with the invite model (no server-only validation required).

#### Scenario: Invalid or expired token

- **WHEN** the token does not match a pending invite or the invite is no longer pending
- **THEN** the user sees an error state and cannot join the group through that link
