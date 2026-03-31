## ADDED Requirements

### Requirement: Task lists separate active and completed tasks

The system SHALL present tasks with `isCompleted == false` in an **active** block and tasks with `isCompleted == true` in a **completed** block on the **Hoje** tab (both the undated inbox list and the selected-day task list) and on the **group detail** task list.

#### Scenario: Active tasks appear before completed

- **WHEN** the user views a task list that contains both incomplete and complete tasks
- **THEN** all incomplete tasks are shown above any completed tasks in that list context

#### Scenario: Only active tasks

- **WHEN** there are no completed tasks in that list context
- **THEN** the UI shows only the active list without an empty completed section header, or shows the completed section in an empty state as specified by the implementation (consistent per surface)

### Requirement: Completed tasks live in a dedicated collapsible section

The system SHALL show completed tasks inside a dedicated section at the end of the list (below active tasks), with a visible section header and a control to **expand or collapse** the completed items.

#### Scenario: User collapses completed section

- **WHEN** the user collapses the completed section
- **THEN** completed task rows are hidden while the section header (or a compact summary) remains visible so the user can expand again

#### Scenario: User expands completed section

- **WHEN** the user expands the completed section
- **THEN** completed tasks are visible again in that section

### Requirement: Collapse state is remembered per surface

The system SHALL persist whether the completed section is expanded or collapsed separately for (1) the Hoje undated inbox list, (2) the Hoje selected-day list, and (3) each group detail list (keyed by group id), using local storage on the device.

#### Scenario: Group A collapse does not affect group B

- **WHEN** the user collapses completed tasks on group A’s detail screen
- **THEN** opening group B’s detail screen does not reuse group A’s collapsed state unless B was already set the same way

### Requirement: Completing a task moves it into the completed section

The system SHALL remove the task from the active block and show it under the completed block immediately after the completion toggle succeeds (visual ordering follows the dedicated completed section rules).

#### Scenario: User completes a task in group detail

- **WHEN** the user marks a task complete from the group task list
- **THEN** the task appears under the completed section for that group (or under the collapsed section if collapsed, without breaking layout)

### Requirement: Uncompleting a task returns it to the active block

The system SHALL move the task back to the active block when the user marks it incomplete, consistent with the same list surface rules.

#### Scenario: User uncompletes from completed section

- **WHEN** the user toggles completion off on a task shown in the completed section
- **THEN** the task appears in the active block again
