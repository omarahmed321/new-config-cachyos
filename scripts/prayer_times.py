#!/usr/bin/env python3
import urllib.request
import json
import datetime
import os
import sys

CACHE_FILE = "/tmp/prayer_times.json"

def get_location():
    try:
        req = urllib.request.Request(
            "http://ip-api.com/json",
            headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            return data.get("lat"), data.get("lon"), data.get("city")
    except Exception:
        return 30.0444, 31.2357, "Cairo"

def get_prayer_timings(lat, lon):
    today = datetime.date.today().isoformat()
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'r') as f:
                cached = json.load(f)
                if cached.get("date") == today:
                    return cached.get("timings")
        except Exception:
            pass

    try:
        url = f"http://api.aladhan.com/v1/timings?latitude={lat}&longitude={lon}&method=5"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=5) as response:
            res = json.loads(response.read().decode())
            timings = res["data"]["timings"]
            with open(CACHE_FILE, 'w') as f:
                json.dump({"date": today, "timings": timings}, f)
            return timings
    except Exception:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, 'r') as f:
                    return json.load(f).get("timings")
            except Exception:
                pass
        return None

def parse_time(time_str):
    parts = time_str.split(":")
    return int(parts[0]), int(parts[1])

def main():
    lat, lon, city = get_location()
    timings = get_prayer_timings(lat, lon)
    if not timings:
        print("No timings")
        sys.exit(0)

    prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    now = datetime.datetime.now()
    
    prayer_times = []
    for p in prayers:
        t_str = timings.get(p)
        if not t_str:
            continue
        h, m = parse_time(t_str)
        p_time = now.replace(hour=h, minute=m, second=0, microsecond=0)
        prayer_times.append((p, p_time))

    next_p = None
    next_p_time = None

    for name, p_time in prayer_times:
        if p_time > now:
            next_p = name
            next_p_time = p_time
            break

    if not next_p:
        next_p = "Fajr"
        f_str = timings.get("Fajr")
        h, m = parse_time(f_str)
        next_p_time = now.replace(hour=h, minute=m, second=0, microsecond=0) + datetime.timedelta(days=1)

    diff = next_p_time - now
    diff_seconds = diff.total_seconds()
    hours = int(diff_seconds // 3600)
    minutes = int((diff_seconds % 3600) // 60)
    seconds = int(diff_seconds % 60)

    next_p_time_str = next_p_time.strftime("%I:%M %p").lstrip('0')
    print(f"{next_p} in {hours}:{minutes:02d}:{seconds:02d} ({next_p_time_str})")

if __name__ == "__main__":
    main()
