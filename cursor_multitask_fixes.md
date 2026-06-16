# Cursor Multitask — 5 Correções

---

## Tarefa 1 — Campo de descrição vem fechado ao abrir tarefa que já tem descrição

**Arquivo:** `lib/ui/widgets/task_form_modal.dart`

**Problema:**  
`_showDescriptionSection` é sempre inicializado como `false` (linha ~70). Quando o usuário abre uma tarefa existente que já tem descrição, a seção fica colapsada e ele não consegue ver o conteúdo.

**Correção:**  
No `_TaskFormModalState.initState()`, após carregar os dados de `task`, adicionar:

```dart
if (task?.description?.isNotEmpty == true) {
  _showDescriptionSection = true;
}
```

Colocar esse bloco junto com as outras inicializações de campos da tarefa (perto de onde `_reminderType`, `_selectedDate`, etc. são definidos a partir de `task`).

---

## Tarefa 2 — Tarefas de geolocalização sempre aparecem como "concluídas hoje" na home

**Arquivo:** `lib/business_logic/task_day_visibility.dart`

**Problema:**  
`_personalInboxUndatedVisibleOnDay()` retorna `true` para qualquer tarefa pessoal sem `dueDate` — inclusive tarefas de localização (`reminderType == 'location'`). Depois que uma tarefa de localização é disparada pelo geofence e marcada como concluída (`isCompleted = true`), ela satisfaz as duas condições todo dia: "visível hoje" + "isCompleted". Por isso aparece permanentemente na seção "Concluídas hoje" na home.

**Correção:**  
Excluir tarefas de localização da checagem de visibilidade do inbox. Em `_personalInboxUndatedVisibleOnDay`, adicionar um retorno antecipado:

```dart
bool _personalInboxUndatedVisibleOnDay(
  TaskModel t,
  DateTime day, {
  required DateTime now,
}) {
  if (t.dueDate != null || !_noGroup(t)) return false;
  if (t.reminderType == 'location') return false; // ADICIONAR ESTA LINHA
  final today = DateTime(now.year, now.month, now.day);
  return _sameCalendarDay(day, today);
}
```

---

## Tarefa 3 — Ditado não cria lembrete para tempo relativo ("em 2 minutos")

**Arquivos:**  
- `lib/business_logic/voice_reminder_heuristic_parser.dart`  
- `lib/constants/voice_task_extraction_prompt.dart` (verificar o prompt do LLM)

**Problema:**  
`VoiceReminderHeuristicParser` reconhece padrões de horário absoluto (`às 14h`, `14:30`) e datas relativas específicas (`hoje`, `amanhã`, `depois de amanhã`), mas não expressões de tempo relativo como `"em 2 minutos"`, `"em 30 minutos"`, `"daqui a 1 hora"`. Quando nenhum padrão casa, `confident = false` e o parser retorna sem resultado — a tarefa é criada sem agendamento de lembrete.

**Correção no parser heurístico:**  
Adicionar novos padrões para detectar `"em N minutos"` e `"em/daqui a N horas"`, calcular o horário real somando o offset ao `referenceDate`, e preencher `timeStr` e `dateStr`:

```dart
static final _relativeMinutes = RegExp(
  r'\bem\s+(\d+)\s+minutos?\b',
  caseSensitive: false,
);
static final _relativeHours = RegExp(
  r'\b(?:em|daqui\s+a)\s+(\d+)\s+horas?\b',
  caseSensitive: false,
);
```

Em `parse()`, após a extração existente de `timeStr`:
```dart
if (timeStr == null) {
  final mMin = _relativeMinutes.firstMatch(normForTime);
  final mHour = _relativeHours.firstMatch(normForTime);
  if (mMin != null) {
    final offset = int.parse(mMin.group(1)!);
    final target = referenceDate.add(Duration(minutes: offset));
    timeStr = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
    dateStr ??= localCalendarDayKey(target);
  } else if (mHour != null) {
    final offset = int.parse(mHour.group(1)!);
    final target = referenceDate.add(Duration(hours: offset));
    timeStr = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
    dateStr ??= localCalendarDayKey(target);
  }
}
```

A linha `final confident = (timeStr != null || hasRelativeDate) && text.length >= 3;` já funciona corretamente após essa correção, pois `timeStr` será não-nulo.

**Correção no prompt do LLM** (`voice_task_extraction_prompt.dart` ou no builder do prompt):  
Garantir que o prompt passe a data **e o horário atual** como contexto (não só a data), para que o LLM consiga resolver `"em 2 minutos"` → timestamp real. Se o prompt já passa `referenceDate`, alterar para incluir também a hora atual: ex.: `"Hoje: 2025-06-16 14:35"`.

---

## Tarefa 4 — Bottom sheet demora para fechar ao salvar uma tarefa

**Arquivo:** `lib/ui/widgets/task_form_modal.dart`

**Problema:**  
Em `_submit()`, o `Navigator.of(context).pop()` só é chamado depois que todas as operações assíncronas terminam: salvamento no Firestore (`fs.updateTask/addTask`) E sincronização de notificações (`ns.syncTaskDatetimeReminders`). O agendamento de notificações pode ser lento, causando um atraso visível antes do sheet fechar.

**Correção:**  
Fechar o sheet imediatamente após o save no Firestore e rodar a sincronização de notificações em background (fire-and-forget):

```dart
// Dentro de _submit(), substituir o bloco após o save no Firestore:

final persisted = task.copyWith(id: savedId);

// Fechar o sheet imediatamente — não aguardar sync de notificações.
if (mounted) Navigator.of(context).pop();

// Sincronizar notificações em background.
if (!continuous && reminderType == 'datetime') {
  ns.syncTaskDatetimeReminders(persisted).catchError((e) {
    debugPrint('Erro no agendamento: $e');
  });
} else {
  ns.cancelAllTaskReminderSlots(savedId).catchError((e) {
    debugPrint('Erro ao cancelar notificações: $e');
  });
}
```

Mover ou remover o `setState(() => _isLoading = false)` do bloco `finally`, já que o widget será desmontado após o pop.

---

## Tarefa 5 — Seção "Atividade recente" no grupo ocupa muito espaço

**Arquivo:** `lib/ui/screens/group_detail_screen.dart`

**Problema:**  
`GroupActivitySection` é renderizado inline (linha ~493), sempre completamente expandido, ocupando muito espaço vertical mesmo quando o usuário não quer ver o feed.

**Correção:**  
Envolver `GroupActivitySection` em um `ExpansionTile` que começa colapsado. Substituir:

```dart
if (!g.isPersonal)
  GroupActivitySection(tasks: tasks, profiles: profileMap),
```

Por:

```dart
if (!g.isPersonal)
  Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      initiallyExpanded: false,
      title: Text(
        'Atividade recente',
        style: ExText.label(context.ex.textSecondary),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      children: [
        GroupActivitySection(tasks: tasks, profiles: profileMap),
      ],
    ),
  ),
```

Também remover o label `'Atividade recente'` de dentro de `GroupActivitySection.build()` (em `group_activity_section.dart`), pois agora ele é o título do `ExpansionTile` — evita duplicação.
