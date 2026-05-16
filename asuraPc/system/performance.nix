# Performance Tuning (low-level)
{ ... }:

{
  # IRQ balancing across CPU cores
  services.irqbalance.enable = true;

  # ── OOM killer: earlyoom ──────────────────────────────────────────
  # Kills the highest-memory process when RAM gets critically low,
  # BEFORE the kernel OOM killer fires. This prevents the multi-second
  # desktop freeze that occurs when the kernel OOM killer stalls I/O.
  # Trigger at <10% free RAM / <10% free swap.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 10;
    # Keep extraArgs empty here. The current module serializes regex-style
    # options through EARLYOOM_ARGS in a way earlyoom receives as one bad arg.
    enableNotifications = true;
  };

  # User-space sched-ext scheduler for smoother interactive desktop load on 6.12+ kernels.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # Let games and heavy interactive apps request temporary CPU/GPU priority boosts.
  programs.gamemode.enable = true;

  # SSD TRIM for ext4 / NVMe health
  services.fstrim.enable = true;

  # ── zram (compressed RAM swap) ──────────────────────────────────
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # 25% of 16GB = 4GB compressed swap (was 50% — too aggressive)
  };

  # ── Kernel sysctl tuning ────────────────────────────────────────
  boot.kernel.sysctl = {
    # VM / memory
    "vm.swappiness" = 5; # prefer RAM over zram swap
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
    "vm.page-cluster" = 0; # no readahead for zram (compressed, no seek)
    "vm.max_map_count" = 1048576; # helps games / large apps
    "vm.mglru_min_ttl_ms" = 1000; # keep recently touched desktop pages resident a bit longer

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
    "net.ipv4.tcp_fastopen" = 3; # client + server
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Security-safe network hardening
    "net.ipv4.tcp_syncookies" = 1;
  };

  # BBR congestion control (needs tcp_bbr module)
  boot.kernelModules = [ "tcp_bbr" ];

  # Explicit block scheduler policy keeps interactive I/O predictable.
  hardware.block.scheduler = {
    "nvme[0-9]*" = "kyber";
    "sd[a-z]" = "bfq";
    "mmcblk[0-9]*" = "bfq";
  };

  # Raise open file limits for the user
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "*";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];
}
