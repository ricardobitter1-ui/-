## Context

Tarefas no Firestore usam `title` livre (capitalização e acentos preservados). Integrações e buscas por “nome” precisam de um campo derivado e determinístico para `where` sem depender do ID do documento.

## Goals / Non-Goals

**Goals:**

- Persistir `titleSearchKey` (ou nome equivalente acordado) junto de cada tarefa, sempre coerente com o `title` atual.
- Normalização: minúsculas e remoção de diacríticos (NFD + strip combining marks, ou pacote `diacritic`), com trim de espaços.
- UI continua mostrando apenas `title`.

**Non-Goals:**

- Unicidade global da chave por usuário ou por grupo (duas tarefas podem ter o mesmo título normalizado salvo que regra de negócio futura exija índice único).
- Full-text search nativo do Firestore (apenas campo escalar para igualdade/prefixo conforme necessidade).
- Alterar regras de segurança além do que já permita leitura/escrita dos campos da tarefa.

## Decisions

1. **Nome do campo no Firestore**: `titleSearchKey` (camelCase, alinhado a `ownerId`, `groupId`). Alternativa `searchKey` — menos específica; preferir `titleSearchKey` para deixar claro a origem.

2. **Onde calcular**: função pura `normalizeTitleSearchKey(String title)` chamada no cliente ao montar `TaskModel` para `addTask`/`updateTask` e, se necessário, ao ler documentos legados sem o campo (fallback na leitura ou primeira escrita).

3. **Dependência**: usar pacote `diacritic` (ou implementação manual com `characters`/Unicode) para manter comportamento estável entre plataformas; evitar regex frágil só para PT-BR.

4. **Título vazio**: chave vazia `''` ou rejeitar título vazio no formulário (manter comportamento atual do app); se título trim resultar vazio, chave vazia.

5. **Atualização**: sempre que `title` mudar em `updateTask`, recalcular e gravar `titleSearchKey`.

## Risks / Trade-offs

- **[Risco] Documentos antigos sem campo** → Mitigação: `_taskFromDoc` usa `data['titleSearchKey'] ?? normalize(data['title'])` para o modelo em memória; opcional script/admin ou “lazy write” no próximo update.

- **[Risco] Colisão de chaves** → Mitigação: documentar que integrações podem receber múltiplos documentos; resolução por contexto (`ownerId`/`groupId`) nas queries compostas.

- **[Trade-off] Tamanho do documento** → Campo string adicional pequeno; aceitável.

## Migration Plan

1. Deploy do app que passa a escrever `titleSearchKey` em create/update.
2. (Opcional) Job ou Cloud Function para backfill em lote; ou aceitar preenchimento gradual.
3. Rollback: versão anterior do app ignora campo extra; sem quebra.

## Open Questions

- Integrações futuras exigirão índice composto (`titleSearchKey` + `ownerId`)? Documentar quando a primeira query composta for definida.
