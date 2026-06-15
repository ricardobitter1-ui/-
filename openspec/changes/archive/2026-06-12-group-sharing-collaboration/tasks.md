# Tasks: Group sharing, roles, assignees, security

## 1. Data model and migration

- [x] 1.1 Extend `GroupModel` with `admins`, `isPersonal` (defaults: `admins == [ownerId]` when absent in Firestore)
- [x] 1.2 Add invite model and Firestore paths (`groupInvites` or agreed structure from design)
- [x] 1.3 Extend `TaskModel` with `assigneeIds` and `createdBy` for group tasks
- [x] 1.4 Lazy or scripted backfill: mark personal default group `isPersonal: true`; set `admins` on legacy groups

## 2. Firestore rules and tests

- [x] 2.1 Implement `firestore.rules` for groups, invites, tasks, and FCM token paths per specs
- [x] 2.2 Add Firebase emulator rule tests covering member vs non-member, admin vs member, assignee validation, personal group (`firestore-tests/`; execução requer Firebase CLI + JDK 21+)
- [x] 2.3 Deploy rules to staging before enabling invite UI in production builds (instruções em `firebase/README.md`; executar `firebase deploy --only firestore:rules,firestore:indexes` no projeto)

## 3. Backend (Cloud Functions) — if using Functions-first membership

- [ ] 3.1 Implement callable `inviteUser`, `acceptInvite`, `declineInvite`, `removeMember` (and admin promotion if in scope) with validation
- [ ] 3.2 Rate limiting / basic abuse guards for invite callables
- [ ] 3.3 Wire task onWrite (or dedicated triggers) for assignee push on create/update

_Notas: fluxo atual usa apenas Firestore Rules + cliente. Ver `functions/README.md` para extensão opcional._

## 4. FCM and client

- [x] 4.1 Add `firebase_messaging`, store registration token under user-private path per rules
- [x] 4.2 Initialize FCM on login; handle token refresh
- [ ] 4.3 Optional: enable App Check for Firestore and Functions

## 5. Flutter UI and services

- [x] 5.1 Group admin UI: manage members, invites, roles (within product scope)
- [ ] 5.2 Invite flows: search, share link, email handoff to deep link _(MVP: convite por UID + copiar ID do grupo; pesquisa de utilizadores, deep links e email por implementar)_
- [x] 5.3 Inbox for pending invites and accept/decline actions
- [x] 5.4 Task form: assignee multi-select limited to group members; persist `assigneeIds`

## 6. Notifications alignment

- [x] 6.1 Define behavior when creator also schedules local reminder vs assignee-only push (avoid duplicate UX where possible) _(ver `firebase/README.md`)_
- [ ] 6.2 Server-side scheduled reminder dispatch for assignees (Scheduler or batch job) per design
