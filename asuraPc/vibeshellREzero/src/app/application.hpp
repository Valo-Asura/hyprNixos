#pragma once

#include <filesystem>

#include "ipc/ipc_server.hpp"
#include "renderer/renderer.hpp"
#include "state/config.hpp"
#include "state/hyprland_ipc.hpp"
#include "state/shell_state.hpp"
#include "wayland/wayland_shell.hpp"

namespace vibeshell {

class Application {
 public:
  explicit Application(std::filesystem::path config_path);
  Application(const Application&) = delete;
  Application& operator=(const Application&) = delete;
  ~Application();

  int run();

 private:
  std::string handleIpc(std::string_view command);
  void requestRedraw();
  void refreshState();
  int createTimer();

  std::filesystem::path config_path_;
  Config config_;
  HyprlandIpc hyprland_;
  ShellState state_;
  WaylandShell shell_;
  Renderer renderer_;
  IpcServer ipc_;
  int timer_fd_ = -1;
  std::uint64_t render_count_ = 0;
  bool running_ = true;
  bool redraw_requested_ = true;
};

}  // namespace vibeshell
