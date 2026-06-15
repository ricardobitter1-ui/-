# Tasks: Ditado em modo nota (`voice-note-capture`)

## 1. Contexto e modo

- [x] 1.1 Criar `lib/business_logic/voice_note_capture_context.dart` com `isNoteCaptureGroupName` e `shouldUseNoteCapture` (grupo + sinais na transcrição)
- [x] 1.2 Adicionar `VoiceExtractMode.noteCapture` e flag `noteCapture` / `shoppingListItemTitles` em `VoiceExtractRequest`
- [x] 1.3 Adicionar `kVoiceNoteCaptureExtractionSystemPrompt` em `voice_task_extraction_prompt.dart` (título Área:problema, descrição polida leve, split conservador)

## 2. Router e pipeline

- [x] 2.1 Refatorar `VoiceIntentRouter.classify`: prioridade reminder → note → shopping → general; corrigir `hasForcedGroup` ≠ shopping automático
- [x] 2.2 Ligar `VoiceExtractPromptBuilder` ao modo nota + linha de hint no user content
- [x] 2.3 Em `voice_task_pipeline.dart`, calcular `noteCapture` e passar ao request; `_finalizeExtractedTasks` com ramo nota (sem sanitizar descrição agressivamente)

## 3. Testes

- [x] 3.1 `test/voice_note_capture_context_test.dart` — nomes de grupo (Melhorias, Supermercado, Chico)
- [x] 3.2 Actualizar `test/voice_intent_router_test.dart` — melhorias forced vs supermercado vs lembrete no grupo
- [x] 3.3 `test/voice_note_capture_golden_test.dart` — `ExtractedVoiceTaskDto.parseTasksJson` com payloads exemplo (1 nota, 2 notas, descrição polida)
- [x] 3.4 Regressão: correr testes existentes de voz (shopping, reminder, sanitizer)

## 4. Verificação manual e docs

- [ ] 4.1 Testar no dispositivo: melhoria longa (1 tarefa, título + descrição); 2 pontos com "outro ponto"; supermercado e lembrete sem regressão
- [x] 4.2 Confirmar `VoicePerfLogger` / tempo percebido ≈ fluxo actual (sem 2ª chamada extract)
- [x] 4.3 Actualizar `PROJECT_LOG.md` (Estado atual) após implementação
