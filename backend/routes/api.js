const express = require('express');
const router = express.Router();
const multer = require('multer');

// Controllers
const uploadController = require('../controllers/uploadController');
const userController = require('../controllers/userController');

// Multer memory storage configuration for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 20 * 1024 * 1024 // 20MB limit
  }
});

// Upload route (single image upload under the 'avatar' key)
router.post('/upload', upload.single('avatar'), uploadController.uploadAvatar);

// User Profile & Home routes
router.get('/user/profile/:uid', userController.getProfile);
router.post('/user/profile/:uid', userController.saveProfile);
router.get('/user/home/:uid', userController.getHomeDashboard);

// Workouts routes
router.get('/user/workouts/:uid', userController.getWorkouts);
router.post('/user/workout/:uid', userController.saveWorkout);


module.exports = router;
