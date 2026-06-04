#include "state/config.hpp"

#include <algorithm>
#include <charconv>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string_view>

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

std::string unquote(std::string value) {
  value = trim(std::move(value));
  if (value.size() >= 2 && value.front() == '"' && value.back() == '"') {
    return value.substr(1, value.size() - 2);
  }
  return value;
}

int parseInt(std::string_view value, int fallback) {
  int parsed = fallback;
  const auto* begin = value.data();
  const auto* end = value.data() + value.size();
  const auto result = std::from_chars(begin, end, parsed);
  if (result.ec != std::errc{}) {
    return fallback;
  }
  return parsed;
}

float channelFromHex(std::string_view value, size_t offset) {
  unsigned int channel = 0;
  std::stringstream stream;
  stream << std::hex << value.substr(offset, 2);
  stream >> channel;
  return static_cast<float>(channel) / 255.0F;
}

Color parseColor(std::string value, const Color& fallback) {
  value = unquote(trim(std::move(value)));
  if (!value.empty() && value.front() == '#') {
    value.erase(value.begin());
  }
  if (value.size() != 6 && value.size() != 8) {
    return fallback;
  }
  if (!std::ranges::all_of(value, [](const char c) {
        return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') ||
               (c >= 'A' && c <= 'F');
      })) {
    return fallback;
  }

  Color color = fallback;
  color.r = channelFromHex(value, 0);
  color.g = channelFromHex(value, 2);
  color.b = channelFromHex(value, 4);
  color.a = value.size() == 8 ? channelFromHex(value, 6) : 1.0F;
  return color;
}

void applyValue(Config& config, const std::string& key, const std::string& value) {
  const auto trimmed_value = trim(value);
  if (key == "bar_position") {
    config.bar_position = unquote(trimmed_value);
  } else if (key == "bar_height") {
    config.bar_height = std::clamp(parseInt(trimmed_value, config.bar_height), 24, 160);
  } else if (key == "surface_height") {
    config.surface_height = std::clamp(parseInt(trimmed_value, config.surface_height), 24, 480);
  } else if (key == "exclusive_zone") {
    config.exclusive_zone = std::clamp(parseInt(trimmed_value, config.exclusive_zone), 0, 200);
  } else if (key == "bar_margin") {
    config.bar_margin = std::clamp(parseInt(trimmed_value, config.bar_margin), 0, 32);
  } else if (key == "workspace_count") {
    config.workspace_count = std::clamp(parseInt(trimmed_value, config.workspace_count), 1, 20);
  } else if (key == "font_family") {
    config.font_family = unquote(trimmed_value);
  } else if (key == "font_size") {
    config.font_size = std::clamp(parseInt(trimmed_value, config.font_size), 8, 32);
  } else if (key == "background") {
    config.background = parseColor(trimmed_value, config.background);
  } else if (key == "surface") {
    config.surface = parseColor(trimmed_value, config.surface);
  } else if (key == "surface_dim") {
    config.surface_dim = parseColor(trimmed_value, config.surface_dim);
  } else if (key == "accent") {
    config.accent = parseColor(trimmed_value, config.accent);
  } else if (key == "text") {
    config.text = parseColor(trimmed_value, config.text);
  } else if (key == "muted") {
    config.muted = parseColor(trimmed_value, config.muted);
  } else if (key == "border") {
    config.border = parseColor(trimmed_value, config.border);
  }
}

}  // namespace

Config loadConfig(const std::filesystem::path& path) {
  Config config;
  std::ifstream file(path);
  if (!file.good()) {
    log::warn("config not found, using built-in defaults: " + path.string());
    return config;
  }

  std::string line;
  while (std::getline(file, line)) {
    if (const auto comment = line.find('#'); comment != std::string::npos) {
      line.erase(comment);
    }
    line = trim(std::move(line));
    if (line.empty()) {
      continue;
    }
    const auto separator = line.find('=');
    if (separator == std::string::npos) {
      continue;
    }
    const auto key = trim(line.substr(0, separator));
    const auto value = line.substr(separator + 1);
    applyValue(config, key, value);
  }

  return config;
}

std::filesystem::path defaultConfigPath() {
  if (const char* explicit_path = std::getenv("VIBESHELLREZERO_CONFIG");
      explicit_path != nullptr && explicit_path[0] != '\0') {
    return explicit_path;
  }

  std::filesystem::path local = std::filesystem::current_path() / "config" / "default.toml";
  if (std::filesystem::exists(local)) {
    return local;
  }

  return "/etc/nixos/asuraPc/vibeshellREzero/config/default.toml";
}

std::string colorToHex(const Color& color) {
  auto to_channel = [](const float value) {
    return std::clamp(static_cast<int>(value * 255.0F + 0.5F), 0, 255);
  };
  std::ostringstream stream;
  stream << '#'
         << std::hex << std::setfill('0') << std::setw(2) << to_channel(color.r)
         << std::setw(2) << to_channel(color.g) << std::setw(2) << to_channel(color.b)
         << std::setw(2) << to_channel(color.a);
  return stream.str();
}

}  // namespace vibeshell
