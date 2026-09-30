# Dead Zone HUD icons

One TGA per distance band, loaded by `Modules/DeadZone/deadzone.lua`. As the
target gets closer the HUD steps down this list (far -> near):

| File              | When it shows                                   |
|-------------------|-------------------------------------------------|
| `OutOfRange.tga`  | Out of range                                    |
| `MaxRange.tga`    | Past 35 yd, still inside Auto Shot range        |
| `Range35.tga`     | 30-35 yd                                        |
| `Range30.tga`     | 25-30 yd                                        |
| `Range25.tga`     | 20-25 yd                                        |
| `Range20.tga`     | 15-20 yd                                        |
| `Range15.tga`     | 10-15 yd                                        |
| `Range10.tga`     | under 10 yd (still able to shoot)               |
| `DeadZone.tga`    | Too close to shoot, too far for melee           |
| `Melee.tga`       | Melee range                                     |

`InRange.tga` is no longer used.

Export each as **32-bit TGA with alpha, one flat layer, ~256x256**, no spaces
in the name. Overwrite the file, then fully restart the game (`/reload` does
not pick up new texture files). The Range/Max files are simple placeholders.
