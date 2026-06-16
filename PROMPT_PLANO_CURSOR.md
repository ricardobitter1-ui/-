# Prompt para o Cursor (Plan Mode)

Copie tudo abaixo da linha e cole no Cursor com o modo Plan ativado.

---

Você é o arquiteto técnico deste projeto Flutter (`lib/`, Riverpod + Firebase/Firestore). Leia primeiro o arquivo `AVALIACAO_UX.md` na raiz — ele é a fonte de verdade desta tarefa: contém a avaliação de usabilidade completa, os achados numerados (A1–D4) e um roadmap em 4 fases na seção 6.

**Sua missão:** transformar o roadmap da seção 6 em um plano de implementação estruturado e executável. NÃO escreva código ainda — apenas o plano.

**Explore antes de planejar.** Confirme no código os pontos citados na avaliação, no mínimo: `lib/ui/screens/home_screen.dart` (grid de cards, contagens), `lib/ui/screens/main_shell.dart`, `lib/ui/screens/filtered_task_list_screen.dart` (timeline), `lib/data/models/group_model.dart` (ausência de `type`), `lib/business_logic/voice_shopping_list_context.dart` (regex a substituir), `lib/ui/widgets/expandable_create_task_fab.dart`, `lib/ui/widgets/task_form_modal.dart`, `lib/business_logic/task_day_visibility.dart`, `lib/ui/widgets/partitioned_group_task_list.dart`, `firestore.rules` e `firestore-tests/`.

**Estruture o plano por fase (1 a 4), e para cada fase entregue:**

1. **Escopo** — quais achados da avaliação ela resolve (citar A1, B2 etc.).
2. **Mudanças por arquivo** — arquivo a arquivo, o que muda e por quê. Sinalize arquivos novos.
3. **Mudanças de dados** — campos novos no Firestore, valores default, atualização de `firestore.rules` e de `firestore.indexes.json` se necessário.
4. **Migração e retrocompatibilidade** — especialmente na Fase 2: grupos existentes sem `type` devem funcionar como `tasks`; planejar migração one-shot que usa o regex atual do `VoiceShoppingListContext` para *sugerir* conversão de grupos para lista contínua (decisão do usuário, não automática). Documentos antigos não podem quebrar (seguir o padrão de fallback já usado em `GroupModel.fromMap`).
5. **Ordem de commits/PRs** — passos pequenos e testáveis, cada um deixando o app funcional.
6. **Testes** — quais testes unitários criar/ajustar (o projeto já testa lógica em `business_logic/`; siga o padrão de injeção de `clock`/`now` existente) e o que validar manualmente.
7. **Critérios de aceite** — comportamento observável que define "pronto".
8. **Riscos e pontos de atenção** — ex.: contagens da home dependem de `tasksStreamProvider` compartilhado; o FAB é usado em 3 telas (home, lista filtrada, detalhe do grupo); o pipeline de voz tem `forcedGroupId`/`contextGroup` que precisam continuar funcionando.

**Decisões de design já tomadas (não reabrir):**
- Fase 2 usa campo `type` no `GroupModel` que mapeia para flags de comportamento (`continuous`, `defaultDueDate`, `countsInHome`, `completionLabel`, `progressCard`, `voiceMode`, `reAdd`) — ver tabela na seção 4.B da avaliação. Nada de `if (type == 'shopping')` espalhado: centralizar as flags em uma única classe de configuração por tipo.
- FAB: tap abre `TaskFormModal` com mic no campo de título; long-press inicia ditado direto.
- Apagar tarefa: remover dialog de confirmação, manter undo via snackbar.
- Idioma padrão dos textos: pt-BR.

**Decisões em aberto — liste-as no plano com sua recomendação e aguarde minha escolha antes de detalhar:**
- Quais templates de tipo entram na v1 (sugestão da avaliação: Tarefas, Lista contínua, Projeto, Rotina — avalie se Projeto/Rotina ficam para depois).
- O que fazer com o card "Todas" (reescopar vs. remover vs. virar busca).
- Onde a visão Calendário/Agenda vive após sair do card "Hoje".

**Formato de saída:** um plano em markdown com as fases como seções, tarefas numeradas com checkbox, e uma seção final "Decisões em aberto". Estime esforço relativo por tarefa (P/M/G). O plano deve permitir executar as fases em ordem, com a Fase 1 entregável de forma independente.
