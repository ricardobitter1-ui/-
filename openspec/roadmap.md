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

- **[ ] Navegação por Abas (Bottom Nav):** Implementar Dashboard e Calendário.
- **[ ] Dashboard de Entrada:** Criar seção de "Atemporais" (Tarefas sem data) e Lista de Grupos.
- **[ ] Calendário Premium:** Refinar o `Horizontal Date Picker` e a timeline diária.
- **[ ] CRUD de Grupos Elite:** Gestão de cores e ícones no Firestore.

---

## 🤝 Fase 3: Detalhes & Colaboração (PLANEJADO)
*Foco: Gestão profunda de grupos e UI avançada.*

- **[ ] Tela de Detalhe do Grupo:** Visualização completa de tarefas por grupo.
- **[ ] Sub-tarefas (Checklist):** Implementar suporte a sub-itens dentro de uma tarefa.
- **[ ] Glassmorphism UI:** Efeitos visuais premium nas transições e cards.
- **[ ] Gestão de Membros (Invite Flow):** Convite básico para grupos.

---

## 📈 Fase 4: Analytics & Automação (FUTURO)
- **[ ] Dashboard de Performance:** Estatísticas de produtividade (Statistics Screen).
- **[ ] Geofencing de Grupo:** Alertas por localização.


---

## 📝 Próximos Passos (Próxima Sprint)
1. **Implementar Update Task:** Criar a função no `FirebaseService` e a UI de edição.
2. **Polir TaskCard:** Adicionar campos de Horário e Prioridade.
3. **Setup Database Grupos:** Criar a estrutura para suportar múltiplos grupos por UID.
