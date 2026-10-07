import postFrag from './shaders/post.frag.glsl?raw';
import quadVert from './shaders/quad.vert.glsl?raw';
import sceneFrag from './shaders/scene.frag.glsl?raw';

export const BASE_RADIUS = 270;

const SCENE_UNIFORMS = [
  'uRes', 'uR', 'uScene', 'uT', 'uG', 'uP', 'uSeed', 'uMono', 'uCor', 'uInner', 'uGrain', 'uWrite', 'uSun',
  'uTick', 'uZoom', 'uRot', 'uFlash', 'uPulse', 'uStars', 'uTxt', 'uTxt2', 'uTxt3',
] as const;
const POST_UNIFORMS = ['uScn', 'uRes', 'uR', 'uZoom', 'uDof', 'uBloom', 'uFlash', 'uGrain', 'uG', 'uCA'] as const;

type SceneUniform = (typeof SCENE_UNIFORMS)[number];
type PostUniform = (typeof POST_UNIFORMS)[number];

export interface SceneParams {
  readonly scene: number;
  readonly local: number;
  readonly global: number;
  readonly progress: number;
  readonly seed: number;
  readonly mono: number;
  readonly corona: number;
  readonly inner: number;
  readonly write: number;
  readonly sun: readonly [number, number];
  readonly zoom: number;
  readonly rot: number;
  readonly flash: number;
  readonly pulse: number;
  readonly stars: number;
}

export interface PostParams {
  readonly dof: number;
  readonly bloom: number;
  readonly aberration: number;
}

export type Uploader = (unit: number, source: HTMLCanvasElement, wrapS: number) => void;

export class Renderer {
  readonly log: string[] = [];
  readonly floatTarget: boolean;
  private readonly gl: WebGL2RenderingContext;
  private readonly scene: WebGLProgram;
  private readonly post: WebGLProgram;
  private readonly quad: WebGLBuffer;
  private readonly target: WebGLTexture;
  private readonly fbo: WebGLFramebuffer;
  private readonly su: Record<SceneUniform, WebGLUniformLocation | null>;
  private readonly pu: Record<PostUniform, WebGLUniformLocation | null>;

  constructor(private readonly canvas: HTMLCanvasElement) {
    const gl = canvas.getContext('webgl2', { antialias: false, preserveDrawingBuffer: true, alpha: false });
    if (!gl) throw new Error('WebGL2 is not available');
    this.gl = gl;
    this.floatTarget = gl.getExtension('EXT_color_buffer_float') !== null;
    this.scene = this.program(quadVert, sceneFrag);
    this.post = this.program(quadVert, postFrag);
    this.quad = this.must(gl.createBuffer());
    gl.bindBuffer(gl.ARRAY_BUFFER, this.quad);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
    this.target = this.must(gl.createTexture());
    gl.activeTexture(gl.TEXTURE4);
    gl.bindTexture(gl.TEXTURE_2D, this.target);
    gl.texStorage2D(gl.TEXTURE_2D, 7, this.floatTarget ? gl.RGBA16F : gl.RGBA8, canvas.width, canvas.height);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    this.fbo = this.must(gl.createFramebuffer());
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.target, 0);
    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) this.log.push('framebuffer incomplete');
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    this.su = this.locate(this.scene, SCENE_UNIFORMS);
    this.pu = this.locate(this.post, POST_UNIFORMS);
  }

  get repeat(): number {
    return this.gl.REPEAT;
  }

  get clamp(): number {
    return this.gl.CLAMP_TO_EDGE;
  }

  readonly upload: Uploader = (unit, source, wrapS) => {
    const gl = this.gl;
    const texture = this.must(gl.createTexture());
    gl.activeTexture(gl.TEXTURE0 + unit);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, source);
    gl.generateMipmap(gl.TEXTURE_2D);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrapS);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  };

  renderer(): string {
    const info = this.gl.getExtension('WEBGL_debug_renderer_info');
    return info ? String(this.gl.getParameter(info.UNMASKED_RENDERER_WEBGL)) : 'unknown';
  }

  draw(s: SceneParams, p: PostParams): void {
    const gl = this.gl;
    const W = this.canvas.width;
    const H = this.canvas.height;
    const radius = BASE_RADIUS * (H / 1080);
    gl.useProgram(this.scene);
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    gl.viewport(0, 0, W, H);
    this.bindQuad(this.scene);
    const u = this.su;
    gl.uniform2f(u.uRes, W, H);
    gl.uniform1f(u.uR, radius);
    gl.uniform1i(u.uScene, s.scene);
    gl.uniform1f(u.uT, s.local);
    gl.uniform1f(u.uG, s.global);
    gl.uniform1f(u.uP, s.progress);
    gl.uniform1f(u.uSeed, s.seed);
    gl.uniform1f(u.uMono, s.mono);
    gl.uniform1f(u.uCor, s.corona);
    gl.uniform1f(u.uInner, s.inner);
    gl.uniform1f(u.uGrain, 1);
    gl.uniform1f(u.uWrite, s.write);
    gl.uniform2f(u.uSun, s.sun[0], s.sun[1]);
    gl.uniform1f(u.uZoom, s.zoom);
    gl.uniform1f(u.uRot, s.rot);
    gl.uniform1f(u.uFlash, s.flash);
    gl.uniform1f(u.uPulse, s.pulse);
    gl.uniform1f(u.uStars, s.stars);
    gl.uniform1i(u.uTick, 0);
    gl.uniform1i(u.uTxt, 1);
    gl.uniform1i(u.uTxt2, 2);
    gl.uniform1i(u.uTxt3, 3);
    gl.drawArrays(gl.TRIANGLES, 0, 3);

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.activeTexture(gl.TEXTURE4);
    gl.bindTexture(gl.TEXTURE_2D, this.target);
    gl.generateMipmap(gl.TEXTURE_2D);
    gl.useProgram(this.post);
    gl.viewport(0, 0, W, H);
    this.bindQuad(this.post);
    const q = this.pu;
    gl.uniform1i(q.uScn, 4);
    gl.uniform2f(q.uRes, W, H);
    gl.uniform1f(q.uR, radius);
    gl.uniform1f(q.uZoom, s.zoom);
    gl.uniform1f(q.uDof, p.dof);
    gl.uniform1f(q.uBloom, p.bloom);
    gl.uniform1f(q.uFlash, s.flash);
    gl.uniform1f(q.uGrain, 1);
    gl.uniform1f(q.uG, s.global);
    gl.uniform1f(q.uCA, p.aberration);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.finish();
  }

  private bindQuad(program: WebGLProgram): void {
    const gl = this.gl;
    const at = gl.getAttribLocation(program, 'p');
    gl.bindBuffer(gl.ARRAY_BUFFER, this.quad);
    gl.enableVertexAttribArray(at);
    gl.vertexAttribPointer(at, 2, gl.FLOAT, false, 0, 0);
  }

  private program(vertex: string, fragment: string): WebGLProgram {
    const gl = this.gl;
    const program = this.must(gl.createProgram());
    gl.attachShader(program, this.shader(gl.VERTEX_SHADER, vertex));
    gl.attachShader(program, this.shader(gl.FRAGMENT_SHADER, fragment));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) this.log.push(gl.getProgramInfoLog(program) ?? 'link failed');
    return program;
  }

  private shader(type: number, source: string): WebGLShader {
    const gl = this.gl;
    const shader = this.must(gl.createShader(type));
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) this.log.push(gl.getShaderInfoLog(shader) ?? 'compile failed');
    return shader;
  }

  private locate<K extends string>(program: WebGLProgram, names: readonly K[]): Record<K, WebGLUniformLocation | null> {
    const out = {} as Record<K, WebGLUniformLocation | null>;
    for (const name of names) out[name] = this.gl.getUniformLocation(program, name);
    return out;
  }

  private must<T>(value: T | null): T {
    if (value === null) throw new Error('WebGL object allocation failed');
    return value;
  }
}
