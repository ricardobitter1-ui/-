## 1. Fundamentos e preferências

- [x] 1.1 Definir chaves de `SharedPreferences` (ou API existente no app) para: Hoje inbox sem data, Hoje dia selecionado, e `group_{groupId}` para detalhe de grupo; documentar no código onde forem usadas.
- [x] 1.2 Implementar helper ou extensão para particionar `List<TaskModel>` em `(active, completed)` preservando ordem relativa do stream atual.

## 2. Componente de lista com seção de concluídas

- [x] 2.1 Extrair ou criar widget que renderiza bloco de tarefas ativas + cabeçalho colapsável + lista de concluídas (compatível com o padrão de scroll da tela: `Sliver` ou `ListView` conforme `home_screen` / `group_detail_screen`).
- [x] 2.2 Cabeçalho da seção concluídas: título acessível, indicador de expandido/recolhido, toque para alternar; persistir estado ao sair/voltar da tela.
- [x] 2.3 Quando não houver concluídas, não exibir seção vazia intrusiva (alinhar ao cenário da spec: só ativas ou empty state coerente).

## 3. Aba Hoje

- [x] 3.1 Aplicar o layout particionado à lista **sem data** (inbox) em `home_screen.dart` (ou equivalente), mantendo ações atuais de toggle/edit/delete.
- [x] 3.2 Aplicar o mesmo à lista do **dia selecionado** na aba Hoje, com chave de colapso independente da inbox.

## 4. Detalhe do grupo

- [x] 4.1 Aplicar o layout particionado à lista de tarefas em `group_detail_screen.dart`, com chave de colapso por `group.id`.
- [x] 4.2 Garantir que toggle de conclusão continue usando `firebaseService.toggleTaskCompletion` sem regressão.

## 5. Feedback visual e reduced motion

- [x] 5.1 Implementar transição ao mover item entre ativas e concluídas (abordagem escolhida no design: `AnimatedList` / slivers animados / ou realce curto com chave estável por `task.id`).
- [x] 5.2 Respeitar reduced motion: se `MediaQuery.disableAnimationsOf(context)` (ou equivalente do projeto) for verdadeiro, usar duração zero ou apenas mudança de estado sem deslocamento animado.
- [x] 5.3 Evitar duplicação visível do mesmo `task.id` nos dois blocos após o frame de atualização (cenário da spec `task-completion-feedback`).

## 6. Verificação

- [x] 6.1 Revisar acessibilidade básica: leitores de tela no cabeçalho da seção e no checkbox da tarefa.
- [x] 6.2 Testar manualmente: completar/descompletar em Hoje (inbox + dia) e em dois grupos distintos; colapso independente entre superfícies.

## 7. Opcional — após confirmar Fase 5 (tags) pronta

**Entregue após Fase 5.** Roadmap Fase 6 “combinar com tags”: área geral de concluídas + chips e filtro por tag sem subseções por tag na lista ativa.

- [x] 7.1 Na seção de concluídas (ou barra acima dela), exibir **chips** derivados das tags da tarefa (conforme modelo da Fase 5).
- [x] 7.2 Adicionar **filtro por tag** que restringe as concluídas exibidas a um recorte (uma tag selecionada / estado “todas”), sem criar uma subseção por tag na lista principal.
- [x] 7.3 Ajustar specs desta change ou delta na change de tags se o comportamento normativo cruzar as duas capabilities.
