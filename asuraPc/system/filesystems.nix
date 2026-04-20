# Filesystem Support Configuration
{ pkgs, ... }:

{
  # Enable NTFS support for Windows drives
  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
    "vfat"
  ];

  # Mount Windows ESP so systemd-boot can discover the Windows Boot Manager entry.
  # nvme0n1p1 is the Windows EFI partition (GPT UUID 80db9e1e-b7fd-4e42-84c7-f1b5fd475279).
  fileSystems."/boot/efi-windows" = {
    device = "/dev/disk/by-partuuid/80db9e1e-b7fd-4e42-84c7-f1b5fd475279";
    fsType = "vfat";
    options = [
      "ro"
      "fmask=0077"
      "dmask=0077"
      "nofail"
      "x-systemd.automount"
    ];
  };

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
