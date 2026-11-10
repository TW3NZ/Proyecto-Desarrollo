#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uSkin;
uniform vec4 uHair;
uniform vec4 uShirt;
uniform vec4 uTrousers;
uniform float uFemale;
uniform vec3 uFaceStyles;
uniform sampler2D uImage;
uniform sampler2D uFaceA;
uniform sampler2D uFaceB;
out vec4 fragColor;

// Recoloración en tiempo de ejecución del PNG v2: conservar luces y sombras.
// Las regiones de color y altura son específicas de este recurso, no universales.
vec3 recolor(vec3 source, vec4 target, float referenceValue) {
  float value = max(source.r, max(source.g, source.b));
  vec3 mapped = clamp(target.rgb * value / referenceValue, 0.0, 1.0);
  return mix(source, mapped, target.a);
}

// Coordenadas normalizadas del lienzo 887 × 1774: solo sustituir cada rasgo.
float region(vec2 uv, vec4 bounds) {
  vec2 fade = vec2(0.003, 0.0015);
  vec2 low = smoothstep(bounds.xy, bounds.xy + fade, uv);
  vec2 high = 1.0 - smoothstep(bounds.zw - fade, bounds.zw, uv);
  return low.x * low.y * high.x * high.y;
}

vec3 feature(vec3 base, vec4 a, vec4 b, float style, float mask) {
  if (style < 0.5) return base;
  vec4 selected = style < 1.5 ? a : b;
  return mix(base, selected.rgb / max(selected.a, 0.001), mask * selected.a);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 sampleColor = texture(uImage, uv);
  if (sampleColor.a < 0.001) {
    fragColor = vec4(0.0);
    return;
  }
  vec3 c = sampleColor.rgb / sampleColor.a;
  vec4 a = texture(uFaceA, uv);
  vec4 b = texture(uFaceB, uv);
  float eyes = max(region(uv, vec4(0.443, 0.122, 0.542, 0.158)),
                   region(uv, vec4(0.574, 0.117, 0.632, 0.155)));
  float nose = max(region(uv, vec4(0.542, 0.152, 0.596, 0.169)),
                   region(uv, vec4(0.561, 0.135, 0.582, 0.160)));
  // La boca queda por debajo de la nariz; sus máscaras no se mezclan.
  float mouth = region(uv, vec4(0.502, 0.1685, 0.605, 0.196));
  c = feature(c, a, b, uFaceStyles.x, eyes);
  c = feature(c, a, b, uFaceStyles.y, nose * (1.0 - eyes));
  c = feature(c, a, b, uFaceStyles.z, mouth);
  vec3 result = c;
  // Camiseta verde-azulada: no afectar piel, cabello ni pantalón.
  if (uv.y > 0.21 && uv.y < 0.53 && c.g > c.r * 1.18 && c.b > c.r * 1.12) {
    result = recolor(c, uShirt, 0.42);
  } else if (uv.y > 0.47 && uv.y < 0.94 && c.b > c.r * 1.12 && c.b > c.g * 1.08) {
    result = recolor(c, uTrousers, 0.30);
  } else if (uv.y < mix(0.22, 0.42, uFemale) && c.r > c.g * 1.12 && c.g > c.b * 1.05 && c.r < 0.63
      && !(uv.y > 0.117 && uv.y < 0.197 && uv.x > 0.44 && uv.x < 0.65)) {
    result = recolor(c, uHair, 0.47);
  } else if (uv.y > 0.075 && uv.y < 0.64 && c.r > c.g * 1.16 && c.g > c.b * 1.12 && c.r >= 0.63) {
    result = recolor(c, uSkin, 0.95);
  }
  fragColor = vec4(result * sampleColor.a, sampleColor.a);
}
