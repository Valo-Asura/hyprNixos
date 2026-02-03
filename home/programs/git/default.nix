# Git configuration
{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Valo-Asura";
      user.email = "vimalranghar016@gmail.com";
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos/";
    };
  };
}