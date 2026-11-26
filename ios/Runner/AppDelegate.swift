import Flutter
import UIKit
import WidgetKit
import ActivityKit
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
      name: "es.andenlibre.app/sharing",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    SceneDelegate.channel = channel

    let activityChannel = FlutterMethodChannel(
      name: "es.andenlibre.app/live_activity",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    activityChannel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else {
        result(FlutterError(
          code: "LIVE_ACTIVITY_UNAVAILABLE",
          message: "As actividades en directo requiren iOS 16.2 ou posterior.",
          details: nil
        ))
        return
      }
      Task { @MainActor in
        do {
          switch call.method {
          case "start":
            guard let data = call.arguments as? [String: Any],
                  ActivityAuthorizationInfo().areActivitiesEnabled else {
              throw NativeActivityError.activitiesDisabled
            }
            guard let defaults = UserDefaults(suiteName: NativeActivityStore.appGroup) else {
              throw NativeActivityError.appGroupUnavailable
            }
            let attributes = LiveActivitiesAppAttributes()
            NativeActivityStore.write(data, id: attributes.id, to: defaults)
            let content = ActivityContent(
              state: LiveActivitiesAppAttributes.ContentState(
                appGroupId: NativeActivityStore.appGroup
              ),
              staleDate: nil
            )
            let activity = try Activity<LiveActivitiesAppAttributes>.request(
              attributes: attributes,
              content: content,
              pushType: nil
            )
            result(activity.id)
          case "update":
            guard let payload = call.arguments as? [String: Any],
                  let activityId = payload["activityId"] as? String,
                  let data = payload["data"] as? [String: Any],
                  let activity = Activity<LiveActivitiesAppAttributes>.activities
                    .first(where: { $0.id == activityId }),
                  let defaults = UserDefaults(suiteName: NativeActivityStore.appGroup) else {
              throw NativeActivityError.activityNotFound
            }
            NativeActivityStore.write(data, id: activity.attributes.id, to: defaults)
            await activity.update(ActivityContent(
              state: LiveActivitiesAppAttributes.ContentState(
                appGroupId: NativeActivityStore.appGroup
              ),
              staleDate: nil
            ))
            result(nil)
          case "end":
            guard let activityId = call.arguments as? String,
                  let activity = Activity<LiveActivitiesAppAttributes>.activities
                    .first(where: { $0.id == activityId }) else {
              throw NativeActivityError.activityNotFound
            }
            await activity.end(nil, dismissalPolicy: .immediate)
            result(nil)
          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(
            code: "LIVE_ACTIVITY_NATIVE_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }

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
      name: "es.andenlibre.app/pdf",
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
      name: "es.andenlibre.app/widget-cache",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    widgetChannel.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(suiteName: "group.es.andenlibre.app") else {
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
    if url.scheme == "andenlibre", url.host == "import-inbox" {
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

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  typealias LiveDeliveryData = ContentState

  struct ContentState: Codable, Hashable {
    var appGroupId: String

    init(appGroupId: String) {
      self.appGroupId = appGroupId
    }
  }

  var id: UUID

  init(id: UUID = UUID()) {
    self.id = id
  }
}

private enum NativeActivityStore {
  static let appGroup = "group.es.andenlibre.app"

  static func write(_ values: [String: Any], id: UUID, to defaults: UserDefaults) {
    for (key, value) in values where key != "activityId" && key != "data" {
      defaults.set(value, forKey: "\(id.uuidString)_\(key)")
    }
  }
}

private enum NativeActivityError: LocalizedError {
  case activitiesDisabled
  case appGroupUnavailable
  case activityNotFound

  var errorDescription: String? {
    switch self {
    case .activitiesDisabled:
      return "As actividades en directo están desactivadas ou non dispoñibles."
    case .appGroupUnavailable:
      return "Non está dispoñible o grupo compartido da aplicación."
    case .activityNotFound:
      return "Non se atopou a actividade en directo solicitada."
    }
  }
}

private enum SharedInbox {
  private static let appGroup = "group.es.andenlibre.app"

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
        domain: "AndenLibre.PDF",
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
