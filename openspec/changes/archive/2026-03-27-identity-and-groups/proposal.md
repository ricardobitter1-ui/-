# Proposal: Identity and Groups Infrastructure

## Why

To support a shared task app, we need to transition from a local-only/anonymous model to a user-centric model. Implementing Firebase Auth and a group-based data architecture allows users to:
1. Securely access their data across devices.
2. Organize tasks into groups (e.g., "Personal", "Work").
3. Prepare the foundation for future sharing features where tasks are scoped to specific groups with multiple members.

## Goals

- `auth-implementation`: Implement Firebase Auth with a streamlined LoginScreen and `AuthService`.
- `auth-wrapper`: Refactor `main.dart` to use an `AuthWrapper` that directs unauthenticated users to Login and authenticated users to Home.
- `group-architecture`: Implement a `GroupModel` where every task is linked to an `ownerId` and optionally a `groupId`.
- `auto-group-creation`: Automatically create a default "Pessoal" group for new users upon their first login.
- `service-injection`: Ensure Firebase services (Firestore) are initialized with the authenticated `User` context.

## Impact

- `lib/main.dart`: Refactored to handle authentication state.
- `lib/data/models/task_model.dart`: Updated to include `ownerId` and `groupId`.
- `lib/data/models/group_model.dart`: New model for representing task groups.
- `lib/data/services/auth_service.dart`: New service for authentication.
- `lib/ui/screens/login_screen.dart`: New screen for user authentication.
- `lib/ui/screens/home_screen.dart`: Modified to require an authenticated user and handle group-level filtering.
