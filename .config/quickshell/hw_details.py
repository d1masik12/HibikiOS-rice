#!/usr/bin/env python3
import json, os, shutil, subprocess

def run(args):
    try:
        return subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=1.5).stdout.strip()
    except Exception:
        return ""

def at(lst, idx, default="-"):
    return lst[idx] if idx < len(lst) and lst[idx] else default

cpu_name = "Intel Core i5-13500"
mhz_list = []
try:
    with open("/proc/cpuinfo") as f:
        for line in f:
            if line.startswith("model name") and cpu_name == "Intel Core i5-13500":
                cpu_name = line.split(":", 1).pop().strip()
            elif line.startswith("cpu MHz"):
                mhz_list.append(float(line.split(":", 1).pop().strip()))
except Exception:
    pass
avg_mhz = round(sum(mhz_list) / len(mhz_list)) if mhz_list else 0
cores = os.cpu_count() or 20
la = " ".join(open("/proc/loadavg").read().split()[:3]) if os.path.exists("/proc/loadavg") else "-"

gpu_raw = run(["nvidia-smi", "--query-gpu=name,driver_version,power.draw,power.limit,clocks.gr,clocks.mem,fan.speed,memory.used,memory.total", "--format=csv,noheader,nounits"])
g = [x.strip() for x in gpu_raw.split(",")] if gpu_raw else []
gpu_info = {
    "model": at(g, 0, "NVIDIA GeForce RTX 3060"),
    "driver": at(g, 1),
    "power": at(g, 2) + " / " + at(g, 3) + " Вт" if len(g) > 3 else "-",
    "clocks": at(g, 4) + " / " + at(g, 5) + " МГц" if len(g) > 5 else "-",
    "fan": at(g, 6) + "%" if len(g) > 6 else "-",
    "vram": at(g, 7) + " / " + at(g, 8) + " МБ" if len(g) > 8 else "-"
}

mem = {}
with open("/proc/meminfo") as f:
    for line in f:
        k, v = line.split(":", 1)
        mem[k] = int(v.strip().split().pop(0))
ram_cached = round((mem.get("Cached", 0) + mem.get("Buffers", 0)) / 1048576, 1)
swap_tot = round(mem.get("SwapTotal", 0) / 1048576, 1)
swap_used = round((mem.get("SwapTotal", 0) - mem.get("SwapFree", 0)) / 1048576, 1)
ps_out = run(["ps", "-eo", "comm,rss", "--sort=-rss"]).splitlines()[1:4]
top_procs = []
for ln in ps_out:
    p = ln.rsplit(None, 1)
    if len(p) == 2:
        top_procs.append(f"{p.pop(0)} ({round(int(p.pop(0))/1024)} МБ)")

du = shutil.disk_usage("/")
disk_model = "NVMe SSD"
for ln in run(["lsblk", "-no", "MOUNTPOINT,PKNAME,FSTYPE"]).splitlines():
    pts = ln.split()
    if pts and pts.pop(0) == "/":
        pk = pts.pop(0) if pts else ""
        fs = pts.pop(0) if pts else ""
        m = run(["lsblk", "-no", "MODEL", "/dev/" + pk]).strip() if pk else ""
        disk_model = f"{m} ({fs})" if m else (fs or "NVMe SSD")
        break

print(json.dumps({
    "cpu": {"model": cpu_name, "cores": f"{cores} потоков", "freq": f"{avg_mhz} МГц", "load": la},
    "gpu": gpu_info,
    "ram": {"cached": f"{ram_cached} ГБ", "swap": f"{swap_used} / {swap_tot} ГБ", "top": ", ".join(top_procs) or "-"},
    "disk": {"model": disk_model, "free": f"{round(du.free/(1024**3))} ГБ свободно", "total": f"{round(du.total/(1024**3))} ГБ всего"}
}, ensure_ascii=False))
