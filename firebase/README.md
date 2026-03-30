# Firebase (Exm To-Do)

## Firestore rules e índices

- Regras: `firestore.rules` (raiz do repositório).
- Índices: `firestore.indexes.json`.

### Deploy (staging / produção)

Na raiz do projeto (com Firebase CLI instalado e projeto selecionado):

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Confirme no [Firebase Console](https://console.firebase.google.com/) que as regras foram aplicadas **antes** de distribuir builds com convites e colaboração.

## Testes das regras

Ver `firestore-tests/README.md`. Comandos típicos:

```bash
cd firestore-tests
npm install
npm test
```

## Notificações (tarefa 6.1)

- **Lembretes locais** (`flutter_local_notifications`): agendados no dispositivo de quem cria ou edita a tarefa com alarme de data/hora.
- **Push (FCM)** para responsáveis: requer Cloud Functions (ou backend) que leia tokens em `users/{uid}/fcmTokens/*` e envie mensagens — não está incluído neste repositório de forma completa (ver `functions/README.md`).

## Cloud Functions (convites avançados / push)

Convites funcionam **só com Firestore + cliente** conforme implementado. Functions callable são opcionais para endurecer membership ou rate-limit; ver `functions/README.md`.
