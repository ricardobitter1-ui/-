# Proposal: Corrigir sobreuso do sync de lembretes locais

## Why

Com o app aberto e o usuário parado, o terminal de debug dispara milhares de linhas `DEBUG NOTIF` por minuto e o dispositivo fica reagendando alarmes continuamente. A causa não é o recurso de **repetir lembretes enquanto a tarefa não for concluída** (hoje configurado para 1 hora no Perfil) — esse comportamento é desejado —, e sim a forma como o app **sincroniza** esses lembretes: re-sync em massa a cada emissão do stream de tarefas, execuções paralelas sem trava, e agendamento discretizado em excesso para tarefas recorrentes. Isso gera desperdício de CPU/bateria e risco de atingir limites do Android sem melhorar a experiência do usuário.

## What Changes

- Introduzir um **coordenador de sync** de lembretes datetime com debounce, mutex (um sync por vez) e diff por tarefa — só reagendar quando campos relevantes mudarem ou na carga inicial.
- Corrigir o **agendamento de repetição pendente** em tarefas recorrentes: usar alarme repetitivo nativo do Android (já usado em tarefas pontuais) em vez de centenas/milhares de `zonedSchedule` discretos entre ocorrências.
- Respeitar de fato o teto de **48 slots** por tarefa ao discretizar ocorrências futuras.
- Mover o listener do `MainShell` para **`listenManual`** (padrão já adotado em `PendingInviteCoordinator`) e eliminar sync duplicado desnecessário.
- **Cachear** a checagem de permissão de alarme exato por sessão de sync (não por agendamento individual).
- Reduzir ruído de debug: logs `DEBUG NOTIF` apenas em `kDebugMode` e com resumo por sync (não uma linha por alarme em loop).
- **Preservar** integralmente: lembrete no horário da tarefa, repetição configurável no Perfil (30 s / 5 min / 15 min / 30 min / 1 h / desativado), tarefas recorrentes, ações Concluir/Reprogramar na notificação.

## Capabilities

### New Capabilities

- `datetime-reminder-sync`: Política de quando e como re-sincronizar lembretes locais com o Firestore — debounce, exclusão mútua, diff de tarefas e sync inicial vs incremental.

### Modified Capabilities

- `notification-reminders`: Requisitos de agendamento eficiente para repetição pendente e recorrência, mantendo o comportamento funcional atual (repetir a cada intervalo até conclusão).

## Impact

- `lib/data/services/notification_service.dart` — refatorar `_schedulePendingReminderSeries`, cache de permissão, logs condicionais.
- `lib/ui/screens/main_shell.dart` — substituir `ref.listen` por `listenManual`; delegar ao coordenador.
- Novo módulo em `lib/business_logic/` ou `lib/data/services/` para o coordenador de sync.
- `lib/ui/screens/profile_screen.dart` — continua disparando re-sync ao mudar intervalo (via coordenador, não loop manual).
- Pontos que já chamam `syncTaskDatetimeReminders` diretamente (formulário, conclusão, voz) — passam a usar o coordenador ou sync cirúrgico de uma tarefa.
- Testes unitários para diff de lembrete, limites de slots e política de repetição em recorrentes.
