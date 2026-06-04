project(
  'vibeshellREzero',
  ['c', 'cpp'],
  version: '0.1.0',
  default_options: [
    'cpp_std=c++20',
    'cpp_extensions=false',
    'warning_level=3',
    'werror=false',
  ],
)

cpp = meson.get_compiler('cpp')

deps = [
  dependency('wayland-client'),
  dependency('wayland-egl'),
  dependency('egl'),
  dependency('glesv2'),
  dependency('cairo'),
  dependency('pangocairo'),
  dependency('fontconfig'),
  dependency('xkbcommon'),
]

wayland_scanner = find_program('wayland-scanner')
layer_shell_xml = files('protocols/wlr-layer-shell-unstable-v1.xml')

layer_shell_header = custom_target(
  'wlr-layer-shell-client-header',
  input: layer_shell_xml,
  output: 'wlr-layer-shell-unstable-v1-client-protocol.h',
  command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],
)

layer_shell_code = custom_target(
  'wlr-layer-shell-private-code',
  input: layer_shell_xml,
  output: 'wlr-layer-shell-unstable-v1-protocol.c',
  command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],
)

sources = [
  layer_shell_header,
  layer_shell_code,
  'src/main.cpp',
  'src/app/application.cpp',
  'src/ipc/ipc_server.cpp',
  'src/renderer/renderer.cpp',
  'src/state/config.cpp',
  'src/state/hyprland_ipc.cpp',
  'src/state/shell_state.cpp',
  'src/wayland/xdg_popup_stub.c',
  'src/wayland/wayland_shell.cpp',
]

inc = include_directories('include', 'src')

executable(
  'vibeshellREzero',
  sources,
  include_directories: inc,
  dependencies: deps,
  cpp_args: [
    '-Wall',
    '-Wextra',
    '-Wpedantic',
    '-Wconversion',
    '-Wshadow',
    '-Wno-missing-field-initializers',
  ],
  install: true,
)
