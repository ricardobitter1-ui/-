## ADDED Requirements

### Requirement: Completed tasks show tag chips when tags exist

The system SHALL render, on each completed task card in the **Hoje** tab (inbox and selected day) and on the **group detail** list, a row of **chips** for tags that resolve for that task’s `groupId` and `tagIds` (same visual vocabulary as group tags). Tasks without a group or without resolvable tags SHALL omit the chip row.

#### Scenario: Group task with tags in completed section

- **WHEN** a completed group task has `tagIds` that match tags in that group’s tag list
- **THEN** the task card shows chips with each tag’s name and color

#### Scenario: Personal or tagless completed task

- **WHEN** the task has no `groupId` or no resolvable tags
- **THEN** no tag chips are shown on the card (other card content unchanged)

### Requirement: Filter completed tasks by tag without per-tag sections

The system SHALL provide, when the completed section is expanded and at least one completed task has a resolvable tag, a horizontal **filter** with an option **Todas** and one entry per distinct tag in use among **completed** tasks in that list context. Selecting a tag SHALL restrict the visible completed tasks to those that include that tag. The active list SHALL NOT be split into separate sections per tag for this filter (the filter applies only within the single completed block).

#### Scenario: Group detail completed filter

- **WHEN** the user selects a tag chip in the completed filter on group detail
- **THEN** only completed tasks that contain that `tagId` are listed under the completed section

#### Scenario: Hoje completed filter across groups

- **WHEN** completed tasks on Hoje belong to more than one group
- **THEN** filter options remain distinct per tag instance (group + tag identity), and selecting one shows only completed tasks that carry that tag in that group

#### Scenario: No matching tasks for filter

- **WHEN** a filter is active and no completed task matches
- **THEN** the UI shows an empty-state message for that filter without duplicating task rows

### Requirement: Filter state does not persist across unrelated surfaces

The system SHALL keep filter selection independent between **Hoje inbox**, **Hoje selected day**, and **each group detail** (changing filter on one surface does not change another).

#### Scenario: Inbox filter independent from day filter

- **WHEN** the user selects a tag filter on the inbox completed section
- **THEN** the selected-day completed section filter remains unchanged until the user changes it there
