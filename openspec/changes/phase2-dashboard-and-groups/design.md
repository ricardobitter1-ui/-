# Design: Fase 2 — Dashboard de Entrada & Elite Groups Backend

## Context

O app hoje possui um `FirebaseService` monolítico com uma única collection `tasks` filtrada por `ownerId`. O provider `tasksStreamProvider` retorna todas as tarefas do usuário, deixando para a UI a responsabilidade de filtrar por data — o que causa o desaparecimento silencioso de tarefas sem `dueDate`.

Para a Fase 2, precisamos:
- Uma collection `groups` no Firestore com modelo próprio
- Streams especializados no serviço para desacoplar Dashboard (atemporais) de Calendário (agendadas)
- Providers Riverpod segregados por domínio (tasks vs groups)

## Goals / Non-Goals

**Goals:**
- Criar `GroupModel` com `fromMap` / `toMap` / `copyWith` completos
- Implementar CRUD de grupos no `FirebaseService` com acesso por membership (`members.contains(uid)` via `array-contains`)
- Expor `getAtemporalTasksStream()`, `getTasksByGroupStream(groupId)`, `getScheduledTasksStream(date)` como streams separados
- Criar `groupsStreamProvider` no Riverpod para consumo reativo em qualquer widget
- Adicionar `copyWith` em `TaskModel` para garantir immutability safe nas edições

**Non-Goals:**
- UI de navegação bottom nav (frontend)
- Convite de membros / gerenciamento de roles (Fase 3)
- Regras de segurança do Firestore (Fase 3)
- Geofencing por grupo (Fase 4)

## Decisions

### D1: Estrutura da collection `groups`

**Decisão:** Cada documento em `groups` contém um campo `members: List<String>` com UIDs. Para encontrar os grupos do usuário logado, usamos a query `where('members', arrayContains: uid)`.

**Alternativa considerada:** Subcollections por usuário (`users/{uid}/groups`). **Rejeitada** porque impossibilitaria queries cross-user futuramente e quebraria a feature de membros compartilhados.

**Trade-off:** Documentos com `members` crescentes podem atingir o limite do Firestore (1MB/doc). Para Fase 2, isso é negligenciável — Elite Groups são pequenos.

### D2: Separação de Streams por Caso de Uso

**Decisão:** Em vez de uma única query `getTasksStream()` com filtragem na UI, criar 3 streams especializados:
- `getAtemporalTasksStream()` → `where('dueDate', isNull: true).where('ownerId', isEqualTo: uid)`
- `getScheduledTasksStream(DateTime date)` → filtra por `dueDate` no range do dia especificado
- `getTasksByGroupStream(String groupId)` → filtra por `groupId`

**Alternativa considerada:** Stream único com filtragem local. **Rejeitada** porque carrega dados desnecessários do Firestore, aumenta latência e custo de leitura.

**Nota de implementação:** O stream `getScheduledTasksStream` usa `isGreaterThanOrEqualTo` / `isLessThan` no `dueDate`. Isso **exige um índice composto** `(ownerId ASC, dueDate ASC)` no Firestore — documentado na migration plan.

### D3: Substituição Gradual de `tasksStreamProvider`

**Decisão:** Manter o `tasksStreamProvider` existente sem quebrar. Criar `atemporalTasksStreamProvider` e `scheduledTasksStreamProvider(date)` como *family providers* adicionais. A UI pode migrar gradualmente.

**Alternativa considerada:** Deprecar `tasksStreamProvider` agora. **Rejeitada** por ser uma breaking change que quebraria o `HomeScreen` atual sem uma migração coordenada.

### D4: `GroupModel` imutável + `copyWith`

**Decisão:** Implementar `copyWith` em `GroupModel` e `TaskModel`. Riverpod funciona melhor com objetos imutáveis — sem `copyWith`, qualquer update força a recriação manual de instâncias.

## Risks / Trade-offs

- **[Risco] Índice composto no Firestore não existe** → A query `getScheduledTasksStream` falhará silenciosamente até o índice ser criado. **Mitigação:** Documentar o link de criação do índice nas tasks e no walkthrough final.
- **[Risco] `getTasksStream()` retorna tarefas sem `ownerId`** (dados legacy da Fase 0 anônima) → Podem aparecer no stream de qualquer usuário. **Mitigação:** A query atual já filtra por `ownerId`, então dados sem esse campo simplesmente não aparecem.
- **[Risco] `array-contains` em `members`** tem limitação de 1 `array-contains` por query → Não podemos combinar com outro `array-contains` na mesma query. **Mitigação:** Não há necessidade disso na Fase 2.

## Migration Plan

1. Adicionar classe `GroupModel` (zero risco, arquivo novo)
2. Adicionar `copyWith` em `TaskModel` (zero risco, adição pura)
3. Adicionar métodos ao `FirebaseService` sem remover existentes (backward compatible)
4. Criar `GroupProvider` no Riverpod (zero risco, novo provider)
5. Criar índice composto no Firestore Console: `tasks → ownerId (ASC) + dueDate (ASC)`
6. Validar todos os streams com testes manuais antes de conectar na UI

**Rollback**: Como todas as mudanças são aditivas (novos arquivos ou novos métodos), o rollback consiste em simplesmente não consumir os novos providers/streams na UI.
