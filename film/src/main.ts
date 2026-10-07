import './style.css';
import { clamp01, ease } from './ease';
import { Overlay } from './overlay';
import { Renderer } from './renderer';
import { paintTextures } from './textures';
import { LOOK, SCENES, shotAt, shotEnd, sinceBeat } from './timeline';
import type { Timeline } from './timeline';
import { loadFaces, paintWord } from './typography';

declare global {
  interface Window {
    boot: (timeline?: Timeline) => Promise<BootReport>;
    frame: (t: number) => true;
  }
}

interface BootReport {
  readonly log: readonly string[];
  readonly renderer: string;
  readonly floatTarget: boolean;
  readonly genesisBytes: number;
  readonly missingFonts: readonly string[];
}

const canvas = document.getElementById('gl');
if (!(canvas instanceof HTMLCanvasElement)) throw new Error('#gl canvas is missing');
const word = document.getElementById('word');
if (!word) throw new Error('#word is missing');

const renderer = new Renderer(canvas);
let tl: Timeline | null = null;
let overlay: Overlay | null = null;

function frame(t: number): true {
  if (!tl || !overlay) throw new Error('boot() first');
  const i = shotAt(tl, t);
  const shot = tl.shots[i];
  if (!shot) return true;
  const end = shotEnd(tl, i);
  const local = t - shot.t;
  const montage = shot.montage === true;
  const beat = sinceBeat(tl, t);
  const e = tl.end;
  const kick = shot.hit ? 0.09 : montage ? 0.02 : 0.05;

  let zoom = 1 + kick * Math.exp(-local / 0.17) + (montage ? 0 : 0.012 * local);
  let rot = (i % 2 ? 1 : -1) * (0.015 + 0.04 * local) * (montage ? 0.4 : 1);
  let flash = shot.hit ? 0.85 * Math.exp(-local / 0.045) : 0;
  let sun: [number, number] = [0, 0];
  let corona = 1;
  let mono = 0;
  let inner = 0.06;
  let pulse = 0;
  let stars = 1;

  if (shot.s === 'space' && shot.phase === 'intro') {
    const k = 1 - Math.pow(1 - clamp01(t), 2.4);
    sun = [0.34 * (1 - k), 0.14 * (1 - k)];
    inner = 1;
    corona = t < 1 ? 0 : ease(clamp01((t - 1) / 0.35));
    flash = t >= 1 ? 0.85 * Math.exp(-(t - 1) / 0.05) : 0;
    zoom = 1 + (t >= 1 ? 0.08 * Math.exp(-(t - 1) / 0.2) : 0) + 0.01 * t;
    rot = 0;
    pulse = t >= 1 ? 0.22 * Math.exp(-beat / 0.14) : 0;
  } else if (shot.s === 'space') {
    const fade = 1 - ease(clamp01((t - e.corOut) / 1));
    inner = 1;
    mono = 1;
    rot = 0;
    corona = ease(clamp01((t - e.open) / 0.25)) * fade;
    stars = fade;
    pulse = 0.18 * Math.exp(-beat / 0.14) * fade;
    zoom = 1 + 0.09 * Math.exp(-local / 0.2);
  } else if (shot.s === 'black') {
    flash = 0;
    zoom = 1;
    rot = 0;
  }

  const look = LOOK[shot.s];
  renderer.draw(
    {
      scene: SCENES[shot.s],
      local,
      global: t,
      progress: clamp01(local / (end - shot.t)),
      seed: (((i * 7919) % 97) / 97) * 6 + 0.37,
      mono,
      corona,
      inner,
      write: 13.5 + (t - 11) * 6,
      sun,
      zoom,
      rot,
      flash,
      pulse,
      stars,
    },
    { dof: montage ? look.dof * 0.6 : look.dof, bloom: look.bloom, aberration: shot.s === 'space' ? 0.0015 : 0.003 },
  );
  paintWord(word as HTMLElement, tl, t, i);
  overlay.stamp(t, shot, end);
  overlay.ending(t, shot.s === 'space' && shot.phase === 'end');
  overlay.fade(ease(clamp01((t - e.out) / (tl.duration - e.out))));
  return true;
}

window.boot = async (timeline) => {
  tl = timeline ?? ((await (await fetch('timeline.json')).json()) as Timeline);
  overlay = new Overlay(tl);
  const missingFonts = await loadFaces();
  await overlay.mountEye('eye.svg');
  const { genesisBytes } = paintTextures(renderer);
  overlay.measure();
  return { log: renderer.log, renderer: renderer.renderer(), floatTarget: renderer.floatTarget, genesisBytes, missingFonts };
};
window.frame = frame;

if (new URLSearchParams(location.search).has('play')) {
  void window.boot().then(() => {
    const start = performance.now();
    const tick = (now: number) => {
      const t = ((now - start) / 1000) % (tl?.duration ?? 1);
      frame(t);
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  });
}
