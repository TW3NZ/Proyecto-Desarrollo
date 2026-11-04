# Prompts del concepto de avatar

## Avatar v2 — 2026-11-04

Herramienta integrada `image_gen`, con `transparent_background: true` y la última imagen compartida por el usuario como referencia visual (`num_last_images_to_include: 1`). Recurso seleccionado: `my_daily_routine/lib/assets/avatar_human_v2.png`.

```text
Use case: stylized-concept. Create a new full-body human avatar asset for a Flutter habit app. Use the user's attached reference image ONLY for its illustration style: youthful stylized cartoon, softly sculpted simple shapes, discreet cel shadows, rounded contours, slightly oversized head but elongated young adult body, approximately 5 heads tall, relaxed confident demeanor. Do not copy the reference person's appearance, accessories, branding or environment. New character: medium warm skin, short softly swept chestnut hair, visible simple expressive brown eyes (not gigantic baby eyes), subtle smile, plain muted teal short-sleeve shirt, loose dark navy trousers, clean cream sneakers. No glasses, headphones, backpack, logos or lettering. Relaxed standing pose slightly three-quarter facing viewer, both hands visible by sides, arms slightly away from torso. Entire head and shoes inside canvas with 5 percent margins. Narrow centered silhouette. Render as polished clean 2D illustration matching the reference style, not photorealistic, not 3D. TRANSPARENT BACKGROUND with genuine alpha, no room, no backdrop, no glow, no shadow outside silhouette. Single character only.
```

Fecha: 2026-11-04. Herramienta: generación de imágenes integrada (`image_gen`), con `transparent_background: true`. La segunda imagen es el recurso seleccionado. No se usó la API desde la aplicación.

## Generación

```text
Use case: stylized-concept. Asset type: transparent full-body avatar PNG for the center of a Flutter habit tracker called My Daily Rutine. Create one original friendly human young-adult cartoon character, gender-neutral casual appearance, warm medium skin, short dark softly rounded hair, expressive eyebrows, large simple eyes, small smiling mouth. Large head, compact body, simple mitten-like hands, relaxed standing front view, arms slightly separated from torso, both feet visible. Teal casual sweatshirt, dark navy trousers, simple light sneakers. Flat 2D geometric illustration, playful rounded shapes and confident clean silhouettes, visual simplicity of educational app characters such as Duolingo but original character and no brand elements. Minimal flat shadow shapes, no realistic texture, no gradients, no 3D. Character centered, fills about 90 percent of portrait canvas height, narrow silhouette for fitting between side menus. Genuine transparent background, no scenery, no ground, no text, no watermark, no accessories or additional characters. This is a single concept image, not a sprite sheet.
```

## Refinamiento

Entrada: la imagen generada en el paso anterior.

```text
Edit the supplied human avatar. Preserve exactly its character identity, outfit colors, pose, proportions and full-body composition. Remove ALL the diffuse colored glow/halo outside the silhouette. Outside the crisp silhouette must be completely transparent alpha zero. Use clean flat solid color fills on the character, no gradients, no texture, no soft lighting, no bloom. Keep tiny antialiasing only at edges. Leave a small transparent margin above hair and below shoes so nothing touches or is cropped by the canvas. No ground shadow. Output one transparent PNG character cutout.
```
