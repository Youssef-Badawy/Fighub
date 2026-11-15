# FigHub session checkpoint — 2026-11-15

## Repository state
- Repository: Youssef-Badawy/Fighub
- Branch: main
- Latest application changes are merged through PR #6.
- PR #6 merge commit: dbf1063fe3022e3b0dfb1532387f586bceeac07a
- PR: https://github.com/Youssef-Badawy/Fighub/pull/6

## Changes in PR #6
1. The "اطلب تصميمك" action is intended for signed-in, non-anonymous regular users and hidden/blocked for admin accounts.
2. Firestore rules for print_design_requests require an authenticated non-anonymous user with an existing profile, a non-admin role, and customerId matching the signed-in UID.
3. Home search with no results displays "بحث خطأ" instead of an empty product list; the home list was changed to reduce stale sliver/scroll-state problems.
4. Flutter analysis, formatting, Firestore rules compilation, and Cloudflare JS syntax checks passed. A standalone Android debug APK workflow also succeeded.

## APK
- Actions run: https://github.com/Youssef-Badawy/Fighub/actions/runs/43753461151
- Artifact name: fighub-debug-apk-3a693e0f670d42b9be0e4e1919f77253a6ae299f
- Download the artifact ZIP from the run's Artifacts section, then extract the APK.

## Pending user-side step
Before testing the APK, deploy the Firestore rules from the latest main:
```bash
cd /workspaces/Fighub/fighub
git checkout main
git pull origin main
firebase deploy --only firestore:rules --project fighub-egypt-2026
```
Wait for `✔ Deploy complete!` before installing/testing.

## Next session — test checklist
1. Sign in with a regular non-anonymous user: verify "اطلب تصميمك" is visible.
2. Sign in with an admin account: verify "اطلب تصميمك" is hidden.
3. Submit a design request from a regular user and verify it is saved.
4. Search for a product that does not exist: verify the page shows "بحث خطأ" and no red error screen.
5. If the search still crashes, capture the complete Flutter red-screen stack trace or `flutter run` console output and fix the underlying exception. Do not treat the issue as resolved until tested on-device.

## Important product direction
Keep the three chat/account types visually separate:
- Group offers
- Ordinary individual products
- 3D Printing

Do not merge them into one mixed chat/account list.
