import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.ecliniq/custom_notifications",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if #available(iOS 16.1, *) {
          switch call.method {
          case "showCustomNotification":
              guard let args = call.arguments as? [String: Any] else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                  return
              }
              
              let title = args["title"] as? String ?? ""
              let doctorName = args["doctorName"] as? String ?? ""
              let timeInfo = args["timeInfo"] as? String ?? ""
              let expectedTime = args["expectedTime"] as? String ?? ""
              let currentToken = args["currentToken"] as? Int ?? 0
              let userToken = args["userToken"] as? Int ?? 0
              let hospitalName = args["hospitalName"] as? String ?? ""
              
              // Use appointment ID from notification payload or generate one?
              // The attributes need a unique ID. Using a timestamp or fixed for now since Android uses fixed ID
              let appointmentId = "current_appointment"
              
              LiveActivityService.shared.start(
                  appointmentId: appointmentId,
                  doctorName: doctorName,
                  timeInfo: timeInfo,
                  expectedTime: expectedTime,
                  currentToken: currentToken,
                  userToken: userToken,
                  hospitalName: hospitalName
              )
              result(true)
              
          case "updateCustomNotification":
              guard let args = call.arguments as? [String: Any] else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                  return
              }
              
              let doctorName = args["doctorName"] as? String ?? ""
              let timeInfo = args["timeInfo"] as? String ?? ""
              let expectedTime = args["expectedTime"] as? String ?? ""
              let currentToken = args["currentToken"] as? Int ?? 0
              let userToken = args["userToken"] as? Int ?? 0
              let hospitalName = args["hospitalName"] as? String ?? ""
              
              LiveActivityService.shared.update(
                  doctorName: doctorName,
                  timeInfo: timeInfo,
                  expectedTime: expectedTime,
                  currentToken: currentToken,
                  userToken: userToken,
                  hospitalName: hospitalName
              )
              result(true)
              
          case "dismissCustomNotification":
              LiveActivityService.shared.end()
              result(true)
              
          default:
              result(FlutterMethodNotImplemented)
          }
      } else {
          // Fallback for older iOS versions (handled by local notifications in Dart)
          result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
