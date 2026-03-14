import Flutter
import UIKit
import UserNotifications
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupLiveActivityChannel(registry: engineBridge.pluginRegistry)
  }

  private func setupLiveActivityChannel(registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "LiveActivityPlugin") else { return }
    let channel = FlutterMethodChannel(
      name: "com.example.ecliniq/custom_notifications",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleLiveActivityCall(call: call, result: result)
    }
  }

  private func handleLiveActivityCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterMethodNotImplemented)
      return
    }

    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "showCustomNotification":
      LiveActivityService.shared.start(
        appointmentId: args["appointmentId"] as? String ?? "",
        doctorName: args["doctorName"] as? String ?? "",
        timeInfo: args["timeInfo"] as? String ?? "",
        expectedTime: args["expectedTime"] as? String ?? "",
        currentToken: args["currentToken"] as? Int ?? 0,
        userToken: args["userToken"] as? Int ?? 0,
        hospitalName: args["hospitalName"] as? String ?? ""
      )
      result(nil)

    case "updateCustomNotification":
      LiveActivityService.shared.update(
        doctorName: args["doctorName"] as? String ?? "",
        timeInfo: args["timeInfo"] as? String ?? "",
        expectedTime: args["expectedTime"] as? String ?? "",
        currentToken: args["currentToken"] as? Int ?? 0,
        userToken: args["userToken"] as? Int ?? 0,
        hospitalName: args["hospitalName"] as? String ?? ""
      )
      result(nil)

    case "dismissCustomNotification":
      LiveActivityService.shared.end()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Intercept FCM data messages when the app is backgrounded.
  // The Dart background isolate Firebase creates does NOT have the MethodChannel
  // registered, so Live Activity updates via Dart fail silently in background.
  // Handling it here in native code ensures the Live Activity is always updated.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if #available(iOS 16.2, *) {
      // FCM places data-dict keys at the top level of userInfo on iOS.
      let notificationType = userInfo["notificationType"] as? String
      let type = userInfo["type"] as? String

      if notificationType == "SLOT_LIVE_UPDATE" || type == "ACTIVE" || type == "SLOT_LIVE_UPDATE" {
        let doctorName   = userInfo["doctorName"]   as? String ?? "Your Doctor"
        let hospitalName = userInfo["hospitalName"] as? String ?? "eClinic-Q"
        let yourTokenStr    = (userInfo["yourToken"]    as? String) ?? (userInfo["tokenNumber"] as? String) ?? "0"
        let currentTokenStr =  userInfo["currentToken"] as? String ?? "0"
        let estimatedTime   =  userInfo["estimatedTime"] as? String ?? ""

        let yourToken    = Int(yourTokenStr)    ?? 0
        let currentToken = Int(currentTokenStr) ?? 0

        var timeInfo = ""
        if currentToken == 0 {
          timeInfo = "Queue not started yet"
        } else if yourToken > currentToken {
          timeInfo = "in \((yourToken - currentToken) * 2) min"
        } else if yourToken == currentToken {
          timeInfo = "Your turn!"
        } else {
          timeInfo = "Your token has been called"
        }

        LiveActivityService.shared.update(
          doctorName:   doctorName,
          timeInfo:     timeInfo,
          expectedTime: estimatedTime,
          currentToken: currentToken,
          userToken:    yourToken,
          hospitalName: hospitalName
        )
      }
    }

    // Let Firebase route the message to the Dart background isolate as well
    // (its MethodChannel call will fail gracefully, native update above already ran).
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound, .list])
  }
}
