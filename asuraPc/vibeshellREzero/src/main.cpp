#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

#include "app/application.hpp"
#include "ipc/ipc_server.hpp"
#include "state/config.hpp"

namespace {

void printHelp() {
  std::cout << R"(vibeshellREzero 0.1.0

Native C++20 Wayland/OpenGL ES shell MVP for Hyprland.

Usage:
  vibeshellREzero [--config PATH]
  vibeshellREzero msg <command>
  vibeshellREzero --help
  vibeshellREzero --version

IPC commands:
  ping
  status
  refresh
  workspace <n>
  quit
)";
}

}  // namespace

int main(const int argc, char** argv) {
  std::vector<std::string> args;
  args.reserve(static_cast<size_t>(argc));
  for (int i = 0; i < argc; ++i) {
    args.emplace_back(argv[i]);
  }

  if (argc >= 2 && (args[1] == "--help" || args[1] == "-h")) {
    printHelp();
    return 0;
  }
  if (argc >= 2 && args[1] == "--version") {
    std::cout << "vibeshellREzero 0.1.0\n";
    return 0;
  }
  if (argc >= 3 && args[1] == "msg") {
    std::string command;
    for (int i = 2; i < argc; ++i) {
      if (!command.empty()) {
        command.push_back(' ');
      }
      command += args[static_cast<size_t>(i)];
    }
    return vibeshell::IpcServer::sendCommand(command);
  }

  std::filesystem::path config_path = vibeshell::defaultConfigPath();
  for (int i = 1; i < argc; ++i) {
    if (args[static_cast<size_t>(i)] == "--config" && i + 1 < argc) {
      config_path = args[static_cast<size_t>(i + 1)];
      ++i;
    }
  }

  vibeshell::Application app{config_path};
  return app.run();
}
