# Testes das Firestore Rules

Requer Node.js e [Firebase CLI](https://firebase.google.com/docs/cli).

Na raiz do repositório (um nível acima desta pasta), o ficheiro `firestore.rules` é usado pelo emulador.

```bash
cd firestore-tests
npm install
npm test
```

O script corre o emulador Firestore e executa `jest` com `@firebase/rules-unit-testing`.
