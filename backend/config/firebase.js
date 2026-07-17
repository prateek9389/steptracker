const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let db;
let auth;
let isMock = false;

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
const resolvedPath = path.resolve(serviceAccountPath);

if (fs.existsSync(resolvedPath)) {
  try {
    const serviceAccount = require(resolvedPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    db = admin.firestore();
    auth = admin.auth();
    console.log('Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.error('Failed to initialize Firebase Admin SDK with service account:', error.message);
    isMock = true;
  }
} else {
  console.warn(`Firebase service account file not found at: ${resolvedPath}`);
  console.warn('Running with mock database behavior. Please place your Firebase service account JSON file at the configured path to enable live database writes.');
  isMock = true;
}

module.exports = {
  admin,
  db,
  auth,
  isMock
};
