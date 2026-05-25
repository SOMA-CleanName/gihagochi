import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // APNs 등록을 명시적으로 트리거 — FlutterImplicitEngineDelegate 패턴(Flutter 3.40+)에서는
    // plugin 등록이 didInitializeImplicitFlutterEngine에서 일어나 firebase_messaging의
    // swizzling이 APNs 등록 타이밍을 놓침. 명시적으로 호출해서 토큰 발급 보장.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
