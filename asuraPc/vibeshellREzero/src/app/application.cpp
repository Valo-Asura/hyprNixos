#include "app/application.hpp"

#include <poll.h>
#include <sys/timerfd.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <cstdint>
#include <string>
#include <utility>

#include "utils/log.hpp"

namespace vibeshell {
namespace {

std::string renderSnapshot(const ShellState& state) {
  std::string snapshot = state.statusLine();
  snapshot += "|overlay:";
  snapshot += state.overlay_mode;
  for (const auto& workspace : state.workspaces) {
    snapshot += "|ws:";
    snapshot += std::to_string(workspace.id);
    snapshot += workspace.active ? ":a" : ":i";
    snapshot += workspace.occupied ? ":o" : ":e";
  }
  return snapshot;
}

}  // namespace

Application::Application(std::filesystem::path config_path)
    : config_path_(std::move(config_path)),
      config_(loadConfig(config_path_)),
      shell_(config_) {}

Application::~Application() {
  if (timer_fd_ >= 0) {
    ::close(timer_fd_);
    timer_fd_ = -1;
  }
}

int Application::createTimer() {
  const int fd = ::timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
  if (fd < 0) {
    return -1;
  }

  itimerspec spec{};
  spec.it_value.tv_sec = 1;
  spec.it_interval.tv_sec = 1;
  if (::timerfd_settime(fd, 0, &spec, nullptr) != 0) {
    ::close(fd);
    return -1;
  }
  return fd;
}

void Application::refreshState() {
  const std::string before = renderSnapshot(state_);
  state_.refresh(config_, hyprland_);
  if (renderSnapshot(state_) != before) {
    requestRedraw();
  }
}

void Application::requestRedraw() {
  redraw_requested_ = true;
}

std::string Application::handleIpc(const std::string_view command) {
  if (command == "ping") {
    return "pong";
  }
  if (command == "status" || command.empty()) {
    return "renders=" + std::to_string(render_count_) + " " + state_.statusLine();
  }
  if (command == "refresh") {
    refreshState();
    return "refreshed";
  }
  if (command == "quit") {
    running_ = false;
    return "quitting";
  }
  if (command == "hide" || command == "close") {
    state_.overlay_mode.clear();
    requestRedraw();
    return "hidden";
  }
  if (command.starts_with("run ")) {
    const std::string mode{command.substr(4)};
    state_.overlay_mode = state_.overlay_mode == mode ? "" : mode;
    requestRedraw();
    return state_.overlay_mode.empty() ? "hidden" : "showing " + state_.overlay_mode;
  }
  if (command.starts_with("toggle ")) {
    const std::string mode{command.substr(7)};
    state_.overlay_mode = state_.overlay_mode == mode ? "" : mode;
    requestRedraw();
    return state_.overlay_mode.empty() ? "hidden" : "showing " + state_.overlay_mode;
  }
  if (command.starts_with("workspace ")) {
    try {
      const int workspace = std::stoi(std::string{command.substr(10)});
      if (workspace > 0 && hyprland_.dispatchWorkspace(workspace)) {
        refreshState();
        return "ok";
      }
    } catch (...) {
    }
    return "workspace dispatch failed";
  }
  return "unknown command";
}

int Application::run() {
  log::info("starting native shell from config " + config_path_.string());
  refreshState();

  if (!shell_.init()) {
    return 1;
  }
  shell_.setClickHandler([this](const int x, const int y) {
    const int workspace = renderer_.workspaceAt(config_, x, y);
    if (workspace > 0) {
      hyprland_.dispatchWorkspace(workspace);
      refreshState();
      return;
    }

    const std::string action = renderer_.actionAt(config_, shell_.width(), x, y);
    if (action.empty()) {
      if (!state_.overlay_mode.empty() && y > config_.bar_height) {
        state_.overlay_mode.clear();
        requestRedraw();
      }
      return;
    }
    if (action == "pin") {
      return;
    }
    state_.overlay_mode = state_.overlay_mode == action ? "" : action;
    requestRedraw();
    if (action == "launcher") {
      log::info("launcher placeholder opened from bar click");
    }
  });

  if (!shell_.waitForConfigure()) {
    return 1;
  }

  if (!renderer_.init(shell_.display(), shell_.eglWindow())) {
    return 1;
  }

  timer_fd_ = createTimer();
  if (timer_fd_ < 0) {
    log::warn("timerfd unavailable; redraws will only happen from Wayland/IPC events");
  }
  ipc_.start(IpcServer::defaultSocketPath());
  requestRedraw();

  while (running_ && !shell_.closed()) {
    if (redraw_requested_ || shell_.needsRedraw()) {
      renderer_.render(config_, state_, shell_.width(), shell_.height());
      ++render_count_;
      shell_.clearRedraw();
      redraw_requested_ = false;
    }

    shell_.flush();

    std::array<pollfd, 3> fds{};
    nfds_t count = 0;
    const int wayland_fd = shell_.fd();
    if (wayland_fd >= 0) {
      fds[count++] = pollfd{.fd = wayland_fd, .events = POLLIN, .revents = 0};
    }
    if (timer_fd_ >= 0) {
      fds[count++] = pollfd{.fd = timer_fd_, .events = POLLIN, .revents = 0};
    }
    if (ipc_.fd() >= 0) {
      fds[count++] = pollfd{.fd = ipc_.fd(), .events = POLLIN, .revents = 0};
    }

    const int poll_result = ::poll(fds.data(), count, -1);
    if (poll_result < 0) {
      if (errno == EINTR) {
        continue;
      }
      log::error("poll failed");
      return 1;
    }

    size_t index = 0;
    if (wayland_fd >= 0) {
      if ((fds[index].revents & POLLIN) != 0) {
        if (!shell_.dispatch()) {
          log::error("Wayland dispatch failed");
          return 1;
        }
      }
      ++index;
    }
    if (timer_fd_ >= 0) {
      if ((fds[index].revents & POLLIN) != 0) {
        std::uint64_t expirations = 0;
        while (::read(timer_fd_, &expirations, sizeof(expirations)) > 0) {
        }
        refreshState();
      }
      ++index;
    }
    if (ipc_.fd() >= 0 && (fds[index].revents & POLLIN) != 0) {
      ipc_.process([this](const std::string_view command) { return handleIpc(command); });
    }
  }

  ipc_.shutdown();
  renderer_.shutdown();
  shell_.shutdown();
  log::info("shutdown complete");
  return 0;
}

}  // namespace vibeshell
