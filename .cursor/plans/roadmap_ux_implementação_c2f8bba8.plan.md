---
name: Roadmap UX Implementação
overview: Transformar o roadmap da seção 6 do AVALIACAO_UX.md em um plano executável por fase (1 a 4), com Fase 1 entregável de forma independente, centralizando o comportamento de tipo de grupo em uma classe de configuração de flags e mantendo retrocompatibilidade total dos documentos existentes no Firestore.
todos:
  - id: fase1
    content: Fase 1 — Correções rápidas na home (A1, A3, A2-parcial, A6, A7, D1, D2/D3); entregável independente
    status: completed
  - id: fase2
    content: Fase 2 — Tipo de grupo + completedAt + edição de tipo (B1-B4)
    status: completed
  - id: fase3
    content: Fase 3 — Fluxo de entrada (C1, C2, C4)
    status: completed
  - id: fase4
    content: Fase 4 — FCM, atividade, Calendário, busca, convite direto (D4, A4/A5, B5)
    status: completed
  - id: decisoes
    content: Decisões resolvidas — templates v1, Todas→busca F4, Calendário no header
    status: completed
isProject: false
---

# Plano de Implementação — Roadmap UX (Exm to do)

Plano derivado da seção 6 do [AVALIACAO_UX.md](AVALIACAO_UX.md). Esforço: **P** (pequeno), **M** (médio), **G** (grande).

Decisões fixadas: tipo via flags centralizadas; FAB tap=formulário+mic / long-press=ditado; apagar=só undo; pt-BR.

---

## Decisões resolvidas

1. **Templates v1:** só **Tarefas** + **Lista contínua** na Fase 2; `project`/`routine` reservados no enum, sem UI.
2. **Card "Todas":** Fase 1 reescopa para ativas; Fase 4 remove do grid e vira **busca**.
3. **Calendário:** ícone no header (placeholder Fase 1 → `TaskFilterType.scheduled`); visão própria na Fase 4.

---

## Fase 1 — Correções rápidas na home (entregável independente)

**Escopo:** A1, A3, A2 (parcial), A6, **A7**, D1, D2/D3.

### Mudanças por arquivo
- [ ] **1.1 (M)** Novo `lib/business_logic/home_counts.dart`: `pendingTodayCount`, `pendingScheduledCount`, `pendingAllCount` com `now` injetável.
- [ ] **1.2 (M)** [home_screen.dart](lib/ui/screens/home_screen.dart): usar home_counts nos cards (A3, A2 parcial).
- [ ] **1.3 (G)** [home_screen.dart](lib/ui/screens/home_screen.dart): seção "Atrasadas (N)" inline (A1).
- [ ] **1.4 (M)** "Reagendar todas" — lógica pura + UI; só tarefas pontuais.
- [ ] **1.5 (P)** Header: remover logout; ícone calendário → `TaskFilterType.scheduled` (placeholder).
- [ ] **1.6 (P)** [profile_screen.dart](lib/ui/screens/profile_screen.dart): "Sair" com confirmação (A6).
- [ ] **1.7 (M)** Remover dialog de apagar em home/filtered/partitioned (D1).
- [ ] **1.8 (P)** Textos pt-PT → pt-BR e jargão (D2/D3).
- [ ] **1.9 (P)** **A7:** remover sheet bloqueante do `initState` da home; pedir permissão ao salvar primeira tarefa com lembrete ([task_form_modal.dart](lib/ui/widgets/task_form_modal.dart) / [task_schedule_dialog.dart](lib/ui/widgets/task_schedule_dialog.dart)); fallback reapresentável no Perfil.

### Ordem de commits
1. 1.8 → 2. 1.5+1.6 → 3. 1.7 → 4. 1.1+1.2 → 5. 1.3 → 6. 1.4 → 7. 1.9

### Testes
- [ ] `test/home_counts_test.dart`
- [ ] `test/reschedule_overdue_batch_test.dart` (se lógica pura extraída)
- [ ] Manual conforme critérios de aceite

---

## Fase 2 — Tipo de grupo (mudança estrutural)

**Escopo:** B1-B4 + **completedAt** + **conversão de tipo no EditGroupSheet**.

### Mudanças por arquivo
- [ ] **2.1-2.3** enum `GroupType` (tasks, continuous; project/routine reservados), `GroupTypeConfig`, `GroupModel.type`.
- [ ] **2.4** templates na criação ([create_group_sheet.dart](lib/ui/widgets/create_group_sheet.dart)).
- [ ] **2.5** `firebase_service`: `addGroup` grava `type`; `updateGroupType`.
- [ ] **2.5b (M)** [edit_group_sheet.dart](lib/ui/widgets/edit_group_sheet.dart): seletor "Tipo de lista" (admin), reusando templates do 2.4 — não só migração sugestiva.
- [ ] **2.6** card por tipo em [groups_screen.dart](lib/ui/screens/groups_screen.dart).
- [ ] **2.6a (M)** **completedAt:** campo `completedAt: Timestamp?` em [task_model.dart](lib/data/models/task_model.dart); gravado em [complete_task_action.dart](lib/business_logic/complete_task_action.dart) / `toggleTaskCompletion` ao concluir, `null` ao reabrir; fallback `null` em docs antigos. Rules: campo opcional em tasks.
- [ ] **2.7** "Comprados recentemente" em [partitioned_group_task_list.dart](lib/ui/widgets/partitioned_group_task_list.dart); ordenação v1 por `completedAt` desc (legados sem campo → fim).
- [ ] **2.8** `countsInHome` em home_counts.
- [ ] **2.9** voz lê tipo (não regex).
- [ ] **2.10** firestore.rules: `type` em metadata update.
- [ ] **2.11** migração sugestiva one-shot.

### Ordem de commits
1. 2.1+2.2 → 2. 2.3 → 3. 2.10 → 4. 2.5 → 5. 2.4 → 6. **2.5b** → 7. 2.6 → 8. 2.8 → 9. **2.6a** (completedAt + rules) → 10. **2.7** → 11. 2.9 → 12. 2.11

### Testes
- [ ] `test/group_type_config_test.dart`, `test/group_model_type_test.dart`
- [ ] `test/task_completed_at_test.dart` — concluir grava timestamp; reabrir limpa
- [ ] `test/home_counts_test.dart` — exclusão continuous
- [ ] firestore-tests — `type` e `completedAt` opcional

---

## Fase 3 — Fluxo de entrada

(Sem alteração — C1, C2, C4)

Ordem: 3.1 → 3.2 → 3.3 → 3.4

---

## Fase 4 — Colaboração de verdade

**Escopo:** D4, atividade, A4/A5, **B5**.

### Mudanças adicionais
- [ ] **4.5 (P)** **B5:** "Copiar link de convite" gera convite+link em um passo; e-mail opcional (inverter fluxo atual em group_detail).
- [ ] **4.4** remover card "Todas" do grid; função vira busca.
- [ ] **4.3** visão Calendário/Agenda própria (ícone do header).

Ordem sugerida: 4.5 (independente) pode entrar cedo na fase; 4.1 FCM → 4.2 atividade → 4.3 calendário → 4.4 nova home.

---

## Riscos globais

- `tasksStreamProvider` compartilhado — centralizar filtros em helpers.
- FAB em 3 telas — manter callbacks.
- Pipeline voz: `forcedGroupId`/`contextGroup` intactos na Fase 2.
