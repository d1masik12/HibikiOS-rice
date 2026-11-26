#!/usr/bin/env python3
import hashlib, json, os, re, sys, urllib.parse, urllib.request

title = sys.argv.pop(1).strip() if len(sys.argv) > 1 else ""
artist = sys.argv.pop(1).strip() if len(sys.argv) > 1 else ""
track_len = float(sys.argv.pop(1)) if len(sys.argv) > 1 else 0.0

if not title:
    print(json.dumps({"lines": []}))
    sys.exit(0)

JUNK = r"\b(?:slowed|reverb|reverbed|sped\s*up|speed\s*up|nightcore|bass\s*boosted|8d|audio|official|video|lyrics|visualizer|remix|edit|flip|ver|version|mix|prod\.?.*)\b"

def clean_str(s):
    s = re.sub(r"\[.*?\]|\(.*?\)|\{.*?\}", " ", s)
    s = re.sub(r"[-–—|/\+•]+", " ", s)
    s = re.sub(JUNK, " ", s, flags=re.IGNORECASE)
    return re.sub(r"\s+", " ", s).strip()

ct = clean_str(title) or title
ca = clean_str(artist)
ca_main = re.split(r"\b(?:feat|ft|with|x|&)\b|,", ca, flags=re.IGNORECASE).pop(0).strip()

cache_dir = os.path.expanduser("~/.cache/hibiki-lyrics")
os.makedirs(cache_dir, exist_ok=True)
key = hashlib.md5(f"{ca_main.lower()}|{ct.lower()}|{int(track_len)}".encode()).hexdigest()
cache_path = os.path.join(cache_dir, key + ".json")

if os.path.exists(cache_path):
    print(open(cache_path, encoding="utf-8").read())
    sys.exit(0)

def parse_lrc(lrc_text, ratio=1.0):
    out = []
    for raw in lrc_text.splitlines():
        m = re.match(r"\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)", raw.strip())
        if m:
            sec = (int(m.group(1)) * 60 + float(m.group(2))) * ratio
            txt = m.group(3).strip()
            if txt:
                out.append({"t": round(sec, 2), "text": txt})
    return out

def search_api(params):
    try:
        q = urllib.parse.urlencode(params)
        req = urllib.request.Request("https://lrclib.net?" + q, headers={"User-Agent": "HibikiUI/1.1"})
        with urllib.request.urlopen(req, timeout=4.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data if isinstance(data, list) else []
    except Exception:
        return []

items = search_api({"track_name": ct, "artist_name": ca_main}) if ca_main else []
if not items:
    items = search_api({"track_name": ct})

lines = []
for it in items:
    synced = it.get("syncedLyrics") or ""
    if synced:
        orig_dur = float(it.get("duration") or 0)
        ratio = (track_len / orig_dur) if (track_len > 15 and orig_dur > 15 and 0.7 <= track_len / orig_dur <= 1.45) else 1.0
        lines = parse_lrc(synced, ratio)
        if lines:
            break

if not lines and items:
    for it in items:
        plain = (it.get("plainLyrics") or "").strip()
        if plain:
            raw_lines = [ln.strip() for ln in plain.splitlines() if ln.strip()]
            dur = track_len if track_len > 15 else max(60.0, len(raw_lines) * 3.5)
            step = (dur * 0.86) / max(1, len(raw_lines))
            lines = [{"t": round(4.0 + i * step, 2), "text": ln} for i, ln in enumerate(raw_lines)]
            break

res = json.dumps({"lines": lines}, ensure_ascii=False)
with open(cache_path, "w", encoding="utf-8") as f:
    f.write(res)
print(res)
