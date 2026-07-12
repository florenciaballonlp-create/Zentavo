const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();

async function getUserTokens(userId) {
  const devices = await admin
    .firestore()
    .collection('users')
    .doc(userId)
    .collection('devices')
    .get();

  return devices.docs
    .map((d) => (d.data() || {}).token)
    .filter((t) => typeof t === 'string' && t.length > 0);
}

async function sendToUsers({ userIds, title, body, data }) {
  const allTokens = [];
  for (const userId of userIds) {
    const tokens = await getUserTokens(userId);
    allTokens.push(...tokens);
  }

  if (allTokens.length === 0) {
    return;
  }

  await admin.messaging().sendEachForMulticast({
    tokens: allTokens,
    notification: { title, body },
    data,
  });
}

exports.onDirectMessageCreated = functions.firestore
  .document('direct_chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data() || {};
    const senderId = message.senderId;
    const text = (message.text || '').toString();

    const chatSnap = await admin
      .firestore()
      .collection('direct_chats')
      .doc(context.params.chatId)
      .get();

    if (!chatSnap.exists) return;

    const chat = chatSnap.data() || {};
    const participants = Array.isArray(chat.participants) ? chat.participants : [];
    const participantNames = chat.participantNames || {};

    const recipients = participants.filter((id) => id !== senderId);
    if (recipients.length === 0) return;

    const senderName = participantNames[senderId] || 'Nuevo mensaje';

    await sendToUsers({
      userIds: recipients,
      title: senderName,
      body: text.length > 100 ? `${text.slice(0, 100)}...` : text,
      data: {
        type: 'direct',
        chatId: context.params.chatId,
      },
    });
  });

exports.onEventMessageCreated = functions.firestore
  .document('event_chats/{eventId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data() || {};
    const senderId = message.senderId;
    const text = (message.text || '').toString();

    const eventChatSnap = await admin
      .firestore()
      .collection('event_chats')
      .doc(context.params.eventId)
      .get();

    if (!eventChatSnap.exists) return;

    const eventChat = eventChatSnap.data() || {};
    const members = Array.isArray(eventChat.memberIds) ? eventChat.memberIds : [];
    const eventName = (eventChat.eventName || 'Evento').toString();

    const recipients = members.filter((id) => id !== senderId);
    if (recipients.length === 0) return;

    await sendToUsers({
      userIds: recipients,
      title: `Nuevo mensaje en ${eventName}`,
      body: text.length > 100 ? `${text.slice(0, 100)}...` : text,
      data: {
        type: 'event',
        eventId: context.params.eventId,
      },
    });
  });

exports.onEventNoteCreated = functions.firestore
  .document('event_notes/{eventId}/posts/{postId}')
  .onCreate(async (snap, context) => {
    const note = snap.data() || {};
    const authorId = note.authorId;
    const title = (note.title || 'Nueva nota').toString();

    const eventNotesSnap = await admin
      .firestore()
      .collection('event_notes')
      .doc(context.params.eventId)
      .get();

    if (!eventNotesSnap.exists) return;

    const eventNotes = eventNotesSnap.data() || {};
    const members = Array.isArray(eventNotes.memberIds) ? eventNotes.memberIds : [];
    const eventName = (eventNotes.eventName || 'Evento').toString();

    const recipients = members.filter((id) => id !== authorId);
    if (recipients.length === 0) return;

    await sendToUsers({
      userIds: recipients,
      title: `Nueva nota en ${eventName}`,
      body: title.length > 100 ? `${title.slice(0, 100)}...` : title,
      data: {
        type: 'event_note',
        eventId: context.params.eventId,
        postId: context.params.postId,
      },
    });
  });
