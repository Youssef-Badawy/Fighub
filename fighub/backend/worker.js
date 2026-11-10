import { jwtVerify, createRemoteJWKSet } from 'jose';

const FIREBASE_PROJECT_ID = 'fighub-egypt-2026';

const FIREBASE_ISSUER =
  `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;

const FIREBASE_KEYS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', {
        status: 405,
      });
    }

    try {
      const authHeader = request.headers.get('Authorization');

      if (!authHeader ||
          !authHeader.startsWith('Bearer ')) {
        return new Response(
          JSON.stringify({
            error: 'Unauthorized',
          }),
          {
            status: 401,
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
      }

      const idToken = authHeader.substring(7);

      const { payload } = await jwtVerify(
        idToken,
        FIREBASE_KEYS,
        {
          issuer: FIREBASE_ISSUER,
          audience: FIREBASE_PROJECT_ID,
        },
      );

      if (!payload.sub) {
        return new Response(
          JSON.stringify({
            error: 'Invalid Firebase user',
          }),
          {
            status: 401,
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
      }

      const body = await request.json();

      const {
        userId,
        chatId,
        messageId,
        title,
        message,
      } = body;

      if (!userId || !chatId || !messageId || !title || !message) {
        return new Response(
          JSON.stringify({
            error:
              'userId, title and message are required',
          }),
          {
            status: 400,
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
      }

      // A valid Firebase token alone must not let a user push
      // arbitrary recipients. Read the chat using the caller's token so
      // Firestore security rules verify membership before sending.
      const chatResponse = await fetch(
        `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/chats/${encodeURIComponent(chatId)}`,
        {
          headers: {
            Authorization: `Bearer ${idToken}`,
          },
        },
      );

      if (!chatResponse.ok) {
        return new Response(
          JSON.stringify({ error: 'Chat access denied' }),
          {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          },
        );
      }

      const chatDocument = await chatResponse.json();
      const participants =
        chatDocument.fields?.participants?.arrayValue?.values
          ?.map((value) => value.stringValue)
          .filter(Boolean) ?? [];

      if (
        !participants.includes(payload.sub) ||
        !participants.includes(userId) ||
        userId === payload.sub
      ) {
        return new Response(
          JSON.stringify({ error: 'Recipient is not a chat participant' }),
          {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          },
        );
      }

      // Only deliver a push for a message that actually exists in this chat
      // and was created by the authenticated caller.
      const messageResponse = await fetch(
        `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/chats/${encodeURIComponent(chatId)}/messages/${encodeURIComponent(messageId)}`,
        {
          headers: {
            Authorization: `Bearer ${idToken}`,
          },
        },
      );

      if (!messageResponse.ok) {
        return new Response(
          JSON.stringify({ error: 'Message access denied' }),
          {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          },
        );
      }

      const messageDocument = await messageResponse.json();
      const senderId = messageDocument.fields?.senderId?.stringValue;

      if (senderId !== payload.sub) {
        return new Response(
          JSON.stringify({ error: 'Message sender does not match caller' }),
          {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          },
        );
      }

      const response = await fetch(
        'https://api.onesignal.com/notifications',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization:
              `Key ${env.ONESIGNAL_REST_API_KEY}`,
          },
          body: JSON.stringify({
            app_id:
              'e8996f31-dd11-4713-ae16-5e8e8635e737',
            target_channel: 'push',
            include_aliases: {
              external_id: [userId],
            },
            headings: {
              en: title,
              ar: title,
            },
            contents: {
              en: message,
              ar: message,
            },
          }),
        },
      );

      const result = await response.text();

      return new Response(result, {
        status: response.status,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    } catch (error) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
        }),
        {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
          },
        },
      );
    }
  },
};
