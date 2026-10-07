# The Exlipse film

<img src="../assets/reveal.gif" alt="The eye opens inside the eclipse" width="480" align="right">

A 47-second film rendered entirely from code — no stock footage, no samples.

- **27 scenes in one WebGL2 fragment shader** (`src/shaders/scene.frag.glsl`): Stonehenge, the Nebra sky disc, an oracle bone,
  the Bayeux Tapestry, a Babylonian tablet, the Antikythera dial, the Dunhuang star chart, a Maya codex, Copernicus,
  Galileo's sunspots, Halley's eclipse map, a daguerreotype, the 1919 Sobral plate, tulip mania, Dojima, a stock ticker,
  the Bitcoin genesis block and a Solana radar.
- **A post pass** (`post.frag.glsl`) with depth of field, bloom and chromatic aberration on a half-float target.
- **Adaptive typography** (`src/typography.ts`): every line re-sets itself in the typeface of the era on screen,
  letter by letter, on the cut.
- **A synthesized score** (`audio/synth.py`): drone, formant choir, taiko, per-era foley, riser and a singing bowl —
  cut to a 120 BPM grid shared with the picture.

<br clear="right">

```
film/
├── index.html            stage: canvas, eye mask, text layers
├── public/timeline.json  every shot, word and cue, on the beat grid
├── src/
│   ├── main.ts           frame(t): camera kick, flashes, corona, ending
│   ├── renderer.ts       WebGL2 programs, float framebuffer, post pass
│   ├── textures.ts       ticker tape, Bayeux lettering, Copernicus labels, genesis hex dump
│   ├── typography.ts     era typefaces and the letter-by-letter swap
│   ├── overlay.ts        evidence stamps, year counter, eye and lockup
│   └── shaders/          scene, post and quad shaders
├── audio/
│   ├── timeline.py       builds public/timeline.json
│   └── synth.py          renders the score to public/audio.wav
└── tools/render.ts       headless Chrome → ffmpeg, frame by frame
```

## Run

```bash
npm install
npm run dev                      # open /?play to watch it loop in the browser
python audio/timeline.py         # regenerate the edit
python audio/synth.py            # needs numpy and scipy
FILM_URL=http://localhost:5173/ npm run render -- exlipse-film.mp4
```

Rendering is deterministic: `window.frame(t)` draws any moment of the film, so the renderer simply steps through
`t = n / fps` and pipes screenshots into ffmpeg.
