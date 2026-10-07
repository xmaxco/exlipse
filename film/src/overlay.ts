import { clamp01, inOut, lerp, out3 } from './ease';
import type { Shot, Timeline } from './timeline';

interface Lockup {
  readonly box: number;
  readonly cy: number;
  readonly eyeCx: number;
  readonly markX: number;
  readonly markH: number;
  readonly pillY: number;
}

const $ = (id: string): HTMLElement => {
  const node = document.getElementById(id);
  if (!node) throw new Error(`#${id} is missing`);
  return node;
};

const svg = (id: string): SVGElement => {
  const node = document.getElementById(id);
  if (!(node instanceof SVGElement)) throw new Error(`#${id} is not an SVG element`);
  return node;
};

export class Overlay {
  private lockup: Lockup | null = null;

  constructor(private readonly tl: Timeline) {}

  async mountEye(url: string): Promise<void> {
    const source = await (await fetch(url)).text();
    const d = / d="([^"]+)"/.exec(source)?.[1];
    if (d) svg('eyePath').setAttribute('d', d);
  }

  measure(): Lockup {
    const mark = $('mark').getBoundingClientRect();
    const box = 196;
    const glyph = box * (340 / 512);
    const gap = 30;
    const left = 960 - (glyph + gap + mark.width) / 2;
    this.lockup = { box, cy: 488, eyeCx: left + glyph / 2 + box * (4 / 512), markX: left + glyph + gap, markH: mark.height * 0.98, pillY: 600 };
    return this.lockup;
  }

  stamp(t: number, shot: Shot, end: number): void {
    const node = $('stamp');
    if (shot.montage) {
      const m = this.tl.montage;
      const k = clamp01((t - m.t0) / (m.t1 - m.t0 - 0.12));
      const year = Math.round(lerp(m.from, m.to, Math.pow(k, 1.6)));
      node.className = 'layer counter';
      node.textContent = year < 0 ? `${-year} BC` : String(year);
      node.style.opacity = '1';
      return;
    }
    node.className = 'layer';
    if (!shot.stamp) {
      node.textContent = '';
      return;
    }
    const dark = shot.ink === 'dark';
    node.textContent = shot.stamp.slice(0, Math.floor(clamp01((t - shot.t) / 0.26) * shot.stamp.length));
    node.style.color = dark ? 'rgba(18,14,10,0.96)' : 'rgba(250,248,242,0.97)';
    node.style.textShadow = dark
      ? '0 0 6px rgba(246,240,228,0.95), 0 0 16px rgba(246,240,228,0.75)'
      : '0 0 6px rgba(0,0,0,0.9), 0 0 18px rgba(0,0,0,0.65)';
    node.style.opacity = String(clamp01((end - t) / 0.1));
  }

  ending(t: number, active: boolean): void {
    const eye = $('eye');
    const mark = $('mark');
    const pill = $('pill');
    const lock = this.lockup ?? this.measure();
    const e = this.tl.end;
    if (!active) {
      for (const node of [eye, mark, pill]) node.style.opacity = '0';
      return;
    }
    const lid = 1 - out3(clamp01((t - e.open - 0.06) / 0.42));
    svg('lidU').setAttribute('transform', `translate(0 ${-160 * (1 - lid)})`);
    svg('seam').setAttribute('transform', `translate(0 ${-160 * (1 - lid)})`);
    svg('lidL').setAttribute('transform', `translate(0 ${40 * (1 - lid)})`);
    svg('seam').style.opacity = String(clamp01((lid - 0.88) / 0.12));
    const m = inOut(clamp01((t - e.lock) / 0.95));
    const box = lerp(540, lock.box, m);
    const cx = lerp(960, lock.eyeCx, m);
    const cy = lerp(540, lock.cy, m);
    eye.style.width = `${box}px`;
    eye.style.height = `${box}px`;
    eye.style.transform = `translate(${cx - box / 2}px, ${cy - box / 2}px)`;
    eye.style.opacity = String(clamp01((t - e.open) / 0.05));
    const w = out3(clamp01((t - e.lock - 0.4) / 0.7));
    mark.style.opacity = String(w);
    mark.style.transform = `translate(${lock.markX - (1 - w) * 18}px, ${lock.cy - lock.markH / 2}px)`;
    mark.style.filter = `blur(${(1 - w) * 6}px)`;
    const b = out3(clamp01((t - e.button) / 0.65));
    pill.style.opacity = String(b);
    pill.style.transform = `translate(-50%, ${lock.pillY + (1 - b) * 18}px) scale(${0.96 + 0.04 * b})`;
  }

  fade(level: number): void {
    $('fade').style.opacity = String(level);
  }
}
