import { ENV } from './env.js';

export const initFirebase = () => {
  if (!ENV.FIREBASE_PROJECT_ID) {
    console.warn('[Firebase] Firebase configuration not provided. Push notifications will run in stub mode.');
    return null;
  }

  // Placeholder for firebase-admin initialization
  console.log(`[Firebase] Initialized for project: ${ENV.FIREBASE_PROJECT_ID}`);
  return {
    messaging: () => ({
      send: async (payload) => {
        console.log('[Firebase Stub] Sending message:', payload);
        return { success: true, messageId: 'stub-' + Date.now() };
      },
    }),
  };
};

export const firebaseAdmin = initFirebase();
