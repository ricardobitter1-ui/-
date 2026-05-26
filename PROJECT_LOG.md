# PROJECT_LOG — Exm to do

Registro pessoal de decisões e estado do projeto.

---

## Log de decisões

### 2026-05-26 — Ditado em modo nota (`note_capture`)

**O que mudou**
- Novo modo de ditado: título **Área: problema** + **descrição** com polimento leve (mesma chamada LLM).
- Router: lembrete → nota → compras → general; grupo fixo já não assume compras.
- Grupos tipo Melhorias/Bugs/Ideias ou fala longa narrativa activam nota; supermercado mantém lista de produtos.

**Por que mudou**
- Melhorias e pontos pessoais precisam de contexto na descrição, não só título curto.
- Velocidade: zero chamadas LLM extra.

**O que aprendi**
- Router por nome de grupo + sinais na fala resolve sem multi-agente.

---

### 2026-05-26 — Ditado em lista de compras: título só com o produto

**O que mudou**
- Prompt específico para grupos de supermercado/mercado/compras quando uso o ditado dentro do grupo.
- Regra clara: cada tarefa criada deve ter só o nome do item ("Arroz", "Feijão"), nunca "Comprar arroz".
- Sanitizador depois do modelo que remove verbos como comprar, pegar, adicionar se o LLM ainda errar.
- Detecção automática pelo nome do grupo (supermercado, mercado, compras, feira, hortifruti, mercearia, etc.).

**Por que mudou**
- Uso muito o ditado no grupo de supermercado para falar vários itens de uma vez.
- Frases do tipo "adicione à lista arroz, macarrão e feijão" geravam tarefas "Comprar macarrão", "Comprar feijão" — ruim para lista de compras.
- O grupo já é o contexto de compra; o título precisa ser o produto em si.

**O que aprendi**
- O prompt genérico tende a transformar fala em "tarefa de ação" (verbo + objeto). Em lista de compras o formato certo é substantivo puro.
- Duas camadas ajudam: instrução forte no prompt + limpeza local depois, porque o modelo às vezes insiste no verbo.
- Não dá para tratar todo ditado com grupo fixo como compras — só grupos com nome de lista, senão estrago lembretes em outros grupos (ex.: "Comprar ração pro Chico").

---

## Estado atual

**App:** to-do com grupos, ditado por voz, etiquetas por grupo, lista particionada.

**Ditado por voz:**
- Lembrete com data/hora (fluxo próprio).
- Supermercado/mercado/compras: título = nome do produto.
- Nota/melhoria (Melhorias, Bugs, narrativa longa): título `Área: problema` + descrição polida; 1 tarefa por defeito, várias só com "outro ponto" etc.
- Outros grupos fixos: modo general (não compras automático).

**Validar no telefone (pendente):** ditado longo em Melhorias; supermercado e lembrete sem regressão (task 4.1 OpenSpec).

**Arquivos principais (voz):**
- `lib/business_logic/voice_note_capture_context.dart`
- `lib/business_logic/voice_intent_router.dart`
- `lib/constants/voice_task_extraction_prompt.dart`
- `lib/data/services/voice_task_pipeline.dart`
