import { jwtVerify, createRemoteJWKSet } from 'jose';

const FIREBASE_PROJECT_ID = 'fighub-egypt-2026';

const FIREBASE_ISSUER =
  `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;

const FIREBASE_KEYS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

const CLOUDINARY_CLOUD_NAME = 'jcfyuify';

function readStringField(fields, name) {
  return fields?.[name]?.stringValue ?? '';
}

function readStringArray(fields, name) {
  return fields?.[name]?.arrayValue?.values
      ?.map((value) => value.stringValue)
      .filter(Boolean) ?? [];
}

function cloudinaryPublicId(assetUrl) {
  let url;
  try {
    url = new URL(assetUrl);
  } catch (_) {
    throw new Error('Invalid Cloudinary asset URL');
  }

  if (url.hostname !== 'res.cloudinary.com') {
    throw new Error('Asset is not hosted by Cloudinary');
  }

  const parts = url.pathname.split('/').filter(Boolean);
  if (parts.length < 5 || parts[0] !== CLOUDINARY_CLOUD_NAME) {
    throw new Error('Cloudinary asset does not belong to this app');
  }

  const resourceType = parts[1];
  const uploadIndex = parts.indexOf('upload');
  if (!['image', 'video', 'raw'].includes(resourceType) ||
      uploadIndex < 0 || uploadIndex === parts.length - 1) {
    throw new Error('Unsupported Cloudinary asset URL');
  }

  const publicParts = parts.slice(uploadIndex + 1);
  if (/^v\\d+$/.test(publicParts[0])) publicParts.shift();
  if (publicParts.length === 0) throw new Error('Missing public ID');

  const last = publicParts.length - 1;
  publicParts[last] = publicParts[last].replace(/\\.[^/.]+$/, '');
  return { resourceType, publicId: decodeURIComponent(publicParts.join('/')) };
}

async function deleteCloudinaryAsset(assetUrl, env) {
  const { resourceType, publicId } = cloudinaryPublicId(assetUrl);
  if (!env.CLOUDINARY_API_KEY || !env.CLOUDINARY_API_SECRET) {
    throw new Error('Cloudinary deletion credentials are not configured');
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const signatureText =
      `invalidate=true&public_id=${publicId}&timestamp=${timestamp}${env.CLOUDINARY_API_SECRET}`;
  const digest = await crypto.subtle.digest(
      'SHA-1',
      new TextEncoder().encode(signatureText),
  );
  const signature = Array.from(new Uint8Array(digest))
      .map((byte) => byte.toString(16).padStart(2, '0'))
      .join('');

  const form = new URLSearchParams({
    public_id: publicId,
    timestamp,
    api_key: env.CLOUDINARY_API_KEY,
    invalidate: 'true',
    signature,
  });

  const response = await fetch(
      `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/${resourceType}/destroy`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: form,
      },
  );
  const result = await response.json();
  if (!response.ok || !['ok', 'not found'].includes(result.result)) {
    throw new Error('Cloudinary asset deletion failed');
  }
}

async function readFirestoreDocument(path, idToken) {
  const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
      { headers: { Authorization: `Bearer ${idToken}` } },
  );
  if (!response.ok) return null;
  return response.json();
}

async function handleCloudinaryDeletion(body, payload, idToken, env) {
  const { ownerType, ownerId } = body;
  if (!ownerId || !['product', 'offer'].includes(ownerType)) {
    return new Response(JSON.stringify({ error: 'Invalid deletion request' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const parentPath = ownerType === 'product'
      ? `products/${encodeURIComponent(ownerId)}`
      : `offers/${encodeURIComponent(ownerId)}`;
  const parent = await readFirestoreDocument(parentPath, idToken);
  if (!parent || readStringField(parent.fields, 'sellerId') !== payload.sub) {
    return new Response(JSON.stringify({ error: 'Owner verification failed' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const requestedUrls = new Set();
  if (ownerType === 'product') {
    const fields = parent.fields ?? {};
    const allowed = new Set([
      ...readStringArray(fields, 'imagePaths'),
      readStringField(fields, 'imagePath'),
    ].filter(Boolean));
    const urls = Array.isArray(body.assetUrls) ? body.assetUrls : [];
    for (const url of urls) {
      if (typeof url !== 'string' || !allowed.has(url)) {
        return new Response(JSON.stringify({ error: 'Asset ownership mismatch' }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      requestedUrls.add(url);
    }
    if (readStringField(fields, 'status') !== 'Available') {
      return new Response(JSON.stringify({ error: 'Only available products can be deleted' }), {
        status: 409,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  } else {
    const items = Array.isArray(body.items) ? body.items : [];
    if (items.length > 100) {
      return new Response(JSON.stringify({ error: 'Too many offer items in one request' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    for (const item of items) {
      if (!item || typeof item.itemId !== 'string' ||
          !Array.isArray(item.assetUrls)) {
        return new Response(JSON.stringify({ error: 'Invalid offer asset list' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      const source = await readFirestoreDocument(
          `offers/${encodeURIComponent(ownerId)}/items/${encodeURIComponent(item.itemId)}`,
          idToken,
      );
      if (!source) {
        if (item.assetUrls.length === 0) continue;
        return new Response(JSON.stringify({ error: 'Offer item not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      const allowed = new Set([
        ...readStringArray(source.fields, 'imagePaths'),
        readStringField(source.fields, 'imagePath'),
      ].filter(Boolean));
      for (const url of item.assetUrls) {
        if (typeof url !== 'string' || !allowed.has(url)) {
          return new Response(JSON.stringify({ error: 'Asset ownership mismatch' }), {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          });
        }
        requestedUrls.add(url);
      }
    }
  }

  for (const assetUrl of requestedUrls) {
    await deleteCloudinaryAsset(assetUrl, env);
  }

  return new Response(JSON.stringify({
    success: true,
    deletedAssets: requestedUrls.size,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

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

      if (body.action === 'deleteCloudinaryAssets') {
        return await handleCloudinaryDeletion(body, payload, idToken, env);
      }

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
              'userId, chatId, messageId, title and message are required',
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
