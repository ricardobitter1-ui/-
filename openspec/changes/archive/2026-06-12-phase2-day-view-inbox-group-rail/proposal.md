## Why

A Fase 2 do roadmap pede consolidar a **entrada do produto**: visão por dia, tratamento claro de **tarefas sem data** e ligação forte com **grupos**. Hoje a aba principal ainda se chama “Calendário” e o bloco “tarefa em foco” é único e desconectado dos grupos; precisamos alinhar UX, nomenclatura e modelo mental (dia + grupos + inbox).

## What Changes

- **Renomear** a aba (e o conceito na UI) que hoje é “Calendário” para um nome que reflita **visão do dia / agenda diária** (nome final definido no design; ex.: “Hoje” ou “Agenda”).
- Manter **seletor de data** e lista/timeline de tarefas **do dia selecionado** (tarefas com `dueDate` naquele dia).
- Introduzir tratamento explícito de **tarefas sem data (atemporais)** na **mesma tela**: seção dedicada (inbox) com regras de visibilidade e interação.
- **Substituir** o card único “Tarefa em Foco” por um **carrossel horizontal scrollável** de cards (um por **grupo** do usuário), cada um mostrando **progresso do grupo** no contexto do dia selecionado; **toque** navega para o **detalhe do grupo**.
- Atualizar o **roadmap** (Fase 2) para refletir itens concluídos ou replanejados quando esta change for implementada.

## Capabilities

### New Capabilities

- `day-view-tab`: Aba principal renomeada, visão por dia, integração com seletor de datas e seção de tarefas **sem data** na mesma tela.
- `group-progress-rail`: Faixa horizontal de cards por grupo com indicador de progresso (ligado ao dia selecionado) e navegação para a tela do grupo.

### Modified Capabilities

<!-- (vazio) — comportamento atual da Home/Calendário será substituído por esta change; não há spec arquivada em openspec/specs/ para delta. -->

## Impact

- UI: `HomeScreen` (ou equivalente da aba principal), `MainShell` (rótulo/ícone da aba), possivelmente `GroupDetailScreen` (entrada por deep link do carrossel).
- Dados: agregação de progresso por grupo e dia a partir de `TaskModel` / streams existentes (`ownerId`, `groupId`, `dueDate`, `isCompleted`).
- Cópia do produto: strings em PT-BR e consistência com bottom nav.
