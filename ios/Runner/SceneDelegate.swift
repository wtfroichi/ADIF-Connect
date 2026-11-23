import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  static var initialPassPath: String?
  static var channel: FlutterMethodChannel?

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url else { return }
    handleIncomingPassUrl(url)
  }

  private func handleIncomingPassUrl(_ url: URL) {
    let safePath = SceneDelegate.copySecurityScopedUrlToTemp(url) ?? url.path
    if let channel = SceneDelegate.channel {
      channel.invokeMethod("onPassReceived", arguments: safePath)
    } else {
      SceneDelegate.initialPassPath = safePath
    }
  }

  static func copySecurityScopedUrlToTemp(_ url: URL) -> String? {
    let isSecurityScoped = url.startAccessingSecurityScopedResource()
    defer {
      if isSecurityScoped {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let tempDir = FileManager.default.temporaryDirectory
    let destUrl = tempDir.appendingPathComponent(UUID().uuidString + ".pkpass")

    do {
      if FileManager.default.fileExists(atPath: destUrl.path) {
        try FileManager.default.removeItem(at: destUrl)
      }
      try FileManager.default.copyItem(at: url, to: destUrl)
      return destUrl.path
    } catch {
      if let data = try? Data(contentsOf: url) {
        try? data.write(to: destUrl)
        return destUrl.path
      }
      return url.path
    }
  }
}
