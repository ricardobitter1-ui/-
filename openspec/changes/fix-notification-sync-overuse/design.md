# Design: Sync eficiente de lembretes datetime

## Context

Hoje o fluxo é:

```
tasksStreamProvider (Firestore, N listeners)
        → MainShell.ref.listen (build)
        → _syncDatetimeReminders (todas as tarefas datetime)
        → syncTaskDatetimeReminders por tarefa
                → cancelAllTaskReminderSlots (48 IDs)
                → _schedulePendingReminderSeries
```

Problemas confirmados em produção/debug:

1. **Paralelismo**: `unawaited(_syncDatetimeReminders)` permite vários syncs simultâneos quando o stream emite de novo antes do anterior terminar.
2. **Volume de agendamento**: para tarefas **recorrentes** com repetição pendente ativa, o `while` em `_schedulePendingReminderSeries` agenda alarmes discretos a cada intervalo (ex.: 1 h) até `untilExclusive` (próxima ocorrência), sem incrementar `slot` — gerando centenas/milhares de chamadas por tarefa.
3. **Re-sync desnecessário**: qualquer mudança em qualquer tarefa reprocessa **todas** as tarefas com lembrete datetime.
4. **Custo por alarme**: `hasAlarmPermission()` é chamado em cada `scheduleTaskReminder`.
5. **Logs**: `print` incondicional multiplica o ruído no terminal.

O recurso de **repetir a cada 1 hora enquanto pendente** (Perfil) deve continuar funcionando — inclusive para tarefas recorrentes — mas sem materializar cada repetição futura como alarme separado quando o Android suporta repetição nativa.

## Goals / Non-Goals

**Goals:**

- Um único sync de lembretes em execução por vez; novas solicitações debounced ou enfileiradas.
- Re-sync apenas de tarefas cujo “fingerprint” de lembrete mudou, mais sync completo na primeira carga após login.
- Repetição pendente (1 h, etc.) preservada via `repeatIntervalMilliseconds` no Android para a **ocorrência ativa** de cada tarefa (pontual ou recorrente).
- Teto de 48 slots respeitado para ocorrências futuras discretas de recorrência.
- Reduzir CPU/bateria e logs sem alterar UX de notificação.

**Non-Goals:**

- Mudar o intervalo padrão (30 min) ou opções do dropdown no Perfil.
- Migrar para FCM/push para lembretes locais.
- Reescrever o plugin `flutter_local_notifications`.
- Remover logs de diagnóstico em debug — apenas torná-los condicionais e resumidos.

## Decisions

### 1. `DatetimeReminderSyncCoordinator` (novo)

Classe singleton (via Riverpod `Provider`) responsável por:

| Método | Uso |
|--------|-----|
| `scheduleFullSync(List<TaskModel> tasks)` | Carga inicial / mudança de intervalo no Perfil |
| `scheduleTaskSync(TaskModel task)` | Após criar/editar/concluir uma tarefa |
| `scheduleIncrementalSync(List<TaskModel> tasks)` | Listener do stream (debounced) |

**Comportamento interno:**

- `debounce` de **400 ms** para emissões do stream.
- `Mutex` (`Completer` chain ou `Lock` simples): se sync em andamento, marcar `pendingResync` e rodar uma vez ao terminar (coalescing).
- Manter `Map<taskId, String fingerprint>` em memória.
- Fingerprint = hash estável de: `reminderType`, `dueDate`, `dueHasTime`, `isCompleted`, `recurrence`, `completedOccurrenceDateKeys`, `title`, `description` (campos que afetam lembrete).

Sync incremental: para cada tarefa datetime, comparar fingerprint; se igual, **skip**; se removida/completada/tipo mudou, cancelar slots; se mudou, `syncTaskDatetimeReminders`.

**Alternativa rejeitada:** sync completo sempre — simples mas mantém o problema de bateria.

### 2. MainShell: `listenManual` + coordenador

Espelhar `PendingInviteCoordinator`:

```dart
// initState → addPostFrameCallback
ref.listenManual(tasksStreamProvider, (prev, next) {
  next.whenData(coordinator.scheduleIncrementalSync);
}, fireImmediately: true);
```

`fireImmediately: true` cobre carga inicial; incremental com fingerprint evita reprocessar tudo nas emissões seguintes.

**Alternativa rejeitada:** `ref.listen` no `build` — já causou problemas no projeto.

### 3. Repetição pendente em recorrentes: alarme nativo por ocorrência ativa

Para cada ocorrência futura que ainda não passou e não está concluída:

- **Se** `repeatInterval != null` **e** Android **e** existe janela até `nextOccurrence`:
  - Usar `_androidZonedScheduleRepeatingReminder` (um alarme com `repeatIntervalMilliseconds`) no slot da ocorrência.
  - Mesmo ID por ocorrência (`baseId + slot`) — substitui notificação anterior na gaveta.
- **Senão**: um único `zonedSchedule` no horário da ocorrência.

Elimina o `while` que adiciona `repeatInterval` até `untilExclusive` com milhares de iterações.

**Comportamento preservado:** usuário com 1 h no Perfil continua recebendo lembrete a cada hora após o horário da tarefa até concluir aquela ocorrência — o SO re-dispara o alarme repetitivo.

**iOS:** manter série discretizada mas **limitada**: no máximo `min(slotsRestantes, ceil((untilExclusive - now) / repeatInterval))` e nunca ultrapassar 48 slots totais por tarefa.

**Alternativa rejeitada:** desativar repetição em recorrentes — rejeitada pelo usuário.

### 4. Teto de 48 slots

- Contador global `slot` incrementado a cada ocorrência agendada (incluindo repeating chain que consome 1 slot).
- Parar o loop de ocorrências quando `slot >= kTaskNotificationSlots`.

Corrigir bug atual onde `slot` não incrementa dentro do `while` de repetição discretizada.

### 5. Cache de permissão de alarme exato

Em `NotificationService`:

- Campo `bool? _cachedExactAlarmPermission` invalidado em `requestPermission()` e no início de cada `syncTaskDatetimeReminders`.
- `hasAlarmPermission()` retorna cache se disponível.

### 6. Logging

- Substituir `print` por `debugPrint` guardado com `kDebugMode`.
- Em `syncTaskDatetimeReminders`: um log resumo — `taskId`, ocorrências agendadas, slots usados, duração ms.
- Remover log por alarme individual no caminho quente; manter logs de erro.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Fingerprint incompleto deixa lembrete desatualizado | Incluir todos os campos que afetam título/corpo/horário; testes unitários; sync cirúrgico após save no form |
| Alarme repetitivo Android não respeita `untilExclusive` | Documentar: repetição segue até conclusão ou próximo sync que cancela slots ao marcar ocorrência concluída; ao virar a próxima ocorrência, sync reconfigura |
| iOS com menos slots discretos | Limitar discretização; priorizar ocorrência mais próxima |
| Primeira carga após login demora mais que antes | Aceitável uma vez; debounce evita repetir |
| Sync coalesced atrasa lembrete alguns ms após edição | Debounce 400 ms é imperceptível para o usuário |

## Migration Plan

1. Implementar coordenador e testes de fingerprint/debounce.
2. Refatorar `NotificationService` (repeating + slots + logs).
3. Trocar `MainShell` e chamadas diretas para usar coordenador.
4. Validar manualmente: tarefa pontual com 1 h; tarefa recorrente semanal com 1 h; concluir pela notificação; mudar intervalo no Perfil.
5. Sem migração de dados Firestore; alarmes locais são reescritos no próximo sync.

## Open Questions

- Nenhuma bloqueante. Intervalo de debounce (400 ms) pode ser ajustado após teste em dispositivo com muitos grupos.
