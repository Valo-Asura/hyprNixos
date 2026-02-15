#!/usr/bin/env python3
import time
import sys
import os
import json
import subprocess
import re


class SystemMonitor:
    def __init__(self):
        self.prev_cpu_total = 0
        self.prev_cpu_idle = 0
        self.disks = []
        self.gpu_vendor = "none"
        self.gpu_count = 0
        self.detect_gpu()

    def detect_gpu(self):
        # Check for NVIDIA
        try:
            subprocess.run(
                ["nvidia-smi"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            self.gpu_vendor = "nvidia"
            # Get count
            try:
                out = subprocess.check_output(
                    ["nvidia-smi", "--query-gpu=count", "--format=csv,noheader,nounits"]
                )
                self.gpu_count = int(out.strip())
            except:
                self.gpu_count = 0
            return
        except FileNotFoundError:
            pass

        # Check for AMD
        # Look for /sys/class/drm/card*/device/gpu_busy_percent
        amd_cards = []
        if os.path.exists("/sys/class/drm"):
            for card in os.listdir("/sys/class/drm"):
                if card.startswith("card") and os.path.exists(
                    f"/sys/class/drm/{card}/device/gpu_busy_percent"
                ):
                    amd_cards.append(card)
        if amd_cards:
            self.gpu_vendor = "amd"
            self.gpu_count = len(amd_cards)
            self.amd_cards = sorted(amd_cards)  # Keep order consistent
            return

        # Check for Intel
        # Intel is harder to detect reliably without intel_gpu_top or similar,
        # but the original code used intel_gpu_top. We'll skip complex intel detection for now
        # or assume if intel_gpu_top is in path.
        # For simplicity and speed in this script, we might skip Intel specific heavy logic
        # if it requires spawning a heavy process, but let's see.
        # Original used: intel_gpu_top -J -s 100
        # That's a blocking command waiting for samples. Not good for a one-shot loop unless managed carefully.
        # We will mark it as "intel" if found, but might strictly limit how we query it.
        try:
            subprocess.run(
                ["intel_gpu_top", "-h"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self.gpu_vendor = "intel"
            self.gpu_count = 1  # Simplified
        except FileNotFoundError:
            pass

    def get_cpu(self):
        try:
            with open("/proc/stat", "r") as f:
                line = f.readline()  # cpu  ...
                if not line.startswith("cpu "):
                    return 0.0

                parts = line.split()
                # user, nice, system, idle, iowait, irq, softirq, steal
                # parts[0] is 'cpu'
                values = [int(x) for x in parts[1:]]

                idle = values[3] + values[4]  # idle + iowait
                total = sum(values)

                diff_idle = idle - self.prev_cpu_idle
                diff_total = total - self.prev_cpu_total

                self.prev_cpu_total = total
                self.prev_cpu_idle = idle

                if diff_total == 0:
                    return 0.0

                usage = ((diff_total - diff_idle) * 100.0) / diff_total
                return max(0.0, min(100.0, usage))
        except:
            return 0.0

    def get_cpu_temp(self):
        # Try standardized hwmon
        try:
            base = "/sys/class/hwmon"
            if not os.path.exists(base):
                return -1

            best_temp = -1

            for hwmon in os.listdir(base):
                path = os.path.join(base, hwmon)
                name_path = os.path.join(path, "name")
                if not os.path.exists(name_path):
                    continue

                with open(name_path, "r") as f:
                    name = f.read().strip()

                if name in [
                    "coretemp",
                    "k10temp",
                    "zenpower",
                    "cpu_thermal",
                    "x86_pkg_temp",
                    "amd_energy",
                ]:
                    # Found a CPU monitor, look for inputs
                    for item in os.listdir(path):
                        if item.endswith("_input") and item.startswith("temp"):
                            try:
                                with open(os.path.join(path, item), "r") as f:
                                    val = int(f.read().strip())
                                    # Basic sanity check (10C to 120C)
                                    if 10000 < val < 120000:
                                        return val // 1000
                            except:
                                continue

            # Fallback to thermal_zone if no hwmon match
            base_tz = "/sys/class/thermal"
            if os.path.exists(base_tz):
                for tz in os.listdir(base_tz):
                    if not tz.startswith("thermal_zone"):
                        continue
                    path = os.path.join(base_tz, tz)
                    try:
                        with open(os.path.join(path, "type"), "r") as f:
                            t_type = f.read().strip()
                        if t_type in [
                            "x86_pkg_temp",
                            "cpu-thermal",
                            "soc_thermal",
                            "proc_thermal",
                        ]:
                            with open(os.path.join(path, "temp"), "r") as f:
                                val = int(f.read().strip())
                                if 1000 < val < 120000:
                                    return val // 1000
                    except:
                        continue

            return -1
        except:
            return -1

    def get_mem(self):
        try:
            mem_total = 0
            mem_available = 0
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        mem_total = int(line.split()[1])
                    elif line.startswith("MemAvailable:"):
                        mem_available = int(line.split()[1])
                    if mem_total > 0 and mem_available > 0:
                        break

            if mem_total == 0:
                return 0.0, 0, 0, 0

            mem_used = mem_total - mem_available
            usage = (mem_used * 100.0) / mem_total
            return usage, mem_total, mem_used, mem_available
        except:
            return 0.0, 0, 0, 0

    def get_disk_usage(self, disks):
        usage_map = {}
        for mount in disks:
            try:
                st = os.statvfs(mount)
                total = st.f_blocks * st.f_frsize
                free = st.f_bavail * st.f_frsize
                used = total - free
                # Use f_blocks (total) vs f_bavail (available to non-root)
                # df usually does used / (used + avail) to account for reserved
                # simple percentage:
                if total > 0:
                    pct = (used / total) * 100.0
                    usage_map[mount] = pct
                else:
                    usage_map[mount] = 0.0
            except:
                usage_map[mount] = 0.0
        return usage_map

    def get_gpu_stats(self):
        usages = []
        temps = []

        if self.gpu_vendor == "nvidia" and self.gpu_count > 0:
            try:
                # Combined query is faster than two
                out = subprocess.check_output(
                    [
                        "nvidia-smi",
                        "--query-gpu=utilization.gpu,temperature.gpu",
                        "--format=csv,noheader,nounits",
                    ]
                )
                lines = out.decode("utf-8").strip().split("\n")
                for line in lines:
                    parts = line.split(",")
                    if len(parts) >= 2:
                        try:
                            usages.append(float(parts[0].strip()))
                            temps.append(int(parts[1].strip()))
                        except:
                            usages.append(0.0)
                            temps.append(-1)
            except:
                usages = [0.0] * self.gpu_count
                temps = [-1] * self.gpu_count

        elif self.gpu_vendor == "amd" and self.gpu_count > 0:
            for card in self.amd_cards:
                # Usage
                try:
                    with open(
                        f"/sys/class/drm/{card}/device/gpu_busy_percent", "r"
                    ) as f:
                        usages.append(float(f.read().strip()))
                except:
                    usages.append(0.0)

                # Temp - simplistic scan for first sensor
                t_val = -1
                hwmon_base = f"/sys/class/drm/{card}/device/hwmon"
                if os.path.exists(hwmon_base):
                    try:
                        hwmon_dir = os.listdir(hwmon_base)[0]  # Usually hwmonX
                        full_path = os.path.join(hwmon_base, hwmon_dir)
                        # Try temp1_input (usually edge)
                        t_path = os.path.join(full_path, "temp1_input")
                        if os.path.exists(t_path):
                            with open(t_path, "r") as f:
                                t_val = int(f.read().strip()) // 1000
                    except:
                        pass
                temps.append(t_val)

        elif self.gpu_vendor == "intel":
            # Intel stats are hard without sudo/tools. Returning dummy 0.
            usages = [0.0]
            temps = [-1]

        return usages, temps

    def update_disks_from_stdin(self):
        # Non-blocking read from stdin to update monitored disks if needed
        # For simplicity in this version, we assume disks are passed as arguments or fixed,
        # but the QML sends them.
        # Actually, best pattern: QML starts process with args.
        # If args change, QML restarts process. Simplest.
        pass


if __name__ == "__main__":
    monitor = SystemMonitor()

    # Arguments: disks to monitor (space separated)
    # If no args, default to /
    disks_to_monitor = sys.argv[1:] if len(sys.argv) > 1 else ["/"]

    # Main loop
    try:
        while True:
            # CPU
            cpu_usage = monitor.get_cpu()
            cpu_temp = monitor.get_cpu_temp()

            # RAM
            ram_usage, ram_total, ram_used, ram_avail = monitor.get_mem()

            # Disk
            disk_usage = monitor.get_disk_usage(disks_to_monitor)

            # GPU
            gpu_usages, gpu_temps = monitor.get_gpu_stats()

            data = {
                "cpu": {"usage": cpu_usage, "temp": cpu_temp},
                "ram": {
                    "usage": ram_usage,
                    "total": ram_total,
                    "used": ram_used,
                    "available": ram_avail,
                },
                "disk": {"usage": disk_usage},
                "gpu": {
                    "detected": monitor.gpu_vendor != "none",
                    "vendor": monitor.gpu_vendor,
                    "count": monitor.gpu_count,
                    "usages": gpu_usages,
                    "temps": gpu_temps,
                },
            }

            print(json.dumps(data), flush=True)
            time.sleep(2)

    except KeyboardInterrupt:
        sys.exit(0)
