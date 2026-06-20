## 1. Coordenador de sync

- [ ] 1.1 Criar `lib/business_logic/datetime_reminder_sync_coordinator.dart` com debounce (400 ms), mutex/coalescing e mapa de fingerprints por `taskId`
- [ ] 1.2 Implementar `reminderFingerprint(TaskModel)` com campos relevantes (reminderType, dueDate, dueHasTime, isCompleted, recurrence, completedOccurrenceDateKeys, title, description)
- [ ] 1.3 Expor `scheduleIncrementalSync`, `scheduleFullSync` e `scheduleTaskSync` + provider Riverpod
- [ ] 1.4 Adicionar testes em `test/datetime_reminder_sync_coordinator_test.dart` (skip por fingerprint, coalescing, debounce)

## 2. NotificationService — agendamento eficiente

- [ ] 2.1 Corrigir `_schedulePendingReminderSeries`: usar `_androidZonedScheduleRepeatingReminder` para repetição pendente em ocorrências recorrentes (Android), eliminando o `while` de milhares de discretos
- [ ] 2.2 Incrementar `slot` corretamente e respeitar `kTaskNotificationSlots` no loop de ocorrências recorrentes
- [ ] 2.3 Limitar discretização no iOS com teto derivado de slots restantes e `untilExclusive`
- [ ] 2.4 Cachear `hasAlarmPermission()` por pass de sync; invalidar em `requestPermission` e início de `syncTaskDatetimeReminders`
- [ ] 2.5 Substituir `print` por `debugPrint` + `kDebugMode`; log resumo por tarefa em sync (slots, duração); manter logs de erro
- [ ] 2.6 Adicionar/ajustar testes em `test/` para slot budget e política de repeating em recorrentes (lógica extraída se necessário)

## 3. Integração na UI e call sites

- [ ] 3.1 `MainShell`: trocar `ref.listen` no `build` por `listenManual` no `initState` chamando `scheduleIncrementalSync` com `fireImmediately: true`
- [ ] 3.2 `profile_screen.dart`: ao salvar intervalo de repetição, usar `scheduleFullSync` do coordenador
- [ ] 3.3 Redirecionar call sites diretos (`task_form_modal`, `complete_task_action`, `home_screen`, `partitioned_group_task_list`, `filtered_task_list_screen`, `task_search_screen`, `voice_task_pipeline`) para `scheduleTaskSync` do coordenador
- [ ] 3.4 Remover loop manual duplicado de sync em massa onde o coordenador já cobre

## 4. Validação manual

- [ ] 4.1 Tarefa pontual com lembrete + repetição 1 h: confirmar notificações horárias após o horário até concluir
- [ ] 4.2 Tarefa recorrente semanal com repetição 1 h: confirmar repeating sem flood no terminal (debug) por 2+ minutos com app parado
- [ ] 4.3 Concluir pela ação da notificação: alarmes cancelados e sem re-sync em massa desnecessário
- [ ] 4.4 Mudar intervalo no Perfil: lembretes reconfigurados uma vez, sem paralelismo visível nos logs
