import { clamp01, ease, out3 } from './ease';
import type { SceneId, Timeline } from './timeline';

export interface Face {
  readonly family: string;
  readonly weight: number;
  readonly scale: number;
  readonly tracking: number;
  readonly italic?: boolean;
  readonly upper?: boolean;
  readonly color?: string;
  readonly gradient?: keyof typeof GRADIENTS;
  readonly effect?: keyof typeof EFFECTS;
}

const EFFECTS = {
  none: 'none',
  soft: '0 0 18px rgba(0,0,0,0.55)',
  carve: '0 1px 0 rgba(255,255,255,0.22), 0 -1px 1px rgba(0,0,0,0.7), 0 0 18px rgba(0,0,0,0.55)',
  glow: '0 0 16px rgba(255,190,120,0.42), 0 0 2px rgba(255,240,220,0.6)',
  crt: '0 0 12px rgba(200,255,215,0.45), 0 0 2px rgba(255,255,255,0.85)',
  stitch: '0 0 1px rgba(60,30,20,0.9), 0 0 16px rgba(0,0,0,0.55)',
} as const;

const GRADIENTS = {
  gold: 'linear-gradient(180deg, #fff4cc 0%, #e8bb5e 46%, #a9762b 56%, #f6d98f 100%)',
  brass: 'linear-gradient(180deg, #fbe8b6 0%, #cfa152 50%, #926c2d 58%, #ebc67f 100%)',
} as const;

const brand: Face = { family: '"Inter Tight"', weight: 500, scale: 1, tracking: -0.012, color: '#f3f1ec' };
const roman = (color: string, weight = 600, effect: Face['effect'] = 'carve'): Face => ({ family: 'Cinzel', weight, scale: 0.84, tracking: 0.05, color, effect });
const book = (color: string, italic = false, weight = 600): Face => ({ family: '"Cormorant Garamond"', weight, scale: 1.12, tracking: 0, italic, color, effect: 'soft' });
const fell = (color: string, italic = false): Face => ({ family: '"IM Fell English"', weight: 400, scale: 1.1, tracking: 0, italic, color, effect: 'soft' });
const typewriter = (color: string, upper = false): Face => ({ family: '"Courier Prime"', weight: 700, scale: 0.88, tracking: 0.02, upper, color, effect: 'soft' });

export const FACES: Readonly<Record<SceneId, Face>> = {
  space: brand,
  black: brand,
  radar: { ...brand, effect: 'soft' },
  stone: roman('#ece5d6'),
  nebra: { ...roman('#ffffff', 700), gradient: 'gold' },
  egypt: roman('#f0d090'),
  bone: book('#f2e7d0'),
  bayeux: { ...roman('#f1cfa6', 700), effect: 'stitch' },
  engrave: fell('#f2ead8'),
  gold: { family: 'UnifrakturMaguntia', weight: 400, scale: 1.08, tracking: 0.01, gradient: 'gold' },
  sun: { family: '"Inter Tight"', weight: 600, scale: 1, tracking: -0.01, color: '#ffdcaa', effect: 'glow' },
  thermal: { family: '"Geist Mono"', weight: 600, scale: 0.82, tracking: 0, color: '#ffe4b8', effect: 'glow' },
  ink: book('#f2f0ea', true),
  astro: { ...roman('#ffffff'), gradient: 'brass' },
  clay: roman('#ecd0a8', 700),
  greek: roman('#f5a874', 600, 'soft'),
  bronze: roman('#bfe6d6'),
  dunhuang: book('#f4e4c8'),
  codex: roman('#a6e2e4', 700, 'soft'),
  copernicus: book('#f2eadb', false, 700),
  galileo: book('#f2eadb', true),
  map: fell('#f3ead6'),
  dag: { family: '"Playfair Display"', weight: 600, scale: 1.02, tracking: 0, italic: true, color: '#eeede8', effect: 'glow' },
  eddington: typewriter('#f2f2ee'),
  tulip: fell('#f9dcd6', true),
  dojima: { family: '"Shippori Mincho"', weight: 600, scale: 1, tracking: 0.02, color: '#f5ecde', effect: 'soft' },
  ticker: typewriter('#f0e7cd', true),
  genesis: { family: '"Geist Mono"', weight: 500, scale: 0.84, tracking: 0, color: '#e9f2ea', effect: 'crt' },
};

const WORD_PX = 72;
const WORD_MAX = 440;
const fitted = new Map<string, number>();
const measure = document.createElement('canvas').getContext('2d');

export const fontOf = (f: Face, px: number): string => `${f.italic ? 'italic ' : ''}${f.weight} ${px}px ${f.family}`;

function fit(text: string, f: Face): number {
  const key = `${text}|${fontOf(f, 1)}|${f.upper ? 1 : 0}`;
  const cached = fitted.get(key);
  if (cached !== undefined) return cached;
  const base = WORD_PX * f.scale;
  if (!measure) return base;
  measure.font = fontOf(f, base);
  const shown = f.upper ? text.toUpperCase() : text;
  const width = measure.measureText(shown).width + f.tracking * base * shown.length;
  const size = Math.min(base, (base * WORD_MAX) / width);
  fitted.set(key, size);
  return size;
}

function paint(span: HTMLElement, ch: string, f: Face, size: number, blur: number): void {
  span.textContent = ch === ' ' ? ' ' : f.upper ? ch.toUpperCase() : ch;
  span.style.font = fontOf(f, size);
  span.style.letterSpacing = `${f.tracking}em`;
  if (f.gradient) {
    span.style.backgroundImage = GRADIENTS[f.gradient];
    span.style.backgroundClip = 'text';
    span.style.webkitBackgroundClip = 'text';
    span.style.color = 'transparent';
    span.style.textShadow = 'none';
    span.style.filter = `drop-shadow(0 0 10px rgba(255,196,110,0.32))${blur ? ` blur(${blur}px)` : ''}`;
    return;
  }
  span.style.backgroundImage = 'none';
  span.style.color = f.color ?? '#fff';
  span.style.textShadow = EFFECTS[f.effect ?? 'none'];
  span.style.filter = blur ? `blur(${blur}px)` : 'none';
}

export function paintWord(node: HTMLElement, tl: Timeline, t: number, shot: number): void {
  const word = tl.words.find((w) => t >= w.t0 - 0.001 && t < w.t1);
  const current = tl.shots[shot];
  if (!word || !current) {
    node.style.opacity = '0';
    return;
  }
  const face = FACES[current.s];
  const previous = shot > 0 ? FACES[tl.shots[shot - 1]?.s ?? current.s] : face;
  const since = t - current.t;
  const fresh = word.t0 >= current.t - 1e-3;
  const letters = Array.from(word.text);
  if (node.dataset['text'] !== word.text) {
    node.replaceChildren(...letters.map(() => document.createElement('span')));
    node.dataset['text'] = word.text;
  }
  const sizeNow = fit(word.text, face);
  const sizeBefore = fit(word.text, previous);
  const step = Math.min(0.012, 0.16 / Math.max(1, letters.length));
  letters.forEach((ch, k) => {
    const span = node.children[k];
    if (!(span instanceof HTMLElement)) return;
    const d = since - step * k;
    const old = !fresh && d < 0;
    paint(span, ch, old ? previous : face, old ? sizeBefore : sizeNow, !fresh && Math.abs(d) < 0.034 ? 2.4 : 0);
  });
  const enter = clamp01((t - word.t0) / 0.18);
  const leave = clamp01((word.t1 - t) / 0.16);
  node.style.opacity = String(Math.min(out3(enter), ease(leave)));
  node.style.filter = enter < 1 ? `blur(${(1 - out3(enter)) * 7}px)` : 'none';
  node.style.transform = `translateY(-50%) scale(${1.1 - 0.1 * out3(enter)})`;
}

export async function loadFaces(): Promise<string[]> {
  const faces = Object.values(FACES);
  await Promise.all(faces.map((f) => document.fonts.load(fontOf(f, 60), 'Every move an omen')));
  await Promise.all(['600 92px "Inter Tight"', '500 27px "Inter Tight"', '600 25px "Geist Mono"', '600 50px "Geist Mono"'].map((f) => document.fonts.load(f)));
  await document.fonts.ready;
  return faces.filter((f) => !document.fonts.check(fontOf(f, 60), 'Every')).map((f) => f.family);
}
