## ADDED Requirements

### Requirement: Tarefa persiste chave de pesquisa derivada do título

O sistema SHALL armazenar, em cada documento da coleção `tasks`, um campo escalar `titleSearchKey` derivado do campo `title`, de forma que a chave seja o título normalizado em minúsculas e sem caracteres diacríticos (acentos), após remover espaços à esquerda e à direita do título de origem. O campo `title` SHALL continuar a refletir o texto tal como definido pelo utilizador para exibição.

#### Scenario: Criação de tarefa com acentos e maiúsculas

- **WHEN** o utilizador cria uma tarefa com `title` igual a `" Comprar Café  "`
- **THEN** o documento gravado SHALL conter `title` com o valor acordado pela UI (preservando capitalização e acentos conforme entrada válida do utilizador) e `titleSearchKey` igual a `"comprar cafe"`

#### Scenario: Atualização do título recalcula a chave

- **WHEN** o utilizador altera o `title` de uma tarefa existente
- **THEN** o sistema SHALL persistir `titleSearchKey` recalculado a partir do novo `title` com as mesmas regras de normalização

### Requirement: Leitura tolerante a documentos legados

O sistema SHALL interpretar tarefas cujo documento no Firestore não contenha `titleSearchKey`: ao materializar o modelo da tarefa, a chave de pesquisa efetiva SHALL ser derivada do `title` com as mesmas regras de normalização, até que o documento seja atualizado e passe a persistir o campo.

#### Scenario: Documento antigo sem titleSearchKey

- **WHEN** um documento tem `title` `"Ação"` e não tem o campo `titleSearchKey`
- **THEN** a camada de dados SHALL expor para a aplicação uma chave de pesquisa equivalente a `"acao"` (sem exigir migração imediata do documento)

### Requirement: Integrações podem consultar por chave normalizada

O campo `titleSearchKey` SHALL ser o campo preferido para queries de integração que identifiquem tarefas por “nome” sem usar o ID do documento, aplicando a mesma função de normalização ao texto de entrada da integração antes da comparação com valores armazenados.

#### Scenario: Query por chave coincide com variação de escrita

- **WHEN** uma integração normaliza o texto de busca `"CAFÉ"` para `"cafe"` e executa uma query de igualdade em `titleSearchKey`
- **THEN** tarefas cujo título de exibição difere em maiúsculas ou acentos mas normaliza para `"cafe"` SHALL ser candidatas ao resultado da query
