const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Envia push FCM quando assigneeIds ganham novos membros (criação ou update).
 */
exports.notifyTaskAssignees = onDocumentWritten('tasks/{taskId}', async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return;

  const before = event.data?.before?.exists ? event.data.before.data() : null;
  const task = after.data();
  const taskId = after.id;

  const prev = new Set(before?.assigneeIds ?? []);
  const next = task.assigneeIds ?? [];
  const newlyAssigned = next.filter((uid) => uid && !prev.has(uid));
  if (newlyAssigned.length === 0) return;

  const title = task.title?.trim() || 'Nova tarefa';
  const actor = task.createdBy ?? task.ownerId ?? '';

  for (const uid of newlyAssigned) {
    if (uid === actor) continue;
    const tokensSnap = await getFirestore()
      .collection('users')
      .doc(uid)
      .collection('fcmTokens')
      .get();
    const tokens = tokensSnap.docs
      .map((d) => d.data().token)
      .filter((t) => typeof t === 'string' && t.length > 0);
    if (tokens.length === 0) continue;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: 'Tarefa atribuída a você',
        body: title,
      },
      data: {
        type: 'task_assigned',
        taskId,
      },
    });
  }
});
