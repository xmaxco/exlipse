export const clamp01 = (v: number): number => Math.min(1, Math.max(0, v));
export const ease = (v: number): number => v * v * (3 - 2 * v);
export const out3 = (v: number): number => 1 - Math.pow(1 - v, 3);
export const inOut = (v: number): number => (v < 0.5 ? 4 * v * v * v : 1 - Math.pow(-2 * v + 2, 3) / 2);
export const lerp = (a: number, b: number, k: number): number => a + (b - a) * k;
