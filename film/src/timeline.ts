export type SceneId =
  | 'space' | 'stone' | 'nebra' | 'egypt' | 'bone' | 'bayeux' | 'engrave' | 'gold' | 'sun' | 'thermal' | 'ink' | 'astro'
  | 'clay' | 'greek' | 'bronze' | 'dunhuang' | 'codex' | 'copernicus' | 'galileo' | 'map' | 'dag' | 'eddington'
  | 'tulip' | 'dojima' | 'ticker' | 'genesis' | 'radar' | 'black';

export interface Shot {
  readonly t: number;
  readonly s: SceneId;
  readonly stamp?: string;
  readonly ink?: 'dark' | 'light';
  readonly hit?: boolean;
  readonly montage?: boolean;
  readonly phase?: 'intro' | 'end';
}

export interface Word {
  readonly t0: number;
  readonly t1: number;
  readonly text: string;
}

export interface Timeline {
  readonly fps: number;
  readonly duration: number;
  readonly bpm: number;
  readonly beat0: number;
  readonly shots: readonly Shot[];
  readonly words: readonly Word[];
  readonly montage: { readonly t0: number; readonly t1: number; readonly from: number; readonly to: number };
  readonly end: { readonly open: number; readonly corOut: number; readonly lock: number; readonly button: number; readonly out: number };
}

export const SCENES: Readonly<Record<SceneId, number>> = {
  space: 0, bone: 1, engrave: 2, gold: 3, sun: 4, thermal: 5, ink: 6, clay: 7, bronze: 8, map: 9, dag: 10, astro: 11,
  dojima: 12, ticker: 13, radar: 14, stone: 15, nebra: 16, egypt: 17, bayeux: 18, greek: 19, dunhuang: 20, codex: 21,
  copernicus: 22, galileo: 23, eddington: 24, tulip: 25, genesis: 26, black: 99,
};

export interface Look {
  readonly dof: number;
  readonly bloom: number;
}

const look = (dof: number, bloom: number): Look => ({ dof, bloom });

export const LOOK: Readonly<Record<SceneId, Look>> = {
  space: look(0, 0.55), bone: look(9, 0.12), engrave: look(4, 0.1), gold: look(8, 0.45), sun: look(6, 0.4),
  thermal: look(5, 0.3), ink: look(7, 0.1), clay: look(10, 0.1), bronze: look(9, 0.3), map: look(4, 0.08),
  dag: look(6, 0.35), astro: look(8, 0.4), dojima: look(4, 0.08), ticker: look(9, 0.22), radar: look(3, 0.6),
  stone: look(8, 0.15), nebra: look(8, 0.45), egypt: look(7, 0.15), bayeux: look(6, 0.08), greek: look(7, 0.3),
  dunhuang: look(5, 0.1), codex: look(5, 0.1), copernicus: look(4, 0.08), galileo: look(4, 0.08),
  eddington: look(5, 0.2), tulip: look(6, 0.12), genesis: look(3, 0.75), black: look(0, 0),
};

export function shotAt(tl: Timeline, t: number): number {
  let i = 0;
  while (i + 1 < tl.shots.length && (tl.shots[i + 1]?.t ?? Infinity) <= t + 1e-6) i++;
  return i;
}

export function sinceBeat(tl: Timeline, t: number): number {
  const beat = 60 / tl.bpm;
  return (((t - tl.beat0) % beat) + beat) % beat;
}

export function shotEnd(tl: Timeline, i: number): number {
  return tl.shots[i + 1]?.t ?? tl.duration;
}
