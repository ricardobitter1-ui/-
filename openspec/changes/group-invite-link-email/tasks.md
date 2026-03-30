# Tasks: Convites — link + e-mail (**Firebase Spark**)



_Toda a implementação desta fase: **Firestore + Auth + Flutter**. **Sem** Cloud Functions, **sem** e-mail transacional, **sem** FCM disparado pelo servidor para convites._



## 1. Modelo de dados e Firestore



- [x] 1.1 Definir formato final do doc `groupInvites`: `shareToken`, `inviteeEmailLower`, `groupId`, `invitedBy`, `status`, snapshots opcionais (`groupName`, `inviterName`); ID de documento opaco

- [x] 1.2 Atualizar `GroupInviteModel` + métodos em `FirebaseService`: criar convite por e-mail (cliente); criar/regenerar token para link; compatibilidade com convites legados `groupId_uid` se necessário

- [x] 1.3 Índices: `shareToken` + `status`; `inviteeEmailLower` + `status` (para inbox)



## 2. Firestore Security Rules



- [x] 2.1 Leitura: convidado vê convites `pending` onde `inviteeEmailLower` coincide com `request.auth.token.email` (normalizado)

- [x] 2.2 Leitura por link: política para `get`/query por `shareToken` sem permitir listagem aberta (preferir `get` único ou query estrita documentada)

- [x] 2.3 Criação: só admin do grupo; grupo pessoal negado; validar campos obrigatórios

- [x] 2.4 Manter aceite/recusa coerente com `addedOnlySelfToMembers` / convite `accepted`

- [x] 2.5 Deploy `firestore:rules` e `firestore:indexes` *(ficheiros prontos; executar `firebase deploy --only firestore:rules,firestore:indexes` no projeto)*



## 3. Deep linking (Flutter)



- [x] 3.1 Dependência `app_links` (ou equivalente) + `exmtodo://invite?token=` (ajustar scheme ao `AndroidManifest` / iOS)

- [x] 3.2 Handler no arranque e ao retomar app; após login, resolver token → convite → modal

- [x] 3.3 Tratamento de token inválido / já aceite



## 4. UI Flutter



- [x] 4.1 Substituir convite por UID: diálogo **e-mail** → criação de convite no Firestore (cliente)

- [x] 4.2 Menu: **Copiar link de convite** (URL com `shareToken`)

- [x] 4.3 Widget reutilizável modal/sheet: nome do grupo, quem convidou, Aceitar / Recusar (deep link + arranque + inbox)

- [x] 4.4 **Arranque / resume:** com utilizador autenticado e e-mail no token, subscrever convites `pending` por `inviteeEmailLower`; ao detetar pendentes, mostrar modal (fila ordenada, ex. `createdAt`); coordenar com deep link pendente (prioridade documentada no código)

- [x] 4.5 Inbox: mesma query; lista para reentrada / convites adiados; mensagem se o login não tiver e-mail



## 5. Documentação e roadmap



- [x] 5.1 `firebase/README.md` (ou doc da change): plano **Spark** vs extensão **Blaze** futura (FCM + e-mail)

- [x] 5.2 Após implementação, atualizar `openspec/roadmap.md` (Fase 4: distinguir “entregue Spark” vs “push/e-mail quando Blaze”)



---



## Extensão futura — Blaze (não faz parte do Spark)



_Mover para change separada ou secção quando houver upgrade._



- [ ] B.1 Cloud Function callable ou trigger: e-mail transacional + FCM ao criar convite

- [ ] B.2 `getUserByEmail` para pré-preencher `inviteeUid`

- [ ] B.3 Rate limiting e quotas no servidor

