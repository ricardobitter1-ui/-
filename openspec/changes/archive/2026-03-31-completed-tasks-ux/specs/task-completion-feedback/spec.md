## ADDED Requirements

### Requirement: Visual feedback when completion state changes

The system SHALL provide a clear visual transition when a task moves between the active and completed blocks after a successful completion toggle (complete or uncomplete), so the user perceives where the task went.

#### Scenario: User completes a task

- **WHEN** the user marks a task complete and the UI updates
- **THEN** the transition from the active area to the completed area is visually apparent (e.g., motion, fade, or highlight within the list) without requiring an extra navigation step

### Requirement: Respect system reduced motion

The system SHALL not run decorative or long motion transitions for completion changes when the platform accessibility setting for **reduced motion** (or equivalent, e.g. `disableAnimations`) is enabled; feedback SHALL remain clear using non-motion cues (instant placement, brief color/state change, or static emphasis).

#### Scenario: Reduced motion enabled

- **WHEN** reduced motion is enabled on the device
- **THEN** completion and uncompletion updates avoid animated movement or use duration-zero transitions while still updating the list correctly

### Requirement: No confusing duplicate rows during transition

The system SHALL avoid showing the same task twice in the list during the update (active and completed at the same time) except for a brief, intentional cross-fade defined by the implementation that does not look like duplicated data.

#### Scenario: After toggle settles

- **WHEN** the UI has finished processing the toggle
- **THEN** each task id appears in exactly one of the active or completed blocks
