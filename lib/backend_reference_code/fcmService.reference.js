import { getFirebaseMessaging } from "../config/firebase.js";
import {
  markTokenAsInvalid,
  updateTokenLastUsed,
} from "./deviceTokenService.js";

/**
 * FCM Service Provider
 * Handles Firebase Cloud Messaging notifications with batching and token management
 */
class FCMService {
  constructor() {
    this.messaging = getFirebaseMessaging();
    this.MAX_TOKENS_PER_BATCH = 500; // FCM limit
  }

  /**
   * Flatten data object for FCM (all values must be strings)
   * @param {Object} data - Data object
   * @returns {Object} Flattened data with string values
   */
  flattenDataForFCM(data) {
    const flattened = {};

    for (const [key, value] of Object.entries(data)) {
      if (value === null || value === undefined) {
        flattened[key] = "";
      } else if (typeof value === "object") {
        flattened[key] = JSON.stringify(value);
      } else {
        flattened[key] = String(value);
      }
    }

    return flattened;
  }

  /**
   * Handle FCM failures and cleanup invalid tokens
   * @param {string} userId - User ID
   * @param {Object} response - FCM response
   * @param {string[]} tokens - Array of tokens used
   * @returns {Promise<void>}
   */
  async handleFCMFailures(userId, response, tokens) {
    if (!response.responses || response.responses.length === 0) {
      return;
    }

    const invalidationPromises = [];

    response.responses.forEach((resp, index) => {
      if (!resp.success && resp.error) {
        const errorCode = resp.error.code;
        const token = tokens[index];

        // Check if error indicates invalid token
        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered" ||
          errorCode === "messaging/invalid-argument"
        ) {
          console.warn(
            ` Invalid FCM token detected: ${token.substring(
              0,
              20
            )}... (${errorCode})`
          );
          invalidationPromises.push(markTokenAsInvalid(token, errorCode));
        }
      }
    });

    if (invalidationPromises.length > 0) {
      await Promise.all(invalidationPromises);
      console.log(
        `🚫 Marked ${invalidationPromises.length} invalid tokens for user ${userId}`
      );
    }
  }

  /**
   * Send push notification to multiple device tokens (with automatic batching)
   * @param {string} userId - User ID
   * @param {string[]} tokens - Array of device tokens
   * @param {Object} notification - Notification payload
   * @returns {Promise<Object>} Success and failure counts
   */
  async sendPushNotification(userId, tokens, notification) {
    try {
      if (!this.messaging) {
        console.warn(" Firebase messaging not initialized");
        return { success: 0, failed: tokens.length };
      }

      if (!tokens || tokens.length === 0) {
        console.warn(` No device tokens provided for user ${userId}`);
        return { success: 0, failed: 0 };
      }

      // Build FCM message
      const { title, body, data = {}, priority = "high" } = notification;

      // Flatten data for FCM (all values must be strings)
      const fcmData = this.flattenDataForFCM(data);

      const message = {
        notification: {
          title: title || "Notification",
          body: body || "",
        },
        data: fcmData,
        android: {
          priority:
            priority === "critical" || priority === "high" ? "high" : "normal",
          notification: {
            channelId: data.category || "default",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      let totalSuccess = 0;
      let totalFailed = 0;

      // Split into batches if needed (FCM limit is 500 tokens per request)
      for (let i = 0; i < tokens.length; i += this.MAX_TOKENS_PER_BATCH) {
        const batch = tokens.slice(i, i + this.MAX_TOKENS_PER_BATCH);

        try {
          const batchMessage = {
            ...message,
            tokens: batch,
          };

          const response = await this.messaging.sendEachForMulticast(
            batchMessage
          );

          totalSuccess += response.successCount;
          totalFailed += response.failureCount;

          console.log(
            ` FCM batch sent to ${batch.length} devices: ${response.successCount} success, ${response.failureCount} failed`
          );

          // Handle token failures
          await this.handleFCMFailures(userId, response, batch);
        } catch (batchError) {
          console.error(` FCM batch error:`, batchError.message);
          totalFailed += batch.length;
        }
      }
      console.log(
        ` FCM delivery complete for user ${userId}: ${totalSuccess} success, ${totalFailed} failed (${tokens.length} total)`
      );

      return {
        success: totalSuccess,
        failed: totalFailed,
      };
    } catch (error) {
      console.error(
        ` Error sending push notification for user ${userId}:`,
        error.message
      );
      return {
        success: 0,
        failed: tokens.length,
      };
    }
  }

  /**
   * Send FCM notification (supports both single token and multiple tokens)
   * @param {Object} notification - Notification object
   * @returns {Promise<Object>}
   */
  async send(notification) {
    try {
      if (!this.messaging) {
        throw new Error("Firebase messaging not initialized");
      }

      const { recipient, content, metadata } = notification;

      // Check if multiple tokens (batch) or single token
      const isMulticast =
        recipient.deviceTokens && Array.isArray(recipient.deviceTokens);

      if (isMulticast) {
        // Batch sending to multiple tokens
        const tokens = recipient.deviceTokens;

        if (tokens.length === 0) {
          throw new Error("Device tokens array is empty");
        }

        console.log(` Sending FCM to ${tokens.length} device tokens (batch)`);

        const isLiveActivityUpdate = metadata?.type === 'SLOT_LIVE_UPDATE' || metadata?.data?.notificationType === 'SLOT_LIVE_UPDATE';
        // SLOT_LIVE_UPDATE must always be data-only so iOS delivers it via
        // content-available (background processing) instead of showing a banner.
        const isSilent = isLiveActivityUpdate || metadata?.isSilent === "true" || metadata?.isSilent === true;

        const message = {
          tokens: tokens,
          data: this.flattenDataForFCM(metadata?.data || {}),
        };

        // Only add visible notification content for non-silent messages.
        // SLOT_LIVE_UPDATE must be data-only — no notification block, or the
        // OS will auto-show a banner regardless of the app's handler.
        if (!isSilent && (content.subject || content.body)) {
          message.notification = {
            title: content.subject || "Notification",
            body: content.body,
          };
        }

        // Add Android specific options
        message.android = {
          priority: "high", // Always high so data messages wake the app in background
          notification: isSilent
            ? undefined // No Android notification block for silent/data-only
            : {
              sound: "default",
              channelId: metadata?.data?.category || "default",
            },
        };

        // Determine iOS push type
        // If it's a silent push but meant for a Live Activity, it must have 'liveactivity' push type, not background
        const apnsPushType = isLiveActivityUpdate ? "liveactivity" : (isSilent ? "background" : "alert");
        const apnsPriority = (isLiveActivityUpdate || !isSilent) ? "10" : "5";

        // Add iOS specific options
        message.apns = {
          headers: {
            "apns-priority": apnsPriority,
            "apns-push-type": apnsPushType,
          },
          payload: {
            aps: isSilent
              ? {
                "content-available": 1, // Silent push for iOS background processing
              }
              : {
                sound: "default",
                badge: 1,
              },
          },
        };

        console.log("FCM message:", message);
        const response = await this.messaging.sendEachForMulticast(message);

        console.log("FCM response:", response);

        console.log(
          ` FCM batch sent: ${response.successCount} success, ${response.failureCount} failed`
        );

        // Handle token failures and cleanup
        if (response.failureCount > 0 && metadata?.userId) {
          await this.handleFCMFailures(metadata.userId, response, tokens);
        }

        return {
          success: true,
          provider: "FCM_BATCH",
          successCount: response.successCount,
          failureCount: response.failureCount,
          totalTokens: tokens.length,
          responses: response.responses,
        };
      } else {
        // Single token sending (legacy support)
        if (!recipient.deviceToken) {
          throw new Error("Device token is required for FCM");
        }

        const message = {
          token: recipient.deviceToken,
          data: this.flattenDataForFCM(metadata?.data || {}),
        };

        // Only add notification content if present
        if (content.subject || content.body) {
          message.notification = {
            title: content.subject || "Notification",
            body: content.body,
          };
        }

        // Add optional fields
        if (metadata?.imageUrl) {
          message.notification.imageUrl = metadata.imageUrl;
        }

        // Android specific options
        if (metadata?.android) {
          message.android = {
            priority: metadata.priority || "high",
            notification: {
              sound: metadata.sound || "default",
              channelId: metadata.channelId,
              icon: metadata.icon,
              color: metadata.color,
            },
          };
        }

        // iOS specific options
        if (metadata?.apns) {
          message.apns = {
            payload: {
              aps: {
                sound: metadata.sound || "default",
                badge: metadata.badge,
              },
            },
          };
        }

        const response = await this.messaging.send(message);

        console.log(
          ` FCM sent successfully to device: ${recipient.deviceToken.substring(
            0,
            20
          )}...`
        );

        return {
          success: true,
          provider: "FCM",
          messageId: response,
          response: response,
        };
      }
    } catch (error) {
      console.error(" Failed to send FCM:", error.message);
      throw error;
    }
  }

  /**
   * Send to multiple devices
   * @param {Object} notification - Notification object
   * @param {Array} deviceTokens - Array of device tokens
   * @returns {Promise<Object>}
   */
  async sendMulticast(notification, deviceTokens) {
    try {
      if (!this.messaging) {
        throw new Error("Firebase messaging not initialized");
      }

      const { content, metadata } = notification;

      const message = {
        tokens: deviceTokens,
        notification: {
          title: content.subject || "Notification",
          body: content.body,
        },
        data: metadata?.data || {},
      };

      if (metadata?.imageUrl) {
        message.notification.imageUrl = metadata.imageUrl;
      }

      const response = await this.messaging.sendMulticast(message);

      console.log(` FCM multicast sent to ${deviceTokens.length} devices`);
      console.log(
        `Success: ${response.successCount}, Failure: ${response.failureCount}`
      );

      return {
        success: true,
        provider: "FCM_MULTICAST",
        successCount: response.successCount,
        failureCount: response.failureCount,
        responses: response.responses,
      };
    } catch (error) {
      console.error(" Failed to send FCM multicast:", error.message);
      throw error;
    }
  }

  /**
   * Send to topic
   * @param {Object} notification - Notification object
   * @param {string} topic - Topic name
   * @returns {Promise<Object>}
   */
  async sendToTopic(notification, topic) {
    try {
      if (!this.messaging) {
        throw new Error("Firebase messaging not initialized");
      }

      const { content, metadata } = notification;

      const message = {
        topic: topic,
        notification: {
          title: content.subject || "Notification",
          body: content.body,
        },
        data: metadata?.data || {},
      };

      if (metadata?.imageUrl) {
        message.notification.imageUrl = metadata.imageUrl;
      }

      const response = await this.messaging.send(message);

      console.log(` FCM sent to topic: ${topic}`);

      return {
        success: true,
        provider: "FCM_TOPIC",
        messageId: response,
        topic: topic,
        response: response,
      };
    } catch (error) {
      console.error(" Failed to send FCM to topic:", error.message);
      throw error;
    }
  }

  /**
   * Subscribe device to topic
   * @param {Array} deviceTokens - Array of device tokens
   * @param {string} topic - Topic name
   * @returns {Promise<Object>}
   */
  async subscribeToTopic(deviceTokens, topic) {
    try {
      if (!this.messaging) {
        throw new Error("Firebase messaging not initialized");
      }

      const response = await this.messaging.subscribeToTopic(
        deviceTokens,
        topic
      );

      console.log(` Devices subscribed to topic: ${topic}`);

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error(" Failed to subscribe to topic:", error.message);
      throw error;
    }
  }

  /**
   * Unsubscribe device from topic
   * @param {Array} deviceTokens - Array of device tokens
   * @param {string} topic - Topic name
   * @returns {Promise<Object>}
   */
  async unsubscribeFromTopic(deviceTokens, topic) {
    try {
      if (!this.messaging) {
        throw new Error("Firebase messaging not initialized");
      }

      const response = await this.messaging.unsubscribeFromTopic(
        deviceTokens,
        topic
      );

      console.log(` Devices unsubscribed from topic: ${topic}`);

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error(" Failed to unsubscribe from topic:", error.message);
      throw error;
    }
  }
}

export const fcmService = new FCMService();
