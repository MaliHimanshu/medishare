const express = require("express");
const router = express.Router();

const protect = require("../middleware/auth.middleware");
const upload = require("../middleware/upload.middleware");
const { uploadImage } = require("../controllers/upload.controller");

// Support both field names 'file' and 'image'
router.post(
  "/",
  protect,
  (req, res, next) => {
    upload.single("file")(req, res, (err) => {
      if (err) {
        // Fallback to checking field 'image'
        return upload.single("image")(req, res, (err2) => {
          if (err2) {
            return res.status(400).json({ success: false, message: err2.message });
          }
          next();
        });
      }
      next();
    });
  },
  uploadImage
);

module.exports = router;
