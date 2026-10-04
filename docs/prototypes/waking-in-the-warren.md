# Waking in the Warren — throwaway Godot prototype

Question: does the opening defense communicate that fragile kobolds can protect their home through positioning, a trap, and understandable d20 rolls?

This is a first-playtest artifact on `prototype/waking-in-the-warren`, not a production implementation. The user's verdict belongs on [Evaluate a playable Waking in the Warren defense](https://github.com/b0n541/no-heroes-below/issues/3). Agent verification establishes runnable behavior, not the user's answer to that question.

## Run

Open `project.godot` in Godot 4.7 and press **F5**. The main scene is `scenes/prototypes/waking_in_the_warren.tscn`; the gameplay and interface are in `scripts/prototypes/waking_in_the_warren.gd`.

Alternatively run `godot --path .` from the repository root. On the current machine the executable is `/snap/bin/godot-4`. No additional dependencies or export step are needed. State is in memory; Restart resets the entire encounter.

## Controls

| Action | Input |
| --- | --- |
| Select a kobold | Click its ground cell or crew button; keys 1–3 |
| Movement / deployment | Move button or M, then a highlighted tile |
| Normal attack | Attack button or A, then an invader's ground cell |
| Signature ability | Ability button or S, then its target |
| Place preparation pit | Place pit button or T, then a gold tile |
| Commit the preview | Confirm button or Enter |
| Cancel a preview | Escape |
| Start raid / end crew turn | Button or Space |
| Reset encounter | Restart button or R |

Click ground cells rather than the tops of character sprites. Preparation permits free deployment on the right side of the cave. Every combat round gives each surviving kobold its movement allowance and one action; moving and acting may occur in either order. Movement and range count diagonal squares the same as orthogonal squares: one square costs one movement point, and a diagonally adjacent enemy is within melee range. This applies to both kobolds and adventurers. Movement cannot cross a stone corner or end on an occupied tile. Stone blocks movement and sight. Green tiles preview movement; a blue route shows its cost. Gold circles mark the selected kobold; red diamonds mark invaders.

## A first plan to try

1. Place the pit at **E4** and confirm. Position Mumpf at **E5** and Krix at **F3**. Piks can stay at **F4**.
2. Start the raid. Select Piks, choose Ability, click the fighter at **A4**, then **E4**, and confirm the Whistle. End the crew turn.
3. The fighter should approach **D4**. Whistle it toward **E4** again. Krix can preview a shot at it before the crew turn ends.
4. Watch the pit's Dexterity save and the combat log. A failed save stops movement and costs the invader its next turn; a successful save lets it cross safely. Rolls vary between runs.
5. Concentrate attacks on the isolated fighter, then deal with the ranger. Movement is still available after attacking. The ranger takes the lower route around the stone and favors Krix as an attack target.

Piks's **Whistle** targets a visible adventurer within six tiles and a visible lure tile within six of Piks. It redirects the next enemy turn and uses Piks's action without a roll. If a lure route is occupied, the enemy approaches a free adjacent tile.

Mumpf's **Quick Rig** places or resets the encounter's one pit within two squares, including diagonals, once during combat. It consumes his action. A new pit location must be unoccupied, but the existing spent pit can be rearmed while an adventurer remains on it. Rearming causes no immediate damage or saving throw and preserves any climbing penalty; the trap triggers when an invader next enters its tile. The pit is spent after one invader crosses it; kobolds cross safely.

Krix's **Stone Shot** is an attack within four tiles. A hit pushes the target one tile away along the dominant axis; the preview identifies that tile or a blocked push. Place Krix on the far side of an invader to push it onto the armed pit. The push occurs only if the target survives the attack damage.

## Provisional encounter rules

| Unit | HP | AC | Attack bonus | Attack range | Movement |
| --- | --- | --- | --- | --- | --- |
| Piks | 8 | 13 | +4 | 1 | 4 |
| Mumpf | 10 | 12 | +3 | 1 | 3 |
| Krix | 8 | 13 | +4 | 4 | 4 |
| Fighter | 18 | 15 | +4 | 1 | 3 |
| Ranger | 12 | 13 | +3 | 4 | 2 |

All attacks deal 1d6 plus a flat bonus: +1 for kobolds, +2 for invaders. An attack total equal to AC hits. Natural 1 always misses; natural 20 always hits and rolls two damage dice while keeping the flat bonus unchanged. The attack preview shows the bonus, target AC, range, line of sight, and expected hit effects. All rolls use one RandomNumberGenerator. A short die reveal and persistent scrollable log explain the outcomes.

The pit requires a Dexterity saving throw against DC 13. The fighter has +1 and the ranger +3. Failure deals 2d6 damage, ends the invader's movement, and forces it to spend its next turn climbing without attacking. Success avoids damage and movement loss. Saving throws use their total against DC; they do not use the attack-only natural-1/20 rule.

The fighter attacks the lowest-HP kobold in reach. The ranger favors Krix, then Piks, then Mumpf when a target is in range and sight. Otherwise the invaders advance toward the pantry and attack when they find a target in range. A Whistle overrides movement priority for one activation. The sidebar exposes current enemy intentions.

An invader at the pantry steals one supply per activation. Defeating both invaders wins. Losing all three supplies or having the entire crew knocked out loses. Both endings disable combat actions and offer Restart. Units at zero HP leave the battlefield without permadeath or recovery systems.

## Verification

Checked with Godot MCP on Godot 4.7.2:

- Script syntax and types pass validation.
- Actual mouse input places the preparation pit, previews and confirms a Whistle, advances enemy turns, and resolves a failed pit save. MCP input checks account for the live window scaling transform.
- Confirmed movement consumes the path length; a second action in the same round is rejected.
- Stone Shot pushes a surviving fighter onto the pit, which resolves its saving throw.
- Natural 1 misses, natural 20 rolls two damage dice, and a total equal to AC hits.
- A successful pit save consumes the pit without damage or movement restriction.
- A lethal confirmed attack produces victory. An actual enemy pantry activation produces defeat, and a crew knockout produces defeat. Restart restores preparation, HP, supplies, movement, actions, and pit availability.
- Complete legal-action playthroughs: a direct rush with seed 3 lost in round 4; a prepared trap defense with seed 9 won in round 6 with 3/3 supplies. These establish reachable outcomes, not a balance verdict.
- First-feedback checks: all 12 targeted runtime checks pass for diagonal movement, melee/ranged range, enemy melee, blocked stone corners and occupied destinations, occupied-pit rearming, and action/use limits. Actual mouse clicks and Confirm also move diagonally and reset an occupied pit; rearming preserves the invader's climbing turn and triggers only on re-entry. The live script was reloaded with the user's encounter state preserved.
- Resized windows keep the interface's proportions. Character transparency, ground pivots, cave art, both pit states, previews, and the log were visually inspected in the live scene.
- The existing `scripts/mcp_interaction_server.gd` autoload is preserved. Its project reference uses an explicit path so it also works before UID caches are built. The interaction server's existing shadowing/enum warnings remain; the prototype produces no script/runtime errors in completed checks.

## First playtest feedback

The user found trap placement satisfactory and attacks and saving throws understandable. Balance may need adjustment, but tuning is deferred. Two interaction issues were reported: the spent pit could not be rearmed while an adventurer occupied it, and diagonal movement and attacks were unavailable. The prototype now allows rearming that existing occupied pit and uses one-square diagonals for movement and range, while preventing movement across stone corners. These adjustments await the user's next playtest; they do not constitute a final verdict on the encounter.

## Playtest feedback still needed

Can you tell what each kobold can do, why an attack hit or missed, and why a pit save passed or failed? Does setting up the trap feel worthwhile compared with rushing the adventurers? Does the pantry feel like your home to defend? Report any confusing click, unreadable preview, frustrating roll, or pacing issue before this decision ticket is resolved.

## Limits and source notes

No progression, additional encounters, procedural generation, cover/Advantage system, sound, animation set, controller support, or save data. Artwork uses the supplied [asset pack](../../assets/README.md), with the original PNGs preserved; sprites are displayed from their recorded content bounds and ground pivots. The pantry is a simple drawn prop.

Rules sources and modifications are registered in [SRD usage](../legal/srd.md). The repository's [NOTICE](../../NOTICE), [project license](../../LICENSE), and [CC BY 4.0 license](../../licenses/CC-BY-4.0.txt) remain applicable. This is a runnable source prototype, not an exported release package.
