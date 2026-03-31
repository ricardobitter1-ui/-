import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/task_provider.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import 'task_card.dart';

/// [TaskCard] com etiquetas resolvidas via stream do grupo (aba Hoje).
class HomeTaskCardWithTags extends ConsumerWidget {
  const HomeTaskCardWithTags({
    super.key,
    required this.task,
    required this.showTagChips,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.assigneeProfiles,
    this.selfUid,
    this.selfPhotoUrl,
  });

  final TaskModel task;
  final bool showTagChips;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Map<String, UserPublicProfile?>? assigneeProfiles;
  final String? selfUid;
  final String? selfPhotoUrl;

  static String compositeTagKey(String groupId, String tagId) =>
      '$groupId::$tagId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<TagModel>? chips;
    final gid = task.groupId;
    if (showTagChips && gid != null && task.tagIds.isNotEmpty) {
      final async = ref.watch(groupTagsStreamProvider(gid));
      chips = async.when(
        data: (tags) {
          final m = {for (final t in tags) t.id: t};
          final list =
              task.tagIds.map((id) => m[id]).whereType<TagModel>().toList();
          return list.isEmpty ? null : list;
        },
        loading: () => null,
        error: (_, _) => null,
      );
    }

    return TaskCard(
      task: task,
      tagChips: chips,
      assigneeProfiles: assigneeProfiles,
      selfUid: selfUid,
      selfPhotoUrl: selfPhotoUrl,
      onToggle: onToggle,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
