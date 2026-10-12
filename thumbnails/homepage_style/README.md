# Home-page style ad thumbnails

These are glossy 3D renders (no painting), built to the formula that top home-page games use:
- one or two huge subjects;
- the bacon-hair avatar;
- a big number in thick outlined text;
- rarity glow;
- a bright sky with speed lines.

| File | What it is |
|---|---|
| `1_tung_gold.png` | Avatar shows off a giant gold Tung Tung Tung Sahur on their fenced base. Text: `$997,151,167/s`, name, rainbow `SECRET` |
| `2_verity.png` | Same setup with a giant Verity wearing a gold halo. Text: `$2,500,000,000/s` |
| `3_skibidi_toilet.png` | Same setup with a giant shouting toilet head (no name text, to stay clear of trademark issues). Text: `$1,750,000,000/s` |
| `4_secret_hatch.png` | Avatar swings a crystal pickaxe while a purple lava egg bursts open and a black mystery silhouette with a rainbow aura climbs out. Text: `SECRET 1 IN ???`, `$1,000,000/s` |
| `icon_secret_hatch_512.png` | 512x512 icon, no text: a crystal pickaxe hits the lava egg and the mystery silhouette is inside |

All wide thumbnails are 1920x1080.

## Rebuild
Sources are in `src/`.

1. Render the color pass and the aux pass:
   ```
   node render.js V1.glsl V1_col.png 1920 1080 0
   node render.js V1.glsl V1_aux.png 1920 1080 1
   ```
   For Verity (`V2`), add `faces/verity.png` as the last argument.
2. Run the post step: `python buildS.py V1 V1.json`.
   - It needs `fonts/LuckiestGuy.ttf`.
   - `"clean": true` in the JSON selects the glossy (non-painted) look.
