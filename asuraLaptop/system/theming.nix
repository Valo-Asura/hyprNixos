# Minimal Stylix Theming - Gruvbox Dark
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "dark";

    # Gruvbox Dark theme for that warm, cozy dark aesthetic
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    # Solid Gruvbox background (minimal and clean)
    image = pkgs.runCommand "gruvbox-wallpaper" {} ''
      mkdir -p $out
      ${pkgs.imagemagick}/bin/convert -size 1920x1080 xc:"#1d2021" $out/wallpaper.png
    '';

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 18;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.inter;
        name = "Inter";
      };
      sizes = {
        applications = 11;
        terminal = 13;
        desktop = 11;
        popups = 11;
      };
    };

    # Minimal targeting - only what we need
    targets = {
      gtk.enable = true;
    };
  };

  # AGS overlay for additional functionality
  nixpkgs.overlays = [
    (final: prev: {
      ags = prev.ags.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ pkgs.libdbusmenu-gtk3 pkgs.ddcutil ];
      });
    })
    (final: prev: {
      pnpm_10 = prev.pnpm_10.overrideAttrs (old: {
        passthru = (old.passthru or {}) // {
          fetchDeps = args: final.fetchPnpmDeps (args // { pnpm = prev.pnpm_10; });
        };
      });
    })
  ];
}
