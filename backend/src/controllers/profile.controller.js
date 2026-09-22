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

/**
 * PATCH /api/profile/verify/:userId (Admin only)
 */
const verifyUser = async (req, res, next) => {
  try {
    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "Only administrators can verify organization accounts.",
      });
    }

    const { status } = req.body;
    if (!["PENDING", "VERIFIED", "REJECTED"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Status must be PENDING, VERIFIED, or REJECTED.",
      });
    }

    const prisma = require("../config/prisma");
    const updatedUser = await prisma.user.update({
      where: { id: req.params.userId },
      data: { verificationStatus: status },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        organizationName: true,
        verificationStatus: true,
      },
    });

    return res.status(200).json({
      success: true,
      message: `User verification status updated to ${status}.`,
      data: updatedUser,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMyProfile,
  updateMyProfile,
  verifyUser,
};