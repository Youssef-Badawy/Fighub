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

Then deploy the tracked Worker entry point from the `fighub` directory (do not deploy a separate or stale `worker.js` file):

```bash
npx wrangler deploy backend/worker.js --name fighub --compatibility-date 2026-11-12
```

The Flutter app requests signed Cloudinary uploads from this same Worker using
the `signCloudinaryUpload` action. Both `image` and `video` resource types
are supported; Cloudinary audio uploads use the `video` resource type.
The Worker requires both `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET`
to be configured as Worker secrets before signed uploads can succeed.

After deployment, open `https://fighub.youssef-khaled-badawy.workers.dev/health`.
The read-only response reports whether the Cloudinary signing secrets are present;
it never returns the API key or API secret. `cloudinarySigningConfigured` must
be `true` before testing uploads.

The Cloudinary deletion endpoint requires a valid Firebase ID token and checks
the authenticated seller against the Firestore product or offer before deleting
only image/video assets listed on that record. Chat message attachments are not
sent to this endpoint and are never deleted by product or offer cleanup.

The Flutter app attempts Cloudinary cleanup while the corresponding Firestore
product or offer record is still available for ownership verification. Product
deletion is allowed to continue if Cloudinary cleanup fails, so the listing is
not blocked by a stale Worker; in that case, the asset may remain in Cloudinary
and the app logs the cleanup failure. Do not interpret a successful listing
deletion as proof that its remote media was deleted.
