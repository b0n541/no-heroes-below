# Combat feedback comparison — throwaway prototype

Question: which presentation makes attacker, target, attack type, and available range easiest to read during Waking in the Warren?

This prototype compares three treatments on the real encounter board, using staged positions that show the Fighter targeting Mumpf and the Ranger targeting Krix:

1. **Attack lines** — arrows connect each adventurer to its current target; target rings mark eligible victims during an attack or Whistle selection.
2. **Range map** — legal victim tiles and Whistle destinations are tinted and outlined on the board.
3. **Attack cards** — the sidebar lists each source, target, attack type, and AC; red rings mark the threatened kobolds.

Each treatment also names attacks as `MELEE · 1` or `RANGED · N`, and the sidebar states the adventurers' next targets. The bottom switcher and F1–F3 keys change treatments without changing combat state. The selected treatment is the user's decision; this prototype does not record a winner on its own.

Run `project.godot` with Godot 4.7.2. The comparison is in `scripts/prototypes/waking_in_the_warren.gd` on the `prototype/combat-feedback-variants` branch. Restart returns to the staged comparison state.
