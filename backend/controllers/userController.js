const firebaseConfig = require('../config/firebase');

// In-memory fallback database for development testing when Firebase is not configured
const mockDatabase = {
  users: {},
  workouts: {}
};

const getProfile = async (req, res) => {
  const { uid } = req.params;
  if (!uid) {
    return res.status(400).json({ error: 'UID is required.' });
  }

  try {
    if (firebaseConfig.isMock) {
      console.log(`Getting mock user profile for uid: ${uid}`);
      const data = mockDatabase.users[uid] || null;
      return res.status(200).json(data);
    }

    // Live Firestore read
    const doc = await firebaseConfig.db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return res.status(200).json(null);
    }
    return res.status(200).json(doc.data());
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Server error during fetching profile.' });
  }
};

const saveProfile = async (req, res) => {
  const { uid } = req.params;
  const profileData = req.body;
  if (!uid) {
    return res.status(400).json({ error: 'UID is required.' });
  }

  try {
    if (firebaseConfig.isMock) {
      console.log(`Saving mock user profile for uid: ${uid}`);
      mockDatabase.users[uid] = {
        ...profileData,
        updatedAt: new Date().toISOString()
      };
      return res.status(200).json({ success: true, message: 'Mock profile saved successfully.' });
    }

    // Live Firestore set
    await firebaseConfig.db.collection('users').doc(uid).set({
      ...profileData,
      updatedAt: firebaseConfig.admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    return res.status(200).json({ success: true, message: 'Profile saved successfully.' });
  } catch (error) {
    console.error('Error saving profile:', error);
    res.status(500).json({ error: 'Server error during saving profile.' });
  }
};

const getWorkouts = async (req, res) => {
  const { uid } = req.params;
  if (!uid) {
    return res.status(400).json({ error: 'UID is required.' });
  }

  try {
    if (firebaseConfig.isMock) {
      console.log(`Getting mock workouts for uid: ${uid}`);
      const userWorkouts = mockDatabase.workouts[uid] || [];
      return res.status(200).json(userWorkouts);
    }

    // Live Firestore query from subcollection
    const snapshot = await firebaseConfig.db
      .collection('users')
      .doc(uid)
      .collection('walk_history')
      .orderBy('date', 'desc')
      .get();

    const workouts = [];
    snapshot.forEach(doc => {
      workouts.push(doc.data());
    });

    return res.status(200).json(workouts);
  } catch (error) {
    console.error('Error fetching workouts:', error);
    res.status(500).json({ error: 'Server error during fetching workouts.' });
  }
};

const saveWorkout = async (req, res) => {
  const { uid } = req.params;
  const workoutData = req.body;
  if (!uid) {
    return res.status(400).json({ error: 'UID is required.' });
  }
  if (!workoutData.id) {
    return res.status(400).json({ error: 'Workout ID is required.' });
  }

  try {
    if (firebaseConfig.isMock) {
      console.log(`Saving mock workout for uid: ${uid}`);
      if (!mockDatabase.workouts[uid]) {
        mockDatabase.workouts[uid] = [];
      }
      // Insert at beginning of list to simulate descending order
      mockDatabase.workouts[uid].unshift(workoutData);

      return res.status(200).json({ success: true, message: 'Mock workout saved successfully.' });
    }

    // Live Firestore set to subcollection
    await firebaseConfig.db
      .collection('users')
      .doc(uid)
      .collection('walk_history')
      .doc(workoutData.id)
      .set(workoutData);


    return res.status(200).json({ success: true, message: 'Workout saved successfully.' });
  } catch (error) {
    console.error('Error saving workout:', error);
    res.status(500).json({ error: 'Server error during saving workout.' });
  }
};

const getHomeDashboard = async (req, res) => {
  const { uid } = req.params;
  if (!uid) {
    return res.status(400).json({ error: 'UID is required.' });
  }

  try {
    if (firebaseConfig.isMock) {
      console.log(`Getting mock home dashboard for uid: ${uid}`);
      const profile = mockDatabase.users[uid] || null;
      const workouts = mockDatabase.workouts[uid] || [];
      return res.status(200).json({
        profile,
        todayStat: null,
        recentWorkouts: workouts.slice(0, 3),
        weeklyStats: []
      });
    }

    const db = firebaseConfig.db;
    const userRef = db.collection('users').doc(uid);

    // 1. Fetch Profile
    const profilePromise = userRef.get();

    // 2. Fetch Today's Stat
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    const todayStatPromise = userRef.collection('daily_stats').doc(todayStr).get();

    // 3. Fetch Recent Workouts (limit 3)
    const recentWorkoutsPromise = userRef.collection('walk_history')
      .orderBy('date', 'desc')
      .limit(3)
      .get();

    // 4. Fetch Weekly Stats (last 7 days)
    const weeklyStatsPromise = userRef.collection('daily_stats')
      .orderBy('date', 'desc')
      .limit(7)
      .get();

    // Execute all concurrently
    const [profileDoc, todayStatDoc, recentWorkoutsSnapshot, weeklyStatsSnapshot] = await Promise.all([
      profilePromise,
      todayStatPromise,
      recentWorkoutsPromise,
      weeklyStatsPromise
    ]);

    if (!profileDoc.exists) {
      return res.status(404).json({ error: 'User profile not found.' });
    }

    const profileData = profileDoc.data();
    const todayStatData = todayStatDoc.exists ? todayStatDoc.data() : null;
    
    const recentWorkouts = [];
    recentWorkoutsSnapshot.forEach(doc => {
      recentWorkouts.push(doc.data());
    });

    const weeklyStats = [];
    weeklyStatsSnapshot.forEach(doc => {
      weeklyStats.push(doc.data());
    });

    return res.status(200).json({
      profile: profileData,
      todayStat: todayStatData,
      recentWorkouts,
      weeklyStats
    });

  } catch (error) {
    console.error('Error fetching home dashboard:', error);
    res.status(500).json({ error: 'Server error during fetching home dashboard.' });
  }
};

module.exports = {
  getProfile,
  saveProfile,
  getWorkouts,
  saveWorkout,
  getHomeDashboard
};

