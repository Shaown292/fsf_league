import { readFileSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const args = process.argv.slice(2);
const useEmulator = args.includes('--emulator');
const revoke = args.includes('--revoke');
const email = args.find((a) => !a.startsWith('--'));

if (!email) {
  console.error('Usage: node set-admin.mjs <email> [--emulator] [--revoke]');
  process.exit(1);
}

if (useEmulator) {
  // Must match the project ID the running emulators use (.firebaserc default).
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  initializeApp({ projectId: 'fsf-league' });
} else {
  const keyPath = new URL('./serviceAccount.json', import.meta.url);
  const key = JSON.parse(readFileSync(keyPath, 'utf8'));
  initializeApp({ credential: cert(key) });
}

const auth = getAuth();
const user = await auth.getUserByEmail(email);
// Replaces ALL custom claims on the user; fine, we use only "admin".
await auth.setCustomUserClaims(user.uid, revoke ? null : { admin: true });

console.log(
  `${revoke ? 'Removed admin from' : 'Granted admin to'} ${email} (${user.uid}) ` +
    `[${useEmulator ? 'EMULATOR' : 'PRODUCTION'}]`,
);
console.log('The user must sign out and back in (or reload the admin page) to get the new claim.');
