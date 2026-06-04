#pragma once

#include <cstdint>
#include <filesystem>
#include <string>

namespace vibeshell {

struct Color {
  float r = 0.0F;
  float g = 0.0F;
  float b = 0.0F;
  float a = 1.0F;
};

struct Config {
  std::string bar_position = "top";
  int bar_height = 40;
  int surface_height = 120;
  int exclusive_zone = 40;
  int bar_margin = 4;
  int workspace_count = 10;
  std::string font_family = "Roboto Condensed";
  int font_size = 14;
  Color background{0.16F, 0.05F, 0.09F, 0.86F};
  Color surface{0.29F, 0.09F, 0.16F, 0.93F};
  Color surface_dim{0.20F, 0.06F, 0.12F, 0.80F};
  Color accent{1.00F, 0.48F, 0.66F, 1.00F};
  Color text{0.97F, 0.92F, 0.94F, 1.00F};
  Color muted{0.84F, 0.68F, 0.74F, 1.00F};
  Color border{0.47F, 0.19F, 0.29F, 1.00F};
};

Config loadConfig(const std::filesystem::path& path);
std::filesystem::path defaultConfigPath();
std::string colorToHex(const Color& color);

}  // namespace vibeshell
