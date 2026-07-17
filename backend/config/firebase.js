const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let db;
let auth;
let isMock = false;

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
const resolvedPath = path.resolve(serviceAccountPath);

let serviceAccount = null;

if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
  serviceAccount = {
    project_id: process.env.FIREBASE_PROJECT_ID,
    private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    client_email: process.env.FIREBASE_CLIENT_EMAIL,
  };
} else if (fs.existsSync(resolvedPath)) {
  serviceAccount = require(resolvedPath);
}

if (serviceAccount) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    db = admin.firestore();
    auth = admin.auth();
    console.log('Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.error('Failed to initialize Firebase Admin SDK:', error.message);
    isMock = true;
  }
} else {
  console.warn(`Firebase credentials not found in environment variables or at ${resolvedPath}`);
  console.warn('Running with mock database behavior.');
  isMock = true;
}

module.exports = {
  admin,
  db,
  auth,
  isMock
};
