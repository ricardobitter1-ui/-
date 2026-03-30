## Context

- Bottom nav já existe (Grupos / aba principal / Perfil). A aba principal hoje concentra saudação, date picker, um único card “em foco” e a lista do dia.
- Já existem streams no backend para tarefas do usuário e para tarefas **sem data** (`atemporalTasksStreamProvider` / `getAtemporalTasksStream`).
- Grupos já têm lista e detalhe; falta conectar **progresso visual por grupo** na entrada diária.

## Goals / Non-Goals

**Goals:**

- Renomear a aba principal de **“Calendário”** para um nome alinhado a **dia + tarefas** (proposta padrão neste design: **“Hoje”**; alternativa aceitável: **“Agenda”** — escolher uma e usar em todo o app).
- Manter **seleção de dia** e lista de tarefas cujo **`dueDate` cai no dia selecionado** (comportamento atual da lista filtrada por dia).
- Exibir **tarefas sem data** numa **seção “Inbox” / “Sem data”** na **mesma tela**, sempre acessível ao rolar (não escondidas atrás de outra aba).
- Substituir o card único “Tarefa em Foco” por um **carrossel horizontal** de cards — **um card por grupo** do usuário — com **progresso do grupo** calculado para o **dia atualmente selecionado** no date picker.
- **Toque no card** → `GroupDetailScreen` (ou rota equivalente) para aquele grupo.

**Non-Goals:**

- Novo modelo de dados Firestore (subcoleções, agregados server-side).
- Subtarefas, convites, glassmorphism (Fase 3+).
- Mudar regras de notificação ou CRUD de tarefas além do necessário para exibir listas.

## Decisions

| Decisão | Escolha | Alternativas | Racional |
|--------|---------|--------------|----------|
| Nome da aba | **“Hoje”** (padrão) | “Agenda”, “Dia” | Reflete “o que importa agora”; curto para bottom nav. |
| Onde ficam atemporais | Bloco **“Sem data”** abaixo do carrossel de grupos e **acima** (ou integrado ao scroll) da lista do dia | Aba separada; só no dia “hoje” | Roadmap pede “Dashboard de Entrada” + inbox visível sem trocar de aba. |
| Progresso no card do grupo | Tarefas com `groupId == grupo` e **`dueDate` no dia selecionado**; razão = concluídas / total | Progresso global do grupo | Coerente com “visualização por dia”; o date picker é a fonte da verdade temporal. |
| Card sem tarefas no dia | Mostrar **0/N ou barra vazia** + cópia curta (“Nada neste dia”) | Ocultar grupo | Mantém paridade de grupos e reforça o vínculo dia ↔ grupo. |
| Tarefas sem grupo no dia | Continuam só na **lista do dia** | Forçar grupo | Evita bloquear UX; cards são só para grupos. |
| Implementação do carrossel | `ListView` / `PageView` horizontal com altura fixa ou intrínseca, dentro de `CustomScrollView` + `SliverToBoxAdapter` | `Row` sem scroll | Performance e padrão mobile. |

## Risks / Trade-offs

- [Muitos grupos] → Mitigação: scroll horizontal nativo; opcional snap visual em iteração futura.
- [Duas fontes de stream: dia + atemporais] → Mitigação: reutilizar providers existentes; evitar queries compostas novas sem índice.
- [Nome “Hoje” vs dia selecionado passado/futuro] → Mitigação: título da seção do meio pode mostrar data formatada; a **aba** continua “Hoje” como marca da área principal.

## Migration Plan

- Implementar UI atrás da mesma rota/widget da aba central; atualizar `MainShell` labels/icons.
- Após validação manual, marcar itens correspondentes no `openspec/roadmap.md`.

## Open Questions

- Ícone da aba: manter `calendar_month` ou trocar para `today` / `event` alinhado ao novo nome (decidir na implementação).
