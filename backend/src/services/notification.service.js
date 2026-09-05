import { firebaseAdmin } from '../config/firebase.js';

export const sendPushNotification = async ({ targetToken, title, body, data = {} }) => {
  if (!firebaseAdmin) {
    console.log(`[Notification Service] Mock push notification to ${targetToken}: ${title} - ${body}`);
    return { success: true, mocked: true };
  }

  try {
    const response = await firebaseAdmin.messaging().send({
      token: targetToken,
      notification: { title, body },
      data,
    });
    return { success: true, response };
  } catch (error) {
    console.error('[Notification Service Error]:', error);
    return { success: false, error: error.message };
  }
};
