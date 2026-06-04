#include "renderer/renderer.hpp"

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <cairo/cairo.h>
#include <pango/pangocairo.h>
#include <wayland-client.h>
#include <wayland-egl.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>

#include "utils/log.hpp"

namespace vibeshell {
namespace {

constexpr auto* kVertexShader = R"glsl(
attribute vec2 a_position;
attribute vec2 a_uv;
varying vec2 v_uv;
void main() {
  v_uv = a_uv;
  gl_Position = vec4(a_position, 0.0, 1.0);
}
)glsl";

constexpr auto* kFragmentShader = R"glsl(
precision mediump float;
varying vec2 v_uv;
uniform sampler2D u_texture;
void main() {
  gl_FragColor = texture2D(u_texture, v_uv);
}
)glsl";

EGLDisplay toEglDisplay(void* value) {
  return reinterpret_cast<EGLDisplay>(value);
}

EGLSurface toEglSurface(void* value) {
  return reinterpret_cast<EGLSurface>(value);
}

EGLContext toEglContext(void* value) {
  return reinterpret_cast<EGLContext>(value);
}

void setColor(cairo_t* cr, const Color& color, const double alpha_scale = 1.0) {
  cairo_set_source_rgba(cr, color.r, color.g, color.b,
                        std::clamp(static_cast<double>(color.a) * alpha_scale, 0.0, 1.0));
}

void roundedRect(cairo_t* cr, const double x, const double y, const double width,
                 const double height, const double radius) {
  const double r = std::min({radius, width / 2.0, height / 2.0});
  cairo_new_sub_path(cr);
  cairo_arc(cr, x + width - r, y + r, r, -M_PI / 2.0, 0.0);
  cairo_arc(cr, x + width - r, y + height - r, r, 0.0, M_PI / 2.0);
  cairo_arc(cr, x + r, y + height - r, r, M_PI / 2.0, M_PI);
  cairo_arc(cr, x + r, y + r, r, M_PI, 3.0 * M_PI / 2.0);
  cairo_close_path(cr);
}

void fillRounded(cairo_t* cr, const double x, const double y, const double width,
                 const double height, const double radius, const Color& color,
                 const double alpha_scale = 1.0) {
  roundedRect(cr, x, y, width, height, radius);
  setColor(cr, color, alpha_scale);
  cairo_fill(cr);
}

void strokeRounded(cairo_t* cr, const double x, const double y, const double width,
                   const double height, const double radius, const Color& color,
                   const double alpha_scale = 1.0) {
  roundedRect(cr, x + 0.5, y + 0.5, width - 1.0, height - 1.0, radius);
  setColor(cr, color, alpha_scale);
  cairo_set_line_width(cr, 1.0);
  cairo_stroke(cr);
}

PangoFontDescription* fontDescription(const Config& config, const int delta = 0,
                                      const bool bold = false) {
  auto* desc = pango_font_description_new();
  pango_font_description_set_family(desc, config.font_family.c_str());
  pango_font_description_set_size(desc, (config.font_size + delta) * PANGO_SCALE);
  if (bold) {
    pango_font_description_set_weight(desc, PANGO_WEIGHT_SEMIBOLD);
  }
  return desc;
}

int measureText(cairo_t* cr, const Config& config, const std::string& text, const int delta = 0,
                const bool bold = false) {
  auto* layout = pango_cairo_create_layout(cr);
  auto* desc = fontDescription(config, delta, bold);
  pango_layout_set_font_description(layout, desc);
  pango_layout_set_text(layout, text.c_str(), -1);
  int width = 0;
  int height = 0;
  pango_layout_get_pixel_size(layout, &width, &height);
  pango_font_description_free(desc);
  g_object_unref(layout);
  return width;
}

void drawText(cairo_t* cr, const Config& config, const std::string& text, const double x,
              const double y, const Color& color, const int delta = 0, const bool bold = false,
              const double alpha_scale = 1.0) {
  auto* layout = pango_cairo_create_layout(cr);
  auto* desc = fontDescription(config, delta, bold);
  pango_layout_set_font_description(layout, desc);
  pango_layout_set_text(layout, text.c_str(), -1);
  setColor(cr, color, alpha_scale);
  cairo_move_to(cr, x, y);
  pango_cairo_show_layout(cr, layout);
  pango_font_description_free(desc);
  g_object_unref(layout);
}

GLuint compileShader(const GLenum type, const char* source) {
  const GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);

  GLint ok = GL_FALSE;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (ok != GL_TRUE) {
    char log_buffer[1024]{};
    glGetShaderInfoLog(shader, sizeof(log_buffer), nullptr, log_buffer);
    log::error(std::string{"shader compile failed: "} + log_buffer);
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

std::vector<std::uint8_t> cairoToRgba(cairo_surface_t* surface, const int width,
                                      const int height) {
  cairo_surface_flush(surface);
  const auto* source = cairo_image_surface_get_data(surface);
  const int stride = cairo_image_surface_get_stride(surface);

  std::vector<std::uint8_t> rgba(static_cast<size_t>(width) * static_cast<size_t>(height) * 4U);
  for (int y = 0; y < height; ++y) {
    const auto* row = source + static_cast<ptrdiff_t>(y) * stride;
    for (int x = 0; x < width; ++x) {
      std::uint32_t pixel = 0;
      std::memcpy(&pixel, row + static_cast<ptrdiff_t>(x) * 4, sizeof(pixel));
      const auto a = static_cast<std::uint8_t>((pixel >> 24U) & 0xffU);
      const auto r = static_cast<std::uint8_t>((pixel >> 16U) & 0xffU);
      const auto g = static_cast<std::uint8_t>((pixel >> 8U) & 0xffU);
      const auto b = static_cast<std::uint8_t>(pixel & 0xffU);

      const size_t target = (static_cast<size_t>(y) * static_cast<size_t>(width) +
                             static_cast<size_t>(x)) *
                            4U;
      rgba[target + 0U] = r;
      rgba[target + 1U] = g;
      rgba[target + 2U] = b;
      rgba[target + 3U] = a;
    }
  }
  return rgba;
}

void drawWave(cairo_t* cr, const Config& config, const double x, const double y,
              const double width, const double height) {
  setColor(cr, config.accent, 0.65);
  cairo_set_line_width(cr, 1.4);
  const int bars = 42;
  for (int i = 0; i < bars; ++i) {
    const double t = static_cast<double>(i) / static_cast<double>(bars - 1);
    const double amp = (std::sin(t * M_PI * 8.0) * 0.5 + 0.5) * height * 0.42 + 2.0;
    const double px = x + t * width;
    cairo_move_to(cr, px, y + height / 2.0 - amp / 2.0);
    cairo_line_to(cr, px, y + height / 2.0 + amp / 2.0);
  }
  cairo_stroke(cr);
}

void drawButton(cairo_t* cr, const Config& config, const double x, const double y,
                const double size, const std::string& label, const bool active = false) {
  fillRounded(cr, x, y, size, size, size / 2.0, active ? config.accent : config.background,
              active ? 1.0 : 0.95);
  strokeRounded(cr, x, y, size, size, size / 2.0, config.border, active ? 0.65 : 0.45);
  const int text_width = measureText(cr, config, label, -4, true);
  drawText(cr, config, label, x + (size - static_cast<double>(text_width)) / 2.0, y + 8.0,
           active ? config.background : config.text, -4, true);
}

std::string shorten(std::string value, const size_t max_size) {
  if (value.size() <= max_size) {
    return value;
  }
  value.resize(max_size > 3 ? max_size - 3 : max_size);
  value += "...";
  return value;
}

bool inRect(const int x, const int y, const double rx, const double ry, const double rw,
            const double rh) {
  return static_cast<double>(x) >= rx && static_cast<double>(x) <= rx + rw &&
         static_cast<double>(y) >= ry && static_cast<double>(y) <= ry + rh;
}

void drawWorkspaceStrip(cairo_t* cr, const Config& config, const ShellState& state,
                        const double x, const double y, const double height) {
  const double width = 16.0 + static_cast<double>(config.workspace_count) * 22.0;
  fillRounded(cr, x, y, width, height, height / 2.0, config.background, 0.96);
  strokeRounded(cr, x, y, width, height, height / 2.0, config.border, 0.50);

  double ws_x = x + 9.0;
  for (const auto& ws : state.workspaces) {
    const double slot = 22.0;
    const double dot = ws.active ? 18.0 : 8.0;
    const double dot_x = ws_x + (slot - dot) / 2.0;
    const double dot_y = y + (height - dot) / 2.0;
    fillRounded(cr, dot_x, dot_y, dot, dot, dot / 2.0,
                ws.active ? config.accent : config.muted,
                ws.active ? 1.0 : (ws.occupied ? 0.75 : 0.48));
    if (ws.active) {
      const auto label = std::to_string(ws.id);
      drawText(cr, config, label, dot_x + 5.0, dot_y + 1.0, config.background, -4, true);
    }
    ws_x += slot;
  }
}

void drawOverlay(cairo_t* cr, const Config& config, const ShellState& state, const int width) {
  if (state.overlay_mode.empty()) {
    return;
  }

  const double panel_w = std::min(520.0, static_cast<double>(width) - 80.0);
  const double panel_h = 144.0;
  const double x = (static_cast<double>(width) - panel_w) / 2.0;
  const double y = 92.0;

  fillRounded(cr, x + 2.0, y + 4.0, panel_w, panel_h, 26.0,
              Color{0.0F, 0.0F, 0.0F, 1.0F}, 0.32);
  fillRounded(cr, x, y, panel_w, panel_h, 26.0, config.background, 0.96);
  strokeRounded(cr, x, y, panel_w, panel_h, 26.0, config.border, 0.70);

  std::string title = "VibeShell " + state.overlay_mode;
  if (state.overlay_mode == "dashboard-widgets") {
    title = "Dashboard";
  } else if (state.overlay_mode == "dashboard-clipboard") {
    title = "Clipboard";
  } else if (state.overlay_mode == "dashboard-assistant") {
    title = "Assistant";
  } else if (state.overlay_mode == "powermenu") {
    title = "Power Menu";
  } else if (state.overlay_mode == "launcher") {
    title = "Launcher";
  }

  drawText(cr, config, title, x + 22.0, y + 16.0, config.text, 2, true);
  drawText(cr, config, "Native placeholder: module command is wired; full panel parity is staged.",
           x + 22.0, y + 48.0, config.muted, -2, false);

  const std::string status = state.statusLine();
  fillRounded(cr, x + 18.0, y + 88.0, panel_w - 36.0, 34.0, 17.0, config.surface, 0.85);
  drawText(cr, config, shorten(status, 78), x + 34.0, y + 96.0, config.text, -3, false);
}

void paintPanel(cairo_t* cr, const Config& config, const ShellState& state, const int width,
                const int height) {
  (void)height;
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

  const double screen_w = static_cast<double>(width);
  const double top_h = 34.0;
  const double row_y = 40.0;
  const double row_h = 36.0;

  const double top_left_x = std::max(160.0, screen_w * 0.095);
  const double top_left_w = std::min(640.0, screen_w * 0.42);
  fillRounded(cr, top_left_x, 0.0, top_left_w, top_h, 17.0, config.background, 0.96);
  strokeRounded(cr, top_left_x, 0.0, top_left_w, top_h, 17.0, config.border, 0.32);
  drawText(cr, config, "search", top_left_x + 22.0, 8.0, config.muted, -4, true);
  fillRounded(cr, top_left_x + 64.0, 7.0, 38.0, 20.0, 10.0, config.accent, 0.98);
  drawText(cr, config, std::to_string(state.active_workspace), top_left_x + 80.0, 8.0,
           config.background, -4, true);
  drawText(cr, config, shorten(state.active_title, 46), top_left_x + 124.0, 8.0, config.text, -2,
           true);

  const double notch_w = std::min(330.0, screen_w * 0.22);
  const double notch_x = (screen_w - notch_w) / 2.0;
  fillRounded(cr, notch_x, 2.0, notch_w, 32.0, 16.0, config.background, 0.98);
  strokeRounded(cr, notch_x, 2.0, notch_w, 32.0, 16.0, config.border, 0.42);
  drawText(cr, config, shorten(state.active_title, 30), notch_x + 38.0, 8.5, config.text, -3,
           true);
  drawButton(cr, config, notch_x + 8.0, 5.0, 24.0, "V", true);
  drawWave(cr, config, notch_x + notch_w - 98.0, 9.0, 70.0, 16.0);

  const double top_right_w = std::min(650.0, screen_w * 0.35);
  const double top_right_x = screen_w - top_right_w - 6.0;
  fillRounded(cr, top_right_x, 0.0, top_right_w, top_h, 17.0, config.background, 0.96);
  strokeRounded(cr, top_right_x, 0.0, top_right_w, top_h, 17.0, config.border, 0.30);
  std::string top_status = "mix  bell  clip  wifi";
  if (!state.indicators.volume.empty()) {
    top_status += "  vol " + state.indicators.volume;
  }
  if (state.indicators.battery_percent >= 0) {
    top_status += "  bat " + std::to_string(state.indicators.battery_percent) + "%";
  }
  drawText(cr, config, top_status, top_right_x + 22.0, 8.5, config.text, -3, true);
  drawText(cr, config, state.clock_text, top_right_x + top_right_w - 78.0, 8.5, config.text, -2,
           true);

  drawButton(cr, config, 5.0, row_y, row_h, "A", true);
  drawButton(cr, config, 45.0, row_y, row_h, "VS");
  drawWorkspaceStrip(cr, config, state, 84.0, row_y, row_h);
  const double after_ws = 84.0 + 16.0 + static_cast<double>(config.workspace_count) * 22.0 + 8.0;
  drawButton(cr, config, after_ws, row_y, row_h, "L");
  drawButton(cr, config, after_ws + 40.0, row_y, row_h, "P", true);

  const double right_buttons = 9.0 * 40.0 + 92.0;
  double bx = std::max(after_ws + 88.0, screen_w - right_buttons - 6.0);
  const std::string labels[] = {"PR", "T", "N", "ST", "CTL"};
  for (const auto& label : labels) {
    drawButton(cr, config, bx, row_y, row_h, label);
    bx += 40.0;
  }

  fillRounded(cr, bx, row_y, 112.0, row_h, row_h / 2.0, config.background, 0.96);
  strokeRounded(cr, bx, row_y, 112.0, row_h, row_h / 2.0, config.border, 0.42);
  drawText(cr, config, state.indicators.network_up ? "net up" : "net down", bx + 16.0,
           row_y + 9.0, config.text, -4, true);
  bx += 120.0;
  fillRounded(cr, bx, row_y, 78.0, row_h, row_h / 2.0, config.background, 0.96);
  strokeRounded(cr, bx, row_y, 78.0, row_h, row_h / 2.0, config.border, 0.42);
  drawText(cr, config, state.clock_text, bx + 18.0, row_y + 8.0, config.text, -1, true);
  bx += 86.0;
  drawButton(cr, config, bx, row_y, row_h, "S");
  drawButton(cr, config, bx + 40.0, row_y, row_h, "Q");

  if (!state.overlay_mode.empty()) {
    drawOverlay(cr, config, state, width);
  }
}

}  // namespace

Renderer::~Renderer() {
  shutdown();
}

bool Renderer::init(wl_display* display, wl_egl_window* window) {
  if (display == nullptr || window == nullptr) {
    log::error("renderer init missing Wayland display/window");
    return false;
  }

  EGLDisplay egl_display = eglGetDisplay(reinterpret_cast<EGLNativeDisplayType>(display));
  if (egl_display == EGL_NO_DISPLAY) {
    log::error("eglGetDisplay failed");
    return false;
  }
  EGLint major = 0;
  EGLint minor = 0;
  if (eglInitialize(egl_display, &major, &minor) != EGL_TRUE) {
    log::error("eglInitialize failed");
    return false;
  }
  eglBindAPI(EGL_OPENGL_ES_API);

  const EGLint config_attribs[] = {
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8,
      EGL_DEPTH_SIZE, 0, EGL_STENCIL_SIZE, 0, EGL_NONE,
  };
  EGLConfig egl_config{};
  EGLint count = 0;
  if (eglChooseConfig(egl_display, config_attribs, &egl_config, 1, &count) != EGL_TRUE ||
      count == 0) {
    log::error("eglChooseConfig failed");
    eglTerminate(egl_display);
    return false;
  }

  const EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  EGLContext egl_context =
      eglCreateContext(egl_display, egl_config, EGL_NO_CONTEXT, context_attribs);
  if (egl_context == EGL_NO_CONTEXT) {
    log::error("eglCreateContext failed");
    eglTerminate(egl_display);
    return false;
  }

  EGLSurface egl_surface =
      eglCreateWindowSurface(egl_display, egl_config, reinterpret_cast<EGLNativeWindowType>(window),
                             nullptr);
  if (egl_surface == EGL_NO_SURFACE) {
    log::error("eglCreateWindowSurface failed");
    eglDestroyContext(egl_display, egl_context);
    eglTerminate(egl_display);
    return false;
  }

  if (eglMakeCurrent(egl_display, egl_surface, egl_surface, egl_context) != EGL_TRUE) {
    log::error("eglMakeCurrent failed");
    eglDestroySurface(egl_display, egl_surface);
    eglDestroyContext(egl_display, egl_context);
    eglTerminate(egl_display);
    return false;
  }

  egl_display_ = egl_display;
  egl_surface_ = egl_surface;
  egl_context_ = egl_context;

  if (!compileProgram()) {
    shutdown();
    return false;
  }
  glGenTextures(1, &texture_);
  glBindTexture(GL_TEXTURE_2D, texture_);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

  log::info("renderer initialized with EGL/OpenGL ES");
  return true;
}

void Renderer::resize(const int width, const int height) {
  width_ = width;
  height_ = height;
  glViewport(0, 0, width_, height_);
}

bool Renderer::compileProgram() {
  const GLuint vertex = compileShader(GL_VERTEX_SHADER, kVertexShader);
  const GLuint fragment = compileShader(GL_FRAGMENT_SHADER, kFragmentShader);
  if (vertex == 0 || fragment == 0) {
    return false;
  }

  program_ = glCreateProgram();
  glAttachShader(program_, vertex);
  glAttachShader(program_, fragment);
  glBindAttribLocation(program_, 0, "a_position");
  glBindAttribLocation(program_, 1, "a_uv");
  glLinkProgram(program_);
  glDeleteShader(vertex);
  glDeleteShader(fragment);

  GLint ok = GL_FALSE;
  glGetProgramiv(program_, GL_LINK_STATUS, &ok);
  if (ok != GL_TRUE) {
    char log_buffer[1024]{};
    glGetProgramInfoLog(program_, sizeof(log_buffer), nullptr, log_buffer);
    log::error(std::string{"shader link failed: "} + log_buffer);
    glDeleteProgram(program_);
    program_ = 0;
    return false;
  }
  return true;
}

bool Renderer::uploadTexture(const std::vector<std::uint8_t>& pixels, const int width,
                             const int height) {
  glBindTexture(GL_TEXTURE_2D, texture_);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               pixels.data());
  return glGetError() == GL_NO_ERROR;
}

bool Renderer::render(const Config& config, const ShellState& state, const int width,
                      const int height) {
  if (egl_display_ == nullptr || egl_surface_ == nullptr || egl_context_ == nullptr) {
    return false;
  }
  if (width <= 0 || height <= 0) {
    return false;
  }
  resize(width, height);

  cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  if (cairo_surface_status(surface) != CAIRO_STATUS_SUCCESS) {
    cairo_surface_destroy(surface);
    return false;
  }
  cairo_t* cr = cairo_create(surface);
  paintPanel(cr, config, state, width, height);
  cairo_destroy(cr);

  const auto pixels = cairoToRgba(surface, width, height);
  cairo_surface_destroy(surface);

  if (!uploadTexture(pixels, width, height)) {
    log::error("texture upload failed");
    return false;
  }

  glViewport(0, 0, width, height);
  glClearColor(0.0F, 0.0F, 0.0F, 0.0F);
  glClear(GL_COLOR_BUFFER_BIT);
  glUseProgram(program_);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture_);
  glUniform1i(glGetUniformLocation(program_, "u_texture"), 0);

  const GLfloat vertices[] = {
      -1.0F, -1.0F, 0.0F, 1.0F, 1.0F,  -1.0F, 1.0F, 1.0F,
      -1.0F, 1.0F,  0.0F, 0.0F, 1.0F,  1.0F,  1.0F, 0.0F,
  };
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * static_cast<GLsizei>(sizeof(GLfloat)),
                        vertices);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * static_cast<GLsizei>(sizeof(GLfloat)),
                        vertices + 2);
  glEnableVertexAttribArray(1);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);

  return eglSwapBuffers(toEglDisplay(egl_display_), toEglSurface(egl_surface_)) == EGL_TRUE;
}

int Renderer::workspaceAt(const Config& config, const int x, const int y) const {
  const int bar_y = 40;
  const int bar_h = 36;
  const int left_x = 84;
  const int slot_start = left_x + 9;
  const int workspace_w = 16 + config.workspace_count * 22;
  if (y < bar_y || y > bar_y + bar_h || x < left_x || x > left_x + workspace_w) {
    return -1;
  }
  const int index = (x - slot_start) / 22;
  if (index < 0 || index >= config.workspace_count) {
    return -1;
  }
  return index + 1;
}

std::string Renderer::actionAt(const Config& config, const int width, const int x,
                               const int y) const {
  const double screen_w = static_cast<double>(width);
  const double row_y = 40.0;
  const double row_h = 36.0;

  if (inRect(x, y, 5.0, row_y, row_h, row_h)) {
    return "launcher";
  }
  if (inRect(x, y, 45.0, row_y, row_h, row_h)) {
    return "dashboard-widgets";
  }

  const double after_ws = 84.0 + 16.0 + static_cast<double>(config.workspace_count) * 22.0 + 8.0;
  if (inRect(x, y, after_ws, row_y, row_h, row_h)) {
    return "overview";
  }
  if (inRect(x, y, after_ws + 40.0, row_y, row_h, row_h)) {
    return "pin";
  }

  const double right_buttons = 9.0 * 40.0 + 92.0;
  double bx = std::max(after_ws + 88.0, screen_w - right_buttons - 6.0);
  const std::string actions[] = {"presets", "tools", "dashboard-notes", "dashboard-widgets",
                                 "dashboard-controls"};
  for (const auto& action : actions) {
    if (inRect(x, y, bx, row_y, row_h, row_h)) {
      return action;
    }
    bx += 40.0;
  }

  if (inRect(x, y, bx, row_y, 112.0, row_h)) {
    return "dashboard-controls";
  }
  bx += 120.0;
  if (inRect(x, y, bx, row_y, 78.0, row_h)) {
    return "dashboard-widgets";
  }
  bx += 86.0;
  if (inRect(x, y, bx, row_y, row_h, row_h)) {
    return "config";
  }
  if (inRect(x, y, bx + 40.0, row_y, row_h, row_h)) {
    return "powermenu";
  }

  const double top_left_x = std::max(160.0, screen_w * 0.095);
  const double top_left_w = std::min(640.0, screen_w * 0.42);
  if (inRect(x, y, top_left_x, 0.0, top_left_w, 34.0)) {
    return "launcher";
  }

  const double notch_w = std::min(330.0, screen_w * 0.22);
  const double notch_x = (screen_w - notch_w) / 2.0;
  if (inRect(x, y, notch_x, 2.0, notch_w, 32.0)) {
    return "dashboard-widgets";
  }

  return {};
}

void Renderer::shutdown() {
  const EGLDisplay egl_display = toEglDisplay(egl_display_);
  if (egl_display_ != nullptr) {
    eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  }
  if (texture_ != 0) {
    glDeleteTextures(1, &texture_);
    texture_ = 0;
  }
  if (program_ != 0) {
    glDeleteProgram(program_);
    program_ = 0;
  }
  if (egl_surface_ != nullptr) {
    eglDestroySurface(egl_display, toEglSurface(egl_surface_));
    egl_surface_ = nullptr;
  }
  if (egl_context_ != nullptr) {
    eglDestroyContext(egl_display, toEglContext(egl_context_));
    egl_context_ = nullptr;
  }
  if (egl_display_ != nullptr) {
    eglTerminate(egl_display);
    egl_display_ = nullptr;
  }
}

}  // namespace vibeshell
