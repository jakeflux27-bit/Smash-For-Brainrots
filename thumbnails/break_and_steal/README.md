# Break and Steal thumbnails

Painted 1920x1080 thumbnails, same pipeline as the other thumbnails (3D raymarched render, then painted with palette-knife strokes).

| File | Scene |
|---|---|
| `1_samurai_sleeping.png` | Player sneaks up with a rainbow pickaxe while a samurai boss sleeps on its eggs (Zzz, snot bubble) |
| `2_mushroom_mage_wakes.png` | Night: the Grand Mushroom Mage wakes up (?!) as the player grabs a glowing galaxy egg |
| `3_triple_t_chase.png` | Sunset: Triple T (Tung Tung Tung Sahur) swings his bat (!!) while the player runs off with the golden egg |
| `4_verity_toilet_chase.png` | Player runs off with a glowing Verity overhead while the giant toilet boss chases them past its egg nests (!!) |
| `5_toilet_cruelty_chase.png` | Player carries a terrified little toilet boss under one arm while a giant angry Cruelty bounces after them (!!) |
| `6_toilet_titan_cameraman_chase.png` | Player carries a terrified toilet boss while an angry armored Titan Cameraman (red lens, glowing core) stomps after them (!!) |
| `chase/toilet_boss_tung.png` | Player runs with Tung overhead, giant toilet boss chasing |
| `chase/cameraman_verity.png` | Player hugs Verity, giant Cameraman grabbing for it |

## Rebuild
From `src/`: `node render.js E1.glsl E1_col.png 1920 1080 0` and `... E1_aux.png 1920 1080 1`, then `python buildS.py E1 E1.json`
(needs playwright + chromium, numpy, opencv, pillow). Characters live in `chars.glsl`, the player in `avatar.glsl`.
