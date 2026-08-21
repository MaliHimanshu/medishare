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
 *   category  – optional equipment category filter (case-insensitive)
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

  // Base params: $1=lat, $2=lng, $3=radiusKm
  const params = [Number(latitude), Number(longitude), Number(radiusKm)];

  // Build optional extra WHERE conditions (applied AFTER distance is computed)
  const extraClauses = [];

  // Mode filter – DONATE/RENT items are included if mode is BOTH
  if (mode) {
    const allowed = ["DONATE", "RENT", "BOTH"];
    if (!allowed.includes(mode.toUpperCase())) {
      throw new Error("Invalid equipment mode. Allowed: DONATE, RENT, BOTH");
    }
    const m = mode.toUpperCase();
    if (m === "DONATE") {
      extraClauses.push(`mode IN ('DONATE','BOTH')`);
    } else if (m === "RENT") {
      extraClauses.push(`mode IN ('RENT','BOTH')`);
    }
    // BOTH = no extra filter (already included by default)
  }

  // Category filter – case-insensitive
  if (category) {
    params.push(category);
    extraClauses.push(`LOWER(category) = LOWER($${params.length})`);
  }

  const extraWhere =
    extraClauses.length > 0 ? `AND ${extraClauses.join(" AND ")}` : "";

  // Haversine formula (Earth radius ≈ 6371 km)
  const sql = `
    WITH cte AS (
      SELECT
        e.*,
        u.name        AS "ownerName",
        u.phone       AS "ownerPhone",
        u.address     AS "ownerAddress",
        (6371 * acos(
          LEAST(1.0,
            cos(radians($1)) * cos(radians(e.latitude))
              * cos(radians(e.longitude) - radians($2))
            + sin(radians($1)) * sin(radians(e.latitude))
          )
        )) AS distance
      FROM "equipment" e
      JOIN "users" u ON e."ownerId" = u.id
      WHERE
        e.status    = 'AVAILABLE'
        AND e.latitude  IS NOT NULL
        AND e.longitude IS NOT NULL
        ${extraWhere}
    )
    SELECT *
    FROM   cte
    WHERE  distance <= $3
    ORDER  BY distance ASC;
  `;

  console.log("[NearbyEquipment] SQL params:", params);
  const rows = await prisma.$queryRawUnsafe(sql, ...params);
  console.log(`[NearbyEquipment] Found ${rows.length} result(s) within ${radiusKm} km`);

  return rows.map((item) => ({
    id: item.id,
    name: item.name,
    category: item.category,
    description: item.description,
    condition: item.condition,
    images: item.images,
    mode: item.mode,
    status: item.status,
    rentalPricePerDay: item.rentalPricePerDay
      ? item.rentalPricePerDay.toString()
      : null,
    securityDeposit: item.securityDeposit
      ? item.securityDeposit.toString()
      : null,
    latitude: item.latitude ? Number(item.latitude) : null,
    longitude: item.longitude ? Number(item.longitude) : null,
    address: item.address,
    owner: {
      id: item.ownerId,
      name: item.ownerName,
      phone: item.ownerPhone,
      address: item.ownerAddress,
    },
    distance: Number(Number(item.distance).toFixed(2)),
    distanceUnit: "km",
  }));
};

module.exports = { findNearbyEquipment };