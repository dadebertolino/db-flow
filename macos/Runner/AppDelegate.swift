import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // File .flow aperti dal Finder (doppio clic, "Apri con", trascinamento sull'icona).
  override func application(_ application: NSApplication, open urls: [URL]) {
    FlowFiles.shared.receive(urls)
  }
}

/// Passa a Dart il testo dei file .flow aperti dal Finder, sul canale
/// "dbflow/files". Nessun accesso alla rete.
final class FlowFiles {
  static let shared = FlowFiles()

  private var channel: FlutterMethodChannel?
  private var pending: [String] = []
  private var dartReady = false

  func attach(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dbflow/files", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "pending" else { return result(FlutterMethodNotImplemented) }
      self.dartReady = true
      result(self.pending)
      self.pending = []
    }
    self.channel = channel
  }

  func receive(_ urls: [URL]) {
    for url in urls {
      guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
      if dartReady, let channel {
        channel.invokeMethod("open", arguments: text)
      } else {
        pending.append(text)
      }
    }
  }
}
