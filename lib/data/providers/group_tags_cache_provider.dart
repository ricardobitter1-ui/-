import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tag_model.dart';
import '../services/firebase_service.dart';

/// Cache em memória de etiquetas por grupo (invalidar ao criar/editar tags).
class GroupTagsCacheNotifier extends Notifier<Map<String, List<TagModel>>> {
  @override
  Map<String, List<TagModel>> build() => {};

  Future<List<TagModel>> fetchTags(String groupId) async {
    final gid = groupId.trim();
    if (gid.isEmpty) return [];
    final cached = state[gid];
    if (cached != null) return cached;

    final fs = ref.read(firebaseServiceProvider);
    final tags = await fs.fetchGroupTagsOnce(gid);
    state = {...state, gid: tags};
    return tags;
  }

  void invalidate(String groupId) {
    final gid = groupId.trim();
    if (gid.isEmpty || !state.containsKey(gid)) return;
    final next = Map<String, List<TagModel>>.from(state);
    next.remove(gid);
    state = next;
  }

  void invalidateAll() => state = {};
}

final groupTagsCacheProvider =
    NotifierProvider<GroupTagsCacheNotifier, Map<String, List<TagModel>>>(
  GroupTagsCacheNotifier.new,
);
