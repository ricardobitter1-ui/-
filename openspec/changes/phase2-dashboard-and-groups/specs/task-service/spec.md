## MODIFIED Requirements

### Requirement: TaskModel suporta operações imutáveis com copyWith
O `TaskModel` SHALL implementar `copyWith({String? id, String? title, String? description, double? latitude, double? longitude, bool? isCompleted, String? reminderType, DateTime? dueDate, String? locationTrigger, String? ownerId, String? groupId})` retornando uma nova instância com os campos substituídos.

Todos os parâmetros do `copyWith` SHALL ser opcionais e nullable intencionalmente — para suportar a limpeza de campos (ex: remover um `groupId`), o método SHALL usar um sentinel `_unset` interno em vez de `??` simples.

#### Scenario: Marcar tarefa como concluída de forma imutável
- **WHEN** `task.copyWith(isCompleted: true)` é chamado
- **THEN** retorna nova instância com `isCompleted == true` e todos os outros campos iguais ao original

#### Scenario: Remover dueDate de uma tarefa (tarefa vira atemporal)
- **WHEN** `task.copyWith(dueDate: null)` é chamado em tarefa com dueDate definido
- **THEN** retorna nova instância com `dueDate == null`

#### Scenario: Trocar grupo de uma tarefa
- **WHEN** `task.copyWith(groupId: 'novo-grupo-id')` é chamado
- **THEN** retorna nova instância com o `groupId` atualizado e demais campos intactos
