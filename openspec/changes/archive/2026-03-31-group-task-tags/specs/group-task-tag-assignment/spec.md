## ADDED Requirements

### Requirement: Tarefa de grupo pode ter zero ou mais tags

O sistema SHALL permitir que uma tarefa com `groupId` definido inclua o campo opcional `tagIds` (lista de strings). A lista pode estar ausente, vazia, ou conter até **10** identificadores de tag.

#### Scenario: Tarefa sem tags

- **WHEN** uma tarefa de grupo é criada ou atualizada sem `tagIds` ou com lista vazia
- **THEN** a persistência SHALL ser válida e a tarefa SHALL ser tratada como sem tags na UI

#### Scenario: Múltiplas tags

- **WHEN** uma tarefa referencia dois ou mais `tagId` válidos do mesmo grupo
- **THEN** a escrita SHALL ser aceite e todos os ids SHALL permanecer associados à tarefa

### Requirement: TagIds só para tarefas de grupo

O sistema SHALL NOT permitir que `tagIds` seja uma lista não vazia quando `groupId` da tarefa for nulo ou ausente.

#### Scenario: Rejeição em tarefa pessoal

- **WHEN** uma escrita de tarefa sem `groupId` inclui `tagIds` com um ou mais elementos
- **THEN** o sistema (rules ou validação equivalente) SHALL rejeitar a operação

### Requirement: TagIds devem referir tags do mesmo grupo

O sistema SHALL garantir que cada elemento de `tagIds` corresponde a um documento de tag cujo path pertence ao mesmo `groupId` da tarefa.

#### Scenario: Id de outro grupo rejeitado

- **WHEN** uma tarefa do grupo `G` inclui em `tagIds` um id que existe apenas em tags do grupo `H`
- **THEN** a escrita SHALL ser rejeitada

#### Scenario: Id inexistente rejeitado

- **WHEN** uma tarefa inclui em `tagIds` um id que não existe em `groups/{groupId}/tags/`
- **THEN** a escrita SHALL ser rejeitada

### Requirement: Modelo de dados no cliente

O cliente SHALL mapear `tagIds` entre Firestore e `TaskModel` (lista de strings, default vazia), incluindo em `toMap` / parsing de documento.

#### Scenario: Leitura de tarefa legada

- **WHEN** um documento de tarefa não contém o campo `tagIds`
- **THEN** o cliente SHALL interpretar como lista vazia
