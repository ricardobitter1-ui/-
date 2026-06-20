import '../data/models/task_model.dart';

/// Ordena concluídas por [completedAt] desc; legado sem timestamp vai para o fim.
void sortCompletedByRecency(List<TaskModel> completed) {
  completed.sort((a, b) {
    final at = a.completedAt;
    final bt = b.completedAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
}
