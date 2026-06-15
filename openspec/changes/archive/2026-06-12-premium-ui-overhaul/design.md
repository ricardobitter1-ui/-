# Design: Premium UI Overhaul

## Context

Atualmente, o app usa o `AppTheme` padrão com a cor `primaryViolet`. A navegação é baseada em uma `HomeScreen` com `AppBar` e `ListView`. Os widgets de tarefas são cards brancos simples. O sistema de avatar no cabeçalho é apenas um ícone estático.

## Goals / Non-Goals

**Goals:**
- Implementar o Guia de Estilo Visual com foco em **Azul Royal** e **Preto Ônix**.
- Criar uma hierarquia tipográfica clara usando a fonte **Inter**.
- Desenvolver um sistema de **Fallback de Avatar** resiliente.
- Implementar o seletor de data horizontal dinâmico.

**Non-Goals:**
- Não implementar Dark Mode nesta fase.
- Não alterar a lógica de persistência do Firestore ou as regras de negócio de geofencing.

## Design Decisions

### 🎨 Foundation (Theming)
- **Primary Color**: Alterar `AppTheme.primaryViolet` para `#0052FF`.
- **Background**: Utilizar `#F8F9FF` para o scaffold, criando um contraste suave com os cards brancos.
- **Typography**: Configurar `GoogleFonts.interTextTheme()` como o tema de texto padrão no `MaterialApp`.

### 📱 Layout: HomeScreen 2.0
- **Custom Header**: Um widget customizado que não usa a `AppBar` padrão para permitir um layout de saudação ("Hello, [Name]") mais "solto" e a barra de progresso diário logo abaixo.
- **Timeline Selector**: Integração do package `easy_date_timeline` posicionado logo abaixo do header.
- **Focus Section**: Um card de destaque utilizando `Dark Surface (#121212)` para a tarefa mais urgente ou próxima do horário.

### 🧩 Components
- **TaskCard**: Refatoração completa para incluir `borderRadius: 24.0`, `boxShadow` com `blurRadius: 30.0` e opacidade de 3%.
- **CustomAvatar**: Widget que recebe um `User` (Firebase). 
  - Regra: `user.photoURL != null ? Image.network : Text(user.displayName[0])`.
- **DailyProgress**: Um bar indicator linear animado que reflete a saúde das tarefas do dia.

## Risks / Trade-offs

- **Performance de Assets**: O uso de múltiplas fontes via `google_fonts` e SVGs pode impactar levemente o primeiro carregamento.
- **Complexidade de Layout**: A remoção da `AppBar` padrão exige uma gestão manual da `SafeArea` e dos botões de ação do sistema.
