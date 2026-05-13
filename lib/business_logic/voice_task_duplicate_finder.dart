import '../../utils/title_search_key.dart';
import '../data/models/task_model.dart';

/// Encontra tarefa no mesmo grupo com título equivalente ([titleSearchKey]).
TaskModel? findDuplicateGroupTaskByTitle(
  List<TaskModel> groupTasks,
  String title,
) {
  final key = normalizeTitleSearchKey(title);
  for (final t in groupTasks) {
    if (t.titleSearchKey == key) return t;
  }
  return null;
}
