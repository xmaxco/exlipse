import { spawn, type ChildProcess } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

interface Timeline {
  readonly fps: number;
  readonly duration: number;
}

interface CdpMessage {
  readonly id?: number;
  readonly method?: string;
  readonly params?: unknown;
  readonly result?: unknown;
  readonly error?: unknown;
}

const CHROME = process.env['CHROME'] ?? 'google-chrome';
const FFMPEG = process.env['FFMPEG'] ?? 'ffmpeg';
const URL_ = process.env['FILM_URL'] ?? 'http://localhost:5173/';
const PORT = Number(process.env['CDP_PORT'] ?? 9333);
const OUT = process.argv[2] ?? 'exlipse-film.mp4';
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

class Cdp {
  private id = 0;
  private readonly pending = new Map<number, (m: CdpMessage) => void>();
  private constructor(private readonly ws: WebSocket) {
    ws.onmessage = (ev) => {
      const msg = JSON.parse(String(ev.data)) as CdpMessage;
      if (msg.id !== undefined) this.pending.get(msg.id)?.(msg);
    };
  }

  static async open(url: string): Promise<Cdp> {
    const ws = new WebSocket(url);
    await new Promise((r) => (ws.onopen = r));
    return new Cdp(ws);
  }

  send<T>(method: string, params: Record<string, unknown> = {}): Promise<T> {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, (m) => (m.error ? reject(new Error(JSON.stringify(m.error))) : resolve(m.result as T)));
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate<T>(expression: string): Promise<T> {
    const r = await this.send<{ result: { value: T } }>('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    return r.result.value;
  }

  close(): void {
    this.ws.close();
  }
}

async function launch(): Promise<{ chrome: ChildProcess; cdp: Cdp; profile: string }> {
  const profile = mkdtempSync(join(tmpdir(), 'exlipse-film-'));
  const chrome = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--no-first-run', 'about:blank'], { stdio: 'ignore' });
  for (let i = 0; i < 50; i++) {
    try {
      const pages = (await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json()) as { type: string; url: string; webSocketDebuggerUrl: string }[];
      const blank = pages.find((p) => p.type === 'page' && p.url === 'about:blank');
      if (blank) return { chrome, cdp: await Cdp.open(blank.webSocketDebuggerUrl), profile };
    } catch {
      await sleep(200);
    }
  }
  chrome.kill();
  throw new Error('Chrome did not start');
}

async function main(): Promise<void> {
  const tl = JSON.parse(readFileSync(new URL('../public/timeline.json', import.meta.url), 'utf8')) as Timeline;
  const { chrome, cdp, profile } = await launch();
  const ffmpeg = spawn(FFMPEG, ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(tl.fps), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '15', '-pix_fmt', 'yuv420p', OUT], { stdio: ['pipe', 'inherit', 'inherit'] });
  try {
    await cdp.send('Page.enable');
    await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });
    await cdp.send('Page.navigate', { url: URL_ });
    await sleep(1500);
    const report = await cdp.evaluate<{ log: string[]; renderer: string }>('window.boot()');
    if (report.log.length) throw new Error(report.log.join('\n'));
    console.log(`renderer: ${report.renderer}`);
    const frames = Math.round(tl.duration * tl.fps);
    const started = Date.now();
    for (let n = 0; n < frames; n++) {
      await cdp.evaluate(`frame(${n / tl.fps})`);
      const { data } = await cdp.send<{ data: string }>('Page.captureScreenshot', { format: 'jpeg', quality: 95 });
      if (!ffmpeg.stdin?.write(Buffer.from(data, 'base64'))) await new Promise((r) => ffmpeg.stdin?.once('drain', r));
      if (n % 90 === 0) console.log(`frame ${n}/${frames} · ${((Date.now() - started) / 1000).toFixed(0)}s`);
    }
    ffmpeg.stdin?.end();
    await new Promise((r) => ffmpeg.once('close', r));
    console.log(`video: ${OUT}`);
  } finally {
    cdp.close();
    chrome.once('exit', () => rmSync(profile, { recursive: true, force: true }));
    chrome.kill();
  }
}

await main();
