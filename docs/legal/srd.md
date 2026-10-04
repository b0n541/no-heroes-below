# SRD usage and distribution

## Source and license

Use [System Reference Document 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf) as the source for the game's SRD-based material. Its first page supplies the attribution reproduced in [NOTICE](../../NOTICE).

SRD-derived material uses [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/legalcode). A complete copy is in [licenses/CC-BY-4.0.txt](../../licenses/CC-BY-4.0.txt). Project-authored material uses the [Apache License 2.0](../../LICENSE), except where otherwise noted. Preserve the separate license terms when distributing the combined work.

The SRD grant covers the content released in that document. It does not grant permission to copy other rulebooks, artwork, characters, or settings, and CC BY 4.0 does not license trademark rights. Source imported material from the SRD itself rather than assuming that all 2024 D&D material or D&D Beyond Basic Rules is included. See the official [SRD FAQ](https://www.dndbeyond.com/srd) and [Creator FAQ](https://www.dndbeyond.com/creator-faq).

## Source and modification register

The prototype adapts the basic resolution rules below without copying SRD prose or monster stat blocks. As further material is introduced, add a row identifying its destination, the source section and page, and whether it is copied or adapted. For adaptations, describe the actual changes, including translations, wording edits, or gameplay changes. Preserve indications of previous modifications and supplied notices with the material.

| Project file or content | SRD version, section, and page | Copied or adapted; changes |
| --- | --- | --- |
| `scripts/prototypes/waking_in_the_warren.gd`: attack resolution and combat log | [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Playing the Game → D20 Tests / Attack Rolls / Rolling 20 or 1, pp. 6–7; Damage and Healing → Critical Hits, p. 16 | Adapted into original code and concise UI wording. Fixed encounter bonuses and 1d6 damage; natural 1 misses, natural 20 hits and doubles damage dice while leaving the flat bonus unchanged. No Advantage, Disadvantage, weapon tables, or monster stat blocks in this prototype. |
| `scripts/prototypes/waking_in_the_warren.gd`: pit saving throw | SRD 5.2.1, Playing the Game → D20 Tests / Saving Throws, pp. 6–7 | Adapted into a Dexterity roll against DC 13. The one-use pit, 2d6 damage on failure, safe crossing on success, and turn spent climbing are original encounter choices. |

## Game releases

Include the exact attribution from NOTICE, the source and license links, the Section 5 warranty notice, and applicable modification descriptions in every distribution containing SRD material. Make these available to players in accompanying legal documentation or an accessible credits/legal screen. Include the project license and the CC BY 4.0 license copy with release packages.

Godot exports must explicitly include the notices and license documents or ship them alongside the game; repository files alone do not establish that an exported build includes them.

Apply any release terms so recipients can still exercise their CC BY 4.0 rights in the SRD material. CC BY 4.0 Section 2(a)(5)(B) prohibits additional restrictions or effective technological measures that restrict those rights. Avoid claims of official endorsement.
