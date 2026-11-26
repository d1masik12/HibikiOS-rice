#!/usr/bin/env python3
import json, subprocess

ds = subprocess.getoutput("pactl get-default-sink").strip()
dsrc = subprocess.getoutput("pactl get-default-source").strip()
s_out = subprocess.getoutput("pactl -f json list sinks")
src_out = subprocess.getoutput("pactl -f json list sources")

s_data = json.loads(s_out) if s_out.startswith("[") else []
src_data = json.loads(src_out) if src_out.startswith("[") else []

sinks = [{"name": x.get("name", ""), "desc": x.get("description", x.get("name", ""))} for x in s_data]
sources = [{"name": x.get("name", ""), "desc": x.get("description", x.get("name", ""))} for x in src_data if not x.get("name", "").endswith(".monitor")]

print(json.dumps({"ds": ds, "dsrc": dsrc, "sinks": sinks, "sources": sources}, ensure_ascii=False))
