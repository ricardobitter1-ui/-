## ADDED Requirements

### Requirement: Invite by email address in UI (Spark)

The system SHALL replace (or supersede) the “invite by UID” entry path with an input for the invitee’s **email address** for collaborative groups. The client SHALL persist a pending invite in Firestore including a normalized **`inviteeEmailLower`** field. **No server-side email delivery or server-triggered push** is required in this phase (Firebase Spark).

#### Scenario: Admin sends invite by email

- **WHEN** an admin submits a well-formed email for a user who is allowed to be invited
- **THEN** a pending invite document is created with `inviteeEmailLower` set and the inviter identity recorded

### Requirement: Invitee discovers invite in-app (Spark)

When the invitee signs in with Firebase Auth and their **verified email in the Auth token** matches `inviteeEmailLower` on a pending invite, the system SHALL surface that invite **without** transactional email or server-sent push. **Primary surface:** as soon as the authenticated shell is ready after **app launch or resume**, if there is at least one matching pending invite, the app SHALL present the **same invite decision modal** (Accept / Decline) used for deep links—not only a passive list.

#### Scenario: Modal on app open with pending email invite

- **WHEN** the user is already signed in (or has just completed sign-in) and opens or foregrounds the app, and a pending invite exists whose `inviteeEmailLower` matches their Auth email
- **THEN** the invite decision modal appears promptly with group and inviter context, and accept/decline behave like other entry points

#### Scenario: Multiple pending invites

- **WHEN** more than one pending invite matches the user’s email
- **THEN** the app SHALL present them in a defined order (e.g. oldest first) one modal at a time until resolved or deferred per product rules; remaining invites remain reachable from the in-app inbox

#### Scenario: Registered user sees pending invite after login

- **WHEN** a user logs in with an email matching a pending invite’s `inviteeEmailLower`
- **THEN** the modal flow above applies after authentication completes, and the pending-invites list remains available for re-entry

#### Scenario: Email provider without email claim

- **WHEN** the signed-in user has no email claim available to security rules
- **THEN** email-matched invites cannot be authorized by rules; the product SHALL communicate that email-based invites require an email sign-in provider (implementation detail)

### Requirement: No server-side invite notification in Spark scope

In the Spark-scoped delivery, the system SHALL **not** require transactional email or Cloud Functions–triggered FCM to satisfy the invite feature. A future Blaze extension MAY add those channels without changing the core accept/decline rules.

#### Scenario: No backend dependency for MVP

- **WHEN** the project remains on Firebase Spark
- **THEN** invite creation and discovery remain functional using Firestore + client + Auth token email matching

### Requirement: Accept flow parity

The acceptance and decline flows from the **startup modal**, **inbox**, and **deep link** SHALL use the same authorization and membership rules.

#### Scenario: Accept from inbox or startup modal

- **WHEN** the user accepts from the pending-invite list or from the modal shown on app open
- **THEN** membership updates only after explicit accept and security rules pass
