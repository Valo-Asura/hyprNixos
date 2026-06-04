#pragma once

#include <filesystem>
#include <functional>
#include <string>
#include <string_view>

namespace vibeshell {

class IpcServer {
 public:
  using Handler = std::function<std::string(std::string_view)>;

  IpcServer() = default;
  IpcServer(const IpcServer&) = delete;
  IpcServer& operator=(const IpcServer&) = delete;
  ~IpcServer();

  bool start(const std::filesystem::path& socket_path);
  void process(const Handler& handler);
  [[nodiscard]] int fd() const;
  void shutdown();

  static std::filesystem::path defaultSocketPath();
  static int sendCommand(std::string_view command);

 private:
  int fd_ = -1;
  std::filesystem::path socket_path_;
};

}  // namespace vibeshell
