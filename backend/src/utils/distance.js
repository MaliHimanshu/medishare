const calculateDistance = (
    latitude1,
    longitude1,
    latitude2,
    longitude2
) => {
    const EARTH_RADIUS_KM = 6371;

    const toRadians = (degrees) => {
        return (degrees * Math.PI) / 180;
    };

    const deltaLatitude = toRadians(latitude2 - latitude1);
    const deltaLongitude = toRadians(longitude2 - longitude1);

    const a =
        Math.sin(deltaLatitude / 2) ** 2 +
        Math.cos(toRadians(latitude1)) *
        Math.cos(toRadians(latitude2)) *
        Math.sin(deltaLongitude / 2) ** 2;

    const c =
        2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return EARTH_RADIUS_KM * c;
};

module.exports = {
    calculateDistance,
};