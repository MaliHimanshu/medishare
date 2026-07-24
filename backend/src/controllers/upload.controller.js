const cloudinary = require("../config/cloudinary");

/**
 * @desc    Upload single image to Cloudinary
 * @route   POST /api/upload
 * @access  Private (JWT Token Required)
 */
const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No image file provided in request body under field 'file' or 'image'",
      });
    }

    // Stream upload buffer to Cloudinary
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: "medishare",
        resource_type: "auto",
      },
      (error, result) => {
        if (error) {
          console.error("[UploadController] Cloudinary Upload Error:", error);
          return res.status(500).json({
            success: false,
            message: `Cloudinary upload failed: ${error.message || error}`,
          });
        }

        return res.status(200).json({
          success: true,
          message: "Image uploaded successfully",
          url: result.secure_url,
          data: {
            url: result.secure_url,
            public_id: result.public_id,
            format: result.format,
            width: result.width,
            height: result.height,
          },
        });
      }
    );

    stream.end(req.file.buffer);
  } catch (error) {
    console.error("[UploadController] Unexpected error:", error);
    return res.status(500).json({
      success: false,
      message: `Failed to process image upload: ${error.message}`,
    });
  }
};

module.exports = {
  uploadImage,
};
