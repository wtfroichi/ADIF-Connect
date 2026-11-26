import Flutter
import UIKit
import WidgetKit
import PDFKit
import Vision

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
      switch call.method {
      case "getInitialPass":
        result(SceneDelegate.initialPassPath)
        SceneDelegate.initialPassPath = nil
      case "getSharedInbox":
        result(SharedInbox.filePaths())
      case "removeSharedInboxItem":
        guard let path = call.arguments as? String,
              SharedInbox.removeFile(at: path) else {
          result(FlutterError(
            code: "INVALID_INBOX_ITEM",
            message: "Non se puido retirar o ficheiro compartido.",
            details: nil
          ))
          return
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let pdfChannel = FlutterMethodChannel(
      name: "es.adifconnect.app/pdf",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    pdfChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "extractPdfText",
            let typedData = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(
          code: "INVALID_PDF_DATA",
          message: "O contido do PDF non é válido.",
          details: nil
        ))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let text = try PDFTicketTextExtractor.extract(typedData.data)
          DispatchQueue.main.async { result(text) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "PDF_TEXT_EXTRACTION_FAILED",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      }
    }

    let widgetChannel = FlutterMethodChannel(
      name: "es.adifconnect.app/widget-cache",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    widgetChannel.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(suiteName: "group.es.adifconnect.app") else {
        result(FlutterError(
          code: "APP_GROUP_UNAVAILABLE",
          message: "Non está dispoñible o grupo compartido da aplicación.",
          details: nil
        ))
        return
      }

      guard let arguments = call.arguments as? [String: Any],
            let stationCode = arguments["stationCode"] as? String,
            let stationName = arguments["stationName"] as? String else {
        result(FlutterError(
          code: "INVALID_WIDGET_DATA",
          message: "Os datos da estación non son válidos.",
          details: nil
        ))
        return
      }

      switch call.method {
      case "updateDefaultStation":
        defaults.set(stationCode, forKey: "defaultStationCode")
        defaults.set(stationName, forKey: "defaultStationName")
        WidgetCenter.shared.reloadTimelines(ofKind: "StationDeparturesWidget")
        result(nil)
      case "cacheDepartures":
        guard let departuresJSON = arguments["departuresJson"] as? String else {
          result(FlutterError(
            code: "INVALID_DEPARTURES",
            message: "Os datos das saídas non son válidos.",
            details: nil
          ))
          return
        }
        defaults.set(departuresJSON, forKey: "stationDeparturesJSON.\(stationCode)")
        defaults.set(
          ISO8601DateFormatter().string(from: Date()),
          forKey: "stationDeparturesUpdatedAt.\(stationCode)"
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "StationDeparturesWidget")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "adifconnect", url.host == "import-inbox" {
      if let channel = SceneDelegate.channel {
        channel.invokeMethod("onImportInbox", arguments: nil)
      } else {
        SceneDelegate.initialInboxImportPending = true
      }
      return true
    }

    guard url.isFileURL else {
      return super.application(app, open: url, options: options)
    }
    let safePath = SceneDelegate.copySecurityScopedUrlToTemp(url) ?? url.path
    if let channel = SceneDelegate.channel {
      channel.invokeMethod("onPassReceived", arguments: safePath)
    } else {
      SceneDelegate.initialPassPath = safePath
    }
    return super.application(app, open: url, options: options)
  }
}

private enum SharedInbox {
  private static let appGroup = "group.es.adifconnect.app"

  static func filePaths() -> [String] {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) else {
      return []
    }
    let directory = container.appendingPathComponent("SharedInbox", isDirectory: true)
    guard let urls = try? FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    ) else {
      return []
    }
    return urls
      .filter { ["pkpass", "pdf"].contains($0.pathExtension.lowercased()) }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
      .map(\.path)
  }

  static func removeFile(at path: String) -> Bool {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) else {
      return false
    }
    let directory = container.appendingPathComponent("SharedInbox", isDirectory: true)
      .standardizedFileURL
    let file = URL(fileURLWithPath: path).standardizedFileURL
    guard file.deletingLastPathComponent() == directory else { return false }
    do {
      try FileManager.default.removeItem(at: file)
      return true
    } catch {
      return false
    }
  }
}

private enum PDFTicketTextExtractor {
  static func extract(_ data: Data) throws -> String {
    guard let document = PDFDocument(data: data) else {
      throw NSError(
        domain: "ADIFConnect.PDF",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "O ficheiro non é un PDF válido."]
      )
    }

    let pageTexts = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }
    let extractedText = pageTexts.joined(separator: "\n")
    let alphanumericCount = extractedText.unicodeScalars.reduce(into: 0) {
      if CharacterSet.alphanumerics.contains($1) { $0 += 1 }
    }
    if alphanumericCount >= 40 {
      return extractedText
    }

    var recognizedPages: [String] = []
    for index in 0..<document.pageCount {
      guard let page = document.page(at: index) else { continue }
      let image = page.thumbnail(
        of: CGSize(width: 1800, height: 2400),
        for: .mediaBox
      )
      guard let cgImage = image.cgImage else { continue }
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["es-ES", "gl-ES", "en-US"]
      request.usesLanguageCorrection = true
      try VNImageRequestHandler(cgImage: cgImage).perform([request])
      recognizedPages.append(
        (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")
      )
    }
    return recognizedPages.joined(separator: "\n")
  }
}
