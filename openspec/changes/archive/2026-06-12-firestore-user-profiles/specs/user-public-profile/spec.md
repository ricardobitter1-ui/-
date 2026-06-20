## ADDED Requirements

### Requirement: Public profile document per user

The system SHALL store a Firestore document at `users/{userId}` for each user who uses the app, containing only non-sensitive fields intended for display to other signed-in users: at minimum a display name string, optionally a photo URL, and an `updatedAt` timestamp.

#### Scenario: Profile shape

- **WHEN** a client reads `users/{userId}` for a user who has created a profile
- **THEN** the document SHALL expose a display name field and SHALL NOT be used to store secrets (tokens, passwords, private notes).

### Requirement: Profile write ownership

The system SHALL allow only the authenticated user whose UID matches `userId` to create or update their own `users/{userId}` profile document. No other client SHALL be able to write another user’s profile document under these rules.

#### Scenario: Owner updates profile

- **WHEN** an authenticated user performs a write to `users/{userId}` and `request.auth.uid` equals `userId`
- **THEN** the write SHALL succeed subject to valid data types.

#### Scenario: Non-owner cannot write

- **WHEN** an authenticated user attempts to write to `users/{otherUserId}`
- **THEN** the write SHALL be denied.

### Requirement: Profile read for signed-in users

The system SHALL allow any authenticated user to read `users/{userId}` documents, limited to the agreed public display fields, so that the client can resolve member UIDs inside shared groups.

#### Scenario: Group member resolves another member

- **WHEN** user A is signed in and is a member of a group that includes user B
- **THEN** user A’s client SHALL be permitted to read B’s public profile document from Firestore under the deployed rules.

### Requirement: Current user profile upsert

The app SHALL create or update the signed-in user’s profile document when they authenticate or when they save profile information in the app, merging Firebase Auth display name (and email-derived fallback where appropriate) so that collaborators eventually see a human-readable label.

#### Scenario: Login ensures profile exists

- **WHEN** a user completes sign-in and Auth provides uid
- **THEN** the client SHALL upsert `users/{uid}` with at least display name or email-based fallback and `updatedAt`.

### Requirement: Group member list shows human-readable labels

The group detail member list SHALL show each member’s public display name (or agreed fallback) instead of raw UID as the primary label. Role subtitles (e.g. Dono, Admin) MAY remain as today.

#### Scenario: Member with profile

- **WHEN** the group member list renders a UID that has a profile with a non-empty display name
- **THEN** the primary label SHALL be that display name.

#### Scenario: Member without profile

- **WHEN** the group member list renders a UID with no profile or empty display name
- **THEN** the UI SHALL show a non-empty fallback label (e.g. shortened UID or generic “Membro”) and SHALL NOT leave the row blank.

### Requirement: Task assignee selection shows human-readable labels

Where the task form shows group members as assignee chips (or equivalent), each chip SHALL use the same display resolution as the group member list (name with fallback), not a raw UID.

#### Scenario: Assignee chip label

- **WHEN** the user opens assignee selection for a collaboration group
- **THEN** each selectable member SHALL be labeled with the resolved display name or fallback, not only the UID.

### Requirement: Group document ID not shown on default header

The default group detail header SHALL NOT display the Firestore group document ID as routine UI (e.g. no `ID: {docId}` line in the primary header area). Debug or support exposure, if needed later, SHALL be optional and non-intrusive.

#### Scenario: Standard group view

- **WHEN** a user opens a group’s detail screen in normal use
- **THEN** the prominent header area SHALL NOT include the raw group document ID as informational text.
