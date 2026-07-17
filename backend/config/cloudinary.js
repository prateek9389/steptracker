const cloudinary = require('cloudinary').v2;

const isCloudinaryConfigured = 
  process.env.CLOUDINARY_CLOUD_NAME && 
  process.env.CLOUDINARY_API_KEY && 
  process.env.CLOUDINARY_API_SECRET &&
  process.env.CLOUDINARY_API_KEY !== 'your_cloudinary_api_key' &&
  process.env.CLOUDINARY_API_SECRET !== 'your_cloudinary_api_secret';

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true
  });
  console.log('Cloudinary SDK configured successfully.');
} else {
  console.warn('Cloudinary environment credentials are empty or default.');
  console.warn('Running with mock image uploading. Uploaded avatars will return mock URLs.');
}

module.exports = {
  cloudinary,
  isMock: !isCloudinaryConfigured
};
