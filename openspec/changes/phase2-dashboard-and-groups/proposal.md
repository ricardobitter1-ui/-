# Proposal: Fase 2 — Dashboard de Entrada & Elite Groups Backend

## Why

A Fase 1 estabeleceu a camada de identidade do usuário (Auth, displayName, avatar) e um CRUD básico de tarefas (`tasks` collection). O resultado é um app funcional, mas com uma estrutura de dados **flat e sem contexto organizacional**.

Três problemas reais surgem desse estado:

1. **Tarefas sem data ficam perdidas**: A home filtra por `dueDate`, então qualquer tarefa sem data simplesmente desaparece da UI. Isso é um bug de produto — o usuário perde itens do seu backlog.
2. **Ausência de contextos**: Não existe forma de separar tarefas por contexto (Trabalho, Pessoal, Fitness). Tudo vive numa coleção monolítica, impossibilitando o "Dashboard de Grupos" do roadmap.
3. **Backend não escala para colaboração**: A collection `tasks` filtra somente por `ownerId`. Para suportar Grupos de Elite (criador + membros), precisamos de uma camada de acesso multi-usuário desde agora — mesmo que o convite de membros seja Fase 3.

Esta mudança implementa a **infraestrutura de dados e serviços** para toda a Fase 2 do roadmap.

## Goals

- Criar a collection `groups` no Firestore com modelo completo para fase colaborativa.
- Introduzir streams especializados no `FirebaseService` para alimentar o **Dashboard** (atemporais + grupos) e o **Calendário** (tarefas com data).
- Criar o provider Riverpod de Grupos para ser consumido pela UI futura.
- Garantir **zero regressão** em funcionalidades da Fase 1.

## Capabilities

### New Capabilities

- `group-model`: Modelo de dados `GroupModel` para os Grupos de Elite (id, name, icon, color, ownerId, members, createdAt).
- `group-service`: CRUD completo de grupos no `FirebaseService` + stream filtrado por membership.
- `atemporal-task-stream`: Stream específico para tarefas sem `dueDate`, para alimentar o Dashboard Inbox.
- `calendar-task-stream`: Stream de tarefas com `dueDate` em uma data específica, para a aba Calendário.
- `group-provider`: Provider Riverpod `groupsStreamProvider` para consumo reativo na UI.

### Modified Capabilities

- `task-service`: `getTasksStream()` permanece, mas ganharemos `getTasksByGroupStream(groupId)` e `getAtemporalTasksStream()` como variantes especializadas.

## Impact

- **`lib/data/models/group_model.dart`** [NEW]: Modelo de grupo com `fromMap`/`toMap`.
- **`lib/data/services/firebase_service.dart`** [MODIFY]: Adicionar collection `groups`, CRUD e streams avançados.
- **`lib/business_logic/providers/group_provider.dart`** [NEW]: Provider Riverpod para grupos.
- **`lib/data/models/task_model.dart`** [MODIFY]: Adicionar `copyWith` para imutabilidade segura.
