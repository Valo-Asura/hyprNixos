#include "wayland/wayland_shell.hpp"

#include <wayland-client.h>
#include <wayland-egl.h>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <string>
#include <utility>

extern "C" {
#include "wlr-layer-shell-unstable-v1-client-protocol.h"
}

#include "utils/log.hpp"

namespace vibeshell {
namespace {

constexpr std::uint32_t kPointerButtonPressed = 1;

const wl_registry_listener kRegistryListener = {
    .global = WaylandShell::handleRegistryGlobal,
    .global_remove = WaylandShell::handleRegistryRemove,
};

const zwlr_layer_surface_v1_listener kLayerSurfaceListener = {
    .configure = WaylandShell::handleLayerConfigure,
    .closed = WaylandShell::handleLayerClosed,
};

const wl_seat_listener kSeatListener = {
    .capabilities = WaylandShell::handleSeatCapabilities,
    .name = WaylandShell::handleSeatName,
};

const wl_pointer_listener kPointerListener = {
    .enter = WaylandShell::handlePointerEnter,
    .leave = WaylandShell::handlePointerLeave,
    .motion = WaylandShell::handlePointerMotion,
    .button = WaylandShell::handlePointerButton,
    .axis = WaylandShell::handlePointerAxis,
    .frame = WaylandShell::handlePointerFrame,
    .axis_source = WaylandShell::handlePointerAxisSource,
    .axis_stop = WaylandShell::handlePointerAxisStop,
    .axis_discrete = WaylandShell::handlePointerAxisDiscrete,
    .axis_value120 = WaylandShell::handlePointerAxisValue120,
    .axis_relative_direction = WaylandShell::handlePointerAxisRelativeDirection,
};

int fixedToInt(const wl_fixed_t value) {
  return wl_fixed_to_int(value);
}

bool envDisabled(const char* key) {
  const char* value = std::getenv(key);
  return value != nullptr && (std::strcmp(value, "0") == 0 || std::strcmp(value, "false") == 0);
}

bool envEquals(const char* key, const char* expected) {
  const char* value = std::getenv(key);
  return value != nullptr && std::strcmp(value, expected) == 0;
}

}  // namespace

WaylandShell::WaylandShell(const Config& config) : config_(config) {
  height_ = config_.bar_height + config_.bar_margin * 2;
}

WaylandShell::~WaylandShell() {
  shutdown();
}

bool WaylandShell::init() {
  display_ = wl_display_connect(nullptr);
  if (display_ == nullptr) {
    log::error("failed to connect to Wayland display");
    return false;
  }

  registry_ = wl_display_get_registry(display_);
  wl_registry_add_listener(registry_, &kRegistryListener, this);
  wl_display_roundtrip(display_);

  if (compositor_ == nullptr || layer_shell_ == nullptr) {
    log::error("missing required Wayland globals: wl_compositor or wlr-layer-shell");
    return false;
  }

  createLayerSurface();
  wl_display_roundtrip(display_);
  return true;
}

bool WaylandShell::waitForConfigure() {
  while (!configured_ && !closed_) {
    if (wl_display_dispatch(display_) < 0) {
      log::error("Wayland dispatch failed while waiting for configure");
      return false;
    }
  }
  return configured_ && !closed_;
}

int WaylandShell::fd() const {
  return display_ == nullptr ? -1 : wl_display_get_fd(display_);
}

bool WaylandShell::dispatch() {
  if (display_ == nullptr) {
    return false;
  }
  while (wl_display_prepare_read(display_) != 0) {
    if (wl_display_dispatch_pending(display_) < 0) {
      return false;
    }
  }
  wl_display_flush(display_);
  if (wl_display_read_events(display_) < 0) {
    wl_display_cancel_read(display_);
    return false;
  }
  return wl_display_dispatch_pending(display_) >= 0;
}

void WaylandShell::flush() {
  if (display_ != nullptr) {
    wl_display_flush(display_);
  }
}

void WaylandShell::shutdown() {
  if (egl_window_ != nullptr) {
    wl_egl_window_destroy(egl_window_);
    egl_window_ = nullptr;
  }
  if (layer_surface_ != nullptr) {
    zwlr_layer_surface_v1_destroy(layer_surface_);
    layer_surface_ = nullptr;
  }
  if (surface_ != nullptr) {
    wl_surface_destroy(surface_);
    surface_ = nullptr;
  }
  destroyPointer();
  if (seat_ != nullptr) {
    wl_seat_destroy(seat_);
    seat_ = nullptr;
  }
  if (layer_shell_ != nullptr) {
    zwlr_layer_shell_v1_destroy(layer_shell_);
    layer_shell_ = nullptr;
  }
  if (compositor_ != nullptr) {
    wl_compositor_destroy(compositor_);
    compositor_ = nullptr;
  }
  if (registry_ != nullptr) {
    wl_registry_destroy(registry_);
    registry_ = nullptr;
  }
  if (display_ != nullptr) {
    wl_display_disconnect(display_);
    display_ = nullptr;
  }
}

wl_display* WaylandShell::display() const {
  return display_;
}

wl_egl_window* WaylandShell::eglWindow() const {
  return egl_window_;
}

int WaylandShell::width() const {
  return width_;
}

int WaylandShell::height() const {
  return height_;
}

bool WaylandShell::needsRedraw() const {
  return needs_redraw_;
}

void WaylandShell::clearRedraw() {
  needs_redraw_ = false;
}

bool WaylandShell::closed() const {
  return closed_;
}

void WaylandShell::setClickHandler(ClickHandler handler) {
  click_handler_ = std::move(handler);
}

void WaylandShell::createLayerSurface() {
  surface_ = wl_compositor_create_surface(compositor_);
  const std::uint32_t layer = envEquals("VIBESHELLREZERO_LAYER", "overlay")
                                  ? ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY
                                  : ZWLR_LAYER_SHELL_V1_LAYER_TOP;
  layer_surface_ = zwlr_layer_shell_v1_get_layer_surface(
      layer_shell_, surface_, nullptr, layer, "vibeshellREzero");
  zwlr_layer_surface_v1_add_listener(layer_surface_, &kLayerSurfaceListener, this);

  const int requested_height = std::max(config_.bar_height, config_.surface_height) +
                               config_.bar_margin * 2;
  zwlr_layer_surface_v1_set_size(layer_surface_, 0, static_cast<std::uint32_t>(requested_height));

  std::uint32_t anchor = ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT |
                         ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT;
  if (config_.bar_position == "bottom") {
    anchor |= ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM;
  } else {
    anchor |= ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP;
  }
  zwlr_layer_surface_v1_set_anchor(layer_surface_, anchor);
  zwlr_layer_surface_v1_set_exclusive_zone(
      layer_surface_, envDisabled("VIBESHELLREZERO_EXCLUSIVE_ZONE") ? 0 : config_.exclusive_zone);
  zwlr_layer_surface_v1_set_margin(layer_surface_, 0, 0, 0, 0);
  zwlr_layer_surface_v1_set_keyboard_interactivity(
      layer_surface_, ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_NONE);
  wl_surface_commit(surface_);
}

void WaylandShell::bindPointer() {
  if (seat_ != nullptr && pointer_ == nullptr) {
    pointer_ = wl_seat_get_pointer(seat_);
    wl_pointer_add_listener(pointer_, &kPointerListener, this);
  }
}

void WaylandShell::destroyPointer() {
  if (pointer_ != nullptr) {
    wl_pointer_destroy(pointer_);
    pointer_ = nullptr;
  }
}

void WaylandShell::handleRegistryGlobal(void* data, wl_registry* registry, const std::uint32_t name,
                                        const char* interface, const std::uint32_t version) {
  auto* self = static_cast<WaylandShell*>(data);
  if (std::strcmp(interface, wl_compositor_interface.name) == 0) {
    self->compositor_ = static_cast<wl_compositor*>(
        wl_registry_bind(registry, name, &wl_compositor_interface, std::min(version, 5U)));
  } else if (std::strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
    self->layer_shell_ = static_cast<zwlr_layer_shell_v1*>(wl_registry_bind(
        registry, name, &zwlr_layer_shell_v1_interface, std::min(version, 4U)));
  } else if (std::strcmp(interface, wl_seat_interface.name) == 0) {
    self->seat_ = static_cast<wl_seat*>(
        wl_registry_bind(registry, name, &wl_seat_interface, std::min(version, 7U)));
    wl_seat_add_listener(self->seat_, &kSeatListener, self);
  }
}

void WaylandShell::handleRegistryRemove(void* /*data*/, wl_registry* /*registry*/,
                                        std::uint32_t /*name*/) {}

void WaylandShell::handleLayerConfigure(void* data, zwlr_layer_surface_v1* surface,
                                        const std::uint32_t serial, const std::uint32_t width,
                                        const std::uint32_t height) {
  auto* self = static_cast<WaylandShell*>(data);
  zwlr_layer_surface_v1_ack_configure(surface, serial);
  self->width_ = static_cast<int>(std::max(width, 1U));
  self->height_ = static_cast<int>(std::max(height, 1U));
  if (self->egl_window_ == nullptr) {
    self->egl_window_ = wl_egl_window_create(self->surface_, self->width_, self->height_);
  } else {
    wl_egl_window_resize(self->egl_window_, self->width_, self->height_, 0, 0);
  }
  self->configured_ = true;
  self->needs_redraw_ = true;
  wl_surface_commit(self->surface_);
}

void WaylandShell::handleLayerClosed(void* data, zwlr_layer_surface_v1* /*surface*/) {
  auto* self = static_cast<WaylandShell*>(data);
  self->closed_ = true;
}

void WaylandShell::handleSeatCapabilities(void* data, wl_seat* /*seat*/,
                                          const std::uint32_t capabilities) {
  auto* self = static_cast<WaylandShell*>(data);
  if ((capabilities & WL_SEAT_CAPABILITY_POINTER) != 0U) {
    self->bindPointer();
  } else {
    self->destroyPointer();
  }
}

void WaylandShell::handleSeatName(void* /*data*/, wl_seat* /*seat*/, const char* /*name*/) {}

void WaylandShell::handlePointerEnter(void* data, wl_pointer* /*pointer*/, std::uint32_t /*serial*/,
                                      wl_surface* /*surface*/, const wl_fixed_t surface_x,
                                      const wl_fixed_t surface_y) {
  auto* self = static_cast<WaylandShell*>(data);
  self->pointer_x_ = fixedToInt(surface_x);
  self->pointer_y_ = fixedToInt(surface_y);
}

void WaylandShell::handlePointerLeave(void* data, wl_pointer* /*pointer*/, std::uint32_t /*serial*/,
                                      wl_surface* /*surface*/) {
  auto* self = static_cast<WaylandShell*>(data);
  self->pointer_x_ = -1;
  self->pointer_y_ = -1;
}

void WaylandShell::handlePointerMotion(void* data, wl_pointer* /*pointer*/, std::uint32_t /*time*/,
                                       const wl_fixed_t surface_x, const wl_fixed_t surface_y) {
  auto* self = static_cast<WaylandShell*>(data);
  self->pointer_x_ = fixedToInt(surface_x);
  self->pointer_y_ = fixedToInt(surface_y);
}

void WaylandShell::handlePointerButton(void* data, wl_pointer* /*pointer*/, std::uint32_t /*serial*/,
                                       std::uint32_t /*time*/, std::uint32_t /*button*/,
                                       const std::uint32_t state) {
  auto* self = static_cast<WaylandShell*>(data);
  if (state == kPointerButtonPressed && self->click_handler_ && self->pointer_x_ >= 0 &&
      self->pointer_y_ >= 0) {
    self->click_handler_(self->pointer_x_, self->pointer_y_);
  }
}

void WaylandShell::handlePointerAxis(void* /*data*/, wl_pointer* /*pointer*/,
                                     std::uint32_t /*time*/, std::uint32_t /*axis*/,
                                     wl_fixed_t /*value*/) {}

void WaylandShell::handlePointerFrame(void* /*data*/, wl_pointer* /*pointer*/) {}

void WaylandShell::handlePointerAxisSource(void* /*data*/, wl_pointer* /*pointer*/,
                                           std::uint32_t /*axis_source*/) {}

void WaylandShell::handlePointerAxisStop(void* /*data*/, wl_pointer* /*pointer*/,
                                         std::uint32_t /*time*/, std::uint32_t /*axis*/) {}

void WaylandShell::handlePointerAxisDiscrete(void* /*data*/, wl_pointer* /*pointer*/,
                                             std::uint32_t /*axis*/,
                                             std::int32_t /*discrete*/) {}

void WaylandShell::handlePointerAxisValue120(void* /*data*/, wl_pointer* /*pointer*/,
                                             std::uint32_t /*axis*/,
                                             std::int32_t /*value120*/) {}

void WaylandShell::handlePointerAxisRelativeDirection(void* /*data*/, wl_pointer* /*pointer*/,
                                                      std::uint32_t /*axis*/,
                                                      std::uint32_t /*direction*/) {}

}  // namespace vibeshell
