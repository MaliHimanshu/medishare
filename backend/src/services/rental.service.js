const crypto = require("crypto");
const prisma = require("../config/prisma");
const { getRazorpayInstance } = require("../config/razorpay");
const {
  stopTrackingForRentalInternal,
} = require("./tracking.service");

// Create Rental
const createRental = async (userId, data) => {
  const { equipmentId, startDate, endDate } = data;

  const start = new Date(startDate);
  const end = new Date(endDate);

  if (end <= start) {
    throw new Error("End date must be after start date.");
  }

  // Calculate number of days (minimum 1 day)
  const diffTime = end.getTime() - start.getTime();
  const numberOfDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));

  if (numberOfDays <= 0 || numberOfDays > 365) {
    throw new Error("Rental duration must be between 1 and 365 days.");
  }

  // Check equipment exists
  const equipment = await prisma.equipment.findUnique({
    where: { id: equipmentId },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });

  if (!equipment) {
    throw new Error("Equipment not found.");
  }

  // Equipment must be available
  if (equipment.status !== "AVAILABLE") {
    throw new Error("Equipment is not currently available for rent.");
  }

  // Equipment mode must be RENT or BOTH (cannot be DONATE)
  if (equipment.mode === "DONATE") {
    throw new Error("This equipment is available for donation only and cannot be rented.");
  }

  // Equipment must have a positive rental price
  if (!equipment.rentalPricePerDay || Number(equipment.rentalPricePerDay) <= 0) {
    throw new Error("This equipment does not have a valid rental price configured.");
  }

  // Prevent owner from renting own equipment
  if (equipment.ownerId === userId) {
    throw new Error("You cannot rent your own equipment.");
  }

  // Check for overlapping active, approved, or pending rentals
  const overlappingRental = await prisma.rental.findFirst({
    where: {
      equipmentId,
      status: {
        in: ["PENDING", "APPROVED", "ACTIVE"],
      },
      startDate: {
        lte: end,
      },
      endDate: {
        gte: start,
      },
    },
  });

  if (overlappingRental) {
    throw new Error("Equipment is already booked or requested for overlapping dates.");
  }

  const rentalPricePerDay = Number(equipment.rentalPricePerDay) || 0;
  const securityDeposit = Number(equipment.securityDeposit) || 0;
  const rentalAmount = rentalPricePerDay * numberOfDays;
  const totalAmount = rentalAmount + securityDeposit;

  // Create rental record
  const rental = await prisma.rental.create({
    data: {
      equipmentId,
      renterId: userId,
      startDate: start,
      endDate: end,
      numberOfDays,
      rentalAmount,
      securityDeposit,
      totalAmount,
      status: "PENDING",
      paymentStatus: "PENDING",
    },
    include: {
      renter: {
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
        },
      },
      equipment: {
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
            },
          },
        },
      },
    },
  });

  // Notify the equipment owner
  try {
    await prisma.notification.create({
      data: {
        userId: equipment.ownerId,
        title: "New Rental Request",
        message: `${rental.renter.name} requested to rent "${equipment.name}" for ${numberOfDays} day(s).`,
        type: "REQUEST",
      },
    });
  } catch (err) {
    console.error("Failed to create rental notification:", err);
  }

  return rental;
};

// Get All Rentals (scoped by role)
const getAllRentals = async (user) => {
  let where = {};
  if (user && user.role !== "ADMIN") {
    if (user.role === "DONOR") {
      // Donors only see rentals for their owned equipment
      where = { equipment: { ownerId: user.id } };
    } else if (user.role === "RECIPIENT") {
      // Recipients only see their own rentals
      where = { renterId: user.id };
    } else if (user.role === "HOSPITAL" || user.role === "NGO") {
      // Hospitals and NGOs see rentals they created or for equipment they own
      where = {
        OR: [
          { equipment: { ownerId: user.id } },
          { renterId: user.id },
        ],
      };
    }
  }

  return prisma.rental.findMany({
    where,
    include: {
      renter: {
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
        },
      },
      equipment: {
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
            },
          },
        },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });
};

// Get Rental By ID
const getRentalById = async (id, user) => {
  const rental = await prisma.rental.findUnique({
    where: { id },
    include: {
      renter: {
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
        },
      },
      equipment: {
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
            },
          },
        },
      },
    },
  });

  if (!rental) {
    throw new Error("Rental not found.");
  }

  if (user && user.role !== "ADMIN") {
    const isOwner = rental.equipment.ownerId === user.id;
    const isRenter = rental.renterId === user.id;
    if (!isOwner && !isRenter) {
      throw new Error("You are not authorized to view this rental.");
    }
  }

  return rental;
};

// Update Rental Status
const updateRentalStatus = async (id, status, user) => {
  const rental = await prisma.rental.findUnique({
    where: { id },
    include: {
      equipment: true,
      renter: true,
    },
  });

  if (!rental) {
    throw new Error("Rental not found.");
  }

  if (user && user.role !== "ADMIN") {
    const isOwner = rental.equipment.ownerId === user.id;
    const isRenter = rental.renterId === user.id;

    if (!isOwner && !isRenter) {
      throw new Error("You are not authorized to update this rental.");
    }

    // Only owner/admin can approve, activate, reject or mark returned
    // Renter can only cancel their own pending request
    if (isRenter && !isOwner) {
      if (status !== "CANCELLED") {
        throw new Error("Renters can only cancel their pending rental requests.");
      }
    }
  }

  const updatedRental = await prisma.rental.update({
    where: { id },
    data: { status },
    include: {
      renter: {
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
        },
      },
      equipment: {
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
            },
          },
        },
      },
    },
  });

  // Handle side-effects for statuses
  if (status === "APPROVED") {
    try {
      await prisma.notification.create({
        data: {
          userId: rental.renterId,
          title: "Rental Approved",
          message: `Your rental request for "${rental.equipment.name}" has been approved by the owner.`,
          type: "APPROVAL",
        },
      });
    } catch (err) {
      console.error("Failed to create approval notification:", err);
    }
  } else if (status === "ACTIVE") {
    // Mark equipment as RENTED
    await prisma.equipment.update({
      where: { id: rental.equipmentId },
      data: { status: "RENTED" },
    });

    try {
      await prisma.notification.create({
        data: {
          userId: rental.renterId,
          title: "Rental Active",
          message: `Your rental for "${rental.equipment.name}" is now active.`,
          type: "GENERAL",
        },
      });
    } catch (err) {
      console.error("Failed to create active notification:", err);
    }
  } else if (status === "RETURNED") {
    // Mark equipment as AVAILABLE
    await prisma.equipment.update({
      where: { id: rental.equipmentId },
      data: { status: "AVAILABLE" },
    });

    await stopTrackingForRentalInternal(id);

    // Notify renter
    try {
      await prisma.notification.create({
        data: {
          userId: rental.renterId,
          title: "Rental Returned",
          message: `Equipment "${rental.equipment.name}" has been marked as returned.`,
          type: "GENERAL",
        },
      });
    } catch (err) {
      console.error("Failed to create return notification for renter:", err);
    }

    // Notify owner
    try {
      await prisma.notification.create({
        data: {
          userId: rental.equipment.ownerId,
          title: "Equipment Returned",
          message: `Equipment "${rental.equipment.name}" has been returned by ${rental.renter.name}.`,
          type: "GENERAL",
        },
      });
    } catch (err) {
      console.error("Failed to create return notification for owner:", err);
    }
  } else if (status === "REJECTED" || status === "CANCELLED") {
    await stopTrackingForRentalInternal(id);

    // Reset equipment to AVAILABLE if it was RENTED
    if (rental.equipment.status === "RENTED") {
      await prisma.equipment.update({
        where: { id: rental.equipmentId },
        data: { status: "AVAILABLE" },
      });
    }

    if (status === "REJECTED") {
      try {
        await prisma.notification.create({
          data: {
            userId: rental.renterId,
            title: "Rental Rejected",
            message: `Your rental request for "${rental.equipment.name}" was not approved.`,
            type: "REJECTION",
          },
        });
      } catch (err) {
        console.error("Failed to create rejection notification:", err);
      }
    }
  }

  return updatedRental;
};

// Delete Rental
const deleteRental = async (id) => {
  const rental = await prisma.rental.findUnique({
    where: { id },
  });

  if (!rental) {
    throw new Error("Rental not found.");
  }

  await prisma.rental.delete({
    where: { id },
  });

  return {
    success: true,
    message: "Rental record deleted successfully.",
  };
};

const extractRazorpayErrorMessage = (err) => {
  if (!err) return "Unable to connect to payment service.";
  if (typeof err === "string" && err.trim().length > 0 && err !== "undefined") return err;
  if (err.error && typeof err.error === "object" && err.error.description && err.error.description !== "undefined") {
    return String(err.error.description);
  }
  if (err.error && typeof err.error === "string" && err.error !== "undefined") {
    return err.error;
  }
  if (err.message && typeof err.message === "string" && err.message !== "undefined" && err.message.trim().length > 0) {
    return err.message;
  }
  if (err.description && typeof err.description === "string" && err.description !== "undefined") {
    return err.description;
  }
  if (err.statusCode) {
    return `Payment gateway returned status code ${err.statusCode}`;
  }
  return "Unable to process payment order.";
};

// Create Razorpay Order for Rental
const createRazorpayOrder = async (rentalId, userId) => {
  const rental = await prisma.rental.findUnique({
    where: { id: rentalId },
    include: {
      equipment: true,
      renter: true,
    },
  });

  if (!rental) {
    throw new Error(`Rental with ID '${rentalId}' not found in database.`);
  }

  if (rental.renterId !== userId) {
    throw new Error("You are not authorized to pay for this rental.");
  }

  if (rental.paymentStatus === "PAID") {
    throw new Error("This rental is already paid.");
  }

  const rawTotalAmount = Number(rental.totalAmount);
  if (isNaN(rawTotalAmount) || rawTotalAmount <= 0) {
    throw new Error(`Invalid total amount for rental: ${rental.totalAmount}`);
  }

  // Amount in paise (1 INR = 100 paise) as an exact integer
  const amountInPaise = Math.round(rawTotalAmount * 100);
  if (!Number.isInteger(amountInPaise) || amountInPaise <= 0) {
    throw new Error(`Calculated amount in paise is invalid: ${amountInPaise}`);
  }

  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret) {
    throw new Error("Razorpay credentials (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET) are missing in server environment variables.");
  }

  let order;
  console.log("Razorpay create-order request", {
    rentalId,
    amount: amountInPaise,
    currency: "INR",
  });

  try {
    const razorpay = getRazorpayInstance();
    const receiptId = `r_${rental.id.replace(/[^a-zA-Z0-9]/g, "").slice(-28)}`;

    order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: receiptId,
      notes: {
        rentalId: rental.id,
        equipmentId: rental.equipmentId,
        renterId: rental.renterId,
      },
    });
    console.log("Razorpay order created successfully:", order.id);
  } catch (error) {
    console.error("RAZORPAY CREATE ORDER ERROR", {
      message: error?.message,
      statusCode: error?.statusCode,
      error: error?.error,
    });
    const detailMsg = extractRazorpayErrorMessage(error);

    // In development mode, if key is test/dummy (e.g. 1234567890) or Razorpay returns 401 Unauthorized,
    // fallback to a mock order ID so local development/testing of payment flow can proceed smoothly.
    if (process.env.NODE_ENV === "development" && (keyId.includes("12345") || keyId.includes("test") || error?.statusCode === 401)) {
      console.warn("Using fallback mock Razorpay order for development testing.");
      order = {
        id: `order_dev_${Date.now()}_${rental.id.replace(/[^a-zA-Z0-9]/g, "").slice(-6)}`,
        amount: amountInPaise,
        currency: "INR",
      };
    } else {
      throw new Error(`Failed to create Razorpay order: ${detailMsg}`);
    }
  }

  if (!order || !order.id) {
    throw new Error("Razorpay API returned an invalid response with missing order ID.");
  }

  // Save order ID on rental record
  await prisma.rental.update({
    where: { id: rentalId },
    data: {
      razorpayOrderId: order.id,
    },
  });

  return {
    orderId: order.id,
    amount: amountInPaise,
    currency: "INR",
    keyId: keyId,
    rentalId: rental.id,
    totalAmount: rental.totalAmount,
    equipmentName: rental.equipment ? rental.equipment.name : "Medical Equipment",
    renterName: rental.renter ? rental.renter.name : "Renter",
    renterEmail: rental.renter ? rental.renter.email : "",
    renterPhone: rental.renter ? rental.renter.phone : "",
  };
};

// Verify Razorpay Payment (Server-side HMAC SHA256 Signature Verification)
const verifyRazorpayPayment = async (rentalId, userId, paymentData) => {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = paymentData;

  const rental = await prisma.rental.findUnique({
    where: { id: rentalId },
    include: {
      equipment: true,
      renter: true,
    },
  });

  if (!rental) {
    throw new Error("Rental not found.");
  }

  if (rental.renterId !== userId) {
    throw new Error("You are not authorized to verify this payment.");
  }

  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  
  if (!keySecret) {
    throw new Error("Razorpay secret not configured on the server.");
  }

  // Official Razorpay HMAC-SHA256 signature verification
  const body = razorpayOrderId + "|" + razorpayPaymentId;
  const expectedSignature = crypto
    .createHmac("sha256", keySecret)
    .update(body.toString())
    .digest("hex");

  let isAuthentic = expectedSignature === razorpaySignature;

  // In development mode, accept dev order signatures for local test simulation
  if (!isAuthentic && process.env.NODE_ENV === "development" && (razorpayOrderId.startsWith("order_dev_") || razorpaySignature.startsWith("simulated_") || razorpaySignature.includes("test"))) {
    console.warn("Accepting dev mode simulated signature verification for mock order:", razorpayOrderId);
    isAuthentic = true;
  }

  if (!isAuthentic) {
    // Update payment status to FAILED on verification mismatch
    await prisma.rental.update({
      where: { id: rentalId },
      data: {
        paymentStatus: "FAILED",
      },
    });
    throw new Error("Payment signature verification failed. Invalid payment.");
  }

  // Payment signature verified successfully!
  const updatedRental = await prisma.rental.update({
    where: { id: rentalId },
    data: {
      paymentStatus: "PAID",
      status: "APPROVED",
      razorpayOrderId,
      razorpayPaymentId,
    },
    include: {
      equipment: {
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      },
      renter: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });

  // Notify owner
  try {
    await prisma.notification.create({
      data: {
        userId: rental.equipment.ownerId,
        title: "Rental Payment Received",
        message: `Payment of ₹${rental.totalAmount} received from ${rental.renter.name} for "${rental.equipment.name}".`,
        type: "GENERAL",
      },
    });
  } catch (err) {
    console.error("Failed to create payment notification for owner:", err);
  }

  // Notify renter
  try {
    await prisma.notification.create({
      data: {
        userId: rental.renterId,
        title: "Payment Successful",
        message: `Your payment of ₹${rental.totalAmount} for "${rental.equipment.name}" was successful!`,
        type: "GENERAL",
      },
    });
  } catch (err) {
    console.error("Failed to create payment notification for renter:", err);
  }

  return updatedRental;
};

// Record Payment Failure
const recordPaymentFailure = async (rentalId, userId) => {
  const rental = await prisma.rental.findUnique({
    where: { id: rentalId },
  });

  if (!rental) {
    throw new Error("Rental not found.");
  }

  if (rental.renterId !== userId) {
    throw new Error("You are not authorized to update this payment.");
  }

  return prisma.rental.update({
    where: { id: rentalId },
    data: {
      paymentStatus: "FAILED",
    },
  });
};

module.exports = {
  createRental,
  getAllRentals,
  getRentalById,
  updateRentalStatus,
  deleteRental,
  createRazorpayOrder,
  verifyRazorpayPayment,
  recordPaymentFailure,
};
