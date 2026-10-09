# Game thumbnails

1920x1080 PNGs, each under 3 MB, ready to upload in the Creator Dashboard (Places > Thumbnails).

| File | Idea |
|---|---|
| `1_smash.png` | Daytime. The noob smashes a zone egg with a diamond pickaxe and the cracks glow. |
| `2_hatch.png` | Night. A cracked egg blasts gold light and a mystery brainrot silhouette with glowing eyes rises out of it (the silhouette-spin reveal). |
| `3_clash.png` | Sunset arena. The noob's pickaxe clashes with Tung Tung Tung Sahur's bat, with lightning. |

## How they were made (no AI image generator)
1. Each scene is modelled in 3D in code (`src/scene*.glsl`) and rendered with real lighting in headless Chromium/WebGL.
2. A painting pass (`src/paint2.py`) repaints it as tens of thousands of brush strokes: a Kuwahara paint filter for flat colour planes, textured bristle strokes that follow shapes and stop at edges, loose in the background and fine on faces, plus dry-brush scratches and canvas texture.
3. Light effects (glow, lightning, sparks, light beams) go on top, then the logo (`src/logo.html`).

## Regenerate
Needs Node with Playwright, plus Python with `numpy scipy opencv-python-headless`. From `src/`:
```
node render.js sceneA.glsl A_col.png 1920 1080 0
node render.js sceneA.glsl A_aux.png 1920 1080 1
python buildA.py      # writes A_final.png
```
Same for B and C. `node shot.js logo.html logo.png 1100 560` re-renders the logo.
