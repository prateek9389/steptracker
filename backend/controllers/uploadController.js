const cloudinaryConfig = require('../config/cloudinary');

const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded.' });
    }

    if (cloudinaryConfig.isMock) {
      console.log('Using mock Cloudinary upload. Returning placeholder image.');
      // Return a simulated uploaded URL using a random/mock placeholder
      return res.status(200).json({
        url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=250&q=80',
        message: 'Mock upload successful. Real Cloudinary credentials not configured yet.'
      });
    }

    // Live upload using Cloudinary SDK and memory stream
    const uploadStream = cloudinaryConfig.cloudinary.uploader.upload_stream(
      {
        folder: 'stride_avatars',
        resource_type: 'auto'
      },
      (error, result) => {
        if (error) {
          console.error('Cloudinary upload error:', error);
          return res.status(500).json({ error: 'Failed to upload image to Cloudinary.' });
        }
        return res.status(200).json({
          url: result.secure_url,
          message: 'Upload successful.'
        });
      }
    );

    uploadStream.end(req.file.buffer);
  } catch (error) {
    console.error('Error in uploadAvatar controller:', error);
    res.status(500).json({ error: 'Server error during avatar upload.' });
  }
};

module.exports = {
  uploadAvatar
};
