## ADDED Requirements

### Requirement: Note capture mode extracts title and polished description

When the voice pipeline classifies input as note capture, the system SHALL produce one or more tasks where each `title` follows the pattern **Área: problema** (area and problem separated by colon and space) and each non-empty `description` is a lightly polished version of the spoken content: shorter than raw transcription, free of filler words, preserving all factual intent without inventing details.

#### Scenario: Single improvement with context

- **WHEN** the user dictates inside a group whose name indicates improvements (e.g. "Melhorias") a narrative such as a snackbar needing more information when creating a task
- **THEN** the system creates exactly one task with a title like `Snackbar: falta informação ao criar tarefa` and a description of one to four sentences that retains the why/when facts and does not copy the title verbatim

#### Scenario: Description omits filler but keeps facts

- **WHEN** the transcript contains filler ("né", "tipo", "então") and explanatory clauses
- **THEN** the description SHALL remove fillers and repetition while keeping the same meaning as the user's speech

#### Scenario: Description must not invent requirements

- **WHEN** the user does not mention a specific behavior or requirement
- **THEN** the description SHALL NOT add new requirements or assumptions

### Requirement: Note capture uses a single LLM extraction call

The system SHALL perform note capture extraction in the same single LLM request used for other voice extraction modes (after STT), without an additional LLM call for classification or description rewriting.

#### Scenario: Pipeline issues one extract request

- **WHEN** note capture mode is selected for a transcript
- **THEN** the voice pipeline SHALL call the LLM extract client once for task JSON (excluding existing optional shopping tag assignment which only applies to shopping flows)

### Requirement: Router selects note capture without treating all forced groups as shopping

The system SHALL route to note capture when the screen context or group name indicates notes/improvements, or when the transcript has narrative note signals, and SHALL NOT route to shopping solely because `hasForcedGroup` is true.

#### Scenario: Dictation inside Melhorias group

- **WHEN** the user opens voice dictation from a group named "Melhorias" and speaks a multi-sentence improvement
- **THEN** the intent router SHALL select note capture (not shopping)

#### Scenario: Dictation inside Supermercado group with product list

- **WHEN** the user opens voice dictation from a supermarket-like group and lists products
- **THEN** the intent router SHALL select shopping capture (not note capture)

#### Scenario: Reminder inside any group

- **WHEN** the user says a clear reminder with time (e.g. "me lembre de comer daqui duas horas") from any group context
- **THEN** the intent router SHALL select reminder mode before note capture

### Requirement: Default one task per note audio with conservative multi-split

For note capture, the system SHALL default to exactly one task per dictation unless the transcript contains explicit markers of a second distinct subject.

#### Scenario: One improvement per audio

- **WHEN** the user describes one improvement in one continuous narrative without a second-subject marker
- **THEN** the system SHALL create one task

#### Scenario: Two subjects with explicit marker

- **WHEN** the user describes one improvement and then says "outro ponto" (or equivalent marker) and describes a different subject
- **THEN** the system SHALL create two tasks each with its own Área: problema title and polished description

#### Scenario: Do not split on weak conjunction

- **WHEN** the user uses "e" only to continue explaining the same subject
- **THEN** the system SHALL NOT create multiple tasks solely for that conjunction

### Requirement: Note capture is not limited to improvement groups

The system SHALL activate note capture for personal or narrative dictation outside improvement-named groups when transcript signals indicate a note needing detail (e.g. explanatory length and "porque"/"precisa"), not only when the group name matches note patterns.

#### Scenario: Personal note from home without product list

- **WHEN** the user dictates from home a long explanatory note without shopping list cues
- **THEN** the system MAY select note capture and populate description according to polish rules

### Requirement: Shopping and reminder behaviors remain unchanged

Implementing note capture SHALL NOT change existing shopping list title rules (product name only) or reminder extraction (short title, date/time fields, empty description) for inputs that match those modes.

#### Scenario: Supermarket regression

- **WHEN** the user dictates "arroz, feijão e macarrão" in a supermarket-like group
- **THEN** the system SHALL create three tasks with titles `Arroz`, `Feijão`, `Macarrão` and empty descriptions

#### Scenario: Reminder regression

- **WHEN** the user dictates "me lembre de cortar o cabelo amanhã às 10" without forced shopping context
- **THEN** the system SHALL create one reminder task with title without embedded time and appropriate date/time fields

### Requirement: Persisted tasks expose description in existing UI

When note capture sets a non-empty description, the system SHALL persist it on the task document and the existing task list UI SHALL be able to display it without new screens in this change.

#### Scenario: Task card shows description

- **WHEN** a note capture task is saved with a non-empty description
- **THEN** the user SHALL see the description on the task card when viewing the task in the group or inbox list
