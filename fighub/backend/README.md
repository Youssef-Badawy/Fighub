# FigHub Push and Media Cleanup Backend

This Cloudflare Worker sends authenticated OneSignal push notifications and
performs authenticated Cloudinary cleanup for seller-owned products and offers.

Never store OneSignal REST API keys, Cloudinary API secrets, or other secrets
in Flutter code, Firestore documents, Git, or this repository.

## Required Cloudflare secrets

Set these once in the FigHub Worker environment:

```bash
npx wrangler secret put ONESIGNAL_REST_API_KEY
npx wrangler secret put CLOUDINARY_API_KEY
npx wrangler secret put CLOUDINARY_API_SECRET
```

Then deploy from the `fighub` directory:

```bash
npx wrangler deploy
```

The Cloudinary deletion endpoint requires a valid Firebase ID token and checks
the authenticated seller against the Firestore product or offer before deleting
only image/video assets listed on that record. Chat message attachments are not
sent to this endpoint and are never deleted by product or offer cleanup.

The Flutter app calls this endpoint before deleting the corresponding Firestore
product or offer. If Cloudinary credentials are missing or cleanup fails, the
Firestore record is retained (or an offer remains hidden for a safe retry).
