export type MoveKind = 'pump' | 'dump';

export type HypothesisKind =
  | 'smart_money_buy'
  | 'kol_buy'
  | 'buy_cluster'
  | 'migration'
  | 'creator_action'
  | 'trending_entered'
  | 'dex_paid'
  | 'artificial_volume'
  | 'x_post'
  | 'telegram_call';

export type Level = 'low' | 'medium' | 'high';

export interface Move {
  readonly chain: string;
  readonly token: string;
  readonly kind: MoveKind;
  readonly started_at: string;
  readonly change: number;
}

export interface Evidence {
  readonly at: string;
  readonly source: 'market' | 'wallet' | 'social';
  readonly summary: string;
  readonly url?: string;
}

export interface BaseRate {
  readonly samples: number;
  readonly lift: number;
  readonly sufficient: boolean;
}

export interface Hypothesis {
  readonly kind: HypothesisKind;
  readonly confidence: number;
  readonly level: Level;
  readonly followed: boolean;
  readonly base_rate: BaseRate;
  readonly evidence: readonly Evidence[];
}

export interface Explanation {
  readonly move: Move;
  readonly hypotheses: readonly Hypothesis[];
}

export const RULES = {
  mediumFrom: 0.35,
  highFrom: 0.65,
  capWithoutBaseRate: 0.5,
  capSingleEvidence: 0.64,
  pumpMinRise: 0.4,
  dumpMinDrop: 0.5,
  moveWindowMs: 15 * 60_000,
  minLiquidityUsd: 2000,
  minWindowTrades: 20,
} as const;

export const LABELS: Readonly<Record<HypothesisKind, string>> = {
  smart_money_buy: 'Smart-money buy',
  kol_buy: 'KOL buy',
  buy_cluster: 'Buy cluster',
  migration: 'Migration',
  creator_action: 'Creator action',
  trending_entered: 'Trending entry',
  dex_paid: 'Paid promotion',
  artificial_volume: 'Artificial volume',
  x_post: 'X post',
  telegram_call: 'Telegram call',
};

export function levelOf(confidence: number): Level {
  if (confidence >= RULES.highFrom) return 'high';
  if (confidence >= RULES.mediumFrom) return 'medium';
  return 'low';
}

export function followed(move: Move, e: Evidence, graceMs: number): boolean {
  return Date.parse(e.at) > Date.parse(move.started_at) + graceMs;
}

export function cap(confidence: number, rate: BaseRate, pieces: number): number {
  let c = confidence;
  if (!rate.sufficient) c = Math.min(c, RULES.capWithoutBaseRate);
  if (pieces <= 1) c = Math.min(c, RULES.capSingleEvidence);
  return c;
}

export interface Window {
  readonly fromLow: number;
  readonly now: number;
  readonly elapsedMs: number;
  readonly liquidityUsd: number;
  readonly trades: number;
}

export function qualifiesAsPump(w: Window): boolean {
  if (w.fromLow <= 0 || w.elapsedMs > RULES.moveWindowMs) return false;
  return (w.now - w.fromLow) / w.fromLow >= RULES.pumpMinRise && w.liquidityUsd >= RULES.minLiquidityUsd && w.trades >= RULES.minWindowTrades;
}

export function problems(x: Explanation, graceMs = 60_000): string[] {
  const out: string[] = [];
  for (const h of x.hypotheses) {
    if (h.confidence < 0 || h.confidence > 1) out.push(`${h.kind}: confidence ${h.confidence} is outside [0, 1]`);
    if (h.level !== levelOf(h.confidence)) out.push(`${h.kind}: level ${h.level}, expected ${levelOf(h.confidence)}`);
    if (cap(h.confidence, h.base_rate, h.evidence.length) < h.confidence) out.push(`${h.kind}: confidence exceeds its cap`);
    const after = h.evidence.length > 0 && h.evidence.every((e) => followed(x.move, e, graceMs));
    if (after !== h.followed) out.push(`${h.kind}: followed=${h.followed}, evidence says ${after}`);
  }
  return out;
}

export function rank(x: Explanation): Hypothesis[] {
  return [...x.hypotheses].sort((a, b) => Number(a.followed) - Number(b.followed) || b.confidence - a.confidence);
}
