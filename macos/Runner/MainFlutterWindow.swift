import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Finestra iniziale ampia, centrata; sotto la dimensione minima il layout non regge.
    self.setContentSize(NSSize(width: 1200, height: 800))
    self.contentMinSize = NSSize(width: 720, height: 560)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlowFiles.shared.attach(to: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
