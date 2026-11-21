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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FlowFilesPlugin") {
      FlowFilesPlugin.register(with: registrar)
    }
  }
}

/// File .flow aperti da Mail, File, AirDrop…: ne legge il testo e lo passa a Dart
/// sul canale "dbflow/files". Nessun accesso alla rete.
final class FlowFilesPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private var channel: FlutterMethodChannel?
  private var pending: [String] = []
  private var dartReady = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FlowFilesPlugin()
    let channel = FlutterMethodChannel(name: "dbflow/files", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pending" else { return result(FlutterMethodNotImplemented) }
    dartReady = true
    result(pending)
    pending = []
  }

  // App avviata toccando un file.
  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    receive(connectionOptions?.urlContexts ?? [])
    return false
  }

  // App già aperta.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    receive(URLContexts)
    return true
  }

  private func receive(_ contexts: Set<UIOpenURLContext>) {
    for context in contexts {
      guard let text = Self.read(context.url) else { continue }
      if dartReady {
        channel?.invokeMethod("open", arguments: text)
      } else {
        pending.append(text)
      }
    }
  }

  private static func read(_ url: URL) -> String? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let text = try? String(contentsOf: url, encoding: .utf8)
    // iOS copia gli allegati in Documents/Inbox: la copia non serve più.
    if url.path.contains("/Inbox/") { try? FileManager.default.removeItem(at: url) }
    return text
  }
}
