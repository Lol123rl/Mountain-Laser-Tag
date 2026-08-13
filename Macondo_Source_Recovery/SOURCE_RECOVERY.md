# Mountain Laser Tag — Source Recovery Note

This repository contains recovered source code from the development of **Mountain Laser Tag**.

The original local Godot project folder was lost after an earlier attempt to move the very large project through GitHub. The completed/exported game and Hackatime development history remained, but the original complete local project directory did not.

## What is recovered here

- `scripts/BattleManager.gd` — recovered late-stage BattleManager source. This is the large core game script containing game modes, artificial intelligence (AI) teams, objectives, economy/shop logic, achievements, helicopters, final-boss logic, title/menu systems, saving, and web-ending behavior.
- `scripts/Player.gd` — recovered player source with movement, shooting, Blue/Red team behavior, health, stamina, ammunition, and helicopter integration.
- `recovered_history/` — genuine historical source versions recovered from development conversations/backups. These are included because Hackatime recorded work across multiple development files/iterations.
- `project.godot` and `main.tscn` — a small reconstruction scaffold added after the loss so the recovered GDScript can be opened as a Godot project. These two scaffold files are not claimed to be the original lost scene/project files.

## Important disclosure

The files in `scripts/` and `recovered_history/` are recovered development source, not newly invented substitutes for the missing work. The original full Godot scene/asset directory could not be recovered. Hackatime provides the independent development-time record for the project.

The reconstruction scaffold exists only to make the recovered source easier to inspect and continue developing. Some original assets, scene layout details, audio, imported resources, and generated Godot files are not present.

## Why exported files are not included

The large Windows export and Godot-generated `.godot` cache are intentionally excluded from source control. They are build/generated data rather than the editable source requested for review and were also a major reason the original repository upload became impractical.
