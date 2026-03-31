## ADDED Requirements

### Requirement: Sugestões apenas de grupos do utilizador

O sistema (cliente) SHALL oferecer sugestões de rótulos/cores apenas a partir de tags pertencentes a grupos em que o utilizador autenticado é **membro**, excluindo opcionalmente o grupo atual da lista de origem.

#### Scenario: Utilizador vê sugestão de outro grupo

- **WHEN** o utilizador abre o fluxo de adicionar tag no grupo `G` e existe uma tag `T` no grupo `H` onde também é membro
- **THEN** o cliente SHALL poder exibir `T.name` (e cor) como sugestão reutilizável

#### Scenario: Não sugere grupo alheio

- **WHEN** o utilizador não é membro do grupo `X`
- **THEN** o cliente SHALL NOT usar tags de `X` como sugestões

### Requirement: Aplicar sugestão cria nova tag no grupo atual

O sistema SHALL, ao utilizador confirmar uma sugestão originária de outro grupo, **criar um novo documento de tag** no grupo atual com novo `tagId`, copiando pelo menos `name` e `color` da sugestão, sem referenciar o documento de origem.

#### Scenario: Nova entidade após toque

- **WHEN** o utilizador escolhe a sugestão baseada na tag do grupo `H` enquanto edita no grupo `G`
- **THEN** um novo documento SHALL existir em `groups/G/tags/` e **não** SHALL haver campo na nova tag apontando para a tag de `H`

### Requirement: Sugestões são opcionais na UI

O fluxo de criar tarefa ou tag no grupo SHALL funcionar sem o utilizador abrir ou usar sugestões; sugestões são um atalho, não obrigatório.

#### Scenario: Criação manual sem sugestões

- **WHEN** o utilizador cria uma tag apenas digitando nome e escolhendo cor
- **THEN** o sistema SHALL criar a tag normalmente sem exigir sugestões
