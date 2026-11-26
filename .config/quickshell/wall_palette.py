#!/usr/bin/env python3
import colorsys, json, re, subprocess

def get_wallpaper():
    try:
        out = subprocess.check_output(["awww", "query"], text=True, stderr=subprocess.DEVNULL)
        m = re.search(r"image:\s*(.+)", out)
        if m:
            return m.group(1).strip()
    except Exception:
        pass
    return ""

def boost_ice(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    s = max(0.36, min(0.72, s * 1.2))
    v = max(0.85, min(0.98, v * 1.2))
    nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
    return "#{:02x}{:02x}{:02x}".format(int(nr * 255), int(ng * 255), int(nb * 255))

def extract_ffmpeg(path):
    try:
        raw = subprocess.check_output(
            ["ffmpeg", "-v", "quiet", "-i", path, "-vf", "scale=48:48", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            stderr=subprocess.DEVNULL
        )
        buckets = {}
        for i in range(0, len(raw) - 2, 3):
            r, g, b = raw[i], raw[i+1], raw[i+2]
            mx, mn = max(r, g, b), min(r, g, b)
            if mx < 40 or (mx - mn) < 20:
                continue
            key = (r // 24, g // 24, b // 24)
            buckets[key] = buckets.get(key, 0) + 1
        if not buckets:
            return "#a6e3e9", "#89dceb"
        top = sorted(buckets.items(), key=lambda x: -x[1])
        c1 = [v * 24 + 12 for v in top[0][0]]
        c2 = [v * 24 + 12 for v in (top[1][0] if len(top) > 1 else top[0][0])]
        return boost_ice(*c1), boost_ice(*c2)
    except Exception:
        return "#a6e3e9", "#89dceb"

wall = get_wallpaper()
a1, a2 = extract_ffmpeg(wall) if wall else ("#a6e3e9", "#89dceb")
print(json.dumps({"wall": wall, "accent": a1, "accentAlt": a2}))
