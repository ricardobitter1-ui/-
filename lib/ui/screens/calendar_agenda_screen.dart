import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'filtered_task_list_screen.dart';

/// Visão Calendário/Agenda — timeline navegável (antes acoplada ao card "Hoje").
class CalendarAgendaScreen extends ConsumerWidget {
  const CalendarAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const FilteredTaskListScreen(filter: TaskFilterType.today);
  }
}
