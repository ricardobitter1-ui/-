## Context

The application currently operates without explicit user identity. Tasks are stored without ownership, which prevents multi-device sync and group-based collaboration. To move towards a shared task model, we need to introduce a robust identity layer and a hierarchical data structure (Groups -> Tasks).

## Goals / Non-Goals

**Goals:**
- **Firebase Auth Integration**: Setup `AuthService` and `authStateProvider` (Riverpod) to manage user sessions.
- **Premium Login UI**: Create a `LoginScreen` supporting Email/Password and Google Login with a high-end design.
- **Auth Guarding**: Implementation of an `AuthWrapper` to protect the `HomeScreen`.
- **Group Infrastructure**: Implementation of `GroupModel` and updating `TaskModel` to include `ownerId` and `groupId`.
- **Smart Onboarding**: Automatically create a "Pessoal" group for every new user.
- **Service Scoping**: Ensure Firestore-based services receive the `User` object for scoped queries.

**Non-Goals:**
- Implementing advanced group sharing permissions (e.g., admin vs. member) in this phase.
- Deep migration of legacy "anonymous" tasks to the new user-bound structure (unless explicitly requested later).

## Design Decisions

- **Authentication State**: We will use a `StreamProvider` for `FirebaseAuth.instance.authStateChanges()` to provide a reactive user object across the app.
- **Auth Service**: A dedicated `AuthService` class will encapsulate all Firebase Auth interactions (Login, Logout, Group initialization).
- **Group Architecture**:
    - A `groups` collection in Firestore will store documents with fields: `name`, `ownerId`, `isDefault`, and `createdAt`.
    - Every `Task` will now have an `ownerId` (always set to the creator) and an optional `groupId`.
- **Initialization Logic**: The `AuthService` will perform a "Welcome check" during the first successful login to ensure the "Pessoal" group exists in Firestore for that specifically authenticated `uid`.
- **UI Flow**: The `main.dart` will be refactored to use a `ConsumerWidget` that monitors the `authStateProvider`. If `data` is null, show `LoginScreen`; if `data` is a `User`, show `HomeScreen`.

## Risks / Trade-offs

- **First-time Login Latency**: Creating the default group involves a Firestore write immediately after login. We should ensure this doesn't block the UI unnecessarily or provide clear feedback.
- **Data Integrity**: If a task is created without a `groupId`, it should default to the "Pessoal" group's ID to maintain the hierarchy.
