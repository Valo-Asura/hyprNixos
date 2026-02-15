# Performance Tuning (comprehensive)
{ lib, ... }:

{
  # IRQ balancing across CPU cores
  services.irqbalance.enable = true;

  # SSD TRIM for ext4 / NVMe health
  services.fstrim.enable = true;

  # ── zram (compressed RAM swap) ──────────────────────────────────
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;  # use up to 50% of RAM as compressed swap
  };

  # ── Kernel sysctl tuning ────────────────────────────────────────
  boot.kernel.sysctl = {
    # VM / memory
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
    "vm.max_map_count" = 1048576;           # helps games / large apps

    # File descriptors & inotify (VS Code, IDE watchers)
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_queued_events" = 32768;

    # Network performance
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;
    "net.core.optmem_max" = 65536;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_wmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_fastopen" = 3;            # client + server
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Security-safe network hardening
    "net.ipv4.tcp_syncookies" = 1;
  };

  # BBR congestion control (needs tcp_bbr module)
  boot.kernelModules = [ "tcp_bbr" ];

  # I/O scheduler: mq-deadline for NVMe (lower latency than default none)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/scheduler}="bfq"
  '';

  # Raise open file limits for the user
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "soft"; value = "524288"; }
    { domain = "*"; item = "nofile"; type = "hard"; value = "524288"; }
  ];
}
