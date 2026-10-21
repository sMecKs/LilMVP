# LilMVP

A joke WoW Retail (Midnight) addon that posts a fake end-of-key "dungeon data" summary to party chat, one line at a time:

```
********sMecKsDungeonData Addon********
MVP: Lilputo-Shadowmoon
Top DMG: Lilputo-Shadowmoon (363.00M)
Top Healing: Kimk-Shadowmoon (194.04M)
Top Interrupts: Lilputo-Shadowmoon (36)
Top Dispels: Kimk-Shadowmoon (45)
Avoidable DMG: Lilputo-Shadowmoon (454.25K)
************************************************
```

## Install
1. Download `LilMVP-1.0.zip` from the Releases page (or Code > Download ZIP).
2. Unzip it and put the `LilMVP` folder in `World of Warcraft/_retail_/Interface/AddOns`.
3. Restart WoW or `/reload`.

## Commands
- `/lilmvp` – post to party (instance chat in a group-finder group)
- `/lilmvp preview` – show it only in your own chat (names class-colored; Lilputo in paladin pink)
- `/lilmvp say` / `party` / `instance` – post to that channel
- `/lilmvp auto` – toggle auto-post when a Mythic+ key finishes (off by default, saved)

If you're in combat, it waits and posts once combat ends.

## Edit the text
Open `LilMVP/LilMVP.lua` and change the `LINES` table at the top.
