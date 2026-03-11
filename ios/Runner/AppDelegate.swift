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

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound, .list])
  }
}
