import json
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent / "public"


def S(t, s, stamp=None, ink=None, hit=False):
    d = {"t": round(t, 4), "s": s}
    if stamp:
        d["stamp"] = stamp
    if ink:
        d["ink"] = ink
    if hit:
        d["hit"] = True
    return d


shots = [
    S(0.0, "space"),
    S(3.0, "stone", "STONEHENGE · c. 2500 BC", "light", True),
    S(4.5, "nebra", "NEBRA · c. 1600 BC"),
    S(6.0, "egypt", "THEBES · c. 1300 BC", "dark"),
    S(7.0, "bone", "ANYANG · c. 1200 BC", "dark"),
    S(8.0, "bayeux", "BAYEUX · 1066", "dark"),
    S(9.0, "engrave"), S(9.5, "gold"), S(10.0, "sun"), S(10.25, "thermal"), S(10.5, "ink"), S(10.75, "astro"),
    S(11.0, "clay", "BABYLON · 652 BC", "dark", True),
    S(12.5, "greek", "MILETUS · 585 BC"),
    S(13.5, "bronze", "ANTIKYTHERA · c. 100 BC"),
    S(15.0, "dunhuang", "DUNHUANG · c. 650", "dark"),
    S(16.0, "codex", "YUCATÁN · c. 1200", "dark"),
    S(17.0, "copernicus", "NUREMBERG · 1543", "dark"),
    S(18.0, "galileo", "ROME · 1613", "dark"),
    S(19.0, "map", "LONDON · 1715", "dark"),
    S(20.0, "dag", "KÖNIGSBERG · 1851"),
    S(21.0, "eddington", "SOBRAL · 1919", "dark"),
    S(22.0, "astro"), S(22.25, "gold"), S(22.5, "engrave"), S(22.75, "sun"),
    S(23.0, "tulip", "AMSTERDAM · 1637", "dark", True),
    S(24.5, "dojima", "DOJIMA · OSAKA · 1730", "dark"),
    S(26.0, "ticker", "NEW YORK · 1867"),
    S(27.5, "genesis", "GENESIS BLOCK · 2009"),
    S(28.5, "radar", "SOLANA · 2026"),
]
cycle = ["stone", "nebra", "egypt", "bone", "bayeux", "clay", "greek", "bronze", "dunhuang", "codex", "copernicus", "galileo",
         "map", "dag", "eddington", "tulip", "dojima", "ticker", "genesis", "radar", "gold", "engrave", "sun", "astro", "thermal", "ink"]
i = 0
first = True
for a, b, step in ((31.0, 33.0, 0.25), (33.0, 35.0, 1 / 6), (35.0, 37.0, 2 / 30)):
    t = a
    while t < b - 1e-6:
        d = {"t": round(t, 4), "s": cycle[i % len(cycle)], "montage": True}
        if first:
            d["hit"] = True
            first = False
        shots.append(d)
        i += 1
        t += step
shots.append({"t": 37.0, "s": "black"})
shots.append({"t": 38.0, "s": "space", "phase": "end", "hit": True})
shots[0]["phase"] = "intro"
tl = {
    "fps": 30, "duration": 47.0, "bpm": 120, "beat0": 0.0,
    "shots": shots,
    "words": [
        {"t0": 3.0, "t1": 6.9, "text": "They called it"},
        {"t0": 7.0, "t1": 10.9, "text": "an omen."},
        {"t0": 11.0, "t1": 14.9, "text": "Until someone"},
        {"t0": 15.0, "t1": 18.9, "text": "wrote down"},
        {"t0": 19.0, "t1": 22.9, "text": "the date."},
        {"t0": 23.0, "t1": 26.9, "text": "Every move"},
        {"t0": 27.0, "t1": 28.4, "text": "leaves"},
        {"t0": 28.5, "t1": 30.9, "text": "a trace."},
    ],
    "montage": {"t0": 31.0, "t1": 37.0, "from": -2500, "to": 2026},
    "end": {"open": 38.0, "corOut": 39.8, "lock": 40.6, "button": 41.7, "out": 45.5},
    "intro": {"total": 1.0},
}
(HERE / "timeline.json").write_text(json.dumps(tl, ensure_ascii=False, indent=1), encoding="utf-8")
print(len(shots), "shots", sum(1 for s in shots if s.get("stamp")), "stamped", sum(1 for s in shots if s.get("montage")), "montage")
