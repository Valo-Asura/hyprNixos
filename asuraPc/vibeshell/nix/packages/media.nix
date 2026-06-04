# Media packages: video, audio, players
{ pkgs }:

with pkgs;
[
  gpu-screen-recorder

  ffmpeg
  x264
  playerctl

  # Audio
  pipewire
  wireplumber
  mpvpaper
]
