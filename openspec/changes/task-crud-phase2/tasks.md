# Tasks: Task CRUD Core (Phase 2)

- `[x]` **Phase 1: Model & Service (Backend)**
  - `[x]` Verify `TaskModel` supports all CRUD fields
  - `[x]` Add/Refine `updateTask` and `deleteTask` in `FirebaseService`
  - `[x]` Ensure error handling is descriptive

- `[x]` **Phase 2: UI Foundation (Forms)**
  - `[x]` Refactor `CreateTaskModal` to `TaskFormModal` (supports `initialTask` for editing)
  - `[x]` Implement local form validation (title) and safety (past dates)
  - `[x]` Add "Delete" button to TaskFormModal (represented as UI trigger in TaskCard for better UX)

- `[x]` **Phase 3: Screen & Widget Integration**
  - `[x]` Update `HomeScreen` to handle Edit opening (`onEdit` callback from `TaskCard`)
  - `[x]` Integrate delete logic with a "Desfazer" (Undo) snackbar
  - `[x]` Add visual feedback for "Completed" toggle (check style guide animations)
  - `[x]` Verify local notification resync (cancel + reschedule on update)
