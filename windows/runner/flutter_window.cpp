#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <fstream>
#include <iterator>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Dimensione minima della finestra, come sul Mac (punti logici).
constexpr int kMinWidth = 720;
constexpr int kMinHeight = 560;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // File .flow ricevuti dall'esterno. All'avvio il percorso arriva a Dart come
  // argomento; qui arrivano quelli aperti con l'app già in esecuzione, quindi
  // «pending» non ha mai nulla da consegnare.
  files_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "dbflow/files",
      &flutter::StandardMethodCodec::GetInstance());
  files_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "pending") {
          result->Success(flutter::EncodableValue(flutter::EncodableList{}));
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OpenFlowFile(const std::wstring& path) {
  if (!files_channel_) return;
  std::ifstream file(path, std::ios::binary);
  if (!file) return;  // file sparito o illeggibile: si ignora
  std::string text((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
  // BOM UTF-8 eventualmente aggiunto da un editor di testo
  if (text.size() >= 3 && text.compare(0, 3, "\xEF\xBB\xBF") == 0) text.erase(0, 3);
  files_channel_->InvokeMethod("open", std::make_unique<flutter::EncodableValue>(text));
}

void FlutterWindow::OnDestroy() {
  files_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_GETMINMAXINFO: {
      const double scale =
          FlutterDesktopGetDpiForMonitor(::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)) / 96.0;
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = static_cast<LONG>(kMinWidth * scale);
      info->ptMinTrackSize.y = static_cast<LONG>(kMinHeight * scale);
      return 0;
    }
    case WM_COPYDATA: {
      const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
      if (data != nullptr && data->dwData == kFlowFileMessage && data->lpData != nullptr &&
          data->cbData >= sizeof(wchar_t)) {
        const auto* chars = static_cast<const wchar_t*>(data->lpData);
        std::wstring path(chars, data->cbData / sizeof(wchar_t));
        if (!path.empty() && path.back() == L'\0') path.pop_back();
        OpenFlowFile(path);
        return TRUE;
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
