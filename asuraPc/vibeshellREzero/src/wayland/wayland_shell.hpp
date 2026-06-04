#pragma once

#include <cstdint>
#include <functional>
#include <wayland-client.h>

#include "state/config.hpp"

struct wl_compositor;
struct wl_display;
struct wl_egl_window;
struct wl_pointer;
struct wl_registry;
struct wl_seat;
struct wl_surface;
struct zwlr_layer_shell_v1;
struct zwlr_layer_surface_v1;

namespace vibeshell {

class WaylandShell {
 public:
  using ClickHandler = std::function<void(int, int)>;

  explicit WaylandShell(const Config& config);
  WaylandShell(const WaylandShell&) = delete;
  WaylandShell& operator=(const WaylandShell&) = delete;
  ~WaylandShell();

  bool init();
  bool waitForConfigure();
  int fd() const;
  bool dispatch();
  void flush();
  void shutdown();

  [[nodiscard]] wl_display* display() const;
  [[nodiscard]] wl_egl_window* eglWindow() const;
  [[nodiscard]] int width() const;
  [[nodiscard]] int height() const;
  [[nodiscard]] bool needsRedraw() const;
  void clearRedraw();
  [[nodiscard]] bool closed() const;
  void setClickHandler(ClickHandler handler);

  static void handleRegistryGlobal(void* data, wl_registry* registry, std::uint32_t name,
                                   const char* interface, std::uint32_t version);
  static void handleRegistryRemove(void* data, wl_registry* registry, std::uint32_t name);
  static void handleLayerConfigure(void* data, zwlr_layer_surface_v1* surface,
                                   std::uint32_t serial, std::uint32_t width,
                                   std::uint32_t height);
  static void handleLayerClosed(void* data, zwlr_layer_surface_v1* surface);
  static void handleSeatCapabilities(void* data, wl_seat* seat, std::uint32_t capabilities);
  static void handleSeatName(void* data, wl_seat* seat, const char* name);
  static void handlePointerEnter(void* data, wl_pointer* pointer, std::uint32_t serial,
                                 wl_surface* surface, wl_fixed_t surface_x,
                                 wl_fixed_t surface_y);
  static void handlePointerLeave(void* data, wl_pointer* pointer, std::uint32_t serial,
                                 wl_surface* surface);
  static void handlePointerMotion(void* data, wl_pointer* pointer, std::uint32_t time,
                                  wl_fixed_t surface_x, wl_fixed_t surface_y);
  static void handlePointerButton(void* data, wl_pointer* pointer, std::uint32_t serial,
                                  std::uint32_t time, std::uint32_t button,
                                  std::uint32_t state);
  static void handlePointerAxis(void* data, wl_pointer* pointer, std::uint32_t time,
                                std::uint32_t axis, wl_fixed_t value);
  static void handlePointerFrame(void* data, wl_pointer* pointer);
  static void handlePointerAxisSource(void* data, wl_pointer* pointer,
                                      std::uint32_t axis_source);
  static void handlePointerAxisStop(void* data, wl_pointer* pointer, std::uint32_t time,
                                    std::uint32_t axis);
  static void handlePointerAxisDiscrete(void* data, wl_pointer* pointer, std::uint32_t axis,
                                        std::int32_t discrete);
  static void handlePointerAxisValue120(void* data, wl_pointer* pointer, std::uint32_t axis,
                                        std::int32_t value120);
  static void handlePointerAxisRelativeDirection(void* data, wl_pointer* pointer,
                                                 std::uint32_t axis,
                                                 std::uint32_t direction);

 private:
  void createLayerSurface();
  void bindPointer();
  void destroyPointer();

  Config config_;
  wl_display* display_ = nullptr;
  wl_registry* registry_ = nullptr;
  wl_compositor* compositor_ = nullptr;
  zwlr_layer_shell_v1* layer_shell_ = nullptr;
  wl_surface* surface_ = nullptr;
  zwlr_layer_surface_v1* layer_surface_ = nullptr;
  wl_seat* seat_ = nullptr;
  wl_pointer* pointer_ = nullptr;
  wl_egl_window* egl_window_ = nullptr;
  int width_ = 1;
  int height_ = 1;
  int pointer_x_ = -1;
  int pointer_y_ = -1;
  bool configured_ = false;
  bool needs_redraw_ = true;
  bool closed_ = false;
  ClickHandler click_handler_;
};

}  // namespace vibeshell
