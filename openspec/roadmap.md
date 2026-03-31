# Roadmap de Produto: Exm To-Do (Visual Excellence Edition) 🚀

Como Product Manager Sênior, este roadmap foca na criação de uma plataforma de produtividade premium, onde a **Excelência Visual** e a **Identidade do Usuário** são os pilares para uma retenção de longo prazo.

---

## 🏔️ Visão Geral
**Objetivo:** Transformar o gerenciamento de tarefas em uma experiência lúdica e estética, utilizando gamificação, design system moderno (Glassmorphism) e colaboração fluida em Grupos de Elite.

---

## ✅ Fase 1: Identidade Intelectual & Fundamentos (CONCLUÍDA)
*Meta: Sair do "UID anônimo" para uma experiência personalizada.*

- **[x] Firebase Auth Expandido:** Login (Google/Email) capturando `displayName`, `photoUrl`.
- **[x] Saudação Dinâmica e Perfil:** UI da Home com "Olá, [Name]" e avatar.
- **[x] Auth Wrapper & Security:** Redirecionamento de sessão e proteção de dados.
- **[x] Design System Core (Tokens):** Cores, gradientes e sombras premium.

---

## 🚀 Fase 2: Estrutura Base & Grupos de Elite (EM PROGRESSO)
*Foco: Consolidar a navegação e visualização por contextos.*

- **[x] Navegação por Abas (Bottom Nav):** Grupos, perfil e aba principal **Hoje** (antes “Calendário”).
- **[x] Dashboard de Entrada:** Seção **Sem data** (atemporais) na aba Hoje + faixa horizontal de **progresso por grupo** no dia selecionado (toque → detalhe do grupo).
- **[x] CRUD visual completo de Grupos Elite:** Criar, **editar** nome/cor/ícone (sheet no detalhe) e **apagar** (admin/dono, não pessoal). Change: `openspec/changes/group-crud-complete/`.

---

## 🤝 Fase 3: Colaboração em Grupos & Segurança (BASE ENTREGUE)
*Change de referência: `openspec/changes/group-sharing-collaboration/` (proposal, design, specs, tasks).*

*Meta: Membros, convites com aceite obrigatório, responsáveis em tarefas de grupo, regras no Firestore e base para push.*

### Entregue na implementação atual

- **[x] Modelo de dados:** `admins`, `isPersonal`, `members`; convites em `groupInvites`; tarefas com `assigneeIds` e `createdBy`.
- **[x] Firestore Security Rules:** Grupos, convites, tarefas (incl. validação de assignees), tokens FCM em `users/{uid}/fcmTokens/*`; deploy documentado (`firebase/README.md`).
- **[x] Queries de tarefas:** Leitura combinada sem `OR` no Firestore (merge de streams) para compatibilidade com as rules; stream direto por `groupId` no detalhe do grupo.
- **[x] Backfill:** Grupos legados (ex. "Pessoal" sem `members`) e marcação de grupo pessoal ao login.
- **[x] Convites (MVP):** Criação por **UID** (temporário), aceite em dois passos, recusa; inbox na aba **Perfil**.
- **[x] Partilha (MVP):** Copiar **ID** do grupo (placeholder até haver link URL).
- **[x] Admin de equipa:** Remover membros (exceto dono); convidar (MVP por UID); lista de membros no detalhe.
- **[x] Responsáveis na tarefa:** Seleção entre membros do grupo no formulário; persistência em `assigneeIds`.
- **[x] FCM (cliente):** Registo de token ao entrar; refresh associado à conta.
- **[x] Exclusão de grupo:** **Dono ou admin** pode apagar grupos **não pessoais** (rules + UI; `group-crud-complete`).

### Pendências da mesma change (técnico / backlog da proposta)

- **[ ] Cloud Functions:** Callables opcionais, rate limit, trigger de push em `tasks` (ver `tasks.md` §3 e `functions/README.md`).
- **[ ] App Check** (opcional).
- **[ ] Lembretes no servidor** para assignees (Scheduler / batch), além do lembrete local no dispositivo do criador.

### Fase 4 — Continuação (produto prioritário)

*Change Spark (arquivada): `openspec/changes/archive/2026-03-30-group-invite-link-email/` (Firestore + cliente; sem Functions).*

- **[x] Link partilhável (URL):** Link com token `exmtodo://invite?…`, `app_links`, modal Aceitar/Recusar (`group-invite-link-email`). App Links HTTPS ficam como melhoria futura.
- **[x] Convite por e-mail (Spark):** UI por e-mail, `inviteeEmailLower`, modal ao abrir/retomar + inbox no perfil. **Pendente só com Blaze + Functions:** push/e-mail no servidor ao criar convite.
- **[x] CRUD de grupos (papéis):** Entregue com `group-crud-complete` (editar metadados; apagar para admin/dono; grupo pessoal protegido).

---

## 🏷️ Fase 5: Tags e agrupamento de tarefas (MACRO)
*Visão de produto acordada em discussão; **specs por capability** e changes OpenSpec ficam para etapa seguinte com agentes.*

**Escopo e regras de negócio (macro)**

- **Tags por grupo:** vocabulário e documentos de tag pertencem a um `groupId`; não há tag “global” compartilhada entre grupos como mesma entidade.
- **Criação:** qualquer **membro do grupo** pode criar tag (detalhe de UI e validação na spec).
- **Opcionalidade:** tarefa **pode não ter tag**; com várias tags na mesma tarefa, a spec deve definir como a lista agrupada se comporta (ex.: aparecer sob cada tag, ordem, bucket “sem tag”).
- **Múltiplas tags por tarefa:** permitido; combinação com filtros e agrupamento será detalhada nas specs.
- **Cor por tag:** sim, com **escolha livre** (paleta, color picker ou equivalente — a definir na spec de UI).
- **Reuso “de outro grupo” (modelo A):** fluxo de produto apenas **sugere / copia o rótulo** (e opcionalmente a cor); ao aplicar no grupo atual cria-se uma **nova tag com novo id** no grupo atual — **sem** referência cruzada de documentos entre grupos.
- **Privacidade / visibilidade:** sugestões e dados de tag só a partir de grupos em que o usuário **é membro**.

**Backlog técnico implícito (para as specs)**

- Modelo Firestore (ex.: coleção ou subcoleção de tags por grupo, campos em `Task` para ids de tags), **Security Rules** alinhadas a membro do grupo, migração de tarefas existentes sem tag, telas: gestão leve de tags, seletor no formulário de tarefa, lista do grupo agrupada por tag.

**Entregue (change `group-task-tags`, implementação no cliente + rules)**

- Subcoleção `groups/{groupId}/tags/{tagId}` com `name` e `color`; rules para membros; `tasks.tagIds` validado (máx. 10, ids existentes; tarefas pessoais sem `tagIds`).
- `TagModel`, `TaskModel.tagIds`, `FirebaseService` (stream, CRUD de tags, `deleteGroupTag` com limpeza em batches), `groupTagsStreamProvider`.
- `TaskFormModal`: etiquetas para tarefas de grupo (incl. edição pela Home com `groupId`), nova etiqueta com paleta, sugestões de outros grupos (cópia modelo A).
- Detalhe do grupo: `PartitionedGroupTaskList` agrupa pendentes por etiqueta (A–Z) + **Sem etiqueta**; concluídas mantêm secção colapsável existente; menu **Gerir etiquetas** para apagar.

---

## ✅ Fase 6: Tarefas concluídas e UX de conclusão (MACRO)
*Complementa a Fase 5 na experiência de lista; specs detalhadas depois.*

- **Hoje:** concluir risca a tarefa **no mesmo lugar**; **desejo de produto:** mover o foco para um **agrupamento dedicado** a concluídas (ex.: seção no fim, colapsável — formato exato na spec).
- **Animação** ao marcar como concluída (transição clara para o bloco de concluídas); na implementação, respeitar **redução de movimento** do sistema quando aplicável.
- **Combinar com tags:** manter uma **área geral de concluídas** como eixo simples; uso de **chips de tag** e **filtro por tag** para obter o equivalente a “concluídas por recorte” sem multiplicar seções por tag na UI principal (detalhe em spec).

---

## 📈 Fase 7: Analytics e automação (FUTURO)
- **[ ] Geofencing de grupo:** alertas por localização.
- **[ ] Analytics** (métricas de uso, funis — a definir).
- **[ ] Automação** (integrações, rotinas — a definir).

---

## 📝 Próximos passos (para trabalho com agentes)
1. **Fase 5:** change `openspec/changes/group-task-tags/` implementada no código; fazer **deploy** das `firestore.rules` (`firebase deploy --only firestore:rules`). Arquivar a change com `/opsx:archive` quando validado em dispositivo.
2. **Fase 6:** abrir change para lista concluídas + animação + refinamentos com tags (filtros, etc.), conforme macro acima.
3. **Dependências:** Fase 6 pode ser change separada da Fase 5 já entregue.
4. Itens históricos da sprint antiga (Update Task, TaskCard, DB grupos) **arquivar ou revisar** contra o estado atual do repositório antes de priorizar junto com as novas fases.
 