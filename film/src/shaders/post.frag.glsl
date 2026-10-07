#version 300 es
precision highp float;
uniform sampler2D uScn;
uniform vec2 uRes;
uniform float uR;
uniform float uZoom;
uniform float uDof;
uniform float uBloom;
uniform float uFlash;
uniform float uGrain;
uniform float uG;
uniform float uCA;
out vec4 fragColor;
float h2(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
vec3 tap(vec2 uv, vec2 dir, float ca, float lod){
  return vec3(textureLod(uScn, uv - dir * ca, lod).r, textureLod(uScn, uv, lod).g, textureLod(uScn, uv + dir * ca, lod).b);
}
void main(){
  vec2 frag = gl_FragCoord.xy;
  vec2 uv = frag / uRes;
  vec2 q = (frag - uRes * 0.5) / (uR * uZoom);
  float r = length(q);
  vec2 dir = uv - 0.5;
  float ca = uCA * dot(dir, dir) * 2.0;
  float coc = uDof * smoothstep(1.5, 3.4, r) * (uRes.y / 1080.0);
  vec3 col;
  if (coc < 0.75){
    col = tap(uv, dir, ca, 0.0);
  } else {
    vec3 acc = vec3(0.0);
    float lod = log2(max(coc / 7.0, 1.0));
    for (int i = 0; i < 28; i++){
      float fi = float(i) + 0.5;
      float rr = sqrt(fi / 28.0) * coc; float th = fi * 2.39996;
      acc += tap(uv + vec2(cos(th), sin(th)) * rr / uRes, dir, ca, lod);
    }
    col = acc / 28.0;
  }
  vec3 bl = max(textureLod(uScn, uv, 3.0).rgb - 0.72, 0.0) * 0.5;
  bl += max(textureLod(uScn, uv, 4.5).rgb - 0.62, 0.0) * 0.65;
  bl += max(textureLod(uScn, uv, 6.0).rgb - 0.5, 0.0) * 0.8;
  col += bl * uBloom * vec3(1.0, 0.9, 0.82);
  float vig = 1.0 - 0.36 * pow(length(dir * vec2(1.0, 0.72)) * 1.45, 2.6);
  col *= vig;
  col = col / (1.0 + max(col - 1.0, 0.0) * 0.6);
  col = mix(col, vec3(1.0), clamp(uFlash, 0.0, 1.0) * smoothstep(0.97, 1.08, r));
  vec2 gp = floor(frag * (1080.0 / uRes.y));
  col += (h2(gp + fract(uG * 13.7) * vec2(173.0, 91.0)) - 0.5) * 0.045 * uGrain;
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
