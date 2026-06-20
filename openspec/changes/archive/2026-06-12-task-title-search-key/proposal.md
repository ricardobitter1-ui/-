# Proposal: Chave de pesquisa normalizada no título da tarefa

## Why

Integrações externas e buscas por “nome” da tarefa não podem depender do ID do documento nem do texto exato que o usuário digitou (maiúsculas, acentos, variações). É preciso um campo estável no Firestore, derivado do título, para consultas por igualdade ou prefixo sem ambiguidade de formatação.

## What Changes

- Novo campo persistido em cada documento de tarefa na coleção `tasks`: chave de pesquisa derivada do título (minúsculas, sem acentos/diacríticos), mantendo o `title` como exibido ao usuário.
- Cálculo da chave no app ao criar e ao atualizar o título (e migração/backfill opcional para documentos antigos sem o campo).
- Modelo Dart (`TaskModel`), serialização (`toMap` / `_taskFromDoc`) e formulário de tarefa alinhados para sempre gravar a chave junto com o título.
- Documentação de uso para queries futuras (ex.: `where('titleSearchKey', isEqualTo: normalized)`), sem obrigar índice composto até haver combinação com outros filtros.

## Capabilities

### New Capabilities

- `task-title-search-key`: Persistência e regras da chave normalizada derivada do título da tarefa; exibição continua usando `title`; integrações buscam pelo campo padronizado.

### Modified Capabilities

- (nenhum — não há spec canônica além de `openspec/specs/app_navigation.md` afetada por requisito de produto)

## Impact

- `lib/data/models/task_model.dart`: novo campo, `copyWith`, `toMap`, leitura defensiva em `fromMap`/equivalente no serviço.
- `lib/data/services/firebase_service.dart`: `_taskFromDoc`, `addTask`, `updateTask` (garantir chave coerente com o título).
- `lib/ui/widgets/task_form_modal.dart` (e qualquer outro ponto que instancia `TaskModel` para escrita): popular a chave a partir do título.
- Utilitário reutilizável (ex.: `lib/utils/normalize_search_key.dart` ou pacote `diacritic`) para normalização Unicode consistente.
- Dados legados: leitura tolerante (campo ausente → derivar na leitura ou backfill sob demanda); escrita subsequente preenche o campo.
