#include "state/hyprland_ipc.hpp"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <cerrno>
#include <cstring>
#include <cstdlib>
#include <regex>
#include <set>

namespace vibeshell {
namespace {

std::string getenvString(const char* key) {
  const char* value = std::getenv(key);
  return value == nullptr ? std::string{} : std::string{value};
}

std::string unescapeJsonString(std::string value) {
  std::string out;
  out.reserve(value.size());
  bool escaped = false;
  for (const char c : value) {
    if (escaped) {
      switch (c) {
        case 'n':
          out.push_back('\n');
          break;
        case 't':
          out.push_back('\t');
          break;
        default:
          out.push_back(c);
          break;
      }
      escaped = false;
      continue;
    }
    if (c == '\\') {
      escaped = true;
      continue;
    }
    out.push_back(c);
  }
  return out;
}

}  // namespace

HyprlandIpc::HyprlandIpc() {
  const auto runtime = getenvString("XDG_RUNTIME_DIR");
  const auto signature = getenvString("HYPRLAND_INSTANCE_SIGNATURE");
  if (!runtime.empty() && !signature.empty()) {
    socket_path_ = runtime + "/hypr/" + signature + "/.socket.sock";
  }
}

bool HyprlandIpc::available() const {
  return !socket_path_.empty();
}

std::optional<std::string> HyprlandIpc::request(std::string_view command) const {
  if (socket_path_.empty()) {
    return std::nullopt;
  }

  const int fd = ::socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0) {
    return std::nullopt;
  }

  sockaddr_un address{};
  address.sun_family = AF_UNIX;
  if (socket_path_.size() >= sizeof(address.sun_path)) {
    ::close(fd);
    return std::nullopt;
  }
  std::strncpy(address.sun_path, socket_path_.c_str(), sizeof(address.sun_path) - 1);

  if (::connect(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) != 0) {
    ::close(fd);
    return std::nullopt;
  }

  size_t sent = 0;
  while (sent < command.size()) {
    const ssize_t written =
        ::write(fd, command.data() + sent, static_cast<size_t>(command.size() - sent));
    if (written <= 0) {
      ::close(fd);
      return std::nullopt;
    }
    sent += static_cast<size_t>(written);
  }
  ::shutdown(fd, SHUT_WR);

  std::string response;
  char buffer[4096]{};
  while (true) {
    const ssize_t read_count = ::read(fd, buffer, sizeof(buffer));
    if (read_count > 0) {
      response.append(buffer, static_cast<size_t>(read_count));
      continue;
    }
    break;
  }
  ::close(fd);
  return response;
}

std::vector<int> HyprlandIpc::workspaces() const {
  const auto response = request("j/workspaces");
  if (!response) {
    return {};
  }

  std::set<int> ids;
  const std::regex id_regex{"\"id\"\\s*:\\s*(-?[0-9]+)"};
  for (auto it = std::sregex_iterator(response->begin(), response->end(), id_regex);
       it != std::sregex_iterator(); ++it) {
    ids.insert(std::stoi((*it)[1].str()));
  }
  return {ids.begin(), ids.end()};
}

int HyprlandIpc::activeWorkspace() const {
  const auto response = request("j/activeworkspace");
  if (!response) {
    return 1;
  }
  const std::regex id_regex{"\"id\"\\s*:\\s*(-?[0-9]+)"};
  std::smatch match;
  if (std::regex_search(*response, match, id_regex)) {
    return std::stoi(match[1].str());
  }
  return 1;
}

std::string HyprlandIpc::activeWindowTitle() const {
  const auto response = request("j/activewindow");
  if (!response) {
    return "Hyprland";
  }
  const std::regex title_regex{"\"title\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\""};
  std::smatch match;
  if (std::regex_search(*response, match, title_regex)) {
    auto title = unescapeJsonString(match[1].str());
    if (!title.empty()) {
      constexpr size_t max_title = 72;
      if (title.size() > max_title) {
        title.resize(max_title - 1);
        title.push_back('.');
      }
      return title;
    }
  }
  return "Desktop";
}

bool HyprlandIpc::dispatchWorkspace(const int workspace) const {
  const auto is_ok = [](const std::optional<std::string>& response) {
    if (!response) {
      return false;
    }
    std::string lowered = *response;
    std::ranges::transform(lowered, lowered.begin(), [](const unsigned char c) {
      return static_cast<char>(std::tolower(c));
    });
    return lowered.empty() || lowered.find("ok") != std::string::npos ||
           (lowered.find("error") == std::string::npos &&
            lowered.find("unknown") == std::string::npos &&
            lowered.find("fail") == std::string::npos);
  };

  const std::string command =
      "dispatch hl.dsp.focus({ workspace = \"" + std::to_string(workspace) + "\" })";
  if (is_ok(request(command))) {
    return true;
  }
  return is_ok(request("dispatch workspace " + std::to_string(workspace)));
}

}  // namespace vibeshell
