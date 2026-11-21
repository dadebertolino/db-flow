#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shellapi.h>

#include <iterator>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Una sola finestra di DB Flow: un doppio clic su un file .flow con l'app già
// aperta non avvia una seconda copia, ma passa il file alla finestra esistente
// (come su Mac, iPhone e iPad). Nessun accesso alla rete.
constexpr const wchar_t kSingleInstanceMutex[] = L"Local\\DavideBertolino.DBFlow";
constexpr const wchar_t kWindowClassName[] = L"DB_FLOW_WINDOW";
constexpr const wchar_t kWindowTitle[] = L"DB Flow";

bool EndsWithFlow(const std::wstring& path) {
  if (path.size() < 5) return false;
  std::wstring ext = path.substr(path.size() - 5);
  for (auto& c : ext) c = static_cast<wchar_t>(::towlower(c));
  return ext == L".flow";
}

// Percorsi .flow passati sulla riga di comando, resi assoluti.
std::vector<std::wstring> FlowPathsFromCommandLine() {
  std::vector<std::wstring> paths;
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) return paths;
  for (int i = 1; i < argc; i++) {
    std::wstring arg = argv[i];
    if (!EndsWithFlow(arg)) continue;
    wchar_t full[MAX_PATH * 4];
    DWORD n = ::GetFullPathNameW(arg.c_str(), static_cast<DWORD>(std::size(full)), full, nullptr);
    paths.push_back(n > 0 && n < std::size(full) ? std::wstring(full, n) : arg);
  }
  ::LocalFree(argv);
  return paths;
}

// Se DB Flow è già aperta le consegna i file e la porta in primo piano.
// Restituisce true se l'istanza corrente deve chiudersi.
bool HandOffToRunningInstance() {
  HWND existing = ::FindWindowW(kWindowClassName, kWindowTitle);
  if (existing == nullptr) return false;
  for (const auto& path : FlowPathsFromCommandLine()) {
    COPYDATASTRUCT data{};
    data.dwData = kFlowFileMessage;
    data.cbData = static_cast<DWORD>((path.size() + 1) * sizeof(wchar_t));
    data.lpData = const_cast<wchar_t*>(path.c_str());
    ::SendMessageW(existing, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data));
  }
  if (::IsIconic(existing)) ::ShowWindow(existing, SW_RESTORE);
  ::SetForegroundWindow(existing);
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (::GetLastError() == ERROR_ALREADY_EXISTS && HandOffToRunningInstance()) {
    if (instance_mutex) ::CloseHandle(instance_mutex);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // Il percorso di un .flow aperto con doppio clic arriva a Dart come argomento
  // (main(args) in lib/main.dart).
  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Come sul Mac: finestra iniziale 1200×800, minima 720×560 (flutter_window.cpp).
  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1200, 800);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex) ::CloseHandle(instance_mutex);
  return EXIT_SUCCESS;
}
