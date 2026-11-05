#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uSkin;
uniform vec4 uHair;
uniform vec4 uShirt;
uniform vec4 uTrousers;
uniform float uFemale;
uniform sampler2D uImage;
out vec4 fragColor;

// Recoloración en tiempo de ejecución del PNG v2: conservar luces y sombras.
// Las regiones de color y altura son específicas de este recurso, no universales.
vec3 recolor(vec3 source, vec4 target, float referenceValue) {
  float value = max(source.r, max(source.g, source.b));
  vec3 mapped = clamp(target.rgb * value / referenceValue, 0.0, 1.0);
  return mix(source, mapped, target.a);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 sampleColor = texture(uImage, uv);
  if (sampleColor.a < 0.001) {
    fragColor = vec4(0.0);
    return;
  }
  vec3 c = sampleColor.rgb / sampleColor.a;
  vec3 result = c;
  // Camiseta verde-azulada: no afectar piel, cabello ni pantalón.
  if (uv.y > 0.21 && uv.y < 0.53 && c.g > c.r * 1.18 && c.b > c.r * 1.12) {
    result = recolor(c, uShirt, 0.42);
  } else if (uv.y > 0.47 && uv.y < 0.94 && c.b > c.r * 1.12 && c.b > c.g * 1.08) {
    result = recolor(c, uTrousers, 0.30);
  } else if (uv.y < mix(0.22, 0.42, uFemale) && c.r > c.g * 1.12 && c.g > c.b * 1.05 && c.r < 0.63
      && !(uv.y > 0.123 && uv.y < 0.157 && uv.x > 0.44 && uv.x < 0.65)) {
    result = recolor(c, uHair, 0.47);
  } else if (uv.y > 0.075 && uv.y < 0.64 && c.r > c.g * 1.16 && c.g > c.b * 1.12 && c.r >= 0.63) {
    result = recolor(c, uSkin, 0.95);
  }
  fragColor = vec4(result * sampleColor.a, sampleColor.a);
}
