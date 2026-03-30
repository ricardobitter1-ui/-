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

*Change Spark: `openspec/changes/group-invite-link-email/` (Firestore + cliente; sem Functions).*

- **[x] Link partilhável (URL):** Link com token `exmtodo://invite?…`, `app_links`, modal Aceitar/Recusar (`group-invite-link-email`). App Links HTTPS ficam como melhoria futura.
- **[x] Convite por e-mail (Spark):** UI por e-mail, `inviteeEmailLower`, modal ao abrir/retomar + inbox no perfil. **Pendente só com Blaze + Functions:** push/e-mail no servidor ao criar convite.
- **[x] CRUD de grupos (papéis):** Entregue com `group-crud-complete` (editar metadados; apagar para admin/dono; grupo pessoal protegido).

---



## 📈 Fase 5: Analytics & Automação (FUTURO)
- **[ ] Geofencing de Grupo:** Alertas por localização.


---

## 📝 Próximos Passos (Próxima Sprint)
1. **Implementar Update Task:** Criar a função no `FirebaseService` e a UI de edição.
2. **Polir TaskCard:** Adicionar campos de Horário e Prioridade.
3. **Setup Database Grupos:** Criar a estrutura para suportar múltiplos grupos por UID.
