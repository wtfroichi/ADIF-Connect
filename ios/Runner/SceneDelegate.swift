import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  static var initialPassPath: String?
  static var initialInboxImportPending = false
  static var channel: FlutterMethodChannel?

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url else { return }
    handleIncomingPassUrl(url)
  }

  private func handleIncomingPassUrl(_ url: URL) {
    if url.scheme == "adifconnect", url.host == "import-inbox" {
      if let channel = SceneDelegate.channel {
        channel.invokeMethod("onImportInbox", arguments: nil)
      } else {
        SceneDelegate.initialInboxImportPending = true
      }
      return
    }
    guard url.isFileURL else { return }
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
    let fileExtension = url.pathExtension.isEmpty ? "pkpass" : url.pathExtension
    let destUrl = tempDir.appendingPathComponent(UUID().uuidString + ".\(fileExtension)")

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
