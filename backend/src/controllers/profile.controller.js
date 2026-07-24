const {
  getUserProfile,
  updateProfile,
} = require("../services/profile.service");

const {
  updateProfileSchema,
} = require("../validators/profile.validator");

/**
 * GET /api/profile
 */
const getMyProfile = async (req, res, next) => {
  try {
    const user = await getUserProfile(req.user.id);

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/profile
 */
const updateMyProfile = async (req, res, next) => {
  try {
    const validatedData = updateProfileSchema.parse(req.body);

    const updatedUser = await updateProfile(
      req.user.id,
      validatedData
    );

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully.",
      data: updatedUser,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMyProfile,
  updateMyProfile,
};