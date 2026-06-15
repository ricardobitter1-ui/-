import '../data/models/group_type.dart';

enum GroupVoiceMode { tasks, items }

/// Flags de comportamento derivadas do tipo de grupo.
class GroupTypeConfig {
  final bool continuous;
  final bool defaultDueDateOptional;
  final bool countsInHome;
  final String completionLabel;
  final bool progressCard;
  final String progressCardActiveLabel;
  final GroupVoiceMode voiceMode;
  final bool reAdd;

  const GroupTypeConfig({
    required this.continuous,
    required this.defaultDueDateOptional,
    required this.countsInHome,
    required this.completionLabel,
    required this.progressCard,
    required this.progressCardActiveLabel,
    required this.voiceMode,
    required this.reAdd,
  });

  static GroupTypeConfig of(GroupType type) {
    switch (type) {
      case GroupType.continuous:
        return const GroupTypeConfig(
          continuous: true,
          defaultDueDateOptional: false,
          countsInHome: false,
          completionLabel: 'Comprados recentemente',
          progressCard: false,
          progressCardActiveLabel: 'itens para comprar',
          voiceMode: GroupVoiceMode.items,
          reAdd: true,
        );
      case GroupType.project:
        return const GroupTypeConfig(
          continuous: false,
          defaultDueDateOptional: true,
          countsInHome: true,
          completionLabel: 'Concluídas',
          progressCard: true,
          progressCardActiveLabel: 'tarefas',
          voiceMode: GroupVoiceMode.tasks,
          reAdd: false,
        );
      case GroupType.routine:
        return const GroupTypeConfig(
          continuous: true,
          defaultDueDateOptional: false,
          countsInHome: true,
          completionLabel: 'Feitos hoje',
          progressCard: true,
          progressCardActiveLabel: 'hoje',
          voiceMode: GroupVoiceMode.tasks,
          reAdd: false,
        );
      case GroupType.tasks:
        return const GroupTypeConfig(
          continuous: false,
          defaultDueDateOptional: true,
          countsInHome: true,
          completionLabel: 'Concluídas',
          progressCard: true,
          progressCardActiveLabel: 'tarefas',
          voiceMode: GroupVoiceMode.tasks,
          reAdd: false,
        );
    }
  }
}
