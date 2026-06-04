#include "ipc/ipc_server.hpp"

#include <fcntl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <cerrno>
#include <cstring>
#include <cstdlib>
#include <iostream>

#include "utils/log.hpp"

namespace vibeshell {
namespace {

std::string trim(std::string value) {
  const auto first = value.find_first_not_of(" \t\r\n");
  if (first == std::string::npos) {
    return {};
  }
  const auto last = value.find_last_not_of(" \t\r\n");
  return value.substr(first, last - first + 1);
}

bool setNonBlocking(const int fd) {
  const int flags = ::fcntl(fd, F_GETFL, 0);
  if (flags < 0) {
    return false;
  }
  return ::fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

std::string runtimeDir() {
  const char* runtime = std::getenv("XDG_RUNTIME_DIR");
  if (runtime != nullptr && runtime[0] != '\0') {
    return runtime;
  }
  return "/tmp";
}

}  // namespace

IpcServer::~IpcServer() {
  shutdown();
}

bool IpcServer::start(const std::filesystem::path& socket_path) {
  socket_path_ = socket_path;
  std::filesystem::remove(socket_path_);

  fd_ = ::socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd_ < 0) {
    log::warn("IPC socket creation failed");
    return false;
  }
  setNonBlocking(fd_);

  sockaddr_un address{};
  address.sun_family = AF_UNIX;
  const auto path = socket_path_.string();
  if (path.size() >= sizeof(address.sun_path)) {
    log::warn("IPC socket path too long");
    shutdown();
    return false;
  }
  std::strncpy(address.sun_path, path.c_str(), sizeof(address.sun_path) - 1);

  if (::bind(fd_, reinterpret_cast<sockaddr*>(&address), sizeof(address)) != 0) {
    log::warn("IPC socket bind failed");
    shutdown();
    return false;
  }
  if (::listen(fd_, 8) != 0) {
    log::warn("IPC socket listen failed");
    shutdown();
    return false;
  }
  log::info("IPC listening at " + path);
  return true;
}

void IpcServer::process(const Handler& handler) {
  if (fd_ < 0) {
    return;
  }

  while (true) {
    const int client = ::accept4(fd_, nullptr, nullptr, SOCK_CLOEXEC | SOCK_NONBLOCK);
    if (client < 0) {
      if (errno != EAGAIN && errno != EWOULDBLOCK) {
        log::warn("IPC accept failed");
      }
      return;
    }

    std::string command;
    char buffer[1024]{};
    while (true) {
      const ssize_t count = ::read(client, buffer, sizeof(buffer));
      if (count > 0) {
        command.append(buffer, static_cast<size_t>(count));
        if (command.size() > 4096U) {
          break;
        }
        continue;
      }
      break;
    }

    const std::string response = handler(trim(command));
    std::string framed = response;
    framed.push_back('\n');
    size_t written_total = 0;
    while (written_total < framed.size()) {
      const ssize_t written =
          ::write(client, framed.data() + written_total, framed.size() - written_total);
      if (written <= 0) {
        break;
      }
      written_total += static_cast<size_t>(written);
    }
    ::close(client);
  }
}

int IpcServer::fd() const {
  return fd_;
}

void IpcServer::shutdown() {
  if (fd_ >= 0) {
    ::close(fd_);
    fd_ = -1;
  }
  if (!socket_path_.empty()) {
    std::filesystem::remove(socket_path_);
  }
}

std::filesystem::path IpcServer::defaultSocketPath() {
  return std::filesystem::path{runtimeDir()} / "vibeshellREzero.sock";
}

int IpcServer::sendCommand(std::string_view command) {
  const int fd = ::socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0) {
    return 2;
  }

  sockaddr_un address{};
  address.sun_family = AF_UNIX;
  const auto path = defaultSocketPath().string();
  if (path.size() >= sizeof(address.sun_path)) {
    ::close(fd);
    return 2;
  }
  std::strncpy(address.sun_path, path.c_str(), sizeof(address.sun_path) - 1);
  if (::connect(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) != 0) {
    std::cerr << "vibeshellREzero IPC unavailable at " << path << '\n';
    ::close(fd);
    return 1;
  }

  size_t sent = 0;
  while (sent < command.size()) {
    const ssize_t written =
        ::write(fd, command.data() + sent, static_cast<size_t>(command.size() - sent));
    if (written <= 0) {
      ::close(fd);
      return 2;
    }
    sent += static_cast<size_t>(written);
  }
  ::shutdown(fd, SHUT_WR);

  char buffer[1024]{};
  while (true) {
    const ssize_t count = ::read(fd, buffer, sizeof(buffer));
    if (count > 0) {
      std::cout.write(buffer, count);
      continue;
    }
    break;
  }
  ::close(fd);
  return 0;
}

}  // namespace vibeshell
