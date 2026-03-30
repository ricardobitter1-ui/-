# Tasks: CRUD completo de Grupos Elite

## 1. Firestore rules

- [x] 1.1 Update `firestore.rules`: allow `delete` on `groups/{id}` when `isPersonal` is not true and `isGroupAdmin(groupId)` (owner already covered by admin invariant)
- [x] 1.2 Deploy rules (`firebase deploy --only firestore:rules`) and verify in console

## 2. Firebase service

- [x] 2.1 Update `deleteGroup` to allow admins (not only owner), reject `isPersonal` groups with a clear exception message
- [x] 2.2 Keep `updateGroup` aligned with rules (metadata only); no change unless edge cases found in testing

## 3. Flutter UI

- [x] 3.1 Add `EditGroupSheet` (or reuse/adapt `CreateGroupSheet` with initial `GroupModel`) for name, icon, color; wire `updateGroup` on save
- [x] 3.2 On `GroupDetailScreen`, add AppBar menu: "Editar grupo" (visible if `group.isAdmin`) → open edit sheet; refresh via existing `groupsStreamProvider`
- [x] 3.3 Add "Apagar grupo" for `isAdmin && !isPersonal` with confirmation `AlertDialog` (warning text per design D2); call `deleteGroup` then `Navigator.pop` to group list
- [ ] 3.4 Optional: long-press or overflow on `GroupsScreen` list for same actions where it improves discoverability

## 4. Roadmap / docs

- [x] 4.1 After verification, mark "CRUD visual completo de Grupos Elite" as done in `openspec/roadmap.md` and adjust Fase 3 bullet on delete-by-admin if still stale
