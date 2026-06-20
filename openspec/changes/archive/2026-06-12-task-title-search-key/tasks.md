## 1. Normalização e modelo

- [x] 1.1 Adicionar dependência `diacritic` (ou implementar normalização Unicode equivalente) em `pubspec.yaml`, se ainda não existir.
- [x] 1.2 Criar função pura `normalizeTitleSearchKey(String title)` (ex.: `lib/utils/title_search_key.dart`) com trim, minúsculas e remoção de diacríticos.
- [x] 1.3 Estender `TaskModel` com `titleSearchKey`, construtor, `copyWith` e `toMap`; garantir leitura defensiva onde o mapa é montado.

## 2. Firestore e formulário

- [x] 2.1 Atualizar `_taskFromDoc` em `firebase_service.dart` para mapear `titleSearchKey`, com fallback `normalizeTitleSearchKey(title)` quando o campo estiver ausente.
- [x] 2.2 Garantir que `addTask` e `updateTask` persistem `titleSearchKey` coerente com `title` (recalcular no serviço ou exigir que o caller sempre preencha — preferir um único ponto de verdade).
- [x] 2.3 Atualizar `task_form_modal.dart` (e qualquer outro criador de `TaskModel` para escrita) para definir `titleSearchKey` ao salvar.

## 3. Verificação

- [x] 3.1 Testar manualmente ou com teste unitário: criar/editar título com acentos e verificar documento no Firestore (`title` vs `titleSearchKey`).
- [x] 3.2 Documentar no código ou comentário breve no serviço o padrão de query esperado para integrações (`where('titleSearchKey', isEqualTo: ...)` + filtros de escopo).

