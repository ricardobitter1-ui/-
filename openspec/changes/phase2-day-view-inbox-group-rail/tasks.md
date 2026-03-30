## 1. Nomenclatura e shell

- [x] 1.1 Renomear rótulo (e, se necessário, ícone) da aba principal em `MainShell` de “Calendário” para o nome fechado no design (padrão: **Hoje**)
- [x] 1.2 Revisar strings relacionadas na UI (tooltips, títulos) para consistência com o novo nome

## 2. Dados e progresso por grupo / dia

- [x] 2.1 Definir função pura ou provider derivado: para um `DateTime` dia (sem hora) e lista de tarefas + grupos, calcular `{ total, completed }` por `groupId`
- [x] 2.2 Garantir que apenas tarefas com `dueDate` no dia selecionado entram no cálculo do rail (tarefas sem data ficam fora deste cálculo)

## 3. UI — rail de grupos

- [x] 3.1 Remover o bloco único “Tarefa em Foco” da tela principal
- [x] 3.2 Implementar faixa horizontal (`ListView`/`PageView` scroll horizontal) com card por grupo (nome/cor, barra ou fração de progresso)
- [x] 3.3 `onTap` → `Navigator.push` para `GroupDetailScreen` (ou rota existente) com o `GroupModel` correto
- [x] 3.4 Estados vazios: sem grupos; grupo sem tarefas no dia

## 4. UI — inbox (sem data)

- [x] 4.1 Integrar `atemporalTasksStreamProvider` (ou stream equivalente) na mesma tela
- [x] 4.2 Renderizar seção “Sem data” / Inbox com lista reutilizando `TaskCard` (ou componente existente) e ações coerentes (toggle, editar, excluir)
- [x] 4.3 Ordenar o scroll: header + date picker → rail de grupos → inbox sem data → lista do dia (ajustar se o design local pedir outra ordem, documentando no PR)

## 5. Polimento e roadmap

- [x] 5.1 Testar troca de dia: lista do dia + rail + inbox reagem corretamente
- [x] 5.2 Atualizar `openspec/roadmap.md` (Fase 2) para refletir entrega desta change
