# Filesystem Support Configuration
{ pkgs, ... }:

{
  # Enable NTFS support for Windows drives
  boot.supportedFilesystems = [ "ntfs" "exfat" "vfat" ];
  
  # Enable FUSE for user-space filesystems
  programs.fuse.userAllowOther = true;
  
  # Polkit rules for mounting without password
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
            action.id == "org.freedesktop.udisks2.filesystem-mount" ||
            action.id == "org.freedesktop.udisks2.filesystem-unmount" ||
            action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
            action.id == "org.freedesktop.udisks2.encrypted-lock" ||
            action.id == "org.freedesktop.udisks2.eject-media") {
            if (subject.isInGroup("wheel") || subject.isInGroup("storage")) {
                return polkit.Result.YES;
            }
        }
    });
  '';
  
  # Environment variables for proper mounting
  environment.variables = {
    UDISKS2_MOUNT_OPTIONS = "uid=1000,gid=983,dmask=022,fmask=133";
  };
}