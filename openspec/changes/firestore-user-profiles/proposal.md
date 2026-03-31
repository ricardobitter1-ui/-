## Why

Group screens and assignee chips currently show raw Firebase UIDs (and the group detail screen even surfaces the group document ID), which clutters the UI and is unusable for humans. The app already has display name and email for the signed-in user via Firebase Auth, but there is no shared, readable profile for other group members. Storing a small public profile document per user in Firestore is the canonical way to resolve UID → display label for collaborators.

## What Changes

- Add a Firestore document pattern `users/{uid}` (or equivalent top-level path) holding **public** display fields (e.g. display name, optional photo URL) suitable for showing in group member lists and task assignee chips.
- Extend security rules so authenticated users can **read** profiles of users who share at least one group with them (or a slightly broader rule if product requires it), and **write** only their own document.
- Client: ensure the current user’s profile is created/updated when they sign in or edit profile (align with Auth `displayName` / email where appropriate).
- Client: group detail screen, groups flows, and task form assignee UI resolve member UIDs through these documents, with a clear fallback when a profile is missing (e.g. shortened UID or “Membro”).
- Remove or relocate **debug-style** exposure of the group document ID on the main group header (product decision: hide from default UI; optional copy-for-support elsewhere if needed).

## Capabilities

### New Capabilities

- `user-public-profile`: Firestore shape, security rules, client read/write lifecycle, and consumption anywhere the app needs a human-readable label for another user (starting with group members and assignees).

### Modified Capabilities

- _(None.)_ Existing `openspec/specs/app_navigation.md` does not define requirements for profile data or group member labels; no delta spec required for navigation behavior.

## Impact

- **Firestore**: new top-level collection (or agreed path), new indexes only if queries require them (profile-by-uid is typically direct `doc` reads).
- **Security rules**: `firestore.rules` — new `match` for user profile documents; must not weaken task/group rules.
- **Flutter**: `firebase_service` (or dedicated service), `GroupModel` unchanged for membership arrays; new model/provider for profile resolution; `group_detail_screen`, `task_form_modal`, possibly `profile_screen` for writes.
- **Migration**: existing users get a profile doc on next app open or profile save; no forced backfill beyond lazy creation.
