import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';

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
    await setDoc(doc(db, 'products/product-1'), {
      sellerId: 'not-admin',
      name: 'Test product',
      status: 'Available',
    });
    await setDoc(doc(db, 'products/legacy-anonymous-product'), {
      sellerId: 'anonymous-1',
      name: 'Legacy anonymous listing',
      status: 'Available',
    });
    await setDoc(doc(db, 'products/deleted-product'), {
      sellerId: 'not-admin',
      name: 'Hidden product awaiting cleanup',
      status: 'Available',
      isDeleted: true,
      cleanupPending: true,
    });
    await setDoc(doc(db, 'products/reserved-product'), {
      sellerId: 'not-admin',
      name: 'Reserved product',
      status: 'Reserved',
      reservedBy: 'customer-1',
    });
    await setDoc(doc(db, 'offers/offer-1'), {
      sellerId: 'not-admin',
      title: 'Test offer',
    });
    await setDoc(doc(db, 'offers/offer-1/items/item-1'), {
      name: 'Test offer item',
      status: 'Available',
      reservedBy: null,
    });
    await setDoc(doc(db, 'print_products/print-1'), {
      sellerId: 'not-admin',
      name: 'Test print',
      stockQuantity: 5,
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
  await assertSucceeds(
    setDoc(doc(registeredCustomer, 'products/registered-product'), {
      sellerId: 'customer-1',
      name: 'Registered listing',
    }),
  );
  await assertSucceeds(
    setDoc(doc(registeredCustomer, 'offers/registered-offer'), {
      sellerId: 'customer-1',
      title: 'Registered offer',
    }),
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
    setDoc(doc(anonymousCustomer, 'products/anonymous-product'), {
      sellerId: 'anonymous-1',
      name: 'Anonymous listing',
    }),
  );
  await assertFails(
    setDoc(doc(anonymousCustomer, 'offers/anonymous-offer'), {
      sellerId: 'anonymous-1',
      title: 'Anonymous offer',
    }),
  );
  await assertFails(
    updateDoc(doc(anonymousCustomer, 'products/product-1'), {
      status: 'Reserved',
      reservedBy: 'anonymous-1',
    }),
  );
  await assertFails(
    updateDoc(doc(registeredCustomer, 'products/deleted-product'), {
      status: 'Reserved',
      reservedBy: 'customer-1',
      reservedAt: new Date(),
    }),
  );
  await assertFails(
    deleteDoc(doc(anonymousCustomer, 'products/legacy-anonymous-product')),
  );
  await assertFails(
    updateDoc(doc(anonymousCustomer, 'print_products/print-1'), {
      stockQuantity: 4,
    }),
  );
  await assertFails(
    setDoc(doc(anonymousCustomer, 'offers/offer-1/items/item-1/reservations/anonymous-1'), {
      userId: 'anonymous-1',
      status: 'Active',
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
  await assertFails(
    updateDoc(doc(regularSeller, 'print_businesses/not-admin'), {
      officialCatalog: true,
    }),
  );
  await assertSucceeds(
    updateDoc(doc(regularSeller, 'products/product-1'), {
      isDeleted: true,
      cleanupPending: true,
      deletedAt: new Date(),
      updatedAt: new Date(),
    }),
  );
  await assertFails(
    updateDoc(doc(regularSeller, 'products/reserved-product'), {
      isDeleted: true,
      cleanupPending: true,
      deletedAt: new Date(),
      updatedAt: new Date(),
    }),
  );

  const admin = env.authenticatedContext('admin-1', {
    firebase: { sign_in_provider: 'password' },
  }).firestore();
  await assertSucceeds(
    updateDoc(doc(admin, 'print_businesses/admin-1'), {
      officialCatalog: true,
    }),
  );

  console.log('Firestore rules tests passed: design requests, admin-only catalog marker, and ownership checks.');
} finally {
  await env.cleanup();
}
