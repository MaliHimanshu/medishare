// equipmentLocation.service.js
// Real PostgreSQL nearby equipment search using Haversine distance.
// No dummy data; uses Equipment latitude/longitude and joins owner info.

const prisma = require("../lib/prisma");

/**
 * Finds nearby equipment.
 * Parameters:
 *   latitude  – user latitude (decimal degrees)
 *   longitude – user longitude (decimal degrees)
 *   radiusKm  – radius in kilometres (default 20)
 *   mode      – optional equipment mode filter (DONATE, RENT, BOTH)
 *   category  – optional equipment category filter (case‑insensitive)
 */
const findNearbyEquipment = async ({
  latitude,
  longitude,
  radiusKm = 20,
  mode,
  category,
}) => {
  if (latitude == null || longitude == null) {
    throw new Error("Latitude and longitude must be provided");
  }

  const whereClauses = [];
  const params = [latitude, longitude, radiusKm]; // $1 $2 $3

  // Equipment must be AVAILABLE – use exact enum value from Prisma schema.
  whereClauses.push("e.status = 'AVAILABLE'");
  whereClauses.push("e.latitude IS NOT NULL");
  whereClauses.push("e.longitude IS NOT NULL");

  // Mode filter respecting schema enum values.
  if (mode) {
    const allowed = ["DONATE", "RENT", "BOTH"];
    if (!allowed.includes(mode)) {
      throw new Error("Invalid equipment mode");
    }
    if (mode === "DONATE") {
      whereClauses.push("e.mode IN ('DONATE','BOTH')");
    } else if (mode === "RENT") {
      whereClauses.push("e.mode IN ('RENT','BOTH')");
    } else {
      whereClauses.push("e.mode = 'BOTH'");
    }
  }

  // Category filter – case‑insensitive exact match.
  if (category) {
    whereClauses.push(`LOWER(e.category) = LOWER($${params.length + 1})`);
    params.push(category);
  }

  const whereSql = whereClauses.length ? "WHERE " + whereClauses.join(" AND ") : "";

  // Haversine expression (Earth radius ≈ 6371 km).
  const haversine = `
    (6371 * acos(
      cos(radians($1)) * cos(radians(e.latitude)) * cos(radians(e.longitude) - radians($2)) +
      sin(radians($1)) * sin(radians(e.latitude))
    ))`;

  const sql = `
    SELECT e.*, u.name AS "ownerName", u.phone AS "ownerPhone", u.address AS "ownerAddress",
      ${haversine} AS distance
    FROM "Equipment" e
    JOIN "User" u ON e."ownerId" = u.id
    ${whereSql}
    AND ${haversine} <= $3
    ORDER BY distance ASC;
  `;

  const rows = await prisma.$queryRawUnsafe(sql, ...params);

  return rows.map((item) => ({
    id: item.id,
    name: item.name,
    category: item.category,
    description: item.description,
    condition: item.condition,
    images: item.images,
    mode: item.mode,
    status: item.status,
    rentalPricePerDay: item.rentalPricePerDay ? item.rentalPricePerDay.toString() : null,
    securityDeposit: item.securityDeposit ? item.securityDeposit.toString() : null,
    latitude: item.latitude,
    longitude: item.longitude,
    address: item.address,
    owner: {
      id: item.ownerId,
      name: item.ownerName,
      phone: item.ownerPhone,
      address: item.ownerAddress,
    },
    distance: Number(item.distance.toFixed(2)),
    distanceUnit: "km",
  }));
};

module.exports = { findNearbyEquipment };