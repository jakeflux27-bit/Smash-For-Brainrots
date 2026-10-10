# Loading screen panels

Three 1920x1080 painted panels for the loading screen to cycle through:

| File | Scene |
|---|---|
| `1_journey.png` | Golden hour. A player in an orange hoodie, pickaxe on his shoulder, looks toward the zone portal; a giant golden egg glows on the horizon in front of the sun. |
| `2_hatch.png` | Bright day, low angle. Tung Tung Tung Sahur bursts out of a cracked egg with his bat raised while a shocked player in a purple hoodie stumbles back. |
| `3_golden_egg.png` | Starry night with an aurora. A blond player in a green hoodie smashes the Golden Egg event egg; coins and gems burst out. |

Made like the thumbnails: a 3D scene rendered with real lighting (`src/L*.glsl` + `src/avatar.glsl`),
then repainted with palette-knife strokes (`src/knife.py`). No AI image generator.
Regenerate from `src/`: `node render.js L1.glsl L1_col.png 1920 1080 0`, same with `... L1_aux.png 1920 1080 1`, then `python buildL1.py`.
