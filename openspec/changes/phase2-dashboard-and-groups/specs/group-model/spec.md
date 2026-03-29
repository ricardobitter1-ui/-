## ADDED Requirements

### Requirement: GroupModel representa um Grupo de Elite no Firestore
O sistema SHALL definir um `GroupModel` imutável com os campos: `id` (String), `name` (String), `icon` (String — nome do MaterialIcon), `color` (String — hex RGB), `ownerId` (String), `members` (List<String> de UIDs), `createdAt` (DateTime).

O modelo SHALL implementar `fromMap(String id, Map<String, dynamic> data)` para deserialização segura a partir do Firestore, com defaults defensivos para campos ausentes.

O modelo SHALL implementar `toMap()` retornando um `Map<String, dynamic>` pronto para escrita no Firestore, convertendo `createdAt` em `Timestamp`.

O modelo SHALL implementar `copyWith({...})` permitindo criar cópias modificadas sem mutação do objeto original.

#### Scenario: Deserializar documento do Firestore com todos os campos
- **WHEN** `GroupModel.fromMap(docId, data)` é chamado com um map completo
- **THEN** todos os campos são populados corretamente e `id == docId`

#### Scenario: Deserializar documento com campo ausente
- **WHEN** `GroupModel.fromMap(docId, data)` é chamado com `icon` ausente no map
- **THEN** `icon` assume valor default `'group'` sem lançar exceção

#### Scenario: Serializar para envio ao Firestore
- **WHEN** `groupModel.toMap()` é chamado
- **THEN** o mapa resultante NÃO contém a chave `id` e `createdAt` é uma instância de `Timestamp`

#### Scenario: Criar cópia com nome alterado
- **WHEN** `group.copyWith(name: 'Novo Nome')` é chamado
- **THEN** retorna nova instância com `name == 'Novo Nome'` e todos os demais campos inalterados
