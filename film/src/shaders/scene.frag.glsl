#version 300 es
precision highp float;
uniform vec2 uRes;
uniform float uR;
uniform int uScene;
uniform float uT;
uniform float uG;
uniform float uP;
uniform float uSeed;
uniform float uMono;
uniform float uCor;
uniform float uInner;
uniform float uGrain;
uniform float uWrite;
uniform vec2 uSun;
uniform float uZoom;
uniform float uRot;
uniform float uFlash;
uniform float uPulse;
uniform float uStars;
uniform sampler2D uTick;
uniform sampler2D uTxt;
uniform sampler2D uTxt2;
uniform sampler2D uTxt3;
out vec4 fragColor;
const float PI = 3.14159265359;
const float TAU = 6.28318530718;
float S;

float h1(float n){ return fract(sin(n * 12.9898) * 43758.5453); }
float h2(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
vec2 h22(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }
float h3(vec3 p){ p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(h2(i), h2(i + vec2(1, 0)), u.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), u.x), u.y); }
float vn3(vec3 p){ vec3 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
             mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; mat2 m = mat2(1.6, 1.2, -1.2, 1.6); for (int i = 0; i < 5; i++){ s += a * vn(p); p = m * p; a *= 0.5; } return s; }
float fbm3(vec2 p){ float s = 0.0, a = 0.5; mat2 m = mat2(1.6, 1.2, -1.2, 1.6); for (int i = 0; i < 3; i++){ s += a * vn(p); p = m * p; a *= 0.5; } return s / 0.875; }
mat2 rot(float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }
vec3 vor(vec2 x){ vec2 n = floor(x), f = fract(x); float d1 = 8.0, d2 = 8.0; vec2 id = n;
  for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++){ vec2 g = vec2(i, j); vec2 o = h22(n + g); vec2 r = g + o - f; float d = dot(r, r);
    if (d < d1){ d2 = d1; d1 = d; id = n + g; } else if (d < d2){ d2 = d; } }
  return vec3(sqrt(d1), sqrt(d2), h2(id)); }
float ln(float d, float w){ return 1.0 - smoothstep(w - S, w + S, d); }
float stripes(float x, float w){ float fw = fwidth(x); float d = abs(fract(x) - 0.5); return 1.0 - smoothstep(w - fw, w + fw, d); }
float arcDist(float a, float n, float r){ return (0.5 - abs(fract(a / TAU * n) - 0.5)) * TAU * r / n; }

vec3 stars(vec2 P){
  vec3 c = vec3(0.0);
  for (int l = 0; l < 3; l++){
    float sz = 11.0 + float(l) * 9.0;
    vec2 g = P / sz + float(l) * 17.3; vec2 id = floor(g); vec2 f = fract(g);
    float r = h2(id);
    if (r > 0.88){
      vec2 o = h22(id + 5.1) * 0.7 + 0.15;
      float d = length(f - o) * sz;
      float b = pow(h2(id + 9.7), 4.0) * (0.75 + 0.25 * sin(uG * (0.8 + r * 2.0) + r * 50.0));
      c += b * exp(-d * d * 1.1) * mix(vec3(0.78, 0.86, 1.0), vec3(1.0, 0.93, 0.85), h2(id + 2.0));
    }
  }
  return c * 1.3;
}

vec3 sSpace(vec2 q, vec2 P){
  float r = length(q);
  vec2 d = q - uSun; float rs = length(d); float a = atan(d.y, d.x);
  float rr = max(rs - 1.0, 0.0);
  vec2 w = vec2(cos(a), sin(a));
  float lr = log(1.0 + rr * 2.0);
  float s1 = vn3(vec3(w * 2.3 + uSeed, lr * 1.4 - uG * 0.04));
  float s2 = vn3(vec3(w * 6.5 + 7.0, lr * 2.6 - uG * 0.07));
  float st = pow(vn3(vec3(w * 24.0, rr * 0.3 + 3.0 - uG * 0.02)), 2.5);
  float st2 = pow(vn3(vec3(w * 70.0, rr * 0.8 + 9.0)), 3.0);
  float corona = exp(-rr * 2.8) * (0.2 + 0.95 * pow(s1, 2.0)) + exp(-rr * 10.0) * 0.75 * s2
               + exp(-rr * 1.2) * 0.6 * st * smoothstep(0.2, 0.75, s1) + exp(-rr * 5.0) * 0.35 * st2;
  corona += exp(-rr * 0.55) * 0.045;
  vec3 back = mix(vec3(0.82, 0.88, 1.0), vec3(1.0, 0.97, 0.92), exp(-rr * 4.0)) * corona * uCor * (1.0 + uPulse);
  float prom = smoothstep(0.64, 0.82, vn(vec2(a * 7.0 + uSeed, uG * 0.05))) * exp(-rr * 40.0) * smoothstep(0.996, 1.004, rs);
  back += vec3(1.0, 0.26, 0.36) * prom * 0.9 * uCor * (1.0 - uMono);
  float ls = length(uSun);
  float exposed = smoothstep(0.0, 0.3, ls);
  back += stars(P) * (1.0 - exposed * 0.85) * uStars;
  float sunDisc = 1.0 - smoothstep(1.0 - S, 1.0 + S, rs);
  float limb = sqrt(max(1.0 - rs * rs, 0.0));
  back += vec3(1.0, 0.96, 0.9) * (0.65 + 0.35 * limb) * 5.0 * sunDisc * uStars;
  float moon = 1.0 - smoothstep(0.999 - S, 0.999 + S, r);
  vec3 col = back * (1.0 - moon) + moon * vec3(0.006, 0.007, 0.009) * (0.6 + 0.4 * fbm(q * 3.0));
  float glow = exp(-max(r - 1.0, 0.0) * 4.0) * exposed * 0.9 + exp(-max(r - 1.0, 0.0) * 1.2) * exposed * 0.3;
  vec2 dir = ls > 1e-5 ? uSun / ls : vec2(0.0, 1.0);
  float side = clamp(dot(normalize(q + 1e-5), dir), 0.0, 1.0);
  col += vec3(1.0, 0.95, 0.88) * glow * pow(side, 3.0) * (1.0 - moon);
  if (ls > 1e-5){
    vec2 db = q - dir; float bd = length(db);
    float bi = smoothstep(0.0, 0.004, ls) * (1.0 - smoothstep(0.03, 0.16, ls));
    vec2 dbr = db;
    float spikes = exp(-abs(dbr.y) * 120.0) * exp(-abs(dbr.x) * 2.6) + exp(-abs(dbr.x) * 120.0) * exp(-abs(dbr.y) * 2.6);
    col += vec3(1.0, 0.97, 0.92) * bi * (exp(-bd * bd * 1400.0) * 8.0 + exp(-bd * 11.0) * 1.1 + spikes * 0.7);
  }
  col = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))), uMono);
  return col;
}

vec3 sBone(vec2 q, vec2 p){
  float r = length(q);
  vec2 pr = rot(0.35) * p;
  float fib = fbm(pr * vec2(1.4, 15.0) + uSeed);
  float stain = fbm(p * 1.1 + 3.0);
  vec3 col = mix(vec3(0.78, 0.71, 0.56), vec3(0.91, 0.86, 0.73), fib);
  col = mix(col, col * vec3(0.76, 0.63, 0.47), smoothstep(0.45, 0.8, stain) * 0.8);
  vec3 v = vor(p * 13.0);
  col *= 1.0 - 0.4 * (1.0 - smoothstep(0.03, 0.08, v.x)) * step(0.72, v.z);
  float burn = smoothstep(1.6, 1.0, r + 0.3 * (fbm(q * 3.0 + uSeed) - 0.5));
  col = mix(col, vec3(0.30, 0.15, 0.06), burn * 0.88);
  col = mix(col, vec3(0.05, 0.03, 0.02), smoothstep(1.14, 1.0, r + 0.08 * (fbm(q * 6.0) - 0.5)));
  float grow = smoothstep(0.0, 0.7, uP);
  float y = q.y;
  float cx = 0.035 * sin(y * 7.0 + uSeed) + 0.09 * (fbm(vec2(y * 3.0, uSeed)) - 0.5);
  float L = 1.0 + 1.2 * grow;
  float wm = 0.011 * (1.0 - clamp((y - 1.0) / 1.7, 0.0, 1.0)) + 0.0025;
  float dm = abs(q.x - cx);
  float crack = ln(dm, wm) * step(0.95, y) * step(y, L);
  float wm2 = 0.011 * (1.0 - clamp((-y - 1.0) / 1.4, 0.0, 1.0)) + 0.0025;
  crack = max(crack, ln(dm, wm2) * step(y, -0.95) * step(-1.0 - 0.9 * grow, y));
  float y0 = 1.5;
  vec2 o = vec2(0.035 * sin(y0 * 7.0 + uSeed) + 0.09 * (fbm(vec2(y0 * 3.0, uSeed)) - 0.5), y0);
  vec2 bd = normalize(vec2(0.82, 0.57));
  float bx = dot(q - o, bd);
  float by = dot(q - o, vec2(-bd.y, bd.x)) - 0.03 * sin(bx * 9.0) - 0.05 * (fbm(vec2(bx * 4.0, 7.0)) - 0.5);
  float bL = 1.0 * smoothstep(0.25, 0.85, uP);
  crack = max(crack, ln(abs(by), 0.007 * (1.0 - bx / 1.3) + 0.002) * step(0.0, bx) * step(bx, bL));
  vec3 vv = vor(q * 8.0 + uSeed);
  crack = max(crack, ln(vv.y - vv.x, 0.01) * smoothstep(1.7, 1.15, r) * step(1.02, r) * 0.55 * grow);
  col = mix(col, vec3(0.09, 0.045, 0.025), crack);
  float glint = ln(dm - wm - 0.004, 0.0015) * step(0.95, y) * step(y, L) * 0.35;
  col += glint * vec3(1.0, 0.95, 0.85) * 0.4;
  float sx = (abs(q.x) + 3.2) / 0.34; float col_ = floor(sx);
  if (abs(q.x) > 1.9 && abs(q.y) < 1.7){
    vec2 cell = vec2(col_, floor(q.y / 0.3));
    vec2 lc = vec2(fract(sx) - 0.5, fract(q.y / 0.3) - 0.5);
    float g = 0.0;
    for (int k = 0; k < 5; k++){
      float hk = h2(cell + float(k) * 3.7);
      vec2 a0 = (h22(cell + float(k)) - 0.5) * 0.5;
      float qa = floor(hk * 4.0) * PI / 4.0;
      vec2 dd = vec2(cos(qa), sin(qa));
      float t = clamp(dot(lc - a0, dd), -0.2 - 0.1 * h2(cell + float(k)), 0.2);
      g = max(g, 1.0 - smoothstep(0.022, 0.045, length(lc - a0 - dd * t)));
    }
    col = mix(col, col * 0.55, g * step(0.35, h2(cell + 11.0)) * 0.8);
  }
  return col;
}

vec3 sEngrave(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x) + uT * 0.08 + uSeed;
  vec3 paper = vec3(0.91, 0.88, 0.79) * (0.93 + 0.07 * fbm(p * 5.0));
  paper = mix(paper, vec3(0.78, 0.66, 0.48), smoothstep(0.7, 0.85, fbm(p * 1.7 + 11.0)) * 0.45);
  float yy = q.y * 26.0 + 0.12 * sin(q.x * 3.0) + 0.25 * fbm(q * 2.0);
  float dark = clamp(length(q * vec2(0.5, 0.8)) / 1.8, 0.0, 1.0);
  float sky = stripes(yy, mix(0.06, 0.3, dark));
  float N = 32.0; float sec = TAU / N; float k = floor(a / sec + 0.5); float th = a - k * sec;
  float wavy = step(0.5, mod(k, 2.0));
  float rr = r - 1.12;
  float len = mix(1.5, 1.05, wavy);
  float u = clamp(rr / len, 0.0, 1.0);
  float tw = th * r + wavy * 0.05 * sin(rr * 20.0) * smoothstep(0.0, 0.15, rr) * (1.0 - u);
  float hw = mix(0.1, 0.06, wavy) * (1.0 - u);
  float inside = step(0.0, rr) * step(rr, len);
  float inRay = inside * (1.0 - smoothstep(hw - S, hw + S, abs(tw)));
  float outline = inside * ln(abs(abs(tw) - hw), 0.004);
  float hatch = inRay * step(0.0, tw) * stripes(rr * 34.0, 0.16);
  float clear = max(inRay, smoothstep(1.32, 1.18, r));
  float ink = max(sky * (1.0 - clear), max(outline, hatch));
  ink = max(ink, ln(abs(r - 1.035), 0.006) + ln(abs(r - 1.075), 0.003) + ln(abs(r - 1.105), 0.0022));
  vec2 c1 = rot(0.785) * q, c2 = rot(-0.785) * q;
  float ch = max(stripes(c1.y * 30.0, 0.2), stripes(c2.y * 30.0, 0.2));
  ink = max(ink, ch * step(r, 1.0));
  ink *= 0.82 + 0.18 * vn(q * 90.0);
  return mix(paper, vec3(0.07, 0.06, 0.05), clamp(ink, 0.0, 1.0));
}

vec3 sGold(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x);
  float b = fbm(p * 6.0 + uSeed);
  vec3 base = vec3(0.80, 0.59, 0.22);
  vec2 g = p / 0.55 + vec2(0.17, 0.31); vec2 gf = abs(fract(g) - 0.5);
  float seam = smoothstep(0.486, 0.497, max(gf.x, gf.y));
  vec3 v = vor(p * 7.5 + uSeed * 3.0); float crack = (1.0 - smoothstep(0.0, 0.012, v.y - v.x)) * smoothstep(0.35, 0.7, fbm(p * 2.0 + 4.0));
  float sheen = 0.5 + 0.5 * sin(dot(q, vec2(0.9, 0.5)) * 1.4 + uT * 2.2 + uSeed);
  vec3 col = base * (0.45 + 0.75 * sheen) * (0.82 + 0.35 * b);
  col += vec3(1.0, 0.9, 0.6) * pow(sheen, 10.0) * 0.55 * (0.6 + 0.4 * b);
  col = mix(col, col * 1.18, seam * 0.6);
  col = mix(col, vec3(0.42, 0.13, 0.07), crack * 0.45);
  float inc = ln(abs(r - 1.06), 0.005) + ln(abs(r - 1.10), 0.003) + ln(abs(r - 1.46), 0.003) + ln(abs(r - 1.50), 0.005);
  float rays = ln(arcDist(a, 132.0, r), 0.0025) * step(1.12, r) * step(r, 1.44) * 0.55;
  float th = (fract(a / TAU * 96.0) - 0.5) * TAU / 96.0 * r; float dd = length(vec2(th, r - 1.28));
  float punch = 1.0 - smoothstep(0.012 - S, 0.012 + S, dd);
  float rim = ln(abs(dd - 0.013), 0.0025);
  float th2 = (fract(a / TAU * 24.0) - 0.5) * TAU / 24.0 * r; vec2 rc = vec2(th2, r - 1.37);
  float ros = 0.0;
  for (int i = 0; i < 6; i++){ float ang = float(i) * TAU / 6.0; ros = max(ros, 1.0 - smoothstep(0.008 - S, 0.008 + S, length(rc - 0.022 * vec2(cos(ang), sin(ang))))); }
  float hl = clamp(inc + rays, 0.0, 1.0);
  col = mix(col, col * 0.42, hl);
  col = mix(col, col * 0.35, max(punch, ros));
  col += vec3(1.0, 0.85, 0.5) * rim * 0.25;
  return col;
}

vec3 sSun(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x);
  vec2 x = p * 7.0; vec2 n = floor(x), f = fract(x); float d1 = 8.0, d2 = 8.0;
  for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++){
    vec2 g = vec2(i, j); vec2 o = 0.5 + 0.4 * sin(uG * 1.4 + TAU * h22(n + g)); vec2 rv = g + o - f; float d = dot(rv, rv);
    if (d < d1){ d2 = d1; d1 = d; } else if (d < d2){ d2 = d; } }
  d1 = sqrt(d1); d2 = sqrt(d2);
  float lane = smoothstep(0.0, 0.32, d2 - d1);
  float cell = sqrt(clamp(1.0 - d1 * 0.85, 0.0, 1.0)) * lane * (0.8 + 0.4 * h2(floor(x) + 3.0));
  float bright = 0.3 + 0.62 * cell + 0.12 * (fbm(p * 26.0) - 0.5);
  vec2 w = vec2(cos(a), sin(a));
  float edge = 1.7 + 0.2 * (vn(w * 2.0 + uSeed) - 0.5);
  float pen = smoothstep(edge + 0.05, edge - 0.05, r);
  float fil = vn3(vec3(w * 28.0, r * 2.4 + uSeed));
  fil = 0.2 + 0.8 * smoothstep(0.25, 0.85, fil);
  bright = mix(bright, (0.14 + 0.5 * fil) * smoothstep(0.98, 1.3, r) + 0.06, pen);
  vec3 col = mix(vec3(0.24, 0.03, 0.0), vec3(1.0, 0.5, 0.07), bright);
  col = mix(col, vec3(1.0, 0.86, 0.55), pow(clamp(bright, 0.0, 1.0), 3.0) * 0.8);
  return col;
}

vec3 heat(float t){
  t = clamp(t, 0.0, 1.0);
  vec3 c = mix(vec3(0.02, 0.0, 0.06), vec3(0.28, 0.02, 0.45), smoothstep(0.0, 0.25, t));
  c = mix(c, vec3(0.80, 0.08, 0.44), smoothstep(0.2, 0.45, t));
  c = mix(c, vec3(0.98, 0.46, 0.08), smoothstep(0.45, 0.7, t));
  c = mix(c, vec3(1.0, 0.93, 0.58), smoothstep(0.7, 0.95, t));
  return c;
}

vec3 sThermal(vec2 q, vec2 p){
  float r = length(q);
  float f = fbm(p * 1.2 + vec2(0.0, -uT * 1.6) + uSeed);
  float bands = 0.16 * sin(q.x * 7.0 + f * 4.0);
  float v = f * 0.8 + bands + exp(-(r - 1.0) * 1.6) * 0.5 - 0.08;
  return heat(v);
}

vec3 sInk(vec2 q, vec2 p){
  float r = length(q);
  vec2 w = p + 0.7 * vec2(fbm(p * 1.1 + uT * 0.6 + uSeed), fbm(p * 1.1 + 4.3 - uT * 0.5));
  float f = fbm(w * 1.6);
  float rad = exp(-(r - 1.0) * 1.1);
  float d = f * 0.85 + rad * 0.42 - 0.25 - 0.55 * exp(-max(r - 1.0, 0.0) * 16.0);
  float ink = smoothstep(0.3, 0.6, d);
  float edge = smoothstep(0.28, 0.34, d) - smoothstep(0.34, 0.44, d);
  vec3 col = mix(vec3(0.90, 0.89, 0.86), vec3(0.02, 0.025, 0.04), ink);
  col = mix(col, vec3(0.28, 0.3, 0.36), edge * 0.5);
  return col;
}

float wedgeD(vec2 u, float hl, float hw, float tl, float tw){
  float d = 0.0;
  if (u.x > 0.0 && u.x < hl){ float hh = hw * (1.0 - u.x / hl); d = max(d, 1.0 - abs(u.y) / max(hh, 1e-4)); }
  if (u.x > 0.0 && u.x < tl){ d = max(d, (1.0 - abs(u.y) / tw) * 0.5 * (1.0 - 0.5 * u.x / tl)); }
  return clamp(d, 0.0, 1.0);
}

float clayH(vec2 q){
  float h = 0.10 * fbm(q * 2.5 + uSeed) + 0.025 * vn(q * 28.0);
  float rowH = 0.17;
  float row = floor(q.y / rowH); float ly = (fract(q.y / rowH) - 0.5) * rowH;
  h -= 0.12 * (1.0 - smoothstep(0.0, 0.006, abs(abs(ly) - rowH * 0.5)));
  float cw = 0.14;
  float sh = h2(vec2(row, 7.0)) * cw;
  float cc = floor((q.x + sh) / cw); float lx = (fract((q.x + sh) / cw) - 0.5) * cw;
  vec2 id = vec2(cc, row);
  float r = length(q);
  float order = floor((2.0 - q.y) / rowH) + (q.x + 3.6) / 7.2;
  float vis = clamp((uWrite - order) * 5.0, 0.0, 1.0) * step(0.14, h2(id + uSeed)) * step(1.16, r);
  vec2 c = vec2(lx, ly);
  float typ = floor(h2(id + 3.1) * 6.0);
  float d = 0.0;
  if (typ < 1.0){ d = wedgeD(c - vec2(-0.045, 0.0), 0.032, 0.024, 0.09, 0.005); }
  else if (typ < 2.0){ vec2 u = vec2(0.048 - c.y, c.x); d = wedgeD(u, 0.03, 0.022, 0.09, 0.005); }
  else if (typ < 3.0){ vec2 u1 = vec2(0.048 - c.y, c.x + 0.024); vec2 u2 = vec2(0.048 - c.y, c.x - 0.024); d = max(wedgeD(u1, 0.028, 0.02, 0.085, 0.004), wedgeD(u2, 0.028, 0.02, 0.085, 0.004)); }
  else if (typ < 4.0){ vec2 u = rot(0.0) * (c - vec2(-0.025, 0.0)); d = max(wedgeD(vec2(u.x, u.y - u.x * 0.9), 0.045, 0.03, 0.0, 0.001), wedgeD(vec2(u.x, u.y + u.x * 0.9), 0.045, 0.03, 0.0, 0.001)) * 0.9; }
  else if (typ < 5.0){ d = max(wedgeD(c - vec2(-0.05, 0.03), 0.028, 0.02, 0.08, 0.004), wedgeD(vec2(0.04 - c.y, c.x - 0.01), 0.026, 0.019, 0.07, 0.004)); }
  else { for (int i = 0; i < 3; i++){ vec2 u = vec2(0.03 - c.y, c.x + 0.03 - float(i) * 0.03); d = max(d, wedgeD(u, 0.022, 0.014, 0.06, 0.003)); } }
  h -= 0.75 * d * vis;
  h -= 0.9 * smoothstep(1.04, 0.97, r);
  h += 0.11 * exp(-pow((r - 1.07) / 0.04, 2.0));
  return h;
}

vec3 sClay(vec2 q){
  float e = 0.0016;
  float h = clayH(q);
  float hx = clayH(q + vec2(e, 0.0)) - clayH(q - vec2(e, 0.0));
  float hy = clayH(q + vec2(0.0, e)) - clayH(q - vec2(0.0, e));
  vec3 n = normalize(vec3(-hx / (2.0 * e) * 0.1, -hy / (2.0 * e) * 0.1, 1.0));
  vec3 L = normalize(vec3(-0.62, 0.66, 0.38));
  float dif = clamp(dot(n, L), 0.0, 1.0);
  vec3 clay = mix(vec3(0.62, 0.46, 0.32), vec3(0.80, 0.66, 0.49), fbm(q * 1.8 + uSeed));
  clay = mix(clay, vec3(0.42, 0.33, 0.25), smoothstep(0.6, 0.85, fbm(q * 0.9 + 7.0)) * 0.6);
  vec3 col = clay * (0.22 + 0.95 * dif) * (0.72 + 0.28 * smoothstep(-0.5, 0.05, h));
  col += vec3(1.0, 0.9, 0.75) * pow(max(dot(reflect(-L, n), vec3(0.0, 0.0, 1.0)), 0.0), 18.0) * 0.08;
  return col;
}

float bronzeH(vec2 q, out float gear, out float hole){
  float r = length(q), a = atan(q.y, q.x);
  float h = 0.05 * fbm(q * 3.0 + uSeed) + 0.025 * fbm(q * 15.0);
  float b = 0.21, r0 = 1.2;
  float f = (r - r0) / b - a / TAU;
  float fr = fract(f);
  float dist = min(fr, 1.0 - fr) * b;
  float band = step(-0.05, f) * step(f, 4.05);
  h -= 0.22 * (1.0 - smoothstep(0.005, 0.013, dist)) * band;
  float turn = floor(f);
  float u = turn + a / TAU + 0.5;
  float cells = u * 55.75;
  float dt = (0.5 - abs(fract(cells) - 0.5)) * TAU * r / 55.75;
  float inBand = step(0.0, f) * step(f, 4.0) * step(0.025, dist);
  h -= 0.12 * (1.0 - smoothstep(0.003, 0.008, dt)) * inBand;
  float cid = floor(cells) + turn * 300.0;
  vec2 cc = vec2(fract(cells) - 0.5, fr - 0.5);
  h -= 0.1 * step(0.86, h1(cid + uSeed)) * (1.0 - smoothstep(0.12, 0.2, length(cc * vec2(1.0, 1.6)))) * inBand;
  vec2 gc = vec2(2.85, -1.8); vec2 gq = q - gc; float gr = length(gq); float ga = atan(gq.y, gq.x) + uT * 0.4;
  float tooth = abs(fract(ga / TAU * 72.0) - 0.5) * 2.0;
  float R = 1.55; float toothR = R + 0.055 * (1.0 - smoothstep(0.3, 0.7, tooth));
  gear = 1.0 - smoothstep(toothR - S * 2.0, toothR + S * 2.0, gr);
  float sd = (0.5 - abs(fract(ga / TAU * 4.0) - 0.5)) * TAU / 4.0 * gr;
  hole = step(0.42, gr) * step(gr, R - 0.17) * smoothstep(0.08, 0.1, sd);
  gear *= 1.0 - hole;
  h = mix(h, 0.32 + 0.03 * fbm(gq * 8.0) - 0.04 * ln(abs(gr - (R - 0.1)), 0.006), gear);
  h -= 0.5 * hole;
  h -= 0.6 * smoothstep(1.03, 0.98, r);
  h += 0.08 * exp(-pow((r - 1.06) / 0.035, 2.0));
  return h;
}

vec3 sBronze(vec2 q){
  float e = 0.0018; float g0, h0, gd, hd;
  float h = bronzeH(q, g0, h0);
  float hx = bronzeH(q + vec2(e, 0.0), gd, hd) - bronzeH(q - vec2(e, 0.0), gd, hd);
  float hy = bronzeH(q + vec2(0.0, e), gd, hd) - bronzeH(q - vec2(0.0, e), gd, hd);
  vec3 n = normalize(vec3(-hx / (2.0 * e) * 0.06, -hy / (2.0 * e) * 0.06, 1.0));
  vec3 L = normalize(vec3(-0.5, 0.6, 0.62));
  float dif = clamp(dot(n, L), 0.0, 1.0);
  float spec = pow(max(dot(reflect(-L, n), vec3(0.0, 0.0, 1.0)), 0.0), 24.0);
  float pat = smoothstep(0.46, 0.66, fbm(q * 4.6 + uSeed * 2.0) * 0.75 + fbm(q * 13.0) * 0.3 + 0.3 * (0.05 - h));
  vec3 metal = vec3(0.56, 0.37, 0.18);
  vec3 green = mix(vec3(0.24, 0.38, 0.32), vec3(0.50, 0.60, 0.52), fbm(q * 9.0));
  vec3 cup = vec3(0.42, 0.17, 0.09);
  vec3 alb = mix(metal, green, pat);
  alb = mix(alb, cup, smoothstep(0.62, 0.8, fbm(q * 4.0 + 13.0)) * 0.6);
  vec3 col = alb * (0.2 + 0.95 * dif) + vec3(1.0, 0.8, 0.55) * spec * (1.0 - pat) * 0.6;
  col *= 0.7 + 0.3 * smoothstep(-0.45, 0.1, h);
  col *= 1.0 - 0.75 * h0;
  return col;
}

vec3 sMap(vec2 q, vec2 p, vec2 P){
  vec3 paper = vec3(0.90, 0.86, 0.75) * (0.92 + 0.08 * fbm(p * 4.0));
  paper = mix(paper, vec3(0.74, 0.62, 0.44), smoothstep(0.72, 0.9, fbm(p * 1.3 + 5.0)) * 0.5);
  vec2 mp = p * 0.5 + vec2(uSeed, 1.3);
  float f = fbm(mp) + 0.22 * fbm(mp * 3.1);
  float lvl = 0.6;
  float fw = fwidth(f);
  float ink = 1.0 - smoothstep(0.0, 2.2 * fw, abs(f - lvl));
  float sea = step(f, lvl);
  float k = (lvl - f) / 0.02;
  float wl = sea * (1.0 - smoothstep(0.0, 1.6 * fw / 0.02, abs(fract(k) - 0.5) - 0.0)) ;
  wl = sea * stripes(k, 0.06) * step(k, 7.0) * (1.0 - k / 8.5);
  float hz = sea * step(7.0, k) * stripes(q.y * 30.0, 0.08) * 0.55;
  vec3 v = vor(p * 34.0);
  float stip = (1.0 - sea) * step(0.8, v.z) * (1.0 - smoothstep(0.035, 0.06, v.x)) * smoothstep(0.66, 0.95, f);
  float grat = max(stripes(p.x / 0.8, 0.012), stripes(p.y / 0.8, 0.012)) * 0.6;
  float slope = 0.12 + 0.06 * q.x;
  float dc = abs(q.y - (0.12 * q.x + 0.03 * q.x * q.x)) / sqrt(1.0 + slope * slope);
  float edges = ln(abs(dc - 1.0), 0.005);
  float dash = ln(dc, 0.004) * step(0.5, fract(q.x * 3.0));
  float ov = 0.0;
  for (int i = -2; i <= 2; i++){
    if (i == 0) continue;
    float cx = float(i) * 2.15; vec2 c = vec2(cx, 0.12 * cx + 0.03 * cx * cx);
    float e = length((q - c) / vec2(1.2, 0.95));
    ov = max(ov, ln(abs(e - 1.0) * 0.95, 0.004) * step(0.45, fract(atan(q.y - c.y, q.x - c.x) / TAU * 60.0)));
  }
  vec2 B = min(P, vec2(1920.0, 1080.0) - P);
  float bm = min(B.x, B.y);
  float frame = (1.0 - smoothstep(21.0, 22.0, bm)) * smoothstep(13.0, 14.0, bm);
  float bar = step(0.5, fract((B.x < B.y ? P.y : P.x) / 64.0));
  float border = max(ln(abs(bm - 22.0), 1.0 / 540.0 * 0.0 + 0.0) * 0.0, 0.0);
  float bink = frame * bar + (1.0 - smoothstep(0.6, 1.4, abs(bm - 22.0))) + (1.0 - smoothstep(0.6, 1.4, abs(bm - 13.0)));
  ink = max(ink, max(wl, max(hz, max(stip, grat))));
  ink = max(ink, max(edges, max(dash, ov)));
  ink = max(ink, clamp(bink, 0.0, 1.0));
  ink *= 0.84 + 0.16 * vn(q * 80.0);
  return mix(paper, vec3(0.10, 0.08, 0.07), clamp(ink, 0.0, 1.0));
}

vec3 sDag(vec2 q, vec2 P){
  float r = length(q);
  vec2 c = P - vec2(960.0, 540.0);
  vec2 hs = vec2(840.0, 480.0); float rad = 110.0;
  vec2 dq = abs(c) - hs + rad; float e = length(max(dq, 0.0)) + min(max(dq.x, dq.y), 0.0) - rad;
  float sheen = 0.5 + 0.5 * sin(dot(c, vec2(0.0019, 0.0011)) + uT * 1.6 + uSeed);
  vec3 silver = vec3(0.12, 0.125, 0.13) + vec3(0.11) * sheen;
  float rr = max(r - 1.0, 0.0); float a = atan(q.y, q.x); vec2 w = vec2(cos(a), sin(a));
  float img = exp(-rr * 2.3) * (0.5 + 0.5 * vn3(vec3(w * 3.0, rr * 1.5 + uSeed))) + exp(-rr * 9.0) * 0.55;
  img *= smoothstep(0.985, 1.03, r);
  img += 0.04 * fbm(q * 5.0);
  vec3 col = mix(silver, vec3(0.86, 0.86, 0.82), clamp(img, 0.0, 1.0));
  float th = smoothstep(-170.0, 0.0, e + 90.0 * (fbm(P * 0.006 + uSeed) - 0.5));
  vec3 irid = 0.5 + 0.5 * cos(TAU * (th * 0.9 + 0.55 + vec3(0.0, 0.33, 0.67)));
  irid = mix(irid, vec3(dot(irid, vec3(0.33))), 0.4) * 0.6;
  col = mix(col, irid, th * 0.6);
  float sc = 0.0;
  for (int i = 0; i < 9; i++){
    float fi = float(i);
    vec2 o = vec2(h1(fi * 3.1 + uSeed), h1(fi * 7.7 + uSeed)) * vec2(1920.0, 1080.0);
    float ang = h1(fi * 1.3 + 0.5) * PI; vec2 dir = vec2(cos(ang), sin(ang));
    vec2 rel = P - o; float along = dot(rel, dir); float perp = abs(dot(rel, vec2(-dir.y, dir.x)));
    sc += exp(-perp * perp * 2.0) * step(abs(along), 120.0 + 320.0 * h1(fi + 2.0)) * 0.3;
  }
  col += sc * 0.45;
  vec3 v = vor(P * 0.035 + uSeed);
  col += step(0.94, v.z) * (1.0 - smoothstep(0.02, 0.05, v.x)) * 0.35;
  float pat = 0.5 + 0.5 * sin(atan(c.y, c.x) * 48.0) * sin(length(c) * 0.09);
  vec3 brass = vec3(0.64, 0.49, 0.24) * (0.7 + 0.3 * fbm(P * 0.012)) * (0.82 + 0.3 * pat);
  brass += vec3(0.5, 0.42, 0.25) * pow(0.5 + 0.5 * sin(dot(c, vec2(0.004, 0.003)) + uT * 0.7), 6.0) * 0.4;
  float bevel = exp(-pow((e - 7.0) / 5.0, 2.0));
  col = mix(col, brass, smoothstep(-1.5, 1.5, e));
  col += bevel * vec3(0.55, 0.45, 0.26);
  col *= 1.0 - 0.6 * exp(-pow((e + 4.0) / 6.0, 2.0)) * step(e, 0.0);
  return col;
}

vec3 sAstro(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x);
  float ang = a + uT * 0.18 + uSeed;
  vec3 brass = vec3(0.72, 0.55, 0.27) * (0.85 + 0.2 * fbm(p * 3.0));
  float an = pow(abs(cos(a - 0.8 - uT * 0.4)), 5.0);
  float brush = 0.9 + 0.1 * vn(vec2(r * 300.0, 0.0));
  vec3 col = brass * (0.5 + 0.6 * an) * brush + vec3(1.0, 0.9, 0.65) * pow(an, 28.0) * 0.4;
  float ink = 0.0;
  ink = max(ink, ln(abs(r - 1.05), 0.004) + ln(abs(r - 1.09), 0.0025) + ln(abs(r - 1.29), 0.0025) + ln(abs(r - 1.33), 0.004) + ln(abs(r - 1.66), 0.003));
  float idx = floor(ang / TAU * 360.0 + 0.5);
  float tl = mod(idx, 10.0) < 0.5 ? 0.2 : (mod(idx, 5.0) < 0.5 ? 0.13 : 0.07);
  ink = max(ink, ln(arcDist(ang + PI / 360.0, 360.0, r), 0.0018) * step(1.09, r) * step(r, 1.09 + tl));
  ink = max(ink, ln(arcDist(ang, 12.0, r), 0.003) * step(1.33, r) * step(r, 1.66));
  float zz = (fract(ang / TAU * 12.0) - 0.5) * TAU / 12.0 * r;
  vec2 zc = vec2(zz, r - 1.495);
  ink = max(ink, ln(abs(length(zc) - 0.07), 0.003) * 0.9);
  ink = max(ink, ln(abs(length(zc - vec2(0.0, 0.035)) - 0.025), 0.0025) * 0.7);
  vec2 ec = rot(uT * 0.06) * vec2(0.0, -0.45); float er = length(q - ec);
  float rete = (1.0 - smoothstep(0.045 - S, 0.045 + S, abs(er - 1.95))) * step(1.1, r);
  float reteEdge = ln(abs(abs(er - 1.95) - 0.045), 0.003) * step(1.1, r);
  vec3 dark = brass * 0.55 * (0.7 + 0.5 * an);
  col = mix(col, dark, rete);
  col = mix(col, col * 0.35, clamp(ink, 0.0, 1.0) * (1.0 - rete));
  col = mix(col, vec3(0.15, 0.1, 0.05), reteEdge * 0.7);
  for (int i = 0; i < 5; i++){
    float fi = float(i); float sa = fi * 1.31 + 0.4 + uT * 0.06; vec2 sp = vec2(cos(sa), sin(sa)) * (2.15 + 0.3 * h1(fi));
    vec2 sd = q - sp; float da = length(sd);
    float flame = 1.0 - smoothstep(0.02, 0.03, da + 0.03 * sin(atan(sd.y, sd.x) * 3.0));
    col = mix(col, dark * 0.9, flame);
  }
  return col;
}

vec3 sDojima(vec2 q, vec2 p, vec2 P){
  float r = length(q), a = atan(q.y, q.x);
  vec3 paper = vec3(0.93, 0.90, 0.83) * (0.94 + 0.06 * fbm(p * 6.0));
  float fib = 0.0;
  for (int i = 0; i < 3; i++){ vec2 pr = rot(float(i) * 1.9 + uSeed) * p; fib += smoothstep(0.8, 0.95, vn(pr * vec2(2.0, 70.0))); }
  paper -= fib * 0.03;
  float s = mod(2.2 - a, TAU) / TAU;
  float draw = smoothstep(0.0, 0.75, uP) * 0.93;
  float press = 0.82 + 0.18 * vn(vec2(s * 6.0, uSeed)) - 0.45 * smoothstep(0.7, 1.0, s);
  float w = 0.09 * press;
  float dr = abs(r - 1.14 - 0.015 * sin(s * 9.0));
  float dry = smoothstep(0.38, 0.6, vn(vec2(s * 70.0, (r - 1.14) / w * 3.0 + uSeed))) * smoothstep(0.45, 0.95, s);
  float enso = (1.0 - smoothstep(w - S * 1.5, w + S * 1.5, dr + 0.012 * (vn(q * 50.0) - 0.5))) * step(s, draw) * (1.0 - dry);
  float M = 64.0; float k = floor(a / TAU * M + 0.5); float th = (a - k / M * TAU) * r;
  float hk = h1(k * 1.7 + uSeed); float hk2 = h1(k * 3.3 + uSeed + 1.0);
  float b0 = 1.45 + 0.22 * sin(k * 0.37 + uSeed) + 0.12 * sin(k * 1.3) + 0.12 * hk;
  float len = 0.05 + 0.3 * hk2 * hk2;
  float grow = smoothstep(0.0, 0.5, uP - 0.25 * h1(k + 4.0));
  float body = (1.0 - smoothstep(0.017 - S, 0.017 + S, abs(th))) * step(b0, r) * step(r, b0 + len * grow);
  float wick = ln(abs(th), 0.0025) * step(b0 - 0.08 * grow, r) * step(r, b0 + (len + 0.08) * grow);
  float up = step(0.45, hk);
  float rag = 0.85 + 0.15 * vn(q * 120.0);
  vec3 red = vec3(0.80, 0.21, 0.12); vec3 black = vec3(0.06, 0.055, 0.05);
  vec3 col = paper;
  col = mix(col, mix(black, red, up), max(body, wick) * rag);
  col = mix(col, black, enso * rag);
  vec2 sc = P - vec2(1652.0, 868.0);
  float seal = step(abs(sc.x), 46.0) * step(abs(sc.y), 46.0);
  vec2 sg = (sc + 46.0) / 92.0;
  float strokes = 0.0;
  for (int i = 0; i < 6; i++){
    float fi = float(i); vec2 a0 = vec2(h1(fi * 2.1 + 3.0), h1(fi * 5.3 + 1.0)) * 0.7 + 0.15;
    vec2 dd = mix(vec2(1.0, 0.0), vec2(0.0, 1.0), step(0.5, h1(fi * 9.1)));
    float t = clamp(dot(sg - a0, dd), -0.22, 0.22);
    strokes = max(strokes, 1.0 - smoothstep(0.035, 0.05, length(sg - a0 - dd * t)));
  }
  float frameIn = step(0.08, sg.x) * step(sg.x, 0.92) * step(0.08, sg.y) * step(sg.y, 0.92);
  float sealInk = seal * (1.0 - max(strokes * frameIn, (1.0 - frameIn) * 0.0) * 0.95) * (0.8 + 0.2 * vn(P * 0.4));
  sealInk *= 1.0 - (step(0.05, sg.x) * step(sg.x, 0.95) * step(0.05, sg.y) * step(sg.y, 0.95) - frameIn) * 0.9;
  col = mix(col, red * 0.95, clamp(sealInk, 0.0, 1.0) * 0.92);
  return col;
}

vec3 sTicker(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x);
  vec3 bg = vec3(0.035, 0.03, 0.027) * (0.75 + 0.5 * fbm(p * 2.0));
  float b = 0.24, r0 = 1.07, wd = 0.17;
  float f = (r - r0) / b - a / TAU;
  float n = floor(f); float fr = fract(f);
  float v = fr * b / wd;
  vec3 col = bg;
  float shade = 0.55 + 0.55 * smoothstep(-2.4, 2.4, q.y + q.x * 0.35);
  if (f >= 0.0 && f < 6.0){
    float inS = step(v, 1.0);
    float s = (a / TAU + n) * TAU * (r0 + b * (n + 0.5));
    float u = -s * 0.146 + uT * 0.22 + n * 0.37 + uSeed;
    vec3 tex = texture(uTick, vec2(u, 1.0 - clamp(v, 0.0, 1.0))).rgb;
    float curl = 0.78 + 0.22 * sin(v * PI);
    float gap = smoothstep(0.28, 0.33, vn(vec2(s * 0.6 + n * 9.0 + uSeed, n)));
    col = mix(col, tex * curl * shade, inS * gap);
    col *= 1.0 - (1.0 - inS) * 0.6 * exp(-(v - 1.0) * 5.0) * gap;
  }
  return col * (0.8 + 0.2 * shade);
}

vec3 sRadar(vec2 q){
  float r = length(q), a = atan(q.y, q.x);
  vec3 col = vec3(0.012, 0.014, 0.018);
  float grid = 0.0;
  for (int i = 0; i < 6; i++){ grid += ln(abs(r - (1.35 + 0.42 * float(i))), 0.0022) * 0.2; }
  grid += ln(arcDist(a, 12.0, r), 0.0018) * step(1.05, r) * 0.09;
  float bA = uG * 2.4 + uSeed;
  float da = mod(bA - a, TAU);
  float trail = exp(-da * 1.8) * 0.075 * step(1.0, r) * smoothstep(3.9, 2.5, r);
  float beam = exp(-da * r * 260.0) * 0.9 * step(1.0, r) * smoothstep(3.9, 2.5, r);
  beam += exp(-da * r * 40.0) * 0.12 * step(1.0, r) * smoothstep(3.9, 2.5, r);
  grid += ln(abs(r - 1.0), 0.0035) * 0.45;
  col += vec3(0.78, 0.86, 1.0) * (grid + trail + beam);
  float cs = 0.27;
  vec2 g = q / cs; vec2 id = floor(g);
  vec2 o = h22(id + 3.0);
  vec2 c = (id + 0.22 + 0.56 * o) * cs;
  float hr = h2(id + 9.0);
  float lc = length(c);
  if (hr > 0.42 && lc > 1.15 && lc < 3.6){
    float sz = 0.009 + 0.03 * pow(h2(id + 3.0), 3.0);
    float d = length(q - c);
    float pass = mod(bA - atan(c.y, c.x), TAU);
    float lit = 0.22 + 0.95 * exp(-pass * 1.1);
    col += vec3(0.86, 0.93, 1.0) * lit * ((1.0 - smoothstep(sz - S, sz + S, d)) + exp(-d / sz * 1.6) * 0.35);
  }
  vec2 c0 = 1.62 * vec2(cos(0.72), sin(0.72));
  float d0 = length(q - c0);
  col += vec3(1.0) * ((1.0 - smoothstep(0.03 - S, 0.03 + S, d0)) + exp(-d0 * 16.0) * 0.5);
  for (int i = 0; i < 3; i++){
    float ph = fract(uT * 0.7 + float(i) / 3.0);
    col += vec3(0.9, 0.95, 1.0) * ln(abs(d0 - ph * 0.6), 0.003) * (1.0 - ph) * 0.8;
  }
  vec2 tr = c0 - q; float trail0 = 0.0;
  return col;
}

float sdBox(vec2 p, vec2 b, float rr){ vec2 d = abs(p) - b + rr; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - rr; }
float segD(vec2 p, vec2 a, vec2 b){ vec2 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0); return length(pa - ba * h); }

float stoneH(vec2 q){
  float r = length(q), a = atan(q.y, q.x);
  float N = 30.0; float k = floor(a / TAU * N + 0.5); float ac = k / N * TAU;
  vec2 lp = vec2((a - ac) * r, r - 1.5);
  float h = 0.0;
  float up = step(0.16, h1(k * 3.7 + 1.0));
  float d = sdBox(lp, vec2(0.085, 0.066), 0.025) + 0.014 * (vn(q * 26.0 + k) - 0.5);
  h = max(h, up * (1.0 - smoothstep(-0.004, 0.004, d)));
  float k2 = floor(a / TAU * N);
  float lk = step(0.42, h1(k2 * 5.1 + 2.0));
  float dl = abs(r - 1.5) - 0.05 + 0.012 * (vn(q * 22.0) - 0.5);
  h = max(h, lk * (1.0 - smoothstep(-0.004, 0.004, dl)) * 1.2);
  float M = 44.0; float k3 = floor(a / TAU * M + 0.5); vec2 bp = vec2((a - k3 / M * TAU) * r, r - 1.2);
  float db = length(bp / vec2(1.0, 0.75)) - 0.034 - 0.008 * vn(q * 40.0);
  h = max(h, step(0.3, h1(k3 * 1.3 + 5.0)) * (1.0 - smoothstep(-0.004, 0.004, db)) * 0.75);
  vec2 fq = rot(0.6) * (q - vec2(1.95, -0.75)); float df = sdBox(fq, vec2(0.17, 0.065), 0.03) + 0.01 * vn(q * 30.0);
  h = max(h, (1.0 - smoothstep(-0.004, 0.004, df)) * 0.5);
  float dh = length((q - vec2(3.05, 0.6)) / vec2(1.0, 0.8)) - 0.095;
  h = max(h, 1.0 - smoothstep(-0.004, 0.004, dh));
  return h;
}

vec3 sStone(vec2 q){
  float r = length(q);
  vec3 grass = mix(vec3(0.19, 0.26, 0.10), vec3(0.40, 0.45, 0.21), fbm(q * 2.6 + uSeed));
  grass *= 0.84 + 0.16 * vn(q * 70.0);
  grass = mix(grass, grass * vec3(1.15, 1.06, 0.75), smoothstep(0.55, 0.8, fbm(q * 1.3 + 4.0)) * 0.5);
  float bank = exp(-pow((r - 2.72) / 0.12, 2.0)); float ditch = exp(-pow((r - 2.93) / 0.07, 2.0));
  grass = grass * (1.0 + 0.2 * bank) * (1.0 - 0.32 * ditch);
  float av = abs(q.y - 0.2 * q.x - 0.0) ;
  grass = mix(grass, grass * vec3(1.12, 1.08, 0.9), exp(-pow((av - 0.0) / 0.25, 2.0)) * step(2.9, q.x) * 0.5);
  float h = stoneH(q);
  vec2 sd = normalize(vec2(-0.78, 0.55));
  float sh = 0.0;
  for (int i = 1; i <= 5; i++){ float o = float(i) * 0.026; sh = max(sh, stoneH(q + sd * o) * (1.0 - float(i) * 0.1)); }
  float shadow = clamp(sh - h, 0.0, 1.0);
  vec3 stone = mix(vec3(0.44, 0.43, 0.39), vec3(0.68, 0.66, 0.60), fbm(q * 9.0 + 3.0));
  stone = mix(stone, vec3(0.64, 0.64, 0.38), smoothstep(0.62, 0.78, fbm(q * 18.0)) * 0.6);
  float hx = stoneH(q + vec2(0.006, 0.0)) - stoneH(q - vec2(0.006, 0.0));
  float hy = stoneH(q + vec2(0.0, 0.006)) - stoneH(q - vec2(0.0, 0.006));
  float edge = clamp(0.5 - (hx * sd.x + hy * sd.y) * 2.0, 0.0, 1.0);
  stone *= 0.7 + 0.55 * edge;
  vec3 col = mix(grass * (1.0 - 0.6 * shadow), stone, clamp(h, 0.0, 1.0));
  return col * vec3(1.08, 1.0, 0.86);
}

vec3 sNebra(vec2 q){
  float r = length(q);
  vec3 pat = mix(vec3(0.09, 0.25, 0.21), vec3(0.25, 0.46, 0.37), fbm(q * 3.0 + uSeed));
  pat = mix(pat, vec3(0.40, 0.57, 0.46), smoothstep(0.6, 0.8, fbm(q * 9.0)) * 0.5);
  pat = mix(pat, vec3(0.07, 0.14, 0.15), smoothstep(0.62, 0.85, fbm(q * 2.2 + 9.0)) * 0.6);
  pat *= 0.82 + 0.28 * vn(q * 60.0);
  float g = 1.0 - smoothstep(1.08 - S, 1.08 + S, r);
  vec2 cq = q - vec2(-2.05, 0.55);
  g = max(g, (1.0 - smoothstep(-S, S, length(cq) - 0.62)) * smoothstep(-S, S, length(cq - vec2(0.27, 0.12)) - 0.55));
  for (int i = 0; i < 28; i++){
    float fi = float(i);
    vec2 sp = (vec2(h1(fi * 3.3 + 1.0), h1(fi * 5.9 + 2.0)) - 0.5) * vec2(7.0, 3.9);
    if (length(sp) < 1.35 || length(sp - vec2(-2.05, 0.55)) < 0.85 || length(sp - vec2(1.75, 1.05)) < 0.35) continue;
    float sr = 0.05 + 0.025 * h1(fi * 1.7);
    g = max(g, 1.0 - smoothstep(sr - S, sr + S, length(q - sp) + 0.012 * (vn(q * 40.0) - 0.5)));
  }
  for (int i = 0; i < 7; i++){ float fi = float(i); vec2 o = vec2(cos(fi * 2.4), sin(fi * 2.4)) * (0.07 + 0.08 * h1(fi + 30.0)); g = max(g, 1.0 - smoothstep(0.038 - S, 0.038 + S, length(q - vec2(1.75, 1.05) - o))); }
  float hr = length(q - vec2(0.2, 0.0)); float arcA = atan(q.y, q.x - 0.2);
  g = max(g, (1.0 - smoothstep(-S, S, abs(hr - 3.25) - 0.09)) * step(abs(arcA), 0.72));
  float br = length(q - vec2(0.0, 1.3)); float bA = atan(q.y - 1.3, q.x);
  float barque = (1.0 - smoothstep(-S, S, abs(br - 3.05) - 0.06)) * step(abs(bA + PI * 0.5), 0.42);
  g = max(g, barque * (0.7 + 0.3 * stripes(bA * 90.0, 0.14)));
  float hammer = vn(q * 35.0 + 2.0);
  float sheen = 0.5 + 0.5 * sin(dot(q, vec2(0.8, 0.6)) * 2.0 + uT * 1.6 + hammer * 1.5);
  vec3 gold = vec3(0.84, 0.63, 0.26) * (0.55 + 0.62 * sheen) + vec3(1.0, 0.9, 0.6) * pow(sheen, 12.0) * 0.7;
  gold = mix(gold, gold * 0.62, smoothstep(0.55, 0.8, fbm(q * 7.0 + 5.0)) * 0.6);
  return mix(pat, gold, clamp(g, 0.0, 1.0));
}

vec3 sEgypt(vec2 q){
  float r = length(q);
  vec3 sand = mix(vec3(0.68, 0.53, 0.34), vec3(0.86, 0.72, 0.52), fbm(q * 3.0 + uSeed));
  sand *= 0.88 + 0.12 * vn(q * 90.0);
  float ax = abs(q.x);
  float u = ax - 1.02;
  float yc = 0.1 + 0.17 * u - 0.035 * u * u;
  float hh = 0.52 * pow(clamp(1.0 - u / 2.8, 0.0, 1.0), 0.55);
  float t = (q.y - (yc - hh)) / max(2.0 * hh, 1e-3);
  float tipLen = 2.6 - 1.0 * clamp(t, 0.0, 1.0);
  float wing = step(0.0, u) * step(0.0, t) * step(t, 1.0) * step(u, tipLen);
  vec3 col = sand;
  if (wing > 0.5){
    float tb = t < 0.42 ? 0.0 : (t < 0.72 ? 0.42 : 0.72);
    float te = t < 0.42 ? 0.42 : (t < 0.72 ? 0.72 : 1.0);
    float tier = t < 0.42 ? 0.0 : (t < 0.72 ? 1.0 : 2.0);
    float sp = tier < 0.5 ? 0.15 : (tier < 1.5 ? 0.105 : 0.075);
    float fu = u / sp; float id = floor(fu); float fx = fract(fu) - 0.5;
    float lt = (t - tb) / (te - tb);
    float th = (te - tb) * 2.0 * hh;
    float ink = ln(abs(fx) * sp, 0.005) * step(0.48 * fx * fx, lt);
    ink = max(ink, ln(abs(lt - 0.48 * fx * fx) * th, 0.005));
    ink = max(ink, ln(abs(t - tb) * 2.0 * hh, 0.006));
    vec3 c0 = mod(id, 2.0) < 0.5 ? vec3(0.13, 0.29, 0.56) : vec3(0.15, 0.42, 0.33);
    vec3 pc = tier < 0.5 ? c0 : (tier < 1.5 ? vec3(0.66, 0.2, 0.1) : vec3(0.14, 0.3, 0.58));
    float worn = smoothstep(0.32, 0.62, fbm(q * 5.0 + uSeed * 2.0));
    vec3 painted = mix(sand, pc, 0.88 * worn);
    painted *= 1.0 - 0.2 * lt;
    col = mix(painted, vec3(0.24, 0.16, 0.09), ink * 0.85);
  }
  float edgeD = min(min(abs(t), abs(1.0 - t)) * 2.0 * hh, abs(u - tipLen));
  col = mix(col, col * 0.5, wing * ln(edgeD, 0.012));
  col = mix(col, vec3(0.62, 0.18, 0.08) * (0.8 + 0.2 * fbm(q * 8.0)), (1.0 - smoothstep(1.1 - S, 1.1 + S, r)) * step(1.0, r));
  col = mix(col, col * 0.45, ln(abs(r - 1.1), 0.008));
  for (int i = 0; i < 2; i++){
    float sx = i == 0 ? -1.0 : 1.0;
    vec2 uq = q - vec2(0.84 * sx, -0.98);
    float du = length(uq / vec2(0.12, 0.28)) - 1.0;
    float cob = 1.0 - smoothstep(-0.06, 0.06, du);
    col = mix(col, mix(vec3(0.78, 0.56, 0.2), vec3(0.15, 0.4, 0.3), step(0.0, uq.y)), cob * 0.9);
    col = mix(col, col * 0.45, ln(abs(du) * 0.12, 0.004));
  }
  float cl = 0.0;
  for (int i = 0; i < 4; i++){ cl = max(cl, ln(abs(ax - 2.9 - float(i) * 0.22), 0.006)); }
  col = mix(col, col * 0.62, cl * step(abs(q.y), 1.85));
  vec2 gc = vec2((ax - 2.9) / 0.22, q.y / 0.26);
  vec2 gid = floor(gc); vec2 gf = fract(gc) - 0.5;
  if (ax > 2.9 && ax < 3.56 && abs(q.y) < 1.8){
    float gl = 0.0;
    for (int k = 0; k < 3; k++){
      float hk = h2(gid + float(k) * 4.1 + 3.0);
      vec2 a0 = (h22(gid + float(k) * 2.7) - 0.5) * 0.5;
      vec2 dd = vec2(cos(floor(hk * 4.0) * PI / 4.0), sin(floor(hk * 4.0) * PI / 4.0));
      gl = max(gl, 1.0 - smoothstep(0.05, 0.09, segD(gf, a0 - dd * 0.22, a0 + dd * 0.22)));
    }
    gl = max(gl, (1.0 - smoothstep(0.05, 0.09, abs(length(gf - vec2(0.0, 0.1)) - 0.16))) * step(0.7, h2(gid + 9.0)));
    col = mix(col, col * 0.55, gl * 0.8);
  }
  return col;
}

vec3 sBayeux(vec2 q, vec2 P){
  float r = length(q), a = atan(q.y, q.x);
  vec2 w = P * 0.55;
  float warp = 0.5 + 0.5 * sin(w.x * PI); float weft = 0.5 + 0.5 * sin(w.y * PI);
  float weave = mix(warp, weft, step(0.5, fract((floor(w.x) + floor(w.y)) * 0.5)));
  vec3 linen = vec3(0.84, 0.78, 0.63) * (0.86 + 0.14 * weave) * (0.9 + 0.1 * fbm(q * 3.0 + uSeed));
  linen = mix(linen, linen * vec3(0.85, 0.78, 0.65), smoothstep(0.6, 0.85, fbm(q * 1.4 + 3.0)) * 0.5);
  vec3 col = linen;
  float yarn = 0.0; vec3 yc = vec3(0.0);
  for (int i = 0; i < 7; i++){
    float fi = float(i);
    float ang = (fi - 3.0) * 0.15 + 0.06 * sin(uT * 2.0 + fi);
    vec2 dir = vec2(cos(ang), sin(ang));
    float along = dot(q, dir); float across = dot(q, vec2(-dir.y, dir.x)) - 0.06 * sin(along * 3.0 + fi);
    float len = 2.2 + 0.5 * h1(fi + 3.0);
    float wdt = 0.04 * (1.0 - clamp((along - 1.05) / len, 0.0, 1.0)) + 0.012;
    float m = step(1.05, along) * step(along, 1.05 + len) * (1.0 - smoothstep(wdt - S, wdt + S, abs(across)));
    float ply = 0.62 + 0.38 * sin(along * 70.0 + across / wdt * 2.5);
    vec3 c = mod(fi, 3.0) < 1.0 ? vec3(0.64, 0.30, 0.18) : (mod(fi, 3.0) < 2.0 ? vec3(0.26, 0.42, 0.40) : vec3(0.78, 0.60, 0.26));
    if (m > yarn){ yarn = m; yc = c * ply; }
  }
  float ring = 1.0 - smoothstep(0.05 - S, 0.05 + S, abs(r - 1.09));
  if (ring > yarn){ yarn = ring; yc = vec3(0.64, 0.30, 0.18) * (0.62 + 0.38 * sin(a * 170.0 + (r - 1.09) * 60.0)); }
  float spk = ln(arcDist(a + PI / 10.0, 10.0, r), 0.022) * step(1.14, r) * step(r, 1.4) * step(0.75, abs(a));
  if (spk > yarn){ yarn = spk; yc = vec3(0.78, 0.60, 0.26) * (0.62 + 0.38 * sin(r * 90.0)); }
  col = mix(col, yc, yarn);
  float bands = step(1.62, abs(q.y));
  float bline = ln(abs(abs(q.y) - 1.62), 0.014);
  float diag = ln(abs(fract((q.x + abs(q.y) * 0.65) / 0.75) - 0.5) * 0.75, 0.012) * bands;
  col = mix(col, vec3(0.26, 0.42, 0.40) * (0.7 + 0.3 * sin(P.x * 1.7 + P.y)), clamp(bline + diag, 0.0, 1.0));
  vec2 tuv = vec2((q.x + 2.25) / 4.5, (q.y - 1.17) / 0.34);
  if (tuv.x > 0.0 && tuv.x < 1.0 && tuv.y > 0.0 && tuv.y < 1.0){
    float tx = texture(uTxt, vec2(tuv.x, 1.0 - tuv.y)).r;
    col = mix(col, vec3(0.16, 0.2, 0.3) * (0.72 + 0.28 * sin(P.x * 2.1 + P.y * 1.3)), tx);
  }
  return col;
}

float meander(vec2 t){
  float d = segD(t, vec2(-0.05, 0.12), vec2(0.88, 0.12));
  d = min(d, segD(t, vec2(0.88, 0.12), vec2(0.88, 0.88)));
  d = min(d, segD(t, vec2(0.88, 0.88), vec2(0.3, 0.88)));
  d = min(d, segD(t, vec2(0.3, 0.88), vec2(0.3, 0.38)));
  d = min(d, segD(t, vec2(0.3, 0.38), vec2(0.62, 0.38)));
  d = min(d, segD(t, vec2(0.62, 0.38), vec2(0.62, 0.62)));
  d = min(d, segD(t, vec2(0.88, 0.12), vec2(1.05, 0.12)));
  return d;
}

vec3 sGreek(vec2 q){
  float r = length(q), a = atan(q.y, q.x);
  vec3 clay = mix(vec3(0.72, 0.36, 0.18), vec3(0.85, 0.48, 0.25), fbm(q * 2.0 + uSeed));
  vec3 slip = vec3(0.05, 0.045, 0.04);
  float black = 0.0;
  float bw = 0.3; float v = (r - 1.15) / bw;
  float tiles = floor(TAU * 1.3 / bw);
  float u = (a / TAU + 0.5) * tiles;
  float md = meander(vec2(fract(u), v)) * bw;
  black = max(black, step(0.0, v) * step(v, 1.0) * (1.0 - smoothstep(0.024 - S, 0.024 + S, md)));
  black = max(black, ln(abs(r - 1.1), 0.014) + ln(abs(r - 1.5), 0.014));
  float tn = 48.0; float tk = floor(a / TAU * tn + 0.5);
  float ta = (a - tk / tn * TAU) * r; float tv = (r - 1.6) / 0.36;
  float tongue = step(0.0, tv) * step(tv, 1.0) * (1.0 - smoothstep(-0.04, 0.04, length(vec2(ta / 0.07, (tv - 0.48) / 0.52)) - 1.0));
  float alt = step(0.5, mod(tk, 2.0));
  black = max(black, tongue * alt);
  float field = smoothstep(2.05 - S, 2.05 + S, r);
  float incise = ln(abs(r - 2.26), 0.005) + ln(arcDist(a, 36.0, r), 0.004) * step(2.3, r) * step(r, 2.75) + ln(abs(r - 2.8), 0.005);
  black = max(black, field * (1.0 - clamp(incise, 0.0, 1.0)));
  vec3 col = mix(clay, slip, clamp(black, 0.0, 1.0));
  col = mix(col, vec3(0.44, 0.1, 0.08), tongue * (1.0 - alt) * 0.9);
  float sheen = exp(-pow((q.x - 1.3 - 0.4 * sin(uT * 1.2)) / 0.32, 2.0));
  col += vec3(1.0, 0.95, 0.86) * sheen * (0.06 + 0.4 * clamp(black, 0.0, 1.0));
  col *= 0.88 + 0.12 * vn(q * 70.0);
  return col;
}

vec3 sDunhuang(vec2 q, vec2 p){
  float r = length(q);
  vec3 paper = mix(vec3(0.74, 0.64, 0.46), vec3(0.87, 0.79, 0.61), fbm(p * 2.5 + uSeed));
  paper *= 0.9 + 0.1 * vn(vec2(p.x * 3.0, p.y * 90.0));
  paper *= 1.0 - 0.16 * ln(abs(fract(p.x / 1.15 + 0.5) - 0.5) * 1.15, 0.006);
  paper = mix(paper, paper * vec3(0.8, 0.68, 0.5), smoothstep(0.65, 0.85, fbm(p * 1.2 + 4.0)) * 0.6);
  vec3 col = paper;
  float ink = 0.0; vec3 dotc = vec3(0.0); float dotm = 0.0;
  vec2 cs = vec2(0.62);
  vec2 id = floor(p / cs);
  for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++){
    vec2 cid = id + vec2(i, j);
    float n = 1.0 + floor(h2(cid + 7.0) * 4.0);
    vec2 prev = vec2(0.0);
    float kind = h2(cid + 2.0);
    for (int k = 0; k < 5; k++){
      if (float(k) >= n) break;
      vec2 sp = (cid + 0.12 + 0.76 * h22(cid * 1.7 + float(k) * 3.1)) * cs;
      float d = length(p - sp);
      float rad = 0.03;
      float m = 1.0 - smoothstep(rad - S, rad + S, d);
      if (m > dotm){ dotm = m; dotc = kind < 0.4 ? vec3(0.72, 0.16, 0.1) : (kind < 0.75 ? vec3(0.08, 0.07, 0.06) : vec3(0.96, 0.93, 0.84)); }
      ink = max(ink, ln(abs(d - rad), 0.004) * step(0.75, kind));
      if (k > 0) ink = max(ink, ln(segD(p, prev, sp), 0.0035) * step(rad, d) * step(rad, length(p - prev)));
      prev = sp;
    }
  }
  col = mix(col, vec3(0.1, 0.08, 0.06), ink * 0.9);
  col = mix(col, dotc, dotm);
  col = mix(col, vec3(0.12, 0.09, 0.07), ln(abs(r - 1.72), 0.005) * 0.85);
  return col;
}

vec3 sCodex(vec2 q, vec2 p){
  vec3 paper = mix(vec3(0.80, 0.72, 0.55), vec3(0.91, 0.86, 0.71), fbm(p * 2.2 + uSeed));
  paper *= 0.9 + 0.1 * vn(p * 50.0);
  paper = mix(paper, vec3(0.62, 0.48, 0.32), smoothstep(0.66, 0.9, fbm(p * 1.4 + 2.0)) * 0.6);
  vec3 col = paper;
  vec2 cell = vec2(0.72, 0.6);
  vec2 g = p / cell; vec2 id = floor(g); vec2 f = fract(g);
  float rule = max(ln(min(f.x, 1.0 - f.x) * cell.x, 0.011), ln(min(f.y, 1.0 - f.y) * cell.y, 0.007));
  col = mix(col, vec3(0.64, 0.2, 0.12), rule * 0.85);
  float hv = h2(id + 3.0);
  vec2 lc = (f - 0.5) * cell;
  if (hv < 0.6){
    float num = 1.0 + floor(h2(id + 9.0) * 19.0);
    float bars = floor(num / 5.0); float dots = num - bars * 5.0;
    float ink = 0.0;
    for (int b = 0; b < 3; b++){ if (float(b) >= bars) break; ink = max(ink, 1.0 - smoothstep(-S, S, sdBox(lc - vec2(0.0, -0.17 + float(b) * 0.085), vec2(0.2, 0.026), 0.02))); }
    float dy = -0.17 + bars * 0.085 + 0.025;
    for (int d = 0; d < 4; d++){ if (float(d) >= dots) break; ink = max(ink, 1.0 - smoothstep(0.032 - S, 0.032 + S, length(lc - vec2((float(d) - (dots - 1.0) * 0.5) * 0.1, dy)))); }
    col = mix(col, vec3(0.07, 0.06, 0.05), ink * (0.85 + 0.15 * vn(p * 80.0)));
  } else if (hv < 0.8){
    float d = length(lc) - 0.13;
    float glyph = 1.0 - smoothstep(-S, S, d);
    col = mix(col, mix(vec3(0.93, 0.9, 0.8), vec3(0.07), step(0.0, lc.x)), glyph);
    col = mix(col, vec3(0.07), ln(abs(d), 0.006));
    float wl = 1.0 - smoothstep(-S, S, sdBox(lc - vec2(-0.22, 0.02), vec2(0.07, 0.045), 0.03));
    float wr = 1.0 - smoothstep(-S, S, sdBox(lc - vec2(0.22, 0.02), vec2(0.07, 0.045), 0.03));
    col = mix(col, vec3(0.33, 0.6, 0.62), max(wl, wr) * 0.85);
  } else {
    float fill = 1.0 - smoothstep(-S, S, sdBox(lc, cell * 0.5 - 0.06, 0.04));
    col = mix(col, vec3(0.33, 0.58, 0.6) * (0.85 + 0.15 * fbm(p * 8.0)), fill * 0.8);
  }
  return col;
}

vec3 sCopernicus(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x);
  vec3 paper = vec3(0.91, 0.87, 0.77) * (0.92 + 0.08 * fbm(p * 5.0));
  paper = mix(paper, vec3(0.76, 0.64, 0.46), smoothstep(0.7, 0.86, fbm(p * 1.6 + 7.0)) * 0.45);
  float ink = 0.0;
  float R0 = 1.06; float dR = 0.27;
  for (int i = 0; i <= 7; i++){ ink = max(ink, ln(abs(r - (R0 + float(i) * dR)), 0.004)); }
  float k = floor((r - R0) / dR); float v = fract((r - R0) / dR);
  if (k >= 0.0 && k < 7.0){
    float s = mod(PI * 0.62 - a + uT * 0.05 * (k + 1.0), TAU) * r;
    float u = s * 0.1157;
    if (u < 1.0 && v > 0.12 && v < 0.88){
      float tx = texture(uTxt2, vec2(u, (k + 1.0 - v) / 7.0)).r;
      ink = max(ink, tx);
    }
    float pa = 2.4 + k * 0.85 - uT * 0.1 * (7.0 - k);
    vec2 pp = vec2(cos(pa), sin(pa)) * (R0 + (k + 0.5) * dR);
    float pd = length(q - pp);
    ink = max(ink, ln(abs(pd - 0.05), 0.004));
    ink = max(ink, (1.0 - smoothstep(0.025 - S, 0.025 + S, pd)));
  }
  float outer = step(R0 + 7.0 * dR, r);
  ink = max(ink, outer * stripes(dot(q, vec2(0.6, 0.8)) * 26.0, 0.12) * smoothstep(3.0, 3.6, r));
  ink *= 0.82 + 0.18 * vn(q * 90.0);
  return mix(paper, vec3(0.08, 0.07, 0.06), clamp(ink, 0.0, 1.0));
}

vec3 sGalileo(vec2 q, vec2 p){
  float r = length(q);
  vec3 paper = vec3(0.92, 0.89, 0.81) * (0.92 + 0.08 * fbm(p * 5.0));
  paper = mix(paper, vec3(0.8, 0.7, 0.52), smoothstep(0.72, 0.9, fbm(p * 1.5 + 2.0)) * 0.4);
  float ink = ln(abs(r - 2.35), 0.006);
  float wash = 0.0;
  for (int i = 0; i < 16; i++){
    float fi = float(i);
    float ang = h1(fi * 3.1 + uSeed) * TAU + uT * 0.08; float rad = 1.35 + h1(fi * 7.3) * 0.85;
    vec2 c = vec2(cos(ang), sin(ang)) * rad;
    float sz = 0.022 + 0.06 * pow(h1(fi * 1.9), 2.0);
    float dd = length((q - c) / vec2(1.0, 0.72 + 0.32 * h1(fi))) + 0.012 * (vn(q * 40.0 + fi) - 0.5);
    ink = max(ink, 1.0 - smoothstep(sz - S, sz + S, dd));
    wash = max(wash, (1.0 - smoothstep(sz * 1.6, sz * 2.9, dd)) * 0.5);
  }
  wash = max(wash, (1.0 - smoothstep(1.05, 1.45, r + 0.07 * (fbm(q * 5.0) - 0.5))) * 0.55);
  float hatch = stripes(dot(q, vec2(0.7, 0.7)) * 30.0, 0.18) * (1.0 - smoothstep(1.05, 1.4, r)) * step(1.0, r);
  vec3 col = mix(paper, vec3(0.42, 0.36, 0.3), wash * (0.8 + 0.2 * fbm(q * 9.0)));
  col = mix(col, vec3(0.08, 0.07, 0.06), clamp(ink + hatch * 0.7, 0.0, 1.0));
  return col * (1.0 - 0.06 * step(2.35, r));
}

vec3 sEddington(vec2 q, vec2 P){
  float r = length(q), a = atan(q.y, q.x);
  vec2 c = P - vec2(960.0, 540.0);
  vec2 dq = abs(c) - vec2(860.0, 470.0);
  float e = max(dq.x, dq.y) + 8.0 * (vn(P * 0.04) - 0.5);
  float glass = 1.0 - smoothstep(-1.0, 1.0, e);
  float rr = max(r - 1.0, 0.0); vec2 w = vec2(cos(a), sin(a));
  float cor = exp(-rr * 2.5) * (0.5 + 0.5 * vn3(vec3(w * 3.5, rr * 1.3 + uSeed))) + exp(-rr * 9.0) * 0.6;
  cor += exp(-rr * 1.1) * 0.4 * pow(vn3(vec3(w * 20.0, rr * 0.4)), 3.0);
  cor *= step(1.0, r);
  float dens = 0.84 - 0.78 * clamp(cor, 0.0, 1.0);
  vec3 col = vec3(dens) * vec3(0.94, 0.97, 0.96) * (0.94 + 0.06 * fbm(q * 4.0));
  for (int i = 0; i < 12; i++){
    float fi = float(i); float ang = h1(fi * 2.3 + 1.0) * TAU; float rad = 1.55 + 1.5 * h1(fi * 4.1);
    vec2 sp = vec2(cos(ang) * rad * 1.45, sin(ang) * rad * 0.78);
    vec2 o = q - sp;
    col = mix(col, vec3(0.08), 1.0 - smoothstep(0.013 - S, 0.013 + S, length(o)));
    float mk = ln(abs(o.y), 0.004) * step(0.04, abs(o.x)) * step(abs(o.x), 0.12);
    col = mix(col, vec3(0.05, 0.05, 0.09), mk * 0.85);
  }
  float sc = 0.0;
  for (int i = 0; i < 7; i++){
    float fi = float(i);
    vec2 o = vec2(h1(fi * 3.1 + uSeed), h1(fi * 7.7 + uSeed)) * vec2(1920.0, 1080.0);
    float ang = h1(fi * 1.3 + 0.5) * PI; vec2 dir = vec2(cos(ang), sin(ang));
    vec2 rel = P - o;
    sc += exp(-pow(dot(rel, vec2(-dir.y, dir.x)), 2.0) * 2.0) * step(abs(dot(rel, dir)), 150.0 + 300.0 * h1(fi + 2.0)) * 0.3;
  }
  col -= sc * 0.25;
  vec2 lb = c - vec2(-620.0, 330.0);
  float lab = 1.0 - smoothstep(-1.0, 1.0, sdBox(lb, vec2(150.0, 48.0), 4.0));
  float hw = 0.0;
  hw = max(hw, (1.0 - smoothstep(1.0, 2.4, abs(lb.y + 12.0 - 6.0 * sin(lb.x * 0.11) * sin(lb.x * 0.023)))) * step(abs(lb.x + 10.0), 120.0));
  hw = max(hw, (1.0 - smoothstep(1.0, 2.4, abs(lb.y - 16.0 - 5.0 * sin(lb.x * 0.13 + 1.0)))) * step(abs(lb.x + 40.0), 80.0));
  vec3 labc = mix(vec3(0.86, 0.82, 0.7), vec3(0.18, 0.16, 0.3), hw);
  col = mix(col, labc, lab);
  return mix(vec3(0.05, 0.05, 0.06), col, glass);
}

vec3 sTulip(vec2 q, vec2 p){
  float r = length(q), a = atan(q.y, q.x) + uT * 0.06;
  vec3 paper = vec3(0.92, 0.88, 0.78) * (0.92 + 0.08 * fbm(p * 4.0));
  paper = mix(paper, vec3(0.78, 0.68, 0.5), smoothstep(0.7, 0.88, fbm(p * 1.4 + 3.0)) * 0.45);
  vec3 col = paper;
  for (int layer = 0; layer < 2; layer++){
    float off = layer == 0 ? PI / 3.0 : 0.0;
    float sec = TAU / 3.0; float k = floor((a - off) / sec + 0.5); float th = (a - off) - k * sec;
    float rl = layer == 0 ? 2.6 : 2.3;
    float u = (r - 0.85) / (rl - 0.85);
    float wmax = layer == 0 ? 0.95 : 0.88;
    float halfw = wmax * sin(PI * (0.12 + 0.88 * clamp(u, 0.0, 1.0))) * (1.0 - 0.3 * u);
    float x = th * r;
    float band = step(0.0, u) * step(u, 1.0);
    float inP = band * (1.0 - smoothstep(halfw - S * 1.5, halfw + S * 1.5, abs(x)));
    float fl = fbm(vec2(x * 6.0 / max(halfw, 0.05), u * 2.2 + k * 3.0 + float(layer) * 7.0));
    float flame = smoothstep(0.46, 0.6, fl + 0.25 * (1.0 - abs(x) / max(halfw, 0.01)) - 0.12 * u);
    float feather = 0.5 + 0.5 * sin(x * 150.0 + fl * 6.0);
    vec3 white = vec3(0.96, 0.93, 0.88) * (layer == 0 ? 0.84 : 1.0);
    vec3 red = vec3(0.70, 0.07, 0.10) * (0.78 + 0.22 * feather);
    vec3 pc = mix(white, red, flame);
    pc = mix(pc, pc * 0.72, stripes((x + u * 0.3) * 40.0, 0.1) * step(0.0, x) * 0.3);
    pc *= 0.84 + 0.16 * sin(PI * clamp(u, 0.0, 1.0));
    float outline = band * ln(abs(abs(x) - halfw), 0.0055);
    col = mix(col, pc, inP);
    col = mix(col, vec3(0.2, 0.07, 0.05), outline * 0.9);
  }
  return col;
}

vec3 sGenesis(vec2 q, vec2 P){
  vec2 uv = vec2(P.x / 1920.0, 1.0 - P.y / 1080.0 + uT * 0.025);
  vec3 tx = texture(uTxt3, vec2(uv.x, fract(uv.y))).rgb;
  vec3 col = vec3(0.012, 0.014, 0.012) + tx;
  col *= 0.9 + 0.1 * sin(P.y * PI);
  return col;
}

void main(){
  vec2 frag = gl_FragCoord.xy;
  vec2 C = uRes * 0.5;
  vec2 q = rot(uRot) * (frag - C) / (uR * uZoom);
  S = 1.0 / (uR * uZoom);
  vec2 P = vec2(frag.x, frag.y) * (1080.0 / uRes.y);
  float z = 1.0 + uT * 0.09;
  vec2 p = rot(uSeed * 0.7 + uT * 0.06) * q / z + vec2(uSeed * 3.1, uSeed * 1.7) + vec2(uT * 0.14, uT * 0.03);
  vec3 col = vec3(0.0);
  switch (uScene){
    case 0: col = sSpace(q, P); break;
    case 1: col = sBone(q, p); break;
    case 2: col = sEngrave(q, p); break;
    case 3: col = sGold(q, p); break;
    case 4: col = sSun(q, p); break;
    case 5: col = sThermal(q, p); break;
    case 6: col = sInk(q, p); break;
    case 7: col = sClay(rot(uT * 0.03) * q / (1.0 + uT * 0.05)); break;
    case 8: col = sBronze(rot(-uT * 0.05) * q); break;
    case 9: col = sMap(q, q * 1.0 / (1.0 + uT * 0.03) + vec2(uT * 0.2, uT * 0.025) + uSeed, P); break;
    case 10: col = sDag(q, P); break;
    case 11: col = sAstro(q, p); break;
    case 12: col = sDojima(q, p, P); break;
    case 13: col = sTicker(q, p); break;
    case 14: col = sRadar(q); break;
    case 15: col = sStone(rot(uT * 0.04) * q / (1.0 + uT * 0.05)); break;
    case 16: col = sNebra(rot(-uT * 0.05) * q); break;
    case 17: col = sEgypt(q / (1.0 + uT * 0.04)); break;
    case 18: col = sBayeux(q, P + vec2(uT * 30.0, 0.0)); break;
    case 19: col = sGreek(rot(uT * 0.12) * q); break;
    case 20: col = sDunhuang(q, p); break;
    case 21: col = sCodex(q, p); break;
    case 22: col = sCopernicus(q, p); break;
    case 23: col = sGalileo(q, p); break;
    case 24: col = sEddington(q, P); break;
    case 25: col = sTulip(q, p); break;
    case 26: col = sGenesis(q, P); break;
    default: col = vec3(0.0); break;
  }
  float r = length(q);
  float inside = 1.0 - smoothstep(1.0 - S, 1.0 + S, r);
  col = mix(col, col * uInner + vec3(0.004), inside * step(uInner, 0.99));
  fragColor = vec4(max(col, 0.0), 1.0);
}
