#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "state/config.hpp"
#include "state/shell_state.hpp"

struct wl_display;
struct wl_egl_window;

namespace vibeshell {

class Renderer {
 public:
  Renderer() = default;
  Renderer(const Renderer&) = delete;
  Renderer& operator=(const Renderer&) = delete;
  ~Renderer();

  bool init(wl_display* display, wl_egl_window* window);
  void resize(int width, int height);
  bool render(const Config& config, const ShellState& state, int width, int height);
  [[nodiscard]] int workspaceAt(const Config& config, int x, int y) const;
  [[nodiscard]] std::string actionAt(const Config& config, int width, int x, int y) const;
  void shutdown();

 private:
  bool compileProgram();
  bool uploadTexture(const std::vector<std::uint8_t>& pixels, int width, int height);

  void* egl_display_ = nullptr;
  void* egl_surface_ = nullptr;
  void* egl_context_ = nullptr;
  unsigned int program_ = 0;
  unsigned int texture_ = 0;
  int width_ = 0;
  int height_ = 0;
};

}  // namespace vibeshell
