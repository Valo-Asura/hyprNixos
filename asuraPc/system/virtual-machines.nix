# Local virtual machine host for testing other operating systems.
{ pkgs, ... }:

let
  vmEnvInfo = pkgs.writeShellScriptBin "vm-env-info" ''
    cat <<'EOF'
    Virtual machine testing
      GUI:        virt-manager
      Viewer:     virt-viewer
      Hypervisor: qemu:///system
      Images:     /var/lib/libvirt/images

    First use
      1. Rebuild and reboot once so KVM/libvirt groups are active.
      2. Open virt-manager.
      3. Connect to qemu:///system.
      4. Create a VM from an ISO.

    Useful checks
      groups
      systemctl status libvirtd
      virsh -c qemu:///system list --all
    EOF
  '';
in
{
  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
    qemu_kvm
    virt-manager
    virt-viewer
    spice-gtk
    spice-vdagent
    swtpm
    vmEnvInfo
  ];
}
