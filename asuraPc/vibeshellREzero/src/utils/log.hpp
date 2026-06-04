#pragma once

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <string_view>

namespace vibeshell::log {

enum class Level {
  Debug = 0,
  Info = 1,
  Warn = 2,
  Error = 3,
};

inline Level parseLevel(const char* value) {
  if (value == nullptr) {
    return Level::Info;
  }
  const std::string_view level{value};
  if (level == "debug") {
    return Level::Debug;
  }
  if (level == "warn") {
    return Level::Warn;
  }
  if (level == "error") {
    return Level::Error;
  }
  return Level::Info;
}

inline Level& activeLevel() {
  static Level level = parseLevel(std::getenv("VIBESHELLREZERO_LOG"));
  return level;
}

inline const char* label(Level level) {
  switch (level) {
    case Level::Debug:
      return "debug";
    case Level::Info:
      return "info";
    case Level::Warn:
      return "warn";
    case Level::Error:
      return "error";
  }
  return "info";
}

inline void write(Level level, std::string_view message) {
  if (static_cast<int>(level) < static_cast<int>(activeLevel())) {
    return;
  }

  const auto now = std::chrono::system_clock::now();
  const std::time_t raw_time = std::chrono::system_clock::to_time_t(now);
  std::tm tm{};
  localtime_r(&raw_time, &tm);

  char time_buffer[32]{};
  std::strftime(time_buffer, sizeof(time_buffer), "%H:%M:%S", &tm);
  std::fprintf(stderr, "[%s] vibeshellREzero %-5s %.*s\n", time_buffer, label(level),
               static_cast<int>(message.size()), message.data());
}

inline void debug(std::string_view message) {
  write(Level::Debug, message);
}

inline void info(std::string_view message) {
  write(Level::Info, message);
}

inline void warn(std::string_view message) {
  write(Level::Warn, message);
}

inline void error(std::string_view message) {
  write(Level::Error, message);
}

}  // namespace vibeshell::log
