# Proposal: Task CRUD Core (Phase 2)

## Why
Expand the "Exm to do" app from a static task viewer/creator to a fully functional task manager. This phase focuses on the fundamental CRUD lifecycle (Create, Read, Update, Delete) to allow users to manage their daily workflow with premium feedback.

## Goals
- Full Update and Delete operations for tasks.
- Improved validation and edge-case handling (empty titles, past dates).
- Persistent UI feedback (Snackbar confirming deletions with Undo option).
- Real-time Firestore synchronization for all operations.

## Impact
- `lib/data/services/firebase_service.dart`: Add `updateTask` and `deleteTask` (if not already there or needs improvement).
- `lib/ui/widgets/task_form_modal.dart`: New universal form for both creating and editing.
- `lib/ui/widgets/task_card.dart`: Add UI triggers for edit/delete.
- `lib/ui/screens/home_screen.dart`: Coordinate modal opening and delete confirmation.
