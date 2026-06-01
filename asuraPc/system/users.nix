# User Configuration
{ pkgs, ... }:

{
  users = {
    users.asura = {
      isNormalUser = true;
      description = "asura";
      group = "asura";
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "wheel"
        "storage"
        "audio"
        "video"
        "input"
        "power"
        "ydotool"
        "docker"
        "adbusers"
        "libvirtd"
        "kvm"
      ];
    };
    groups.asura = { };
    groups.adbusers = { };
  };
}
