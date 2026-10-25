# LilMVP

A joke WoW Retail (Midnight) addon that posts a fake end-of-key "dungeon data" summary to party chat, one line at a time:

```
********sMecKsDungeonData Addon********
MVP: Lilputo-Shadowmoon
Top DMG: Lilputo-Shadowmoon (512.87M)
Top Healing: Kimk-Shadowmoon (194.04M)
Top Interrupts: Lilputo-Shadowmoon (58)
Top Dispels: Kimk-Shadowmoon (45)
Avoidable DMG: Lilputo-Shadowmoon (12.48K)
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


## 1.1 changes
- All lines post instantly from `/lilmvp` (WoW blocks addon chat sent on a delay, which caused "Interface action failed because of an AddOn").
- `/lilmvp auto` now pops up a **Post LilMVP** button when a Mythic+ key completes; click it to post (right-click to dismiss). `/lilmvp button` shows it any time.
