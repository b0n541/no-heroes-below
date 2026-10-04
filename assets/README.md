# No Heroes Below artwork

Ten PNG assets generated with the built-in image_gen tool on 2026-10-04, using the English game pitch and its three linked images as references. Raised 2D perspective with a slight isometric feel, charcoal outlines, painterly pixel clusters, warm amber highlights and cool cave shadows.

| File | Contents | Canvas |
| --- | --- | --- |
| `characters/piks-idle.png` | Red kobold scout, green hood and scouting whistle | 1536 × 1024 |
| `characters/mumpf-idle.png` | Ochre trapper, goggles, blue scarf, rope and mallet | 1536 × 1024 |
| `characters/krix-idle.png` | Red kobold slinger, sling and stone pouch | 1399 × 1124 |
| `characters/fighter-idle.png` | Human fighter, steel armor, sword and shield | 1536 × 1024 |
| `characters/ranger-idle.png` | Human ranger, green hood, bow and quiver | 1536 × 1024 |
| `terrain/cave-background.png` | Empty cave battlefield with rock walls, open stone floor and torches | 1672 × 941 |
| `terrain/rocks1.png` | Standalone slate boulder cluster obstacle | 1536 × 1024 |
| `terrain/rocks2.png` | Alternative slate boulder cluster obstacle | 1536 × 1024 |
| `terrain/rocks3.png` | Layered slate outcrop obstacle | 1254 × 1254 |
| `terrain/rocks4.png` | Compact cluster of three tightly packed boulders | 1536 × 1024 |
| `terrain/pantry.png` | Placeable pile of provisions: sack, basket, bread and roots | 1402 × 1122 |
| `terrain/pantry-room.png` | Kobold pantry chamber with food storage around an open floor | 1536 × 1024 |
| `traps/pit-armed.png` | Closed disguised wooden cover and rope latch | 1536 × 1024 |
| `traps/pit-triggered.png` | Collapsed cover, open pit and wooden stakes | 1536 × 1024 |

The rock, food pile, characters and traps have genuine alpha transparency. The cave and pantry-room are opaque backgrounds without characters or UI; neither is a seamless tile set. Character and trap images are individual idle/state images, with no animation.

## Godot placement

The original generated PNGs are preserved without resizing or cropping. Use nearest texture filtering to retain the pixel texture. `asset-manifest.json` records canvas sizes, visible content bounds, source-pixel pivots and suggested scales.

For a Sprite2D using the whole PNG, keep `centered = true`, set `offset = Vector2(width / 2.0, height / 2.0) - Vector2(pivot_x, pivot_y)`, and apply `suggested_uniform_scale` to both axes. Then position the unit node at its ground contact. The unit pivots approximate the midpoint of the feet. Suggested visible heights are 64 px for kobolds and 80 px for humans when the background is used at native size; adjust them to the implementation's grid.

Both pit images use the same 1536 × 1024 canvas, shared pivot and shared scale, so a texture swap retains placement. Suggested visible trap width is 80 px. Content bounds use alpha >= 128 and are supplied as metadata, not baked crops. The trap bounds differ by one pixel in height; use the shared pivot and scale for both states.

The rock obstacle and pantry food pile use pivots near their ground contacts; scale them using the manifest. The cave and pantry-room floors suggest stone cells visually; gameplay walkability and the tactical grid belong to the implementation.

## References and generation record

- [English pitch](../docs/game-pitch/no-heroes-below-game-pitch-en.md)
- [Gameplay reference](../docs/game-pitch/16-no-heroes-below-key-gameplay.png)
- [Kobold roster reference](../docs/game-pitch/14-kobold-roster.png)
- [Trap and biome reference](../docs/game-pitch/15-fallen-und-biome.png)
- [Exact final prompt set](provenance/generation-prompts.json)
- [Generated source paths](provenance/source-paths.json)

Validation: all eight files decode as PNGs; all seven sprite/state files have transparent pixels and visible foreground pixels. The pit canvases match. Each generated image was visually inspected for its subject, equipment, style and framing.
