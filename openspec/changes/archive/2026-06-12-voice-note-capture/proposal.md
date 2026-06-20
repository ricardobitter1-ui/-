# Proposal: Ditado em modo nota (título Área:problema + descrição)

## Why

O ditado por voz hoje funciona bem para **lembretes curtos** e **listas de compras**, mas falha quando o utilizador dita **notas mais longas** — melhorias de app, pontos pessoais com contexto, ou vários assuntos no mesmo áudio. O modelo tende a colocar tudo no `title` ou a ignorar `description` (hoje quase sempre vazia). O grupo "Melhorias" é o caso mais frequente, mas o comportamento deve ser **genérico**, não exclusivo de um grupo. A latência do fluxo de voz foi otimizada e **não pode regredir**; a solução deve manter **uma única chamada LLM** por ditado.

## What Changes

- Novo modo de extração **`note_capture`**: título no padrão **Área: problema**; `description` com **polimento leve** (mais sucinta que a transcrição, sem inventar factos).
- **Router** (`VoiceIntentRouter`) ampliado: detectar notas por **nome do grupo** (melhorias, bugs, ideias, etc.) e por **sinais na fala** (`porque`, `melhoria`, texto longo narrativo); deixar de tratar **todo** `hasForcedGroup` como fluxo de compras.
- Novo prompt de sistema **`kVoiceNoteCaptureExtractionSystemPrompt`** e ramo em `VoiceExtractPromptBuilder`.
- Regras de **split**: por defeito **1 tarefa**; várias tarefas só com marcadores claros de segundo assunto ("outro ponto", "também", "segunda coisa", numeração).
- Testes unitários para router, contexto de grupo nota e exemplos de ouro (JSON esperado documentado em spec).
- **Sem** segunda chamada LLM para classificar ou reescrever; **sem** regressão nos modos `reminder` e `shopping`.

## Capabilities

### New Capabilities

- `voice-note-capture`: Comportamento de ditado para notas/melhorias/pontos com detalhe — título, descrição polida, segmentação em múltiplas tarefas quando aplicável, integração com pipeline existente e restrições de latência.

### Modified Capabilities

- (Nenhuma spec existente em `openspec/specs/` para ditado; requisitos novos ficam na spec desta change.)

## Impact

- `lib/constants/voice_task_extraction_prompt.dart` — novo prompt `note_capture`.
- `lib/business_logic/voice_intent_router.dart` — novos modos/sinais; corrigir roteamento `hasForcedGroup`.
- `lib/business_logic/voice_note_capture_context.dart` (novo) — detecção de grupos/sinais de nota, espelhando padrão de `voice_shopping_list_context.dart`.
- `lib/data/services/voice/voice_extract_prompt_builder.dart`, `voice_extract_request.dart` — flag/modo nota.
- `lib/data/services/voice_task_pipeline.dart` — passar modo nota ao request e finalização de títulos.
- `test/voice_intent_router_test.dart`, `test/voice_note_capture_*` — cobertura e suíte de ouro.
- `PROJECT_LOG.md` — decisões já registadas; atualizar após implementação.
