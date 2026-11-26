#!/usr/bin/env python3
import json, subprocess, sys

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=6)
    except Exception:
        return ""

if len(sys.argv) > 1:
    act = sys.argv[1]
    if act == "wifi-toggle":
        st = run(["nmcli", "radio", "wifi"]).strip()
        run(["nmcli", "radio", "wifi", "off" if st == "enabled" else "on"])
    elif act == "wifi-connect":
        ssid = sys.argv[2]
        pw = sys.argv[3] if len(sys.argv) > 3 else ""
        if pw:
            run(["nmcli", "dev", "wifi", "connect", ssid, "password", pw])
        else:
            run(["nmcli", "dev", "wifi", "connect", ssid])
    elif act == "wifi-forget":
        run(["nmcli", "con", "delete", sys.argv[2]])
    elif act == "bt-toggle":
        powered = "Powered: yes" in run(["bluetoothctl", "show"])
        run(["bluetoothctl", "power", "off" if powered else "on"])
    elif act == "bt-scan":
        run(["bluetoothctl", "--timeout", "5", "scan", "on"])
    elif act == "bt-conn":
        mac, mode = sys.argv[2], sys.argv[3]
        run(["bluetoothctl", mode, mac])
    sys.exit(0)

wifi_on = run(["nmcli", "radio", "wifi"]).strip() == "enabled"
nets = []
seen = set()
if wifi_on:
    raw = run(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"])
    for line in raw.splitlines():
        parts = line.split(":")
        if len(parts) < 4:
            continue
        in_use = parts[0] == "*"
        ssid = parts[1].strip()
        if not ssid or ssid in seen:
            continue
        seen.add(ssid)
        sig = int(parts[2]) if parts[2].isdigit() else 0
        sec = parts[3].strip()
        nets.append({"ssid": ssid, "active": in_use, "signal": sig, "secure": bool(sec and sec != "--")})
    nets.sort(key=lambda x: (not x["active"], -x["signal"]))

bt_on = "Powered: yes" in run(["bluetoothctl", "show"])
devs = []
if bt_on:
    raw_d = run(["bluetoothctl", "devices"])
    for line in raw_d.splitlines():
        if not line.startswith("Device "):
            continue
        sp = line.split(" ", 2)
        if len(sp) < 3:
            continue
        mac, name = sp[1], sp[2].strip()
        info = run(["bluetoothctl", "info", mac])
        conn = "Connected: yes" in info
        paired = "Paired: yes" in info
        devs.append({"mac": mac, "name": name, "connected": conn, "paired": paired})
    devs.sort(key=lambda x: (not x["connected"], not x["paired"], x["name"]))

print(json.dumps({"wifiOn": wifi_on, "nets": nets[:10], "btOn": bt_on, "devs": devs[:10]}))
