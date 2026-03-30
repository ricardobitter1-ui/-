# Proposal: Convites a grupos — link partilhável e e-mail (âmbito **Spark**)

## Why

O roadmap (Fase 4) pede convites **humanos**: partilha por **URL** que abre o app com modal (aceitar/recusar), e convite por **e-mail** em vez de UID. O MVP atual (UID + copiar ID) é fraco em UX.

**Restrição de produto:** manter o projeto Firebase no plano **Spark (gratuito)** por agora. Nesse plano **não há Cloud Functions**; logo **não há** envio automático de **e-mail transacional** nem **FCM disparado pelo servidor** para o convidado. Esta revisão alinha a change ao que é **viável só com Firestore + Auth + cliente + FCM já existente no dispositivo** (sem backend Firebase).

## O que fica **fora** no Spark (extensão futura em Blaze)

| Capacidade | Motivo |
|------------|--------|
| Callable / trigger para convite | Spark não suporta deploy de Functions na prática habitual |
| E-mail automático (SendGrid, etc.) | Exige backend |
| Push para **outro** utilizador no momento do convite | Exige Admin SDK / backend |

Documentar numa change ou anexo futuro **“group-invite-blaze-extension”** quando houver upgrade.

## Fase 3 (pendências) — inalterado

As pendências da Fase 3 (Functions completas, App Check, lembretes servidor) **não** são pré-requisitos desta versão Spark.

## What Changes (Spark)

- **Modelo `groupInvites`:** token opaco `shareToken` para links; `inviteeEmailLower` quando o convite é por e-mail; documento pode usar **ID gerado** (não obrigar `groupId_uid` em todos os fluxos); campos para nome do grupo / quem convidou (snapshot ou leituras na UI).
- **Convite por e-mail (cliente):** admin grava convite `pending` com `inviteeEmailLower` normalizado. **Sem** resolver UID no servidor: o convidado é alcançado **assim que abre o app** com sessão cujo **e-mail do Auth** coincide — o cliente faz a query (rules com `request.auth.token.email`) e **apresenta de imediato o mesmo modal** **Aceitar / Recusar** que o deep link usa (não só uma entrada escondida na lista). Vários pendentes: fila (ex. por `createdAt`), um modal de cada vez; a **inbox** no perfil mantém-se como histórico / reentrada.
- **Firestore Rules:** leitura de convites pendentes pelo convidado só quando o e-mail do token corresponde; leitura por `shareToken` para o fluxo do link (utilizador autenticado e elegível conforme regra); criação só admin; grupo pessoal bloqueado.
- **Flutter:** deep link `exmtodo://invite?token=…` (ou scheme acordado); **arranque / retoma** com utilizador autenticado → verificar convites pendentes por e-mail → modal; modal unificado **Aceitar / Recusar**; **Copiar link de convite**; UI de convite por e-mail **sem** callable.
- **Partilha:** o utilizador pode partilhar o link manualmente (WhatsApp, etc.); **não** é o sistema a enviar e-mail.

## Capabilities

### New Capabilities

- `group-invite-deeplink`: URLs, abertura do app, modal, token seguro (inalterado no essencial).
- `group-invite-email`: Convite por e-mail com **modal no arranque da app** (sessão + e-mail coincidente), inbox como apoio, e regras baseadas no e-mail da sessão Auth (**sem** push/e-mail servidor nesta fase).

### Modified Capabilities

- (Nenhuma spec em `openspec/specs/` no repo raiz.)

## Impact

- `firestore.rules`, índices, `GroupInviteModel`, `FirebaseService`, `group_detail_screen`, `profile_screen`, `AuthWrapper` / arranque do app, Android/iOS URL schemes.
- **Sem** `functions/`, **sem** segredos de SMTP nesta fase.
