const prisma = require("../config/prisma");

const TRACKING_ALLOWED_STATUS = "ACTIVE";

const getRentalWithParties = async (rentalId) => {
  const rental = await prisma.rental.findUnique({
    where: { id: rentalId },
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

  return rental;
};

const assertRentalIsActive = (rental) => {
  if (rental.status !== TRACKING_ALLOWED_STATUS) {
    throw new Error(
      "Live tracking is only available while the rental is ACTIVE."
    );
  }
};

const assertCanReadTracking = (rental, userId, userRole) => {
  const isRenter = rental.renterId === userId;
  const isOwner = rental.equipment.ownerId === userId;
  const isAdmin = userRole === "ADMIN";

  if (!isRenter && !isOwner && !isAdmin) {
    throw new Error("You are not authorized to view this tracking session.");
  }
};

const assertCanPublishTracking = (rental, userId) => {
  if (rental.renterId !== userId) {
    throw new Error("Only the renter can publish live location updates.");
  }
};

const startTracking = async (rentalId, userId) => {
  const rental = await getRentalWithParties(rentalId);
  assertRentalIsActive(rental);
  assertCanPublishTracking(rental, userId);

  const updated = await prisma.rental.update({
    where: { id: rentalId },
    data: { isTrackingActive: true },
    include: {
      renter: {
        select: { id: true, name: true, email: true, phone: true },
      },
      equipment: {
        include: {
          owner: {
            select: { id: true, name: true, email: true, phone: true },
          },
        },
      },
    },
  });

  try {
    await prisma.notification.create({
      data: {
        userId: rental.equipment.ownerId,
        title: "Live Tracking Started",
        message: `${rental.renter.name} started sharing live location for "${rental.equipment.name}".`,
        type: "GENERAL",
      },
    });
  } catch (err) {
    console.error("Failed to create tracking start notification:", err);
  }

  return updated;
};

const stopTracking = async (rentalId, userId, userRole, { force = false } = {}) => {
  const rental = await getRentalWithParties(rentalId);

  const isRenter = rental.renterId === userId;
  const isOwner = rental.equipment.ownerId === userId;
  const isAdmin = userRole === "ADMIN";

  if (!force && !isRenter && !isOwner && !isAdmin) {
    throw new Error("You are not authorized to stop this tracking session.");
  }

  if (!rental.isTrackingActive) {
    return rental;
  }

  const updated = await prisma.rental.update({
    where: { id: rentalId },
    data: { isTrackingActive: false },
    include: {
      renter: {
        select: { id: true, name: true, email: true, phone: true },
      },
      equipment: {
        include: {
          owner: {
            select: { id: true, name: true, email: true, phone: true },
          },
        },
      },
    },
  });

  const notifyUserId =
    userId === rental.renterId ? rental.equipment.ownerId : rental.renterId;

  try {
    await prisma.notification.create({
      data: {
        userId: notifyUserId,
        title: "Live Tracking Stopped",
        message: `Live location sharing for "${rental.equipment.name}" has ended.`,
        type: "GENERAL",
      },
    });
  } catch (err) {
    console.error("Failed to create tracking stop notification:", err);
  }

  return updated;
};

const publishPing = async (rentalId, userId, data) => {
  const rental = await getRentalWithParties(rentalId);
  assertRentalIsActive(rental);
  assertCanPublishTracking(rental, userId);

  if (!rental.isTrackingActive) {
    throw new Error(
      "Tracking is not active. Start tracking before publishing location."
    );
  }

  const { latitude, longitude, accuracy, speed, heading } = data;
  const recordedAt = new Date();

  const ping = await prisma.equipmentTrackingPing.create({
    data: {
      rentalId,
      equipmentId: rental.equipmentId,
      latitude,
      longitude,
      accuracy: accuracy ?? null,
      speed: speed ?? null,
      heading: heading ?? null,
      recordedAt,
    },
  });

  await prisma.rental.update({
    where: { id: rentalId },
    data: {
      lastTrackedLatitude: latitude,
      lastTrackedLongitude: longitude,
      lastTrackedAt: recordedAt,
    },
  });

  return ping;
};

const getLatestTracking = async (rentalId, userId, userRole) => {
  const rental = await getRentalWithParties(rentalId);
  assertCanReadTracking(rental, userId, userRole);
  assertRentalIsActive(rental);

  return {
    rentalId: rental.id,
    status: rental.status,
    isTrackingActive: rental.isTrackingActive,
    equipment: {
      id: rental.equipment.id,
      name: rental.equipment.name,
      category: rental.equipment.category,
      latitude: rental.equipment.latitude,
      longitude: rental.equipment.longitude,
      address: rental.equipment.address,
    },
    renter: rental.renter,
    owner: rental.equipment.owner,
    latest: rental.lastTrackedAt
      ? {
          latitude: rental.lastTrackedLatitude,
          longitude: rental.lastTrackedLongitude,
          recordedAt: rental.lastTrackedAt,
        }
      : null,
  };
};

const getTrackingHistory = async (rentalId, userId, userRole, query) => {
  const rental = await getRentalWithParties(rentalId);
  assertCanReadTracking(rental, userId, userRole);
  assertRentalIsActive(rental);

  const where = { rentalId };

  if (query.since) {
    where.recordedAt = { gte: new Date(query.since) };
  }

  const pings = await prisma.equipmentTrackingPing.findMany({
    where,
    orderBy: { recordedAt: "asc" },
    take: query.limit,
    select: {
      id: true,
      latitude: true,
      longitude: true,
      accuracy: true,
      speed: true,
      heading: true,
      recordedAt: true,
    },
  });

  return {
    rentalId,
    count: pings.length,
    pings,
  };
};

const stopTrackingForRentalInternal = async (rentalId) => {
  const rental = await prisma.rental.findUnique({
    where: { id: rentalId },
  });

  if (!rental || !rental.isTrackingActive) {
    return;
  }

  await prisma.rental.update({
    where: { id: rentalId },
    data: { isTrackingActive: false },
  });
};

module.exports = {
  startTracking,
  stopTracking,
  publishPing,
  getLatestTracking,
  getTrackingHistory,
  stopTrackingForRentalInternal,
  TRACKING_ALLOWED_STATUS,
};
