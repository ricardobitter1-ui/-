import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/task_recurrence.dart';
import '../theme/app_theme.dart';

/// Editor de regra de repetição; devolve [TaskRecurrenceRule] ou null se limpar.
class TaskRecurrenceScreen extends StatefulWidget {
  final TaskRecurrenceRule? initialRule;
  final DateTime startDate;

  const TaskRecurrenceScreen({
    super.key,
    this.initialRule,
    required this.startDate,
  });

  @override
  State<TaskRecurrenceScreen> createState() => _TaskRecurrenceScreenState();
}

class _TaskRecurrenceScreenState extends State<TaskRecurrenceScreen> {
  late final TextEditingController _intervalCtrl;
  RecurrenceUnit _unit = RecurrenceUnit.day;
  int _weekdayMask = 0;
  TimeOfDay? _repeatTime;
  RecurrenceEndType _endType = RecurrenceEndType.never;
  DateTime? _endDate;
  final TextEditingController _countCtrl = TextEditingController(text: '10');

  static const _weekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  static const _weekdayBits = [0, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRule;
    _intervalCtrl = TextEditingController(text: '${r?.interval ?? 1}');
    if (r != null) {
      _unit = r.unit;
      _weekdayMask = r.weekdayMask;
      if (r.repeatHour != null && r.repeatMinute != null) {
        _repeatTime = TimeOfDay(hour: r.repeatHour!, minute: r.repeatMinute!);
      }
      _endType = r.endType;
      _endDate = r.endDate;
      if (r.maxOccurrences != null) {
        _countCtrl.text = '${r.maxOccurrences}';
      }
    } else {
      final d = widget.startDate;
      _weekdayMask = 1 << TaskRecurrenceRule.dartWeekdayToBitIndex(d.weekday);
    }
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  TaskRecurrenceRule _buildResult() {
    final n = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final interval = n < 1 ? 1 : n;
    int? rh;
    int? rm;
    if (_repeatTime != null) {
      rh = _repeatTime!.hour;
      rm = _repeatTime!.minute;
    }
    DateTime? endD;
    int? maxOcc;
    switch (_endType) {
      case RecurrenceEndType.never:
        break;
      case RecurrenceEndType.untilDate:
        endD = _endDate;
        break;
      case RecurrenceEndType.afterCount:
        maxOcc = int.tryParse(_countCtrl.text.trim());
        if (maxOcc == null || maxOcc < 1) maxOcc = 1;
        break;
    }
    return TaskRecurrenceRule(
      interval: interval,
      unit: _unit,
      weekdayMask: _unit == RecurrenceUnit.week ? _weekdayMask : 0,
      repeatHour: rh,
      repeatMinute: rm,
      endType: _endType,
      endDate: endD,
      maxOccurrences: maxOcc,
    );
  }

  Future<void> _pickRepeatTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _repeatTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (t != null) setState(() => _repeatTime = t);
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? widget.startDate,
      firstDate: widget.startDate,
      lastDate: DateTime(2035),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (d != null) setState(() => _endDate = d);
  }

  void _save() {
    if (_unit == RecurrenceUnit.week && _weekdayMask == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha pelo menos um dia da semana.')),
      );
      return;
    }
    if (_endType == RecurrenceEndType.untilDate && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha a data de término.')),
      );
      return;
    }
    Navigator.of(context).pop(_buildResult());
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat.yMMMd('pt_BR').format(widget.startDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repetição'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<TaskRecurrenceRule?>(null),
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: _save,
            child: const Text('OK'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Cada', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _intervalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<RecurrenceUnit>(
                  value: _unit,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: RecurrenceUnit.day, child: Text('dia')),
                    DropdownMenuItem(value: RecurrenceUnit.week, child: Text('semana')),
                    DropdownMenuItem(value: RecurrenceUnit.month, child: Text('mês')),
                    DropdownMenuItem(value: RecurrenceUnit.year, child: Text('ano')),
                  ],
                  onChanged: (u) {
                    if (u != null) setState(() => _unit = u);
                  },
                ),
              ),
            ],
          ),
          if (_unit == RecurrenceUnit.week) ...[
            const SizedBox(height: 16),
            Text('Dias da semana', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final bit = _weekdayBits[i];
                final sel = (_weekdayMask & (1 << bit)) != 0;
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (sel) {
                        _weekdayMask &= ~(1 << bit);
                      } else {
                        _weekdayMask |= (1 << bit);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.brandPrimary.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? AppTheme.brandPrimary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(_weekdayLabels[i]),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hora do lembrete (opcional)'),
            subtitle: Text(
              _repeatTime == null
                  ? 'Sem hora definida'
                  : _repeatTime!.format(context),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_repeatTime != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _repeatTime = null),
                  ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickRepeatTime,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Início'),
            subtitle: Text(startStr),
          ),
          const SizedBox(height: 8),
          Text('Término', style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<RecurrenceEndType>(
            title: const Text('Nunca'),
            value: RecurrenceEndType.never,
            groupValue: _endType,
            onChanged: (v) => setState(() => _endType = v!),
          ),
          RadioListTile<RecurrenceEndType>(
            title: const Text('Em data específica'),
            value: RecurrenceEndType.untilDate,
            groupValue: _endType,
            onChanged: (v) => setState(() => _endType = v!),
          ),
          if (_endType == RecurrenceEndType.untilDate)
            ListTile(
              title: Text(
                _endDate == null
                    ? 'Escolher data'
                    : DateFormat.yMMMd('pt_BR').format(_endDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickEndDate,
            ),
          RadioListTile<RecurrenceEndType>(
            title: const Text('Após N ocorrências'),
            value: RecurrenceEndType.afterCount,
            groupValue: _endType,
            onChanged: (v) => setState(() => _endType = v!),
          ),
          if (_endType == RecurrenceEndType.afterCount)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: TextField(
                controller: _countCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de ocorrências',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
