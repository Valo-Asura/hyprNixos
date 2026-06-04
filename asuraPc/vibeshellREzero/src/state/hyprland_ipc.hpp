#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace vibeshell {

class HyprlandIpc {
 public:
  HyprlandIpc();

  [[nodiscard]] bool available() const;
  [[nodiscard]] std::optional<std::string> request(std::string_view command) const;
  [[nodiscard]] std::vector<int> workspaces() const;
  [[nodiscard]] int activeWorkspace() const;
  [[nodiscard]] std::string activeWindowTitle() const;
  bool dispatchWorkspace(int workspace) const;

 private:
  std::string socket_path_;
};

}  // namespace vibeshell
