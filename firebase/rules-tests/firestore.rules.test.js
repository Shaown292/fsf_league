import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

let env;

const hours = (h) => Timestamp.fromMillis(Date.now() + h * 3_600_000);

const asUser = (uid) => env.authenticatedContext(uid).firestore();
const asAdmin = () => env.authenticatedContext('admin1', { admin: true }).firestore();
const asAnon = () => env.unauthenticatedContext().firestore();

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

function contest(overrides = {}) {
  return {
    title: 'Arsenal vs Liverpool',
    homeTeam: 'Arsenal',
    awayTeam: 'Liverpool',
    status: 'PUBLISHED',
    version: 1,
    matchAt: hours(3),
    opensAt: hours(-1),
    deadlineAt: hours(1),
    rules: {
      budget: 500,
      squadSize: 3,
      positions: { GK: 1, DEF: 1, MID: 1, FWD: 0 },
      captainMultiplier: 2,
      maxPerClub: 0,
    },
    players: {
      p1: { name: 'Raya', position: 'GK', club: 'ARS', price: 50, status: 'available' },
      p2: { name: 'Saliba', position: 'DEF', club: 'ARS', price: 60, status: 'available' },
      p3: { name: 'Saka', position: 'MID', club: 'ARS', price: 100, status: 'available' },
      p4: { name: 'Salah', position: 'MID', club: 'LIV', price: 120, status: 'available' },
    },
    ...overrides,
  };
}

const entry = (uid, overrides = {}) => ({
  contestId: 'c1',
  userId: uid,
  username: 'shaown',
  selected: ['p1', 'p2', 'p3'],
  captainId: 'p3',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const storedEntry = (uid, contestId = 'c1') => ({
  contestId,
  userId: uid,
  username: 'shaown',
  selected: ['p1', 'p2', 'p3'],
  captainId: 'p3',
  createdAt: hours(-0.5),
  updatedAt: hours(-0.5),
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fsf-league',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed('contests/c1', contest());
  await seed('contests/c_closed', contest({ opensAt: hours(-3), deadlineAt: hours(-1) }));
  await seed('contests/c_future', contest({ opensAt: hours(1), deadlineAt: hours(2) }));
  await seed('contests/c_draft', contest({ status: 'DRAFT' }));
});

describe('users', () => {
  const profile = (overrides = {}) => ({
    username: 'shaown_01',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  it('owner can create own profile', async () => {
    await assertSucceeds(setDoc(doc(asUser('alice'), 'users/alice'), profile()));
  });

  it('cannot create someone else\'s profile', async () => {
    await assertFails(setDoc(doc(asUser('alice'), 'users/bob'), profile()));
  });

  it('rejects invalid username', async () => {
    await assertFails(setDoc(doc(asUser('alice'), 'users/alice'), profile({ username: 'a b' })));
    await assertFails(setDoc(doc(asUser('alice'), 'users/alice'), profile({ username: 'ab' })));
  });

  it('rejects extra fields such as role flags', async () => {
    await assertFails(setDoc(doc(asUser('alice'), 'users/alice'), profile({ isAdmin: true })));
  });

  it('cannot add forbidden fields on update', async () => {
    await seed('users/alice', { username: 'alice_1', createdAt: hours(-5) });
    await assertFails(updateDoc(doc(asUser('alice'), 'users/alice'), { points: 999 }));
    await assertSucceeds(updateDoc(doc(asUser('alice'), 'users/alice'), { username: 'alice_2' }));
  });

  it('cannot read another user, but admin can', async () => {
    await seed('users/bob', { username: 'bob_1', createdAt: hours(-5) });
    await assertFails(getDoc(doc(asUser('alice'), 'users/bob')));
    await assertSucceeds(getDoc(doc(asAdmin(), 'users/bob')));
  });
});

describe('contests and feed', () => {
  it('signed-in user can read a published contest', async () => {
    await assertSucceeds(getDoc(doc(asUser('alice'), 'contests/c1')));
  });

  it('user cannot read a draft contest, admin can', async () => {
    await assertFails(getDoc(doc(asUser('alice'), 'contests/c_draft')));
    await assertSucceeds(getDoc(doc(asAdmin(), 'contests/c_draft')));
  });

  it('anonymous users cannot read contests', async () => {
    await assertFails(getDoc(doc(asAnon(), 'contests/c1')));
  });

  it('users cannot write contests, admin can', async () => {
    await assertFails(updateDoc(doc(asUser('alice'), 'contests/c1'), { title: 'Hacked' }));
    await assertSucceeds(updateDoc(doc(asAdmin(), 'contests/c1'), { title: 'Edited' }));
  });

  it('feed is readable by users, writable only by admin', async () => {
    await seed('meta/activeContests', { updatedAt: hours(0), contests: [] });
    await assertSucceeds(getDoc(doc(asUser('alice'), 'meta/activeContests')));
    await assertFails(setDoc(doc(asUser('alice'), 'meta/activeContests'), { contests: [] }));
    await assertSucceeds(setDoc(doc(asAdmin(), 'meta/activeContests'), { contests: [] }));
  });
});

describe('entries: create', () => {
  const create = (uid, data, id) =>
    setDoc(doc(asUser(uid), `entries/${id ?? `${data.contestId}_${uid}`}`), data);

  it('accepts a valid entry in an open contest', async () => {
    await assertSucceeds(create('alice', entry('alice')));
  });

  it('rejects an entry for someone else', async () => {
    await assertFails(create('alice', entry('bob'), 'c1_bob'));
  });

  it('rejects an entry whose ID does not match contest and user', async () => {
    await assertFails(create('alice', entry('alice'), 'c1_other'));
  });

  it('rejects entries after the deadline', async () => {
    await assertFails(create('alice', entry('alice', { contestId: 'c_closed' })));
  });

  it('rejects entries before the contest opens', async () => {
    await assertFails(create('alice', entry('alice', { contestId: 'c_future' })));
  });

  it('rejects entries for a draft contest', async () => {
    await assertFails(create('alice', entry('alice', { contestId: 'c_draft' })));
  });

  it('rejects the wrong squad size', async () => {
    await assertFails(create('alice', entry('alice', { selected: ['p1', 'p2'], captainId: 'p1' })));
  });

  it('rejects duplicate players', async () => {
    await assertFails(
      create('alice', entry('alice', { selected: ['p1', 'p1', 'p2'], captainId: 'p1' })),
    );
  });

  it('rejects players that are not in the contest', async () => {
    await assertFails(
      create('alice', entry('alice', { selected: ['p1', 'p2', 'zzz'], captainId: 'p1' })),
    );
  });

  it('rejects a captain who is not in the squad', async () => {
    await assertFails(create('alice', entry('alice', { captainId: 'p4' })));
  });

  it('rejects score, rank or any extra field', async () => {
    await assertFails(create('alice', entry('alice', { score: 100 })));
    await assertFails(create('alice', entry('alice', { rank: 1 })));
  });

  it('rejects a client-supplied createdAt', async () => {
    await assertFails(create('alice', entry('alice', { createdAt: hours(-10) })));
  });
});

describe('entries: update, read, delete', () => {
  beforeEach(async () => {
    await seed('entries/c1_alice', storedEntry('alice'));
    await seed('entries/c_closed_alice', storedEntry('alice', 'c_closed'));
  });

  it('owner can update before the deadline', async () => {
    await assertSucceeds(
      updateDoc(doc(asUser('alice'), 'entries/c1_alice'), {
        selected: ['p1', 'p2', 'p4'],
        captainId: 'p4',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('owner cannot update after the deadline', async () => {
    await assertFails(
      updateDoc(doc(asUser('alice'), 'entries/c_closed_alice'), {
        captainId: 'p1',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('cannot change userId or contestId', async () => {
    await assertFails(
      updateDoc(doc(asUser('alice'), 'entries/c1_alice'), {
        userId: 'bob',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(asUser('alice'), 'entries/c1_alice'), {
        contestId: 'c_future',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('another user cannot update or read it', async () => {
    await assertFails(
      updateDoc(doc(asUser('bob'), 'entries/c1_alice'), { updatedAt: serverTimestamp() }),
    );
    await assertFails(getDoc(doc(asUser('bob'), 'entries/c1_alice')));
  });

  it('owner and admin can read it', async () => {
    await assertSucceeds(getDoc(doc(asUser('alice'), 'entries/c1_alice')));
    await assertSucceeds(getDoc(doc(asAdmin(), 'entries/c1_alice')));
  });

  it('"my entries" query works only when filtered by own userId', async () => {
    const db = asUser('alice');
    await assertSucceeds(getDocs(query(collection(db, 'entries'), where('userId', '==', 'alice'))));
    await assertFails(getDocs(collection(db, 'entries')));
  });

  it('owner can delete before the deadline but not after', async () => {
    await assertSucceeds(deleteDoc(doc(asUser('alice'), 'entries/c1_alice')));
    await assertFails(deleteDoc(doc(asUser('alice'), 'entries/c_closed_alice')));
  });
});

describe('results and admin-only data', () => {
  it('results are readable by users but writable only by admin', async () => {
    await seed('contestResults/c1', { version: 1, top: [] });
    await assertSucceeds(getDoc(doc(asUser('alice'), 'contestResults/c1')));
    await assertFails(setDoc(doc(asUser('alice'), 'contestResults/c1'), { version: 2 }));
    await assertSucceeds(setDoc(doc(asAdmin(), 'contestResults/c1'), { version: 2 }));
  });

  it('drafts and the player library are admin-only', async () => {
    await seed('adminDrafts/c1', { playerPoints: {} });
    await assertFails(getDoc(doc(asUser('alice'), 'adminDrafts/c1')));
    await assertSucceeds(getDoc(doc(asAdmin(), 'adminDrafts/c1')));
    await assertFails(setDoc(doc(asUser('alice'), 'playerLibrary/x'), { name: 'X' }));
    await assertSucceeds(setDoc(doc(asAdmin(), 'playerLibrary/x'), { name: 'X' }));
  });

  it('unknown collections are denied for everyone, including admin', async () => {
    await assertFails(getDoc(doc(asUser('alice'), 'secrets/s1')));
    await assertFails(setDoc(doc(asAdmin(), 'secrets/s1'), { a: 1 }));
  });
});