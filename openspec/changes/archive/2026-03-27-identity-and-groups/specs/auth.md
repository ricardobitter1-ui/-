# Specification: Authentication

## Requirements

### Requirement: Firebase Auth Support
The system must use Firebase Authentication to manage user identity.

### Requirement: Multi-Provider Login
The `LoginScreen` must support:
- Email/Password authentication.
- Google Sign-In.

### Requirement: Auth Wrapper
The application root must observe the authentication state and direct the user to the appropriate screen.

## Scenarios

### Scenario: Unauthenticated User
- **WHEN** the `authStateProvider` emits a null user.
- **THEN** navigation is forced to the `LoginScreen`.

### Scenario: Successful Login
- **WHEN** the user provides valid credentials or completes Google Sign-In.
- **THEN** the auth state updates and the `AuthWrapper` shifts to the `HomeScreen`.
