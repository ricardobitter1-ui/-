## ADDED Requirements

### Requirement: Tag pertence a um único grupo

O sistema SHALL persistir cada tag no Firestore sob o grupo a que pertence, de forma que o identificador do grupo faça parte do path ou do contexto de segurança (ex.: `groups/{groupId}/tags/{tagId}`).

#### Scenario: Membro lê tags do seu grupo

- **WHEN** um utilizador autenticado é membro do grupo `G`
- **THEN** o sistema SHALL permitir leitura dos documentos de tag filhos de `G`

#### Scenario: Não-membro não lê tags

- **WHEN** um utilizador autenticado não é membro do grupo `G`
- **THEN** o sistema SHALL negar leitura das tags de `G`

### Requirement: Membro pode criar tag

O sistema SHALL permitir que **qualquer membro** do grupo crie um novo documento de tag nesse grupo, com campos obrigatórios `name` (string não vazia, limite razoável ex. 80 caracteres) e `color` (inteiro 32-bit representando cor no formato alinhado ao cliente, ex. `0xAARRGGBB`).

#### Scenario: Criação bem-sucedida

- **WHEN** um membro do grupo submete uma nova tag com `name` e `color` válidos
- **THEN** o documento SHALL ser criado sob esse `groupId` e estar disponível para atribuição a tarefas

### Requirement: Membro pode atualizar e eliminar tag

O sistema SHALL permitir que qualquer membro do grupo **atualize** `name` e/ou `color` de uma tag existente e **elimine** o documento da tag, conforme as mesmas regras de membro do grupo.

#### Scenario: Atualização de cor

- **WHEN** um membro altera apenas o campo `color` de uma tag
- **THEN** a alteração SHALL persistir e refletir-se na UI de listagem e no seletor

### Requirement: Sem tag global entre grupos

O sistema SHALL NOT tratar duas tags em grupos diferentes como a mesma entidade; não existe identificador de tag partilhado entre `groupId` distintos.

#### Scenario: Duas tags com mesmo nome em grupos diferentes

- **WHEN** existem tags com o mesmo `name` em grupos `G1` e `G2`
- **THEN** o sistema SHALL manter dois documentos distintos com ids distintos
