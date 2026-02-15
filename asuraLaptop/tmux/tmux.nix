{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    terminal = "screen-256color";
    extraConfig = ''
      # Disable the default welcome message
      set -g quiet on

      # Set prefix to Ctrl+a
      unbind C-b
      set-option -g prefix C-a
      bind-key C-a send-prefix

      # Split panes with | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Status bar candy
      set -g status-bg colour234
      set -g status-fg white
      set -g status-interval 2
      set -g status-left-length 40
      set -g status-left "#[fg=green]#H"
      set -g status-right "#[fg=yellow]%Y-%m-%d #[fg=cyan]%H:%M:%S"

      # Window title colors
      setw -g window-status-current-format "#[fg=black,bg=green] #I:#W "
      setw -g window-status-format "#[fg=white,bg=colour235] #I:#W "

      # Pane borders
      set -g pane-border-style fg=colour240
      set -g pane-active-border-style fg=colour39

      # Truecolor support
      set -g default-terminal "screen-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
    '';
  };
}
