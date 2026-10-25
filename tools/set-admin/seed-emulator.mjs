import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// Pointing at the emulator makes it impossible to touch the real project:
// no credentials are loaded and every call goes to this host.
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
initializeApp({ projectId: 'fsf-league' });

const ADMIN = {
  uid: 'dev-admin',
  email: 'admin@example.com',
  password: 'password123',
};

const auth = getAuth();

async function waitForEmulator() {
  for (let i = 0; i < 120; i++) {
    try {
      await fetch('http://127.0.0.1:9099/');
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  throw new Error('The Auth emulator did not start within 2 minutes.');
}

await waitForEmulator();

let user;
try {
  user = await auth.getUserByEmail(ADMIN.email);
} catch (e) {
  if (e.code !== 'auth/user-not-found') throw e;
}

if (user) {
  user = await auth.updateUser(user.uid, {
    password: ADMIN.password,
    emailVerified: true,
    disabled: false,
  });
} else {
  user = await auth.createUser({
    uid: ADMIN.uid,
    email: ADMIN.email,
    password: ADMIN.password,
    emailVerified: true,
    displayName: 'Dev Admin',
  });
}

if (user.customClaims?.admin !== true) {
  await auth.setCustomUserClaims(user.uid, { admin: true });
}

console.log(
  `Dev admin ready: ${ADMIN.email} / ${ADMIN.password} (uid ${user.uid}) [EMULATOR]`,
);