#include "state/shell_state.hpp"

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <set>
#include <sstream>

namespace vibeshell {
namespace {

std::string readFirstLine(const std::filesystem::path& path) {
  std::ifstream file(path);
  std::string line;
  std::getline(file, line);
  return line;
}

int readBatteryPercent() {
  const std::filesystem::path base{"/sys/class/power_supply"};
  if (!std::filesystem::exists(base)) {
    return -1;
  }
  for (const auto& entry : std::filesystem::directory_iterator(base)) {
    const auto name = entry.path().filename().string();
    if (!name.starts_with("BAT")) {
      continue;
    }
    const auto raw = readFirstLine(entry.path() / "capacity");
    if (raw.empty()) {
      continue;
    }
    try {
      return std::stoi(raw);
    } catch (...) {
      return -1;
    }
  }
  return -1;
}

bool readNetworkUp() {
  const std::filesystem::path base{"/sys/class/net"};
  if (!std::filesystem::exists(base)) {
    return false;
  }
  for (const auto& entry : std::filesystem::directory_iterator(base)) {
    const auto name = entry.path().filename().string();
    if (name == "lo") {
      continue;
    }
    const auto state = readFirstLine(entry.path() / "operstate");
    if (state == "up" || state == "unknown") {
      return true;
    }
  }
  return false;
}

std::string readVolume() {
  FILE* pipe = ::popen("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null", "r");
  if (pipe == nullptr) {
    return {};
  }
  char buffer[128]{};
  const std::string output = std::fgets(buffer, sizeof(buffer), pipe) == nullptr ? "" : buffer;
  ::pclose(pipe);

  const auto pos = output.find("Volume:");
  if (pos == std::string::npos) {
    return {};
  }
  try {
    const double volume = std::stod(output.substr(pos + 7));
    const int percent = static_cast<int>(volume * 100.0 + 0.5);
    if (output.find("MUTED") != std::string::npos) {
      return "muted";
    }
    return std::to_string(percent) + "%";
  } catch (...) {
    return {};
  }
}

void updateClock(ShellState& state) {
  const auto now = std::chrono::system_clock::now();
  const std::time_t raw_time = std::chrono::system_clock::to_time_t(now);
  std::tm tm{};
  localtime_r(&raw_time, &tm);

  char clock_buffer[16]{};
  char date_buffer[32]{};
  std::strftime(clock_buffer, sizeof(clock_buffer), "%H:%M", &tm);
  std::strftime(date_buffer, sizeof(date_buffer), "%a %d %b", &tm);
  state.clock_text = clock_buffer;
  state.date_text = date_buffer;
}

}  // namespace

void ShellState::refresh(const Config& config, const HyprlandIpc& hyprland) {
  active_workspace = hyprland.activeWorkspace();
  active_title = hyprland.activeWindowTitle();

  const auto occupied = hyprland.workspaces();
  std::set<int> occupied_set{occupied.begin(), occupied.end()};

  workspaces.clear();
  workspaces.reserve(static_cast<size_t>(config.workspace_count));
  for (int id = 1; id <= config.workspace_count; ++id) {
    workspaces.push_back(WorkspaceState{
        .id = id,
        .occupied = occupied_set.contains(id),
        .active = id == active_workspace,
    });
  }

  indicators.battery_percent = readBatteryPercent();
  indicators.network_up = readNetworkUp();
  indicators.volume = readVolume();
  updateClock(*this);
  last_refresh = std::chrono::steady_clock::now();
}

std::string ShellState::statusLine() const {
  std::ostringstream stream;
  stream << "workspace=" << active_workspace << " title=\"" << active_title << "\" clock="
         << clock_text << " network=" << (indicators.network_up ? "up" : "down");
  if (!overlay_mode.empty()) {
    stream << " overlay=" << overlay_mode;
  }
  if (!indicators.volume.empty()) {
    stream << " volume=" << indicators.volume;
  }
  if (indicators.battery_percent >= 0) {
    stream << " battery=" << indicators.battery_percent << "%";
  }
  return stream.str();
}

}  // namespace vibeshell
