import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "es.adifconnect.app/sharing",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    SceneDelegate.channel = channel

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getInitialPass" {
        result(SceneDelegate.initialPassPath)
        SceneDelegate.initialPassPath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let safePath = SceneDelegate.copySecurityScopedUrlToTemp(url) ?? url.path
    if let channel = SceneDelegate.channel {
      channel.invokeMethod("onPassReceived", arguments: safePath)
    } else {
      SceneDelegate.initialPassPath = safePath
    }
    return super.application(app, open: url, options: options)
  }
}
