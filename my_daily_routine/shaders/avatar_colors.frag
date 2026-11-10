#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uSkin;
uniform vec4 uHair;
uniform vec4 uShirt;
uniform vec4 uTrousers;
uniform float uFemale;
uniform vec3 uFaceStyles;
uniform vec2 uBody;
uniform vec4 uEyeColor;
uniform float uExpression;
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

vec2 sleepyEyes(vec2 uv, vec4 bounds, float fatigue) {
  float t = clamp((uv.y - bounds.y) / (bounds.w - bounds.y), 0.0, 1.0);
  float mask = region(uv, bounds);
  uv.y += (uv.y - (bounds.y + bounds.w) * 0.5) *
          0.85 * fatigue * 4.0 * t * (1.0 - t) * mask;
  return uv;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  // Feet stay at the base. Portraits receive neutral dimensions from Dart.
  uv.y = 1.0 + (uv.y - 1.0) / uBody.y;
  if (uv.y < 0.0 || uv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  // Bounded horizontal warp: preserve the head and the canvas edges.
  float bodyMask = smoothstep(0.21, 0.35, uv.y);
  uv.x += (uv.x - 0.5) * (1.0 - uBody.x) *
          4.0 * uv.x * (1.0 - uv.x) * bodyMask;
  vec2 faceUv = sleepyEyes(uv, vec4(0.443, 0.122, 0.542, 0.158), max(-uExpression, 0.0));
  faceUv = sleepyEyes(faceUv, vec4(0.574, 0.117, 0.632, 0.155), max(-uExpression, 0.0));
  vec4 sampleColor = texture(uImage, faceUv);
  if (sampleColor.a < 0.001) {
    fragColor = vec4(0.0);
    return;
  }
  vec3 c = sampleColor.rgb / sampleColor.a;
  vec4 a = texture(uFaceA, faceUv);
  vec4 b = texture(uFaceB, faceUv);
  float eyes = max(region(uv, vec4(0.443, 0.122, 0.542, 0.158)),
                   region(uv, vec4(0.574, 0.117, 0.632, 0.155)));
  float nose = max(region(uv, vec4(0.542, 0.152, 0.596, 0.169)),
                   region(uv, vec4(0.561, 0.135, 0.582, 0.160)));
  // La boca queda por debajo de la nariz; sus máscaras no se mezclan.
  float mouth = region(uv, vec4(0.502, 0.1685, 0.605, 0.196));
  c = feature(c, a, b, uFaceStyles.x, eyes);
  c = feature(c, a, b, uFaceStyles.y, nose * (1.0 - eyes));
  c = feature(c, a, b, uFaceStyles.z, mouth);
  // Temporary expressions blend over the selected mouth without saving it.
  c = mix(c, feature(c, a, b, 1.0, mouth), max(uExpression, 0.0));
  c = mix(c, feature(c, a, b, 2.0, mouth), min(max(-uExpression, 0.0) * 2.3, 1.0));
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
  // Explicit eyebrow regions: keep eyebrows linked to hair, including edges
  // excluded from the broader hair mask to protect eyes.
  float brows = max(region(uv, vec4(0.443, 0.105, 0.542, 0.125)),
                    region(uv, vec4(0.574, 0.105, 0.632, 0.124)));
  bool brown = c.r > c.g * 1.12 && c.g > c.b * 1.05 && c.r < 0.63;
  if (brown && brows > 0.0) {
    result = mix(result, recolor(c, uHair, 0.47), brows);
  }
  // Tint brown iris pixels; leave whites, catchlights and near-black pupils.
  float iris = eyes * smoothstep(0.13, 0.28, c.r) *
               (1.0 - smoothstep(0.55, 0.65, c.r));
  if (brown && uv.y > 0.13) {
    result = mix(result, recolor(c, uEyeColor, 0.40), iris);
  }
  fragColor = vec4(result * sampleColor.a, sampleColor.a);
}
