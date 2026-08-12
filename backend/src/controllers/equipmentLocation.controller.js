const {
    findNearbyEquipment,
} = require("../services/equipmentLocation.service");

const getNearbyEquipment = async (req, res) => {
    try {
        const {
            latitude,
            longitude,
            radius = "20",
            mode,
            category,
        } = req.query;

        const parsedLatitude = Number(latitude);
        const parsedLongitude = Number(longitude);
        const parsedRadius = Number(radius);

        if (
            latitude === undefined ||
            Number.isNaN(parsedLatitude) ||
            parsedLatitude < -90 ||
            parsedLatitude > 90
        ) {
            return res.status(400).json({
                success: false,
                message: "Valid latitude is required",
            });
        }

        if (
            longitude === undefined ||
            Number.isNaN(parsedLongitude) ||
            parsedLongitude < -180 ||
            parsedLongitude > 180
        ) {
            return res.status(400).json({
                success: false,
                message: "Valid longitude is required",
            });
        }

        if (
            Number.isNaN(parsedRadius) ||
            parsedRadius <= 0 ||
            parsedRadius > 100
        ) {
            return res.status(400).json({
                success: false,
                message: "Radius must be between 1 and 100 km",
            });
        }

        const equipment = await findNearbyEquipment({
            latitude: parsedLatitude,
            longitude: parsedLongitude,
            radiusKm: parsedRadius,
            mode,
            category,
        });

        return res.status(200).json({
            success: true,
            count: equipment.length,
            location: {
                latitude: parsedLatitude,
                longitude: parsedLongitude,
            },
            radius: parsedRadius,
            radiusUnit: "km",
            equipment,
        });
    } catch (error) {
        console.error("Get nearby equipment error:", error);

        return res.status(500).json({
            success: false,
            message: "Failed to find nearby equipment",
        });
    }
};

module.exports = {
    getNearbyEquipment,
};