# Tasks: Group sharing, roles, assignees, security

## 1. Data model and migration

- [ ] 1.1 Extend `GroupModel` with `admins`, `isPersonal` (defaults: `admins == [ownerId]` when absent in Firestore)
- [ ] 1.2 Add invite model and Firestore paths (`groupInvites` or agreed structure from design)
- [ ] 1.3 Extend `TaskModel` with `assigneeIds` and `createdBy` for group tasks
- [ ] 1.4 Lazy or scripted backfill: mark personal default group `isPersonal: true`; set `admins` on legacy groups

## 2. Firestore rules and tests

- [ ] 2.1 Implement `firestore.rules` for groups, invites, tasks, and FCM token paths per specs
- [ ] 2.2 Add Firebase emulator rule tests covering member vs non-member, admin vs member, assignee validation, personal group
- [ ] 2.3 Deploy rules to staging before enabling invite UI in production builds

## 3. Backend (Cloud Functions) — if using Functions-first membership

- [ ] 3.1 Implement callable `inviteUser`, `acceptInvite`, `declineInvite`, `removeMember` (and admin promotion if in scope) with validation
- [ ] 3.2 Rate limiting / basic abuse guards for invite callables
- [ ] 3.3 Wire task onWrite (or dedicated triggers) for assignee push on create/update

## 4. FCM and client

- [ ] 4.1 Add `firebase_messaging`, store registration token under user-private path per rules
- [ ] 4.2 Initialize FCM on login; handle token refresh
- [ ] 4.3 Optional: enable App Check for Firestore and Functions

## 5. Flutter UI and services

- [ ] 5.1 Group admin UI: manage members, invites, roles (within product scope)
- [ ] 5.2 Invite flows: search, share link, email handoff to deep link
- [ ] 5.3 Inbox for pending invites and accept/decline actions
- [ ] 5.4 Task form: assignee multi-select limited to group members; persist `assigneeIds`

## 6. Notifications alignment

- [ ] 6.1 Define behavior when creator also schedules local reminder vs assignee-only push (avoid duplicate UX where possible)
- [ ] 6.2 Server-side scheduled reminder dispatch for assignees (Scheduler or batch job) per design
