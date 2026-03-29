# Proposal: Elite Groups & Collaborative Backend (Phase 2)

## Why

As part of the **Exm To-Do Visual Excellence Edition** roadmap, the application needs to evolve from a simple personal task list to a multi-context, collaborative ecosystem. Phase 2 focuses on "Elite Groups," which are the foundation for organized, themed, and shared productivity.

Currently, the backend only supports a flat structure of tasks owned by a single user. To achieve the premium vision, we need:
1. **Contextual Organization**: Moving away from a "one big list" approach to specific groups (Work, Personal, Fitness, etc.).
2. **"Deadlines" vs "Atemporals"**: Distinguishing between tasks that must happen at a specific time (Daily Timeline) and those that are just in the backlog (Inbox/Atemporal Dashboard).
3. **Collaboration Readiness**: Structuring the database to support multiple users in a single group (even if UI for invitations comes later).

## Goals

- **Establish Group Schema**: Implement a robust Firestore structure for `groups` including metadata like visual identity (colors, icons).
- **Refactor Task Relations**: Ensure every task can optionally belong to a group, enabling the "Dashboard" view to filter by context.
- **Support Atemporal Tasks**: Optimize the backend logic to handle tasks without `dueDate`, treating them as "Inbox" items for the new Dashboard.
- **Service Scalability**: Update `FirebaseService` to handle complex queries (e.g., "tasks for this group" or "scheduled tasks for today across all groups").

## Impact

- **`lib/data/models/group_model.dart` [NEW]**: Model for Elite Groups.
- **`lib/data/models/task_model.dart` [MODIFY]**: Enhancing for group association and null-safety for dates.
- **`lib/data/services/firebase_service.dart` [MODIFY]**: Adding CRUD for Groups and specialized streams for Dashboard/Calendar.
- **`lib/data/services/auth_service.dart` [READ ONLY]**: Reference for user session context.

## Success Criteria

- Successfully creating and retrieving Groups from Firestore.
- Tasks correctly associated with Groups.
- Ability to stream tasks filtered by "Atemporal" status for the Dashboard.
- Zero regression on existing single-user task functionality.
