# Specification: Elite Groups Functional Behavior

## Overview

Elite Groups are the primary organizational units for Phase 2. They allow users to categorize tasks into specific contexts (Work, Personal, Fitness, etc.) and provide a foundation for future collaboration.

## Data Schema (Firestore)

### Collection: `groups`
- **`id`** (String): Unique identifier.
- **`name`** (String): Group display name.
- **`icon`** (String): Material Icon name (e.g., 'work', 'favorite').
- **`color`** (String): Hexadecimal color code (e.g., '#FF5733').
- **`ownerId`** (String): UID of the group creator.
- **`members`** (List<String>): List of UIDs with access to the group (initially just the owner).
- **`createdAt`** (Timestamp): Server timestamp.

## Functional Requirements

### 1. Group CRUD
- **Create**: Users can create a group with a name, icon, and color.
- **List**: Users see all groups where their UID is in the `members` list.
- **Update**: Group owners can rename or change the visual identity of a group.
- **Delete**: Group owners can delete a group (tasks should either be moved to "Personal" or deleted - Decision: Move to "Personal" for now).

### 2. Task-Group Linking
- Tasks possess an optional `groupId` field.
- If `groupId` is provided, the task is visible in that group's view.
- If `groupId` is null, the task is "Personal" (Inbox).

### 3. "Atemporal" Tasks (Dashboard Inbox)
- Definition: A task where `dueDate` is `null`.
- These tasks appear in the **"Dashboard Inbox"** rather than the **"Daily Timeline"**.
- This allows for a "Backlog" of ideas/tasks that haven't been scheduled yet.

### 4. Group Multi-Tenancy
- Even in Phase 2, the `members` list must be populated with at least the `ownerId` to ensure the security rules (Phase 3 ready) will work when implemented.
