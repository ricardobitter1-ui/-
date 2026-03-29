# Tasks: Identity and Groups Infrastructure

## 1. Data Models & Foundation

- [x] 1.1 Create `GroupModel` in `lib/data/models/group_model.dart` with `id`, `name`, `ownerId`.
- [x] 1.2 Update `TaskModel` in `lib/data/models/task_model.dart` to include `ownerId` and `groupId`.
- [x] 1.3 Add `firebase_auth` and `google_sign_in` dependencies if missing.

## 2. Authentication Service

- [x] 2.1 Implement `AuthService` in `lib/data/services/auth_service.dart` (Email/Pass & Google).
- [x] 2.2 Create `authStateProvider` (StreamProvider) for reactive auth state.
- [x] 2.3 Implement `ensureDefaultGroup` logic to create "Pessoal" group for new users.

## 3. UI Implementation

- [x] 3.1 Create `LoginScreen` in `lib/ui/screens/login_screen.dart` with premium design/animations.
- [x] 3.2 Implement `AuthWrapper` in `lib/ui/widgets/auth_wrapper.dart` (or `main.dart`).
- [x] 3.3 Refactor `main.dart` to initialize the app with `AuthWrapper`.
- [x] 3.4 Update `HomeScreen` to display user-specific data and handle null user cases.

## 4. Service and Logic Refactoring

- [x] 4.1 Update `FirestoreService` (or equivalent) to accept `User` or `uid` for scoped operations.
- [x] 4.2 update task addition logic to automatically inherit `ownerId` or `groupId`.
- [x] 4.3 Verify that `HomeScreen` only loads after successful authentication.
