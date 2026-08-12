const prisma = require("../lib/prisma");
const { calculateDistance } = require("../utils/distance");

const findNearbyEquipment = async ({
    latitude,
    longitude,
    radiusKm = 20,
    mode,
    category,
}) => {
    const latitudeRange = radiusKm / 111;

    const longitudeRange =
        radiusKm / (111 * Math.cos((latitude * Math.PI) / 180));

    const where = {
        status: "AVAILABLE",

        latitude: {
            not: null,
            gte: latitude - latitudeRange,
            lte: latitude + latitudeRange,
        },

        longitude: {
            not: null,
            gte: longitude - longitudeRange,
            lte: longitude + longitudeRange,
        },
    };

    if (mode) {
        if (!["DONATE", "RENT", "BOTH"].includes(mode)) {
            throw new Error("Invalid equipment mode");
        }

        if (mode === "DONATE") {
            where.mode = {
                in: ["DONATE", "BOTH"],
            };
        } else if (mode === "RENT") {
            where.mode = {
                in: ["RENT", "BOTH"],
            };
        } else {
            where.mode = "BOTH";
        }
    }

    if (category) {
        where.category = {
            equals: category,
            mode: "insensitive",
        };
    }

    const equipment = await prisma.equipment.findMany({
        where,

        include: {
            owner: {
                select: {
                    id: true,
                    name: true,
                    phone: true,
                    address: true,
                },
            },
        },

        orderBy: {
            createdAt: "desc",
        },
    });

    return equipment
        .map((item) => {
            const distance = calculateDistance(
                latitude,
                longitude,
                item.latitude,
                item.longitude
            );

            return {
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

                latitude: item.latitude,
                longitude: item.longitude,
                address: item.address,

                owner: item.owner,

                distance: Number(distance.toFixed(2)),
                distanceUnit: "km",
            };
        })
        .filter((item) => item.distance <= radiusKm)
        .sort((a, b) => a.distance - b.distance);
};

module.exports = {
    findNearbyEquipment,
};