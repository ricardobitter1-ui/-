# Implementation Tasks: Elite Groups & Collaborative Backend

- [ ] **Infrastructure & Models**
    - [ ] Create `lib/data/models/group_model.dart` with `GroupModel` class.
    - [ ] Update `lib/data/models/task_model.dart` to handle null `dueDate` correctly and ensure `groupId` is fully integrated.
    - [ ] Create `lib/data/models/group_model.dart` unit tests (scratch script).

- [ ] **Firebase Service Expansion**
    - [ ] Add `groups` collection reference to `FirebaseService`.
    - [ ] Implement `getGroupsStream()` (Filtered by user membership).
    - [ ] Implement `addGroup(GroupModel group)` with `ownerId` and `members` (initial owner) population.
    - [ ] Implement `updateGroup(GroupModel group)` and `deleteGroup(String groupId)`.
    - [ ] Add specialized task streams:
        - [ ] `getTasksByGroupStream(String groupId)`
        - [ ] `getAtemporalTasksStream()` (Where `dueDate == null`).

- [ ] **Integration & Refinement**
    - [ ] Update `addTask(TaskModel task)` to allow optional `groupId`.
    - [ ] Verify that existing tasks without `groupId` or `dueDate` appear correctly in new streams.
    - [ ] **Self-Review**: Ensure Firestore composite index requirements are documented for the user.

- [ ] **Verification**
    - [ ] Run CRUD test script for Groups.
    - [ ] Verify real-time streaming for groups and tasks.
