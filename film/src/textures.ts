import type { Renderer } from './renderer';

const TIMES = 'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

const GENESIS_HEX =
  '01000000' + '0'.repeat(64) + '3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a' + '29ab5f49' + 'ffff001d' + '1dac2b7c' + '01' +
  '01000000' + '01' + '0'.repeat(64) + 'ffffffff' + '4d' + '04ffff001d0104' + '45' +
  Array.from(TIMES, (ch) => ch.charCodeAt(0).toString(16).padStart(2, '0')).join('') +
  'ffffffff' + '01' + '00f2052a01000000' + '43' + '41' +
  '04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f' +
  'ac' + '00000000';

const COPERNICUS = ['MERCURIUS', 'VENUS', 'TELLUS CUM ORBE LUNARI', 'MARS', 'IUPITER', 'SATURNUS', 'SPHAERA STELLARUM FIXARUM'];

function surface(width: number, height: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2D canvas is not available');
  return [canvas, ctx];
}

function seeded(seed: number): () => number {
  let s = seed;
  return () => (s = (s * 16807) % 2147483647) / 2147483647;
}

function tickerTape(r: Renderer): void {
  const [c, x] = surface(4096, 96);
  const rnd = seeded(7);
  x.fillStyle = '#e8e0c8';
  x.fillRect(0, 0, c.width, c.height);
  for (let i = 0; i < 2600; i++) {
    x.fillStyle = `rgba(120,100,70,${rnd() * 0.06})`;
    x.fillRect(rnd() * c.width, rnd() * c.height, 1 + rnd() * 3, 1);
  }
  x.fillStyle = '#1d1a16';
  x.font = '600 50px "Geist Mono"';
  x.textBaseline = 'middle';
  const letters = 'ABCDEFGHIKLMNOPRSTUW';
  const fractions = ['', ' 1/8', ' 1/4', ' 3/8', ' 1/2', ' 5/8', ' 3/4', ' 7/8'];
  let px = 20;
  while (px < c.width - 40) {
    const code = Array.from({ length: 2 + Math.floor(rnd() * 2) }, () => letters[Math.floor(rnd() * letters.length)] ?? 'A').join('');
    const quote = `${code} ${10 + Math.floor(rnd() * 140)}${fractions[Math.floor(rnd() * fractions.length)] ?? ''}   `;
    x.globalAlpha = 0.82 + rnd() * 0.18;
    x.fillText(quote, px, 50);
    px += x.measureText(quote).width;
  }
  r.upload(0, c, r.repeat);
}

function bayeux(r: Renderer): void {
  const [c, x] = surface(2048, 160);
  x.fillStyle = '#000';
  x.fillRect(0, 0, c.width, c.height);
  x.fillStyle = '#fff';
  x.font = '700 118px Georgia, serif';
  x.textBaseline = 'middle';
  x.textAlign = 'center';
  const line = 'ISTI MIRANT STELLA';
  const width = x.measureText(line).width;
  x.translate(c.width / 2, 84);
  x.scale(Math.min(1.6, (c.width - 60) / width), 1);
  x.fillText(line, 0, 0);
  r.upload(1, c, r.clamp);
}

function copernicus(r: Renderer): void {
  const [c, x] = surface(4096, COPERNICUS.length * 128);
  x.fillStyle = '#000';
  x.fillRect(0, 0, c.width, c.height);
  x.fillStyle = '#fff';
  x.font = '600 74px Georgia, serif';
  x.textBaseline = 'middle';
  x.letterSpacing = '6px';
  COPERNICUS.forEach((label, i) => x.fillText(label, 12, i * 128 + 68));
  r.upload(2, c, r.clamp);
}

export function genesisBytes(): number[] {
  return (GENESIS_HEX.match(/../g) ?? []).map((h) => parseInt(h, 16));
}

function genesis(r: Renderer): number {
  const bytes = genesisBytes();
  const messageAt = 80 + 1 + 4 + 1 + 32 + 4 + 1 + 7 + 1;
  const [c, x] = surface(3840, 2160);
  x.fillStyle = '#000';
  x.fillRect(0, 0, c.width, c.height);
  x.font = '500 56px "Geist Mono"';
  x.textBaseline = 'middle';
  const cw = x.measureText('0').width;
  const lh = 2160 / 19;
  const x0 = (3840 - cw * 68) / 2;
  for (let line = 0; line < Math.ceil(bytes.length / 16); line++) {
    const y = (line + 1) * lh;
    x.fillStyle = 'rgba(120,124,120,0.55)';
    x.fillText(`${(line * 16).toString(16).padStart(8, '0')}:`, x0, y);
    for (let i = 0; i < 16; i++) {
      const n = line * 16 + i;
      const b = bytes[n];
      if (b === undefined) break;
      const hot = n >= messageAt && n < messageAt + TIMES.length;
      x.fillStyle = hot ? 'rgba(255,255,255,0.98)' : 'rgba(170,176,170,0.7)';
      x.fillText(b.toString(16).padStart(2, '0'), x0 + cw * (10 + Math.floor(i / 2) * 5 + (i % 2) * 2), y);
      x.fillStyle = hot ? 'rgba(255,255,255,1)' : 'rgba(120,124,120,0.6)';
      x.fillText(b >= 32 && b < 127 ? String.fromCharCode(b) : '.', x0 + cw * (52 + i), y);
    }
  }
  r.upload(3, c, r.repeat);
  return bytes.length;
}

export function paintTextures(r: Renderer): { genesisBytes: number } {
  tickerTape(r);
  bayeux(r);
  copernicus(r);
  return { genesisBytes: genesis(r) };
}
