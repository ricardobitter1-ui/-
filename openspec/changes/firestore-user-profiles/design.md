## Context

The Flutter app uses Firestore `groups` documents with `members` and `admins` as UID arrays. The UI shows truncated UIDs in `GroupDetailScreen` and `TaskFormModal` assignee chips. Firebase Auth supplies `displayName` / `email` only for the current session user. There is no `users/{uid}` profile document in rules today beyond `users/{userId}/fcmTokens/...`.

## Goals / Non-Goals

**Goals:**

- Introduce a **public profile document** per user keyed by UID, with fields safe to show to collaborators (display label, optional avatar URL).
- **Security rules** that allow users to **write only their own** profile and **read** profiles in a way that supports the group UI without opening unrelated data.
- **Client lifecycle**: create or refresh the current user’s profile from Auth (and from in-app profile edits if present).
- **Resolve UIDs to labels** in group member lists and assignee selection, with a deterministic fallback when data is missing.
- **Reduce clutter** by not showing the raw Firestore group document ID on the default group header.

**Non-Goals:**

- Denormalized member name maps on `groups` documents (scenario B from exploration).
- Rich social profiles, status, or presence.
- Server-side Cloud Functions for profile sync in this change (optional later).
- Changing the fundamental `members` / `admins` array model on groups.

## Decisions

1. **Document path: `users/{userId}` (profile fields at document root or a dedicated map)**  
   - **Rationale:** Matches Firebase conventions and keeps FCM token subcollection under the same user root already referenced in rules.  
   - **Alternative:** Top-level `publicProfiles/{uid}` — fewer collisions with non-profile user data; rejected for now to avoid a second user-root pattern.

2. **Fields (initial):** at minimum `displayName` (string), optional `photoUrl` (string), `updatedAt` (timestamp). Empty `displayName` falls back in the client to email local-part or a generic label.  
   - **Rationale:** Enough for group UI; aligns with existing `profile_screen` usage of Auth.

3. **Who can read profiles:** any **signed-in** user may **read** any `users/{userId}` **profile field set** (document), but the document MUST NOT contain secrets.  
   - **Rationale:** Firestore security rules cannot efficiently express “UID A shares a group with UID B” without custom claims, duplicate indexes, or Cloud Functions. Co-member-only read is a follow-up if privacy requirements tighten.  
   - **Alternative:** Public read for everyone — rejected; authenticated-only is a smaller blast radius.

4. **Who can write:** only `request.auth.uid == userId` for the profile document (merge/set).  
   - **Rationale:** Standard ownership model.

5. **FcmTokens subcollection:** keep existing `match /users/{userId}/fcmTokens/{tokenId}` behavior; ensure new `match /users/{userId}` for profile does not block token writes (order and conditions must be consistent).

6. **Client resolution strategy:** batch or parallel `get()` for distinct UIDs when rendering a group; cache results in memory for the session (e.g. Riverpod provider or simple map) to avoid repeated reads.  
   - **Rationale:** Group sizes are small; N document reads per group open is acceptable for v1.

7. **Group ID visibility:** remove the visible `ID: …` line from the default header; if support/debug is needed later, hide behind a long-press or admin-only action.  
   - **Rationale:** Product feedback from exploration.

## Risks / Trade-offs

- **[Privacy] Any signed-in user can read any profile doc** → Mitigation: store only non-sensitive fields; document in spec; revisit co-member rules if requirements change.  
- **[Stale names] Display name in Firestore lags Auth** → Mitigation: update profile on sign-in and when user saves profile.  
- **[Missing doc] New or invited user has no profile yet** → Mitigation: client fallback string; optional lazy `set` when they first open the app.  
- **[Rules regression]** → Mitigation: run through existing group/task invite flows after rules change.

## Migration Plan

1. Deploy Firestore rules adding profile read/write as designed.  
2. Ship client that upserts current user profile on login.  
3. Ship UI that resolves members via profile reads (fallback if missing).  
4. No bulk backfill required; profiles appear as users run the new app.

**Rollback:** revert client to UID labels; tighten or remove profile rules if needed (avoid leaving writable docs without consumer).

## Open Questions

- Whether to sync `displayName` from Google/Apple sign-in automatically on every login or only when empty.  
- Whether profile edits in-app should call `FirebaseAuth.instance.currentUser?.updateDisplayName` in addition to Firestore.
