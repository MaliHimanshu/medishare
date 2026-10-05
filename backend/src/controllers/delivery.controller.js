const { getFirestore } = require("../config/firebaseAdmin");
const crypto = require("crypto");
const prisma = require("../config/prisma");
const smsService = require("../services/sms.service");

// Generate Delivery OTP
const generateDeliveryOtp = async (req, res) => {
  try {
    console.log('[OTP] START');
    const { deliveryId } = req.params;
    console.log(`[OTP] deliveryId: ${deliveryId}`);
    
    const db = getFirestore();

    // 1. Fetch delivery from Firestore
    console.log('[OTP] Firestore delivery lookup: START');
    let start = Date.now();
    const deliveryDoc = await db.collection("deliveries").doc(deliveryId).get();
    
    if (!deliveryDoc.exists) {
      console.log(`[OTP] Firestore delivery lookup: FAILED`);
      return res.status(404).json({ success: false, message: "Delivery not found." });
    }
    console.log(`[OTP] Firestore delivery lookup: SUCCESS`);
    const delivery = deliveryDoc.data();

    // 2. Fetch rental to get the recipient user ID
    console.log(`[OTP] rentalId exists: ${!!delivery.rentalId}`);
    
    start = Date.now();
    const rental = await prisma.rental.findUnique({
      where: { id: delivery.rentalId },
      include: {
        renter: true,
      },
    });

    if (!rental) {
      console.log(`[OTP] Prisma rental lookup: FAILED`);
      return res.status(404).json({ success: false, message: "Rental not found." });
    }
    console.log(`[OTP] Prisma rental lookup: SUCCESS`);
    
    console.log(`[OTP] renterId exists: ${!!rental.renterId}`);
    if (!rental.renter) {
      console.log(`[OTP] recipient user lookup: FAILED`);
      return res.status(404).json({ success: false, message: "Recipient not found." });
    }
    console.log(`[OTP] recipient user lookup: SUCCESS`);

    const recipientPhone = rental.renter.phone;
    console.log(`[OTP] recipient phone exists: ${!!recipientPhone}`);
    
    if (!recipientPhone) {
      return res.status(400).json({ success: false, message: "Recipient phone number is not available. Please update the recipient profile." });
    }

    // Phone normalization (simulated logic for logging as requested, actual normalization happens in smsService)
    try {
      const { normalizePhoneNumber } = require("../utils/phone.utils");
      normalizePhoneNumber(recipientPhone);
      console.log(`[OTP] phone normalization: SUCCESS`);
    } catch (e) {
      console.log(`[OTP] phone normalization: FAILED`);
    }

    // 3. Generate OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const otpHash = crypto.createHash("sha256").update(otp).digest("hex");
    console.log(`[OTP] OTP generation: SUCCESS`);

    // 4. Update Firestore with OTP Hash and Expiry (10 mins)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    try {
      await db.collection("deliveries").doc(deliveryId).update({
        otpHash,
        otpCreatedAt: new Date().toISOString(),
        otpExpiresAt: expiresAt,
        otpAttempts: 0,
        otpVerified: false,
      });
      console.log(`[OTP] Firestore OTP hash write: SUCCESS`);
    } catch (e) {
      console.log(`[OTP] Firestore OTP hash write: FAILED`);
      throw e;
    }

    // TWILIO DIAGNOSTICS
    console.log('[OTP] TWILIO CONFIG:');
    console.log(`accountSid present: ${!!process.env.TWILIO_ACCOUNT_SID}`);
    console.log(`authToken present: ${!!process.env.TWILIO_AUTH_TOKEN}`);
    console.log(`fromNumber present: ${!!process.env.TWILIO_PHONE_NUMBER}`);

    // 5. Send SMS to recipient
    const isDemoMode = process.env.DELIVERY_OTP_DEMO_MODE === 'true';
    console.log(`[DELIVERY OTP] DEMO MODE: ${isDemoMode}`);
    console.log('[DELIVERY OTP] Twilio send attempted');
    
    const messageBody = `Your MediShare delivery OTP is ${otp}. Please share this with the delivery partner to receive your equipment.`;
    
    try {
      await smsService.sendSms(recipientPhone, messageBody);
      console.log(`[OTP] Twilio SMS SUCCESS`);
    } catch (twilioError) {
      console.log(`[OTP] Twilio SMS FAILED`);
      console.log(`[OTP] Twilio error code: ${twilioError.code}`);
      console.log(`[OTP] Twilio error message: ${twilioError.message}`);
      
      if (isDemoMode) {
        console.log('[DELIVERY OTP] Demo fallback used');
        console.log('[OTP] HTTP RESPONSE: 200 (DEMO FALLBACK)');
        return res.status(200).json({
          success: true,
          demoMode: true,
          message: "DEMO ONLY: OTP generated because SMS delivery is unavailable.",
          otp: otp
        });
      }
      
      console.log('[OTP] HTTP RESPONSE: 500');
      return res.status(500).json({ 
        success: false, 
        message: "Unable to send delivery OTP. Please try again.", 
        errorCode: `TWILIO_ERR_${twilioError.code}`
      });
    }
    
    console.log('[OTP] HTTP RESPONSE: 200');
    return res.status(200).json({
      success: true,
      demoMode: false,
      message: "OTP generated and sent to recipient successfully.",
      // NEVER SEND OTP IN RESPONSE!
    });
  } catch (error) {
    console.error("Generate OTP Error:", error);
    console.log('[OTP] HTTP RESPONSE: 500');
    return res.status(500).json({ 
      success: false, 
      message: "Unable to send delivery OTP. Please try again.",
      errorCode: error.code ? `ERR_${error.code}` : "UNKNOWN_ERR" 
    });
  }
};

// Verify Delivery OTP
const verifyDeliveryOtp = async (req, res) => {
  try {
    const { deliveryId } = req.params;
    const { otp, rentalId } = req.body;
    const db = getFirestore();

    if (!otp) {
      return res.status(400).json({ success: false, message: "OTP is required." });
    }

    const deliveryRef = db.collection("deliveries").doc(deliveryId);
    
    // Firestore Transaction for verification
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(deliveryRef);
      if (!doc.exists) throw new Error("Delivery not found");

      const data = doc.data();
      
      if (data.otpVerified) {
        throw new Error("OTP already verified");
      }

      const attempts = data.otpAttempts || 0;
      if (attempts >= 5) {
        throw new Error("Too many attempts. Please request a new OTP.");
      }

      if (data.otpExpiresAt) {
        const expiresAt = new Date(data.otpExpiresAt);
        if (new Date() > expiresAt) {
          throw new Error("Delivery OTP has expired.");
        }
      }

      const enteredHash = crypto.createHash("sha256").update(otp.toString()).digest("hex");

      if (data.otpHash !== enteredHash) {
        transaction.update(deliveryRef, { otpAttempts: attempts + 1 });
        throw new Error("Invalid delivery OTP.");
      }

      // Success
      transaction.update(deliveryRef, {
        status: "DELIVERED",
        deliveredAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        otpVerified: true,
        verifiedAt: new Date().toISOString(),
      });
    });

    // Also update rental status in Prisma if rentalId is provided
    if (rentalId) {
      await prisma.rental.update({
        where: { id: rentalId },
        data: {
          status: "ACTIVE",
          updatedAt: new Date(),
        },
      });
    }

    return res.status(200).json({
      success: true,
      message: "OTP verified successfully.",
    });
  } catch (error) {
    console.error("Verify OTP Error:", error);
    return res.status(400).json({ success: false, message: error.message || "Invalid delivery OTP." });
  }
};

module.exports = {
  generateDeliveryOtp,
  verifyDeliveryOtp,
};
