#pragma once

#include <chrono>
#include <string>
#include <vector>

#include "state/config.hpp"
#include "state/hyprland_ipc.hpp"

namespace vibeshell {

struct WorkspaceState {
  int id = 1;
  bool occupied = false;
  bool active = false;
};

struct SystemIndicators {
  int battery_percent = -1;
  bool network_up = false;
  std::string volume;
};

struct ShellState {
  std::vector<WorkspaceState> workspaces;
  int active_workspace = 1;
  std::string active_title = "Desktop";
  std::string clock_text;
  std::string date_text;
  std::string overlay_mode;
  SystemIndicators indicators;
  std::chrono::steady_clock::time_point last_refresh{};

  void refresh(const Config& config, const HyprlandIpc& hyprland);
  [[nodiscard]] std::string statusLine() const;
};

}  // namespace vibeshell
