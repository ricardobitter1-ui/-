## ADDED Requirements

### Requirement: Lista agrupada por tag no detalhe do grupo

No ecrã de detalhe de um grupo, o sistema SHALL apresentar as tarefas **pendentes** (não concluídas) agrupadas em secções: uma secção por tag que tenha pelo menos uma tarefa pendente com esse `tagId`, mais uma secção **Sem tag** para tarefas pendentes sem tags resolvidas.

#### Scenario: Secção por tag

- **WHEN** existem tarefas pendentes com a tag `Verduras`
- **THEN** o sistema SHALL mostrar uma secção identificável (ex.: cabeçalho com nome/cor da tag) contendo essas tarefas

#### Scenario: Sem tag

- **WHEN** uma tarefa pendente não tem `tagIds` ou só contém ids sem documento de tag
- **THEN** a tarefa SHALL aparecer na secção **Sem tag**

### Requirement: Ordem das secções

O sistema SHALL ordenar as secções de tags por **nome da tag** alfabeticamente (locale do app). A secção **Sem tag** SHALL aparecer **por último** entre as secções de pendentes.

#### Scenario: Duas tags

- **WHEN** existem tags "Verduras" e "Congelados"
- **THEN** a secção "Congelados" SHALL preceder "Verduras" se a ordenação for alfabética crescente em PT

### Requirement: Tarefa com várias tags em várias secções

O sistema SHALL renderizar a mesma tarefa pendente em **cada** secção correspondente a cada uma das suas tags resolvidas.

#### Scenario: Duas tags na mesma tarefa

- **WHEN** uma tarefa pendente tem `tagIds` com tag A e tag B
- **THEN** a tarefa SHALL aparecer na secção de A e na secção de B

### Requirement: Formulário de tarefa de grupo com seletor de tags

No modal ou formulário de criar/editar tarefa quando `groupId` está definido, o sistema SHALL permitir selecionar zero ou mais tags do grupo, criar nova tag no grupo, e aceder ao fluxo de sugestões conforme spec `group-tag-suggestions`.

#### Scenario: Editar tarefa existente

- **WHEN** o utilizador abre edição de uma tarefa de grupo que já tem `tagIds`
- **THEN** o seletor SHALL refletir as tags atuais e permitir alteração

### Requirement: Tarefas concluídas fora do agrupamento por tag (MVP desta change)

Para o âmbito desta change, o sistema MAY manter o comportamento atual de exibição de tarefas concluídas (ex.: mesma lista com estilo diferenciado) **sem** exigir novo agrupamento por tag nas concluídas; a Fase 6 do roadmap pode refinar.

#### Scenario: Concluídas ainda visíveis

- **WHEN** existem tarefas concluídas no grupo
- **THEN** o sistema SHALL continuar a mostrá-las de forma consistente com o comportamento pré-change ou com ajuste mínimo necessário para não quebrar a lista
