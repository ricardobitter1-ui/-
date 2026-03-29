# Mapa de Navegação: Exm To-Do 🗺️

Este documento define a hierarquia de telas e o fluxo de navegação do aplicativo, focando em uma experiência premium e intuitiva.

## 📱 Telas Principais (Bottom Navigation)

### 1. Dashboard (Home)
- **Objetivo:** Entrada principal e visão de "Inbox".
- **Conteúdo:**
  - Header com Avatar e Perfil.
  - Barra de Progresso Diário (Global).
  - **Seção "Atemporais":** Lista compacta de tarefas sem data definida.
  - **Seção "Meus Grupos":** Cards horizontais dos Elite Groups (Trabalho, Pessoal, etc).
  - Botão Flutuante [+] para criação rápida.

### 2. Calendário (Focus View)
- **Objetivo:** Planejamento e execução do dia a dia.
- **Conteúdo:**
  - Seletor de data horizontal (Estilo a imagem de referência).
  - Timeline vertical com as tarefas agendadas por horário.

---

## 📂 Telas Secundárias (Navegação de Fluxo)

### 3. Detalhe do Grupo (Elite Space)
- **Acesso:** Via clique em um card de grupo no Dashboard.
- **Conteúdo:**
  - Header com cor/ícone do grupo e progresso específico.
  - Lista completa de todas as tarefas daquele grupo (filtráveis).
  - Gestão de membros (Invite Flow).

### 4. Formulário de Tarefa (Modal Premium)
- **Acesso:** Botão [+] em qualquer tela.
- **Funcionalidade:** Criação e edição de tarefas, com opção de deixar "Sem Data" para cair no Dashboard.

---

## 🔄 Fluxo de Usuário (User Journey)

1. **Dashboard** -> Clique em Grupo -> **Group View** -> Clique em Tarefa -> **Edição**.
2. **Dashboard** -> Clique em [+] -> **Form Modal** (Sem Data) -> Volta para **Dashboard** (aparece no Inbox).
3. **Calendário** -> Seleciona dia -> Vê Timeline -> Clique em [+] -> **Form Modal** (Com Data) -> Volta para **Calendário**.
