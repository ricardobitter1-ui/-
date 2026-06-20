# Design: Elite Groups & Collaborative Backend

## Context

The current system manages tasks in a flat structure tied to a user's `ownerId`. To support Phase 2 of the roadmap, we need to introduce **Contexts** (Groups) and **Temporal Organization** (Atemporal vs Scheduled).

## Goals / Non-Goals

**Goals:**
- Implement a `groups` collection in Firestore.
- Enable tasks to be categorized into these groups.
- Support "Atemporal" tasks (no due date) for the Dashboard Inbox.
- Infrastructure readiness for group membership (List of UIDs).

**Non-Goals:**
- UI for Groups/Dashboard (Frontend responsibility).
- Advanced group management (Roles, Permissions beyond basic membership).
- Real-time chat (Out of scope for Phase 2).

## Decisions

### 1. Group Membership Model
- **Decision**: Use an array `members` (List of strings) in the Group document.
- **Rationale**: This allows easy querying using `array-contains` for "Groups I'm in". While it has a limit of 10 items for `array-contains-any` in some queries, for Phase 2 "Elite Groups" (typically small sets of people), this is highly efficient.

### 2. Atemporal Task Identification
- **Decision**: Tasks with `dueDate: null` are considered "Atemporal".
- **Rationale**: Simple indexable query. The Frontend can then differentiate between "Must do today" and "Someday/Maybe" without complex flag logic.

### 3. Service Decomposition
- **Decision**: Extend `FirebaseService` with specific streams for the Dashboard.
- **Rationale**: Instead of one monolithic `getTasksStream()`, we'll provide `getGroupsStream()`, `getTasksByGroupStream(groupId)`, and `getAtemporalTasksStream()`. This reduces data transfer and simplifies UI logic.

## Risks / Trade-offs

- **[Risk] Query Complexity** → Firestore doesn't allow multiple `array-contains` or complex joins easily.
- **[Mitigation]** → We will keep Queries focused on either "My Tasks" or "Specific Group's Tasks".
- **[Risk] Indexing Costs** → New queries on `dueDate` and `groupId` will require composite indexes.
- **[Mitigation]** → I'll provide instructions in the `walkthrough` for the user to click the Firestore-generated links to create necessary indexes.

## Migration Plan

1. Create `GroupModel`.
2. Update `TaskModel` to handle null dates safely.
3. Update `FirebaseService` logic.
4. Existing tasks will naturally appear as "Atemporal" if they lack a date, or "Personal" if they lack a `groupId`.

## Open Questions

- **Shared Tasks Visibility**: If a task is in a group, should it still match the user's `ownerId`? (Decision: Yes, for Phase 2, the creator is the owner, but group members can see it).
