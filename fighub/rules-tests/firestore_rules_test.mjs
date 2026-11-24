import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-fighub-rules-test';
const rules = fs.readFileSync(path.resolve(here, '../firestore.rules'), 'utf8');

const env = await initializeTestEnvironment({
  projectId,
  firestore: { rules },
});

try {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/admin-1'), { role: 'admin' });
    await setDoc(doc(db, 'print_businesses/admin-1'), {
      ownerId: 'admin-1',
      name: 'FigHub official catalog',
      active: true,
    });
    await setDoc(doc(db, 'users/not-admin'), { role: 'user' });
    await setDoc(doc(db, 'print_businesses/not-admin'), {
      ownerId: 'not-admin',
      name: 'Regular seller',
      active: true,
    });
  });

  const request = {
    companyId: 'admin-1',
    companyName: 'FigHub official catalog',
    customerId: 'customer-1',
    customerName: 'Test customer',
    category: 'تيشيرتات',
    notes: 'Text-only design request',
    imageUrl: '',
    status: 'new',
  };

  const registeredCustomer = env.authenticatedContext('customer-1', {
    firebase: { sign_in_provider: 'password' },
  }).firestore();

  await assertSucceeds(
    setDoc(doc(registeredCustomer, 'print_design_requests/text-only'), request),
  );

  const anonymousCustomer = env.authenticatedContext('anonymous-1', {
    firebase: { sign_in_provider: 'anonymous' },
  }).firestore();

  await assertFails(
    setDoc(doc(anonymousCustomer, 'print_design_requests/anonymous'), {
      ...request,
      customerId: 'anonymous-1',
    }),
  );

  await assertFails(
    setDoc(doc(registeredCustomer, 'print_design_requests/not-admin'), {
      ...request,
      companyId: 'not-admin',
      companyName: 'Regular seller',
    }),
  );

  await assertFails(
    setDoc(doc(registeredCustomer, 'print_design_requests/forged-customer'), {
      ...request,
      customerId: 'someone-else',
    }),
  );

  const regularSeller = env.authenticatedContext('not-admin', {
    firebase: { sign_in_provider: 'password' },
  }).firestore();
  await assertFails(
    setDoc(doc(regularSeller, 'print_businesses/not-admin'), {
      ownerId: 'not-admin',
      name: 'Fake official catalog',
      active: true,
      officialCatalog: true,
    }),
  );

  console.log('Firestore rules tests passed: design requests, admin-only catalog marker, and ownership checks.');
} finally {
  await env.cleanup();
}
