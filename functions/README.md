# Cloud Functions (opcional)

Esta pasta está reservada para:

- **Callables** (`inviteUser`, `acceptInvite`, …) com Admin SDK, se quiser mover toda a mutação de `members` / `admins` para o servidor.
- **Triggers** em `tasks` para enviar FCM aos `assigneeIds` quando uma tarefa é criada ou atualizada.
- **Agendamento** de lembretes para responsáveis (Cloud Scheduler + fila), em alternativa aos lembretes só locais.

Para inicializar no projeto Firebase:

```bash
firebase init functions
```

Nada aqui é obrigatório para o fluxo atual baseado em Firestore Security Rules + app Flutter.
