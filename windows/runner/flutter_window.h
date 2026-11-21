#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "win32_window.h"

// Identifica il WM_COPYDATA con cui una seconda istanza passa il percorso di un
// file .flow alla finestra già aperta (vedi main.cpp).
constexpr ULONG_PTR kFlowFileMessage = 0x44424657;  // "DBFW"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Canale "dbflow/files", lo stesso di iOS e macOS (lib/io/incoming.dart).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> files_channel_;

  // Legge il file .flow [path] e ne consegna il testo a Dart.
  void OpenFlowFile(const std::wstring& path);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
