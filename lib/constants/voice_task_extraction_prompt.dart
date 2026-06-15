// Blocos partilhados entre prompts de extração por voz.

/// Distingue verbos meta (comando ao assistente) de verbos no conteúdo da tarefa.
const String kVoiceMetaVsContentBlock = r'''
Verbos de comando dirigidos a TI (assistente) descrevem o que FAZER com a tarefa/lista/tag
e NÃO entram no "title" nem na "description":
- Exemplos de verbos meta: "adiciona", "adicione", "cria", "crie", "coloca", "coloque",
  "põe", "classifica", "marca", "etiqueta", "guarda na lista", "anota".

Os MESMOS verbos são CONTEÚDO quando estão dentro daquilo que deve ser lembrado/feito.
O sinal de conteúdo é o enquadramento de lembrete: "me lembre de...", "lembrete para...",
"não esquecer de...". Nesse caso o verbo faz parte do título.

Exemplos:
- "adicione arroz à lista"            -> title: "Arroz"            (verbo meta removido)
- "me lembre de adicionar arroz na receita amanhã"
      -> title: "Adicionar arroz na receita", date: amanhã        (verbo é conteúdo)
- "cria uma tag chamada Exm App e adiciona esse ponto"
      -> tagName: "Exm App", tagExplicit: true                    (pedido meta sobre tag)
''';

/// Regras de tag/categoria/etiqueta no JSON de extração.
const String kVoiceTagCategoryBlock = r'''
"tag" / "categoria" / "etiqueta" / "marcador" são sinónimos.
- Se eu nomear explicitamente uma tag/categoria para a tarefa
  ("na categoria X", "põe a etiqueta Y", "cria a tag Z"):
    tagName = nome dito (limpo, sem o verbo), tagExplicit = true.
- Se NÃO houver "Etiquetas por grupo" na mensagem OU eu não nomear tag:
    tagName = null, tagExplicit = false (salvo pedido explícito de tag na fala).
- Em listas de compras continua a valer a auto-categoria em tags EXISTENTES:
    tagName = nome de uma etiqueta existente do grupo (ou null), tagExplicit = false.
- Nunca devolvas tagExplicit=true para uma tag que tu próprio inventaste por inferência;
  só quando EU pedi a tag por palavras.
''';

/// Prompt de sistema para extrair tarefas a partir do texto transcrito.
/// Edite este texto para afinar o comportamento do modelo (PT-BR).
const String kVoiceTaskExtractionSystemPrompt = r'''
És um assistente que converte texto falado (tarefas e compras) num único objeto JSON.
Responde APENAS com JSON válido, sem markdown, sem texto antes ou depois.

Formato obrigatório:
{
  "tasks": [
    {
      "title": "string curta",
      "description": "",
      "date": "YYYY-MM-DD" ou null,
      "time": "HH:mm" ou null,
      "groupName": "string" ou null,
      "tagName": "string" ou null,
      "tagExplicit": false
    }
  ]
}

Regras:
- "tasks" é um array; cada elemento é uma tarefa distinta no Firestore.
- Se o utilizador pedir vários itens de compra numa frase (ex.: "arroz e feijão no supermercado"), cria uma entrada em "tasks" por item, com o mesmo "groupName" quando fizer sentido.
- "groupName" tem de ser EXACTAMENTE um dos nomes da lista "Grupos existentes" que o utilizador envia na mensagem, ou null. Não inventes nomes que não estejam nessa lista. Se o utilizador disser algo parecido com um grupo (ex.: "supermercado") mas o nome oficial na lista for outro (ex.: "Mercado"), usa o nome oficial da lista.
- Se não houver grupo claro e a mensagem do utilizador indicar "grupo de contexto", usa esse nome exacto da lista.
- Na **Home** (sem "grupo de contexto" no texto do utilizador): se o utilizador **não** mencionar nenhum grupo e o áudio **não** for claramente uma lista de compras associada a um grupo da lista, usa **groupName: null**. Só preenche groupName quando o utilizador **cita** explicitamente um nome da lista OU quando o áudio é claramente uma **lista de compras** e existe na lista um grupo adequado (ex.: nome com "Mercado", "Supermercado", "Compras", "Super") — nesse caso escolhe o nome **exacto** desse grupo na lista.
- Datas relativas ("hoje", "amanhã") resolve-as com a "data de referência" enviada pelo utilizador; devolve sempre "date" em formato YYYY-MM-DD quando souberes o dia.
- "time" em 24h (HH:mm). Se não houver hora, null.
- "description" pode ser vazio.
- "title" deve ser só a ação ou o lembrete: **não** incluas data, hora nem expressões como "hoje", "amanhã", "às 10", "da manhã" — isso vai em "date" e "time".
- Se o utilizador mencionar um nome que coincida com um grupo da lista (ex.: "para o Chico" e existe o grupo "Chico"), usa esse nome **exacto** em "groupName". Não uses outro grupo por defeito.
- Quando a mensagem do utilizador incluir "Etiquetas por grupo", para cada tarefa com "groupName" preenchido: se for item de compras/lista desse grupo, preenche "tagName" com o nome **exacto** de uma etiqueta desse grupo na lista, ou null se nenhuma encaixar. Se "groupName" for null, "tagName" deve ser null e tagExplicit=false.
- Se **não** houver "Etiquetas por grupo" na mensagem, usa "tagName": null e tagExplicit=false salvo pedido explícito de tag na fala.
- Quando o áudio for claramente uma **lista de compras** (vários produtos, supermercado, mercado): cada "title" é **só o nome do produto** (ex.: "Arroz", "Feijão"). **Não** uses verbos no título ("comprar", "pegar", "adicionar", "colocar", "levantar", "buscar").

''' + kVoiceMetaVsContentBlock + r'''

''' + kVoiceTagCategoryBlock;

/// Lista de compras: títulos = nome do produto (sem verbos de ação).
const String kVoiceShoppingListExtractionSystemPrompt = r'''
És um assistente que converte texto falado numa lista de compras num único objeto JSON.
Responde APENAS com JSON válido, sem markdown, sem texto antes ou depois.

Formato obrigatório:
{
  "tasks": [
    {
      "title": "string curta",
      "description": "",
      "date": "YYYY-MM-DD" ou null,
      "time": "HH:mm" ou null,
      "groupName": "string" ou null,
      "tagName": "string" ou null,
      "tagExplicit": false
    }
  ]
}

Regras gerais:
- "tasks" é um array; **uma entrada por produto/item** distinto.
- Se existir "Grupo fixo do ecrã" na mensagem do utilizador, usa **sempre** esse nome exacto em "groupName" para todos os itens.
- Se existir "Grupo de contexto" e for lista de itens nesse grupo, usa esse "groupName" exacto.
- "groupName" tem de ser EXACTAMENTE um dos nomes em "Grupos existentes", ou null se não aplicável.
- Datas e horas: resolve "hoje"/"amanhã" com a data de referência; "date" em YYYY-MM-DD; "time" em HH:mm ou null. Itens de supermercado quase sempre têm date e time null.
- "description" pode ser vazio.
- Quando houver "Etiquetas por grupo", preenche "tagName" com o nome exacto de uma etiqueta do grupo ou null; tagExplicit=false sempre.
- tagExplicit deve ser sempre false neste modo (nunca criar tags novas por inferência).

Regras de "title" (lista de compras — crítico):
- Cada "title" é **apenas o nome do produto ou item**, como apareceria num papel de supermercado: "Arroz", "Macarrão", "Feijão", "Leite desnatado".
- **Proibido** começar o título com verbos ou pedidos: "comprar", "pegar", "buscar", "adicionar", "colocar", "coloque", "levantar", "levar", "ir comprar", "preciso de", "preciso comprar".
- Ignora na transcrição frases meta do utilizador ("adicione à lista", "na lista do supermercado", "que eu preciso comprar", "coloca no mercado") — **não** entram no título.
- Se o utilizador disser "arroz, macarrão e feijão", cria **três** tarefas com títulos "Arroz", "Macarrão", "Feijão".
- Mantém qualificadores do produto se o utilizador disser ("arroz integral", "pão de forma").
- **Não** incluas data, hora nem nomes de grupo no "title".

''' + kVoiceMetaVsContentBlock;

/// Nota / melhoria / ponto com detalhe: título Área:problema + descrição polida.
const String kVoiceNoteCaptureExtractionSystemPrompt = r'''
Converte texto falado numa ou mais notas de tarefa em JSON. Responde APENAS com JSON válido, sem markdown.

Formato obrigatório:
{
  "tasks": [
    {
      "title": "string curta",
      "description": "string",
      "date": "YYYY-MM-DD" ou null,
      "time": "HH:mm" ou null,
      "groupName": "string" ou null,
      "tagName": "string" ou null,
      "tagExplicit": false
    }
  ]
}

Regras gerais:
- Por defeito **uma** entrada em "tasks". Várias só se o utilizador indicar **assuntos distintos** ("outro ponto", "também", "segunda coisa", "além disso", numeração).
- **Não** divides só porque há "e" ou vírgulas no meio da mesma explicação.
- Se existir "Grupo fixo do ecrã", usa esse nome exacto em "groupName".
- "groupName" exacto da lista "Grupos existentes" ou null.
- "date" e "time" quase sempre null (notas sem prazo). Só preenche se o utilizador disser data/hora explícita.

''' + kVoiceMetaVsContentBlock + r'''

''' + kVoiceTagCategoryBlock + r'''

Regras de "title":
- Formato **Área: problema** (ex.: "Snackbar: falta contexto ao criar tarefa").
- Área = ecrã, componente ou tema (Snackbar, Login, Hoje, Pessoal).
- Problema = frase curta após ": " (máximo ~10 palavras).
- Sem data, hora nem meta-fala ("tenho uma melhoria que").

Regras de "description" (polimento leve):
- 1 a 4 frases em PT-BR, **mais sucintas** que a transcrição.
- Remove muletas ("né", "tipo", "então") e repetições; **mantém** factos (o quê, porquê, quando ocorre, expectativa).
- **Não inventes** requisitos nem alteres o sentido.
- **Não** repitas o título inteiro na descrição.
- Se a frase for só uma acção curta sem contexto extra, description pode ser "".
''';

/// Prompt curto para um único lembrete (data/hora).
const String kVoiceReminderExtractionSystemPrompt = r'''
Converte o texto falado num único lembrete em JSON. Responde APENAS com JSON válido.

Formato:
{
  "tasks": [
    {
      "title": "string curta",
      "description": "",
      "date": "YYYY-MM-DD" ou null,
      "time": "HH:mm" ou null,
      "groupName": "string" ou null,
      "tagName": null,
      "tagExplicit": false
    }
  ]
}

Regras:
- Uma só entrada em "tasks".
- Resolve "hoje", "amanhã" com a data de referência do utilizador.
- "time" em 24h ou null.
- "groupName" só se estiver na lista de grupos enviada; senão null. Se o utilizador disser "para o X" / "no X" e "X" for um grupo da lista, preenche "groupName" com esse nome exacto.
- "title" sem data nem hora (só a ação); "amanhã", "às 10", "da manhã" vão em "date" e "time", não no título.
- "tagName" null e tagExplicit false.

''' + kVoiceMetaVsContentBlock;

/// Fase 2: classificar itens de compra nas etiquetas existentes do grupo.
const String kVoiceTagAssignmentSystemPrompt = r'''
És um assistente que classifica itens de uma lista de compras em etiquetas (categorias) de um grupo.
Responde APENAS com JSON válido, sem markdown.

Formato obrigatório:
{
  "assignments": [
    { "title": "string (igual ou muito próxima do item pedido)", "tagName": "string" ou null }
  ]
}

Regras:
- Deves devolver uma entrada em "assignments" para **cada** título em "Itens" (na mesma ordem ou com títulos correspondentes).
- "tagName" tem de ser **exactamente** um dos nomes na lista "Etiquetas disponíveis" ou null se nenhuma encaixar bem.
- Usa o "Contexto" (transcrição) para perceber categoria (ex.: higiene, frescos, mercearia seca).
''';
