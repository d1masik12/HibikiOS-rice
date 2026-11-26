#!/usr/bin/env python3
import json, subprocess

radio = subprocess.getoutput("nmcli radio wifi").strip() == "enabled"
nets = []
seen = set()
if radio:
    out = subprocess.getoutput("nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list")
    for ln in out.splitlines():
        pts = ln.split(":")
        if len(pts) >= 4:
            in_use = pts.pop(0) == "*"
            ssid = pts.pop(0).strip()
            sig = int(pts.pop(0) or 0)
            sec = pts.pop(0).strip()
            if ssid and ssid not in seen:
                seen.add(ssid)
                nets.append({"active": in_use, "ssid": ssid, "sig": sig, "sec": sec != ""})
nets.sort(key=lambda x: (not x["active"], -x["sig"]))
print(json.dumps({"radio": radio, "list": nets}, ensure_ascii=False))
