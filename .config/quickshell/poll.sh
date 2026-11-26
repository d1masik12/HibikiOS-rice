#!/usr/bin/env python3
import json, os, re, shutil, subprocess
from datetime import datetime

def run(args, timeout=1.0):
    try:
        return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, timeout=timeout,
                              check=False).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""

def number(value, default=0):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default

def niri_data():
    raw = run(["niri", "msg", "-j", "workspaces"])
    try:
        workspaces = json.loads(raw) if raw else []
    except json.JSONDecodeError:
        workspaces = []
    raw_windows = run(["niri", "msg", "-j", "windows"])
    try:
        windows = json.loads(raw_windows) if raw_windows else []
    except json.JSONDecodeError:
        windows = []
    focused = ""
    for win in windows if isinstance(windows, list) else []:
        if win.get("is_focused"):
            focused = win.get("title") or ""
            break
    cleaned = []
    for ws in workspaces if isinstance(workspaces, list) else []:
        cleaned.append({
            "id": ws.get("id", 0),
            "idx": ws.get("idx", ws.get("id", 1)),
            "name": ws.get("name", ""),
            "output": ws.get("output", ""),
            "focused": bool(ws.get("is_focused", False)),
            "active": bool(ws.get("is_active", False))
        })
    return cleaned, focused

def audio_data():
    sinks = run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
    m = re.search(r"/\s*(\d+)%", sinks)
    vol = number(m.group(1)) if m else 0
    mic_s = run(["pactl", "get-source-volume", "@DEFAULT_SOURCE@"])
    mm = re.search(r"/\s*(\d+)%", mic_s)
    mic_vol = number(mm.group(1)) if mm else 0
    mute = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"]).lower()
    mic = run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"]).lower()
    return vol, "yes" in mute, mic_vol, "yes" in mic

def system_usage():
    cpu = 0
    try:
        with open("/proc/stat", "r", encoding="utf-8") as f:
            vals = [int(x) for x in f.readline().split()[1:]]
        idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
        total = sum(vals)
        prev = json.loads(open("/tmp/hibiki-quickshell-cpu.json", encoding="utf-8").read())
        dt = total - prev["total"]
        di = idle - prev["idle"]
        if dt > 0:
            cpu = round(100 * (dt - di) / dt)
        with open("/tmp/hibiki-quickshell-cpu.json", "w", encoding="utf-8") as f:
            json.dump({"total": total, "idle": idle}, f)
    except Exception:
        try:
            with open("/proc/stat", "r", encoding="utf-8") as f:
                vals = [int(x) for x in f.readline().split()[1:]]
            idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
            with open("/tmp/hibiki-quickshell-cpu.json", "w", encoding="utf-8") as f:
                json.dump({"total": sum(vals), "idle": idle}, f)
        except Exception:
            pass

    ram_pct, ram_used, ram_tot = 0, 0.0, 64.0
    try:
        mem = {}
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                k, v = line.split(":", 1)
                mem[k] = int(v.strip().split().pop(0))
        tot = mem.get("MemTotal", 0)
        avail = mem.get("MemAvailable", 0)
        if tot:
            ram_pct = round(100 * (tot - avail) / tot)
            ram_tot = round(tot / 1048576, 1)
            ram_used = round((tot - avail) / 1048576, 1)
    except Exception:
        pass
    return max(0, min(100, cpu)), max(0, min(100, ram_pct)), ram_used, ram_tot

def hw_extra():
    cpu_temp = 0
    st = run(["sensors"], timeout=1.5)
    m = re.findall(r"(?:Tctl|Package id 0|Core 0):\s*\+?([\d.]+)°?C", st)
    if m:
        cpu_temp = number(m.pop(0))
    gpu_pct, gpu_temp, vram_u, vram_t = 0, 0, 0, 12288
    gpu = run(["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"])
    if gpu:
        lines = gpu.splitlines()
        if lines:
            pts = [p.strip() for p in lines.pop(0).split(",")]
            if len(pts) >= 4:
                gpu_pct = number(pts.pop(0))
                gpu_temp = number(pts.pop(0))
                vram_u = number(pts.pop(0))
                vram_t = number(pts.pop(0), 12288)
    du = shutil.disk_usage("/")
    disk_tot = round(du.total / (1024**3))
    disk_used = round(du.used / (1024**3))
    disk_pct = round(100 * du.used / max(du.total, 1))
    up = run(["uptime", "-p"]).replace("up ", "")
    wifi_on = run(["nmcli", "radio", "wifi"]) == "enabled"
    ssid = ""
    for line in run(["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]).splitlines():
        if line.startswith("yes:"):
            ssid = line.split(":", 1).pop()
            break
    bt_on = "Powered: yes" in run(["bluetoothctl", "show"])
    return cpu_temp, gpu_pct, gpu_temp, vram_u, vram_t, disk_pct, disk_used, disk_tot, up, wifi_on, ssid, bt_on

def main():
    now = datetime.now().astimezone()
    workspaces, title = niri_data()
    vol, muted, mic_vol, mic_muted = audio_data()
    cpu, ram, ram_u, ram_t = system_usage()
    cpu_t, gpu, gpu_t, vram_u, vram_t, disk_p, disk_u, disk_t, up, wifi_on, ssid, bt_on = hw_extra()
    out = {
        "workspaces": workspaces, "focusedWindow": title,
        "time": now.strftime("%H:%M"), "date": now.strftime("%a, %-d %b"),
        "layout": "EN", "volume": vol, "muted": muted,
        "micVolume": mic_vol, "micMuted": mic_muted,
        "cpu": cpu, "gpu": gpu, "ram": ram,
        "cpuTemp": cpu_t, "gpuTemp": gpu_t,
        "ramUsedGb": ram_u, "ramTotalGb": ram_t,
        "diskPct": disk_p, "diskUsedGb": disk_u, "diskTotalGb": disk_t,
        "vramUsedMb": vram_u, "vramTotalMb": vram_t,
        "uptime": up, "wifiOn": wifi_on, "wifiSsid": ssid, "btOn": bt_on,
        "notifications": number(run(["swaync-client", "-c"]))
    }
    print(json.dumps(out, ensure_ascii=False))

if __name__ == "__main__":
    main()
