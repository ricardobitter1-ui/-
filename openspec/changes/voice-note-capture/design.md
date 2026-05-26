# Design: Ditado em modo nota (`note_capture`)

## Context

O pipeline de voz actual:

```
Áudio → Groq STT → VoiceIntentRouter (regex) → prompt → 1× LLM → sanitizar → Firestore
```

Modos existentes:

| Modo | Prompt | title | description |
|------|--------|-------|-------------|
| `reminder` | curto + heurística local | acção curta | vazia |
| `shopping` | lista de compras | só produto | vazia |
| `general` | genérico | acção/lembrete | quase sempre vazia |

Problemas actuais relevantes:

1. `hasForcedGroup == true` (ditado dentro de **qualquer** grupo) força `intentLabel: shopping_llm` no router, mesmo em "Melhorias".
2. O campo `description` existe em `ExtractedVoiceTaskDto` e persiste em `TaskModel`, e o `TaskCard` já mostra descrição quando não vazia — falta só extração correcta.
3. Latência foi optimizada (uma chamada LLM principal); utilizador não aceita regressão para 15–30s.

Restrição herdada da explore: **sem** segunda chamada LLM para classificar ou reescrever descrição.

## Goals / Non-Goals

**Goals:**

- Modo `note_capture` com título **Área: problema** e `description` com **polimento leve** na mesma resposta JSON.
- Router que escolhe `note_capture` vs `shopping` vs `reminder` sem LLM extra (regex + hint de nome de grupo + sinais na transcrição).
- Por defeito **1 tarefa** por áudio; **N tarefas** só com marcadores explícitos de segundo assunto.
- Manter **uma chamada LLM** por ditado (excepto tag LLM de compras, inalterada).
- Testes unitários + suíte de ouro documentada na spec.

**Non-Goals:**

- Segunda chamada LLM "revisor" ou classificador.
- Reescrita pesada / resumo agressivo da descrição.
- Datas em notas (v1): notas ficam sem `date`/`time` salvo router encaminhar para `reminder` (frase com lembrete claro).
- Configuração UI de "tipo de grupo" pelo utilizador (v1 usa heurística de nome).
- Alterar UI do `TaskCard` (já suporta descrição).

## Decisions

### D1 — Novo `VoiceExtractMode.noteCapture`

**Decisão:** Adicionar `noteCapture` ao enum; `VoiceExtractPromptBuilder.systemPromptFor` devolve `kVoiceNoteCaptureExtractionSystemPrompt` quando `request.noteCapture == true` (ou `mode == noteCapture`).

**Rationale:** Prompts separados evitam regressão em compras/lembretes (lição do `kVoiceShoppingListExtractionSystemPrompt`).

### D2 — Detecção de contexto nota (`VoiceNoteCaptureContext`)

**Decisão:** Ficheiro espelhando `voice_shopping_list_context.dart`:

- `isNoteCaptureGroupName(name)` — regex em nomes: `melhoria(s)`, `bug(s)`, `ideia(s)`, `backlog`, `anotac`, `nota(s)`, etc.
- `shouldUseNoteCapture({ forcedGroupName, contextGroupName, transcript })` — true se grupo for nota **OU** (transcrição longa + sinais narrativos sem ser lista de compras).

Sinais de fala (exemplos): `\b(porque|melhoria|bug|quando eu|precisa|problema|anotar)\b`, `wordCount > 20`, e **não** match de padrão de lista de produtos.

**Rationale:** Melhorias é o caso frequente, mas pontos pessoais na Home também devem activar nota.

### D3 — Corrigir router `hasForcedGroup`

**Decisão:** Ordem de prioridade no `VoiceIntentRouter.classify`:

1. Se lembrete claro (padrão existente) e não lista de compras → `reminder` (mantém regra actual de palavras).
2. Se `shouldUseNoteCapture` → `noteCapture` / `note_llm`.
3. Se `shouldUseShoppingItemTitles` ou cues de compra + forced group → shopping (comportamento actual de supermercado).
4. Se `hasForcedGroup` sem nota nem compra → `general` (não `shopping_llm`).
5. Resto: regras actuais (lista longa, separadores).

**Rationale:** Corrige bug conceptual de tratar todo grupo fixo como compras.

### D4 — Título e descrição (prompt)

**Título:**

- Formato `Área: problema` (dois segmentos separados por `: `).
- Área = componente/ecrã/domínio inferido (Snackbar, Login, Hoje, Pessoal).
- Problema = frase curta (máx. ~8–10 palavras após o `:`).

**Descrição (polimento leve, mesma chamada LLM):**

- 1–4 frases em PT-BR.
- Remover muletas ("né", "tipo", "então"), repetições e meta-fala ("tenho uma melhoria que").
- **Preservar** factos: o quê, porquê, quando ocorre, expectativa.
- **Proibido** inventar requisitos ou alterar o sentido.
- Não repetir o título integral.

**Quando `description` vazia dentro de `note_capture`:** frase já cabe no título e não há contexto extra (raro); preferir pelo menos uma frase se houve "porque".

### D5 — Segmentação multi-nota

**Decisão:** Default `tasks.length == 1`. Criar N>1 só se transcrição tiver marcadores fortes:

- `outro ponto`, `também`, `segunda coisa`, `além disso`, `primeiro… segundo…`, numeração explícita.

**Não** partir só por vírgulas ou um "e" no meio de uma explicação única.

**Rationale:** Utilizador disse que na maioria fala uma melhoria por áudio; split conservador evita ruído.

### D6 — Performance

**Decisão:**

- Zero chamadas LLM adicionais.
- Prompt de nota conciso (não duplicar todas as regras de compras).
- Não invocar `assignShoppingTags` no fluxo nota (já gated por grupo compras).

**Métrica:** `VoicePerfLogger` — comparar `llm_extract_tasks` antes/depois em áudios de teste; não deve subir de forma material.

### D7 — Finalização pós-LLM

**Decisão:** Em `_finalizeExtractedTasks`, quando `noteCapture`:

- Aplicar `VoiceTaskTitleSanitizer.sanitize` no title (datas/horas raras).
- Opcional: validar presença de `:` no título; se ausente, não falhar — aceitar título único segmento.
- Não truncar `description` no cliente no v1 (confiar no prompt); se > N chars no futuro, backlog.

### D8 — Testes

**Decisão:**

- `test/voice_note_capture_context_test.dart` — nomes de grupo.
- `test/voice_intent_router_test.dart` — casos melhorias vs supermercado vs lembrete no grupo.
- `test/voice_note_capture_golden_test.dart` — parsing de JSON exemplo (sem chamar API) OU fixtures de `ExtractedVoiceTaskDto.parseTasksJson` com payloads esperados documentados na spec.

## Risks / Trade-offs

| Risco | Mitigação |
|--------|-----------|
| Título sem padrão `Área: problema` | Prompt + exemplos no user content; testes golden |
| Descrição inventada pelo modelo | Instrução "não inventar"; testes com transcrições reais |
| Split excessivo em uma nota longa | Marcadores conservadores; cenário na spec |
| Grupo "Melhorias" com lista de produtos falada por engano | Priorizar shopping se cues de compra explícitas |
| Prompt maior → latência | Prompt dedicado enxuto; monitorar `llm_extract_tasks` |
| Regressão lembrete no grupo Melhorias | "me lembre…" continua a sair por `reminder` antes de nota |

## Migration Plan

1. Implementar router + context + prompt.
2. Correr testes existentes de voz + novos.
3. Teste manual: supermercado (regressão), lembrete, melhoria longa 1 tarefa, 2 melhorias no mesmo áudio.
4. Actualizar `PROJECT_LOG.md` após apply.

Rollback: feature flag não necessária no v1; revert do PR desactiva modo nota.

## Open Questions

- (Fechado) Descrição: polimento leve na mesma chamada — sim.
- (Fechado) v1 sem data em notas salvo reminder — sim.
- Lista exacta de substrings de grupo pode crescer com uso real (documentar em `VoiceNoteCaptureContext`).
