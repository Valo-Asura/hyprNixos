# Fonts Configuration
{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      google-fonts
      material-symbols
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "FiraCode Nerd Font Mono" ];
        sansSerif = [ "JetBrainsMono Nerd Font" ];
        serif = [ "Hack Nerd Font" ];
      };
    };
  };
}
