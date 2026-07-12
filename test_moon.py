import ephem
from datetime import datetime, timedelta

def get_moon_lon(dt):
    moon = ephem.Moon(dt)
    return float(moon.hlon) * 180 / 3.14159265358979323846

d = datetime(2026, 7, 1)
lon = get_moon_lon(d)
print(f"July 1 2026 00:00 UTC: {lon}")
start = d - timedelta(days=4)
lon_start = get_moon_lon(start)
print(f"June 27 2026 00:00 UTC: {lon_start}")
