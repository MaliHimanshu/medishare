const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Utility to send push notifications safely without exposing sensitive info
async function sendNotification(userId, title, body, data) {
  const tokensSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("notificationTokens")
      .get();

  if (tokensSnapshot.empty) {
    console.log("No tokens for user:", userId);
    return;
  }

  const tokens = [];
  tokensSnapshot.forEach((doc) => {
    tokens.push(doc.id);
  });

  const message = {
    notification: {
      title,
      body,
    },
    data: data || {},
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log("Push notifications sent:", response.successCount);
    // Cleanup invalid tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      // Optionally delete failed tokens
    }
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

// 1. Rental Updates
exports.onRentalUpdate = functions.firestore
    .document("rentals/{rentalId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const rentalId = context.params.rentalId;

      if (before.status !== after.status) {
        // Only safe data in notification payload
        const data = { type: "rental", rentalId };

        if (after.status === "APPROVED") {
          await sendNotification(after.renterId, "Rental Approved", "Your equipment rental has been approved.", data);
        } else if (after.status === "RETURN_REQUESTED") {
          // Notify NGO
          await sendNotification(after.ngoId, "Return Requested", "A user has requested an equipment return.", data);
        } else if (after.status === "COMPLETED") {
          // Notify Renter
          await sendNotification(after.renterId, "Inspection Completed", "Your returned equipment inspection was clean and completed.", data);
        }
      }
    });

exports.onRentalCreate = functions.firestore
    .document("rentals/{rentalId}")
    .onCreate(async (snap, context) => {
      const rental = snap.data();
      const rentalId = context.params.rentalId;
      const data = { type: "rental", rentalId };
      // Notify NGO of new rental request
      await sendNotification(rental.ngoId, "New Rental Request", "A new equipment rental request has been submitted.", data);
    });

// 2. Delivery Updates
exports.onDeliveryUpdate = functions.firestore
    .document("deliveries/{deliveryId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const deliveryId = context.params.deliveryId;
      
      if (before.status !== after.status) {
        const data = { type: "delivery", deliveryId, rentalId: after.rentalId };

        // We get the rental to know the recipient ID
        const rentalDoc = await admin.firestore().collection("rentals").doc(after.rentalId).get();
        if (!rentalDoc.exists) return;
        const rental = rentalDoc.data();
        const recipientId = rental.renterId;

        if (after.status === "ASSIGNED" || after.status === "RETURN_ASSIGNED") {
          // Notify partner
          await sendNotification(after.deliveryPartnerId, "New Assignment", "You have a new delivery assignment.", data);
          // Notify recipient
          await sendNotification(recipientId, "Partner Assigned", "A delivery partner has been assigned to your equipment.", data);
        } else if (after.status === "PICKED_UP") {
          await sendNotification(recipientId, "Pickup Completed", "The partner has picked up the equipment.", data);
        } else if (after.status === "IN_TRANSIT") {
          await sendNotification(recipientId, "Delivery Started", "Your equipment is now on the way.", data);
        } else if (after.status === "DELIVERED") {
          await sendNotification(recipientId, "Equipment Delivered", "Your equipment has been delivered successfully.", data);
          await sendNotification(after.ngoId, "Delivery Completed", "A delivery has been completed successfully.", data);
        }
      }
    });
