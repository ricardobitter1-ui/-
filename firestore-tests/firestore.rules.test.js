const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'exm-rules-test';
const rulesPath = resolve(__dirname, '..', 'firestore.rules');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function authed(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

test('membro lê o próprio grupo', async () => {
  const admin = testEnv.unauthenticatedContext().firestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('groups/g1').set({
      name: 'G',
      icon: 'group',
      color: '#000',
      ownerId: 'owner1',
      members: ['owner1', 'alice'],
      admins: ['owner1'],
      isPersonal: false,
      createdAt: new Date(),
    });
  });

  const db = authed('alice');
  await assertSucceeds(db.doc('groups/g1').get());
});

test('não-membro não lê grupo', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('groups/g1').set({
      name: 'G',
      icon: 'group',
      color: '#000',
      ownerId: 'owner1',
      members: ['owner1'],
      admins: ['owner1'],
      isPersonal: false,
      createdAt: new Date(),
    });
  });

  const db = authed('eve');
  await assertFails(db.doc('groups/g1').get());
});

test('convite pendente: convidado não lê tarefa do grupo', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await fs.doc('groups/g1').set({
      name: 'G',
      icon: 'group',
      color: '#000',
      ownerId: 'owner1',
      members: ['owner1'],
      admins: ['owner1'],
      isPersonal: false,
      createdAt: new Date(),
    });
    await fs.doc('groupInvites/g1_bob').set({
      groupId: 'g1',
      inviteeUid: 'bob',
      invitedBy: 'owner1',
      status: 'pending',
      createdAt: new Date(),
    });
    await fs.doc('tasks/t1').set({
      title: 'x',
      description: '',
      isCompleted: false,
      ownerId: 'owner1',
      groupId: 'g1',
      createdBy: 'owner1',
      assigneeIds: [],
    });
  });

  const db = authed('bob');
  await assertFails(db.doc('tasks/t1').get());
});

test('assigneeIds fora dos membros: create falha', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('groups/g1').set({
      name: 'G',
      icon: 'group',
      color: '#000',
      ownerId: 'owner1',
      members: ['owner1', 'alice'],
      admins: ['owner1'],
      isPersonal: false,
      createdAt: new Date(),
    });
  });

  const db = authed('alice');
  await assertFails(
    db.collection('tasks').add({
      title: 'bad',
      description: '',
      isCompleted: false,
      ownerId: 'alice',
      groupId: 'g1',
      createdBy: 'alice',
      assigneeIds: ['stranger'],
    }),
  );
});

test('grupo pessoal: admin não cria convite', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('groups/p1').set({
      name: 'Pessoal',
      icon: 'group',
      color: '#000',
      ownerId: 'owner1',
      members: ['owner1'],
      admins: ['owner1'],
      isPersonal: true,
      createdAt: new Date(),
    });
  });

  const db = authed('owner1');
  await assertFails(
    db.doc('groupInvites/p1_other').set({
      groupId: 'p1',
      inviteeUid: 'other',
      invitedBy: 'owner1',
      status: 'pending',
      createdAt: new Date(),
    }),
  );
});
