const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

exports.notifyUsersAboutNewOffer = onDocumentCreated(
    "offers/{offerId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const offer = snapshot.data() || {};
      const sellerId = offer.sellerId;

      if (!sellerId) {
        return;
      }

      const title = String(offer.title || "عرض جديد");
      const scheduledAt = offer.scheduledAt;

      const notificationTitle = "عرض جديد على FigHub";
      const notificationMessage = scheduledAt ?
      `تم إنشاء عرض جديد: ${title}` :
      `عرض جديد متاح الآن: ${title}`;

      const usersSnapshot = await db.collection("users").get();

      if (usersSnapshot.empty) {
        return;
      }

      let batch = db.batch();
      let notificationCount = 0;

      for (const userDocument of usersSnapshot.docs) {
        if (userDocument.id === sellerId) {
          continue;
        }

        const notificationReference = userDocument.ref
            .collection("notifications")
            .doc();

        batch.set(notificationReference, {
          title: notificationTitle,
          message: notificationMessage,
          offerId: event.params.offerId,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });

        notificationCount++;

        if (notificationCount >= 450) {
          await batch.commit();
          batch = db.batch();
          notificationCount = 0;
        }
      }

      if (notificationCount > 0) {
        await batch.commit();
      }
    },
);
