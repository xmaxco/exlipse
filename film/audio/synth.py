import json
import sys
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

HERE = Path(__file__).resolve().parent.parent / "public"
TL = json.loads((HERE / "timeline.json").read_text(encoding="utf-8"))
SR = 48000
DUR = TL["duration"]
N = int(SR * DUR)
BEAT = 60.0 / TL["bpm"]
END = TL["end"]
SHOTS = TL["shots"]
BLACK = next(s["t"] for s in SHOTS if s["s"] == "black")
OPEN = END["open"]
rng = np.random.default_rng(11)


def ta(n):
    return np.arange(n) / SR


def noise(n):
    return rng.standard_normal(n)


def filt(x, kind, f, order=2):
    return sosfilt(butter(order, f, btype=kind, fs=SR, output="sos"), x)


def env(n, tau, att=0.002):
    t = ta(n)
    return np.clip(t / att, 0, 1) * np.exp(-t / tau)


def adsr(n, att, rel):
    t = ta(n)
    return np.minimum(np.clip(t / max(att, 1e-4), 0, 1), np.clip((n / SR - t) / max(rel, 1e-4), 0, 1))


dry = np.zeros((N, 2))
send = np.zeros((N, 2))


def place(x, at, g=1.0, pan=0.0, rev=0.3):
    s = int(round(at * SR))
    if s >= N:
        return
    if x.ndim == 1:
        l, r = np.cos((pan + 1) * np.pi / 4) * 1.414, np.sin((pan + 1) * np.pi / 4) * 1.414
        x = np.stack([x * l, x * r], axis=1)
    if s < 0:
        x = x[-s:]
        s = 0
    x = x[: N - s] * g
    dry[s:s + len(x)] += x
    send[s:s + len(x)] += x * rev


def partials(fs, amps, taus, dur, att=0.003):
    n = int(SR * dur)
    t = ta(n)
    out = np.zeros(n)
    for f, a, tau in zip(fs, amps, taus):
        out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * env(n, tau, att)
    return out


def taiko(vel=1.0, f0=58.0, dur=1.4):
    n = int(SR * dur)
    t = ta(n)
    bend = 1 + 0.5 * np.exp(-t / 0.025)
    out = np.zeros(n)
    for ratio, a, tau in ((1.0, 1.0, 0.42), (1.59, 0.45, 0.25), (2.14, 0.3, 0.16), (2.3, 0.22, 0.12), (2.65, 0.15, 0.09)):
        out += a * np.sin(2 * np.pi * np.cumsum(f0 * ratio * bend) / SR) * env(n, tau * (0.6 + 0.4 * vel), 0.002)
    m = int(SR * 0.03)
    out[:m] += filt(noise(m), "bandpass", [180, 2200]) * env(m, 0.008, 0.0005) * 0.6
    return out * vel


def tick(f=2600.0):
    n = int(SR * 0.07)
    t = ta(n)
    x = np.sin(2 * np.pi * f * t) * env(n, 0.012, 0.0005) + 0.5 * np.sin(2 * np.pi * f * 1.52 * t) * env(n, 0.007, 0.0005)
    x += filt(noise(n), "highpass", 3000) * env(n, 0.003, 0.0002) * 0.4
    return x


def whoosh(dur=0.4, lo=260, hi=3200, rise=False):
    n = int(SR * dur)
    src = noise(n)
    out = np.zeros(n)
    for i in range(0, n, 512):
        k = i / n
        k = k if rise else 1 - k
        out[i:i + 512] = filt(src[i:i + 512], "lowpass", lo + (hi - lo) * k)
    return out * np.sin(np.pi * np.clip(ta(n) / dur, 0, 1)) ** 1.5


def rev_swell(dur=0.5):
    n = int(SR * dur)
    x = filt(filt(noise(n), "highpass", 500), "lowpass", 7000) * env(n, dur * 0.3, 0.001)
    return x[::-1] * 0.5


FORM = {"a": [(800, 160, 1.0), (1150, 180, 0.5), (2900, 240, 0.22)], "o": [(450, 130, 1.0), (800, 150, 0.45), (2830, 200, 0.1)]}


def choir(notes, t0, t1, vowel="a", att=1.6, rel=1.8, level=1.0):
    n = int(SR * (t1 - t0))
    t = ta(n)
    out = np.zeros((n, 2))
    slow = filt(noise(n), "lowpass", 2.5)
    slow /= np.max(np.abs(slow)) + 1e-9
    for f in notes:
        for v in range(3):
            det = f * 2 ** (rng.uniform(-8, 8) / 1200)
            vib = 1 + 0.0038 * np.sin(2 * np.pi * (5.0 + rng.uniform(-0.4, 0.4)) * t + rng.uniform(0, 6.28)) * np.clip(t / 1.4, 0, 1)
            inst = det * vib * (1 + 0.0012 * np.roll(slow, int(rng.uniform(0, n))))
            ph = 2 * np.pi * np.cumsum(inst) / SR
            sig = np.zeros(n)
            for h in range(1, int(4200 / det) + 1):
                fh = h * det
                w = sum(a * np.exp(-((fh - F) / B) ** 2) for F, B, a in FORM[vowel]) / h ** 0.5 + 0.01 / h
                if w < 0.003:
                    continue
                sig += w * np.sin(h * ph + rng.uniform(0, 6.28))
            pan = rng.uniform(-0.65, 0.65)
            out[:, 0] += sig * np.cos((pan + 1) * np.pi / 4)
            out[:, 1] += sig * np.sin((pan + 1) * np.pi / 4)
    breath = np.zeros(n)
    for F, B, a in FORM[vowel][:2]:
        breath += filt(noise(n), "bandpass", [F - B, F + B]) * a
    out += np.stack([breath, np.roll(breath, 900)], axis=1) * 0.04
    return out * adsr(n, att, rel)[:, None] * level / np.sqrt(len(notes) * 3)


def bowl(f0=196.0, dur=7.0):
    n = int(SR * dur)
    t = ta(n)
    out = np.zeros(n)
    for ratio, a, tau in ((1.0, 0.4, 5.5), (2.71, 0.22, 3.6), (5.15, 0.1, 2.0), (8.43, 0.05, 1.1)):
        f = f0 * ratio
        out += a * (np.sin(2 * np.pi * f * t) + 0.8 * np.sin(2 * np.pi * (f + 1.3 + ratio * 0.4) * t)) * env(n, tau, 0.01)
    return out * 0.5


def boom():
    n = int(SR * 6.0)
    t = ta(n)
    f = 46 * np.exp(-t / 1.1) + 29
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 1.7, 0.005) * 1.2
    x += filt(noise(n), "lowpass", 130) * env(n, 0.4, 0.004) * 1.5
    return x


def foley(kind):
    if kind == "stone":
        n = int(SR * 0.8)
        x = filt(noise(n), "lowpass", 160) * env(n, 0.12, 0.004) * 2.5
        g = filt(noise(n), "bandpass", [300, 1400]) * (0.5 + 0.5 * np.abs(filt(noise(n), "lowpass", 40)) * 4) * env(n, 0.25, 0.03)
        return x + g * 0.5 + 0.7 * taiko(0.7, 44.0, 0.8)
    if kind == "nebra":
        f0 = 182.0
        return partials([f0 * r for r in (1, 1.47, 2.09, 2.56, 3.39, 4.12)], [0.5, 0.35, 0.28, 0.2, 0.12, 0.08], [2.6, 2.0, 1.4, 1.0, 0.7, 0.5], 3.0, 0.004) * 0.8
    if kind == "egypt":
        n = int(SR * 0.7)
        x = np.zeros(n)
        for k in range(5):
            s = int(SR * (k * 0.07 + rng.uniform(0, 0.02)))
            j = partials([rng.uniform(3200, 4200), rng.uniform(5200, 6400), rng.uniform(7800, 9200)], [0.3, 0.22, 0.15], [0.09, 0.06, 0.04], 0.2, 0.0005)
            x[s:s + len(j)] += j[: n - s] * (1 - k * 0.12)
        return x * 0.9
    if kind == "bone":
        n = int(SR * 0.6)
        x = np.zeros(n)
        for k in range(8):
            s = 0 if k == 0 else int(SR * rng.uniform(0, 0.12))
            m = int(SR * 0.012)
            x[s:s + m] += filt(noise(m), "highpass", 1800) * env(m, 0.0025, 0.0003) * (1.0 if k == 0 else rng.uniform(0.25, 0.6))
        return x + 0.45 * taiko(0.5, 95.0, 0.6)
    if kind == "bayeux":
        return filt(whoosh(0.4, 1500, 7000), "highpass", 1200) * 0.8
    if kind == "clay":
        n = int(SR * 0.7)
        x = filt(noise(n), "lowpass", 260) * env(n, 0.07, 0.004) * 2.0
        for k in range(4):
            s = int(SR * (0.12 + k * 0.09))
            m = int(SR * 0.03)
            x[s:s + m] += filt(noise(m), "bandpass", [400, 1600]) * env(m, 0.008, 0.001) * 0.6
        return x
    if kind == "greek":
        return partials([1840, 4230, 6150], [0.35, 0.2, 0.12], [0.35, 0.18, 0.1], 0.8, 0.0008)
    if kind == "bronze":
        n = int(SR * 0.9)
        x = np.zeros(n)
        for k in range(9):
            s = int(SR * k * 0.045)
            m = int(SR * 0.02)
            x[s:s + m] += filt(noise(m), "bandpass", [2500, 6000]) * env(m, 0.003, 0.0003) * (0.9 - k * 0.05)
        return x + partials([1210, 3340], [0.12, 0.06], [0.6, 0.3], 0.9)
    if kind == "dunhuang":
        f0 = 523.25
        return partials([f0, f0 * 1.19, f0 * 2.4, f0 * 3.9, f0 * 5.5], [0.4, 0.3, 0.2, 0.1, 0.05], [2.2, 2.0, 1.2, 0.7, 0.4], 2.6, 0.002) * 0.6
    if kind == "codex":
        n = int(SR * 0.5)
        x = np.zeros(n)
        for k in range(3):
            s = int(SR * k * 0.11)
            m = int(SR * 0.09)
            x[s:s + m] += filt(noise(m), "bandpass", [5000, 12000]) * np.sin(np.pi * ta(m) / 0.09) * 0.7
        return x
    if kind in ("copernicus", "galileo"):
        n = int(SR * 0.45)
        x = filt(noise(n), "bandpass", [2800, 6500]) * (0.3 + np.abs(filt(noise(n), "lowpass", 25)) * 5)
        return x * np.sin(np.pi * ta(n) / 0.45) * 0.35
    if kind == "map":
        return filt(whoosh(0.35, 900, 6500), "highpass", 800) * 0.7
    if kind == "dag":
        n = int(SR * 0.6)
        x = np.zeros(n)
        for s, gg in ((0, 1.0), (int(SR * 0.045), 0.7)):
            m = int(SR * 0.015)
            x[s:s + m] += filt(noise(m), "bandpass", [1200, 7000]) * env(m, 0.003, 0.0003) * gg
        x += filt(noise(n), "lowpass", 900) * env(n, 0.12, 0.01) * 0.6
        return x
    if kind == "eddington":
        return partials([2410, 5630, 8850], [0.3, 0.18, 0.1], [0.5, 0.25, 0.12], 0.8, 0.0005)
    if kind == "tulip":
        return partials([1568, 2093, 3136], [0.3, 0.2, 0.08], [1.2, 0.9, 0.5], 1.6, 0.002)
    if kind == "dojima":
        n = int(SR * 0.5)
        x = np.zeros(n)
        for s in (0, int(SR * 0.16)):
            m = int(SR * 0.08)
            c = filt(noise(m), "bandpass", [1500, 4200]) * env(m, 0.006, 0.0003)
            c += partials([1120, 2310], [0.5, 0.3], [0.03, 0.02], 0.08, 0.0003)[:m]
            x[s:s + m] += c
        return x * 1.1
    if kind == "ticker":
        n = int(SR * 1.4)
        x = np.zeros(n)
        tt = 0.0
        while tt < 1.35:
            s = int(SR * tt)
            m = int(SR * 0.025)
            c = filt(noise(m), "highpass", 2500) * env(m, 0.0018, 0.0002) + 0.25 * np.sin(2 * np.pi * 2300 * ta(m)) * env(m, 0.006, 0.0005)
            x[s:s + m] += c[: n - s] * rng.uniform(0.35, 0.8)
            tt += rng.uniform(0.03, 0.07)
        return x * 0.5
    if kind == "genesis":
        n = int(SR * 0.6)
        x = np.zeros(n)
        for k in range(7):
            s = int(SR * k * 0.07)
            m = int(SR * 0.04)
            f = rng.choice([880, 1175, 1568, 1760, 2349])
            x[s:s + m] += np.sign(np.sin(2 * np.pi * f * ta(m))) * 0.12 * env(m, 0.02, 0.001)
        return filt(x, "lowpass", 6000)
    if kind == "radar":
        n = int(SR * 1.6)
        t = ta(n)
        return (np.sin(2 * np.pi * 1420 * t) * env(n, 0.35, 0.002) * 0.5 + np.sin(2 * np.pi * 2854 * t) * env(n, 0.12, 0.002) * 0.1) * 0.7
    return whoosh(0.3) * 0.35


def lv(points):
    xs, ys = zip(*points)
    return np.interp(ta(N), xs, ys)


t = ta(N)
level = lv([(0, 0), (1.0, 0.55), (3.0, 0.6), (11.0, 0.72), (23.0, 0.85), (31.0, 1.0), (BLACK, 1.15), (OPEN, 0.7), (END["out"], 0.6), (DUR, 0)])
drone = np.zeros((N, 2))
fc = 420 + 220 * np.sin(2 * np.pi * 0.031 * t) + 260 * np.clip((t - 11) / 26, 0, 1)
for f0, base in ((73.42, 1.0), (110.0, 0.55), (36.71, 0.8)):
    for h in range(1, 15):
        fh = f0 * h
        w = base / h ** 1.1 * (0.3 + np.exp(-((fh - fc) / 260) ** 2))
        for ch, det in ((0, -0.11), (1, 0.13)):
            drone[:, ch] += w * np.sin(2 * np.pi * (fh + det * h) * t + h * 1.7 + ch)
dry += drone * 0.075 * level[:, None]
send += drone * 0.02 * level[:, None]
wind = np.stack([filt(noise(N), "lowpass", 380), filt(noise(N), "lowpass", 380)], axis=1)
dry += wind * (0.5 + 0.5 * np.sin(2 * np.pi * 0.09 * t))[:, None] * 0.05 * level[:, None]

D2, F2, G2, A2, Bb2 = 73.42, 87.31, 98.0, 110.0, 116.54
D3, E3, F3, Fs3, G3, A3, Bb3, Cs3, D4 = 146.83, 164.81, 174.61, 185.0, 196.0, 220.0, 233.08, 138.59, 293.66
for notes, a, b, vow, g in (
    ([D3, A3], 1.0, 11.8, "a", 0.55),
    ([D3, F3, A3], 11.0, 19.6, "a", 0.6),
    ([Bb2, D3, F3], 19.0, 23.6, "a", 0.62),
    ([Bb2, D3, F3], 23.0, 27.6, "o", 0.66),
    ([G2, Bb2, D3], 27.0, 28.9, "o", 0.68),
    ([A2, Cs3, E3, A3], 28.5, BLACK + 0.3, "a", 0.8),
    ([D3, Fs3, A3, D4], OPEN, DUR, "o", 0.7),
):
    c = choir(notes, a, b, vow, att=1.4 if a > 0 else 1.0, rel=1.6, level=g)
    place(c, a, 0.18, rev=0.6)

place(rev_swell(0.9), 0.1, 0.5, rev=0.4)
place(boom(), 1.0, 0.55, rev=0.25)
place(taiko(1.0, 52.0, 1.6), 1.0, 0.5, rev=0.4)
place(bowl(196.0, 6.0), 1.0, 0.28, rev=0.5)

for k in range(int(3.0 / BEAT), int(BLACK / BEAT)):
    bt = k * BEAT
    pos = k % 4
    if bt < 11.0:
        if pos == 0:
            place(taiko(1.0, 56.0), bt, 0.42, pan=-0.1, rev=0.35)
        elif pos == 2:
            place(taiko(0.55, 60.0), bt, 0.32, pan=0.15, rev=0.35)
    elif bt < 23.0:
        if pos in (0, 2):
            place(taiko(1.0 if pos == 0 else 0.7, 57.0), bt, 0.4, pan=-0.1, rev=0.3)
        place(tick(2600.0 if pos % 2 == 0 else 2150.0), bt, 0.12, pan=0.35, rev=0.2)
    elif bt < 31.0:
        place(taiko(1.0 if pos == 0 else 0.65, 58.0), bt, 0.42, pan=0.0, rev=0.3)
        place(tick(2600.0), bt, 0.09, pan=0.35, rev=0.2)
        place(tick(2150.0), bt + BEAT / 2, 0.06, pan=-0.35, rev=0.2)

mt = 31.0
while mt < BLACK - 1e-6:
    step = 0.25 if mt < 33.0 else (1 / 6 if mt < 35.0 else 1 / 12)
    k = (mt - 31.0) / (BLACK - 31.0)
    if step >= 1 / 6:
        place(taiko(0.6 + 0.4 * k, 60.0), mt, 0.4, pan=rng.uniform(-0.3, 0.3), rev=0.3)
    else:
        place(taiko(0.5 + 0.4 * k, 170.0, 0.4), mt, 0.28, pan=rng.uniform(-0.4, 0.4), rev=0.3)
    place(tick(2400.0 + 600.0 * k), mt, 0.07 + 0.05 * k, pan=rng.uniform(-0.5, 0.5), rev=0.2)
    mt += step

n = int(SR * (BLACK - 30.0))
tt = ta(n)
k = tt / (BLACK - 30.0)
src = noise(n)
rz = np.zeros(n)
for i in range(0, n, 512):
    lo = 200 + 3800 * k[i] ** 1.6
    rz[i:i + 512] = filt(src[i:i + 512], "bandpass", [lo, lo * 2.4])
shep = np.zeros(n)
for o in range(6):
    f = 55 * 2 ** (o + 1.6 * k)
    amp = np.exp(-((np.log2(f) - np.log2(440)) / 1.3) ** 2)
    shep += amp * np.sin(2 * np.pi * np.cumsum(f) / SR)
riser = (rz * 0.7 + shep * 0.3) * k ** 2.4
place(riser, 30.0, 0.35, rev=0.3)

for i, s in enumerate(SHOTS):
    if s["s"] in ("space", "black") or s.get("montage"):
        continue
    nxt = SHOTS[i + 1]["t"] if i + 1 < len(SHOTS) else DUR
    kind = s["s"]
    stamped = bool(s.get("stamp"))
    x = foley(kind) if stamped else whoosh(0.28) * 0.4
    place(x, s["t"], 0.5 if stamped else 0.22, pan=float(rng.uniform(-0.3, 0.3)), rev=0.45)

for w in TL["words"]:
    place(rev_swell(0.45), w["t0"] - 0.45, 0.35, rev=0.3)
    place(taiko(0.8, 44.0, 1.2), w["t0"], 0.32, rev=0.2)

place(boom(), OPEN, 0.75, rev=0.3)
place(taiko(1.0, 48.0, 1.8), OPEN, 0.55, rev=0.45)
place(bowl(196.0, 8.0), OPEN, 0.4, rev=0.55)
place(whoosh(0.9, 400, 6000, rise=False), OPEN + 0.04, 0.3, rev=0.4)
for k in range(9):
    f = rng.choice([1174.7, 1480.0, 1760.0, 2349.3, 2960.0, 3520.0])
    place(partials([f, f * 2.01], [0.2, 0.06], [1.6, 0.6], 2.0, 0.004), OPEN + 0.15 + k * 0.17, 0.12, pan=float(rng.uniform(-0.7, 0.7)), rev=0.7)
place(whoosh(1.2, 300, 2500, rise=True) * 0.6, END["lock"] - 0.3, 0.25, rev=0.5)
tink = partials([1318.5, 1975.5, 2637.0], [0.3, 0.22, 0.06], [0.35, 0.28, 0.12], 0.9, 0.0015)
place(tink, END["button"] + 0.05, 0.35, rev=0.35)

ir_n = int(SR * 4.0)
it = ta(ir_n)
ir = np.zeros((ir_n, 2))
for ch in range(2):
    low = filt(noise(ir_n), "lowpass", 600) * np.exp(-it / 0.62)
    mid = filt(filt(noise(ir_n), "highpass", 600), "lowpass", 3800) * np.exp(-it / 0.45)
    high = filt(noise(ir_n), "highpass", 3800) * np.exp(-it / 0.2)
    tail = (low + mid * 0.8 + high * 0.35) * np.clip(it / 0.025, 0, 1)
    er = np.zeros(ir_n)
    for d, g in ((0.011, 0.6), (0.019, 0.45), (0.027, 0.4), (0.041, 0.3), (0.053, 0.28), (0.067, 0.2), (0.083, 0.16)):
        er[int((d + rng.uniform(0, 0.004)) * SR)] += g * rng.choice([-1.0, 1.0])
    ir[:, ch] = er * 0.5 + tail
ir /= np.sqrt((ir ** 2).sum(0, keepdims=True))
wet = np.stack([fftconvolve(send[:, c], ir[:, c])[:N] for c in range(2)], axis=1)
mix = dry + wet * 0.55
mix = filt(mix.T, "highpass", 25).T

blk = 256
nb = N // blk
pw = np.sqrt(np.mean(mix[: nb * blk].reshape(nb, blk, 2) ** 2, axis=(1, 2)) + 1e-12)
db = 20 * np.log10(pw)
thr, ratio = -20.0, 2.5
target = np.where(db > thr, (thr + (db - thr) / ratio) - db, 0.0)
gr = np.zeros(nb)
g = 0.0
a_att = np.exp(-blk / (SR * 0.01))
a_rel = np.exp(-blk / (SR * 0.25))
for i in range(nb):
    c = a_att if target[i] < g else a_rel
    g = c * g + (1 - c) * target[i]
    gr[i] = g
gain = 10 ** (np.interp(np.arange(N), np.arange(nb) * blk + blk / 2, gr) / 20)
mix *= gain[:, None]
gate = np.ones(N)
gate[(t >= BLACK) & (t < OPEN)] = 0.0
fade = int(SR * 0.006)
b0 = int(BLACK * SR)
gate[b0 - fade:b0] = np.linspace(1, 0, fade)
mix *= gate[:, None]
mix = np.tanh(mix * 1.6) / np.tanh(1.6)
mix *= 0.89 / max(1e-9, np.max(np.abs(mix)))
out = HERE / (sys.argv[1] if len(sys.argv) > 1 else "audio.wav")
with wave.open(str(out), "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype("<i2").tobytes())
print("audio", out, DUR, "s")
