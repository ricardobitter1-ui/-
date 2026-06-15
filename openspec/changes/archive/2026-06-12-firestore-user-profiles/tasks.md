## 1. Firestore security rules

- [x] 1.1 Add `match /users/{userId}` allowing read for `signedIn()`, write only when `request.auth.uid == userId`, with field validation appropriate for public profile (displayName string, optional photoUrl, updatedAt).
- [x] 1.2 Confirm existing `users/{userId}/fcmTokens/{tokenId}` rules still apply and do not conflict with the parent user document rule.

## 2. Data layer

- [x] 2.1 Add a `UserPublicProfile` (or equivalent) model and Firestore serialization for `users/{uid}`.
- [x] 2.2 Implement `upsertCurrentUserProfile` in `FirebaseService` (merge from Auth: displayName, email fallback, optional photoURL).
- [x] 2.3 Implement `getUserPublicProfile(uid)` and/or `getUserPublicProfiles(Set<String> uids)` using parallel/batch reads.

## 3. Lifecycle and profile screen

- [x] 3.1 Call `upsertCurrentUserProfile` after successful sign-in / auth state with user (per design: decide empty-vs-always merge).
- [x] 3.2 When the user saves profile in `profile_screen`, update Firestore profile and keep Auth in sync if the product uses `updateDisplayName` / photo.

## 4. State / providers

- [x] 4.1 Add a Riverpod provider (or family) that resolves `Map<String, String>` or `Map<String, UserPublicProfile>` for a set of member UIDs, with in-memory caching for the session.

## 5. UI: groups and tasks

- [x] 5.1 Update `GroupDetailScreen`: remove default header line showing `ID: ${g.id}`; wire member `ListTile` titles to resolved display names with fallback.
- [x] 5.2 Update `TaskFormModal` assignee chips to use the same resolution helper instead of `_assigneeShortLabel(uid)` on raw UID.

## 6. Verification

- [ ] 6.1 Manual pass: two accounts in one group — each sees the other’s display name in members and assignees; fallback when profile missing.
- [x] 6.2 Confirm rules deny writing another user’s profile and allow FCM token registration unchanged.
