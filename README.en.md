# Tactical Callout Dock

**Tactical callouts for Mythic+ and raids – one click instead of a typed line
in the middle of a pull.**

In a keystone the callout is often more important than the rotation: *"wait
for the patrol"*, *"pulling around the corner"*, *"need mana"*. The trouble is
that typing needs both hands, and by the time the line is on screen the pull
is over.

This addon puts a small, freely movable dock on your screen. One click, and
the callout is in the right channel, the skull is on the target and the ping
is placed.

## What it does

**A dock you put where you are already looking.** Horizontal or vertical,
with button size, spacing, background opacity and scale all adjustable, and
wrapping into several rows. The position is remembered.

**Three role profiles, ready to use.** Tank, healer and damage, each with
eight callouts taken from actual keystone runs – from *"skipping this pack –
invisibility now"* to *"interrupts ready – I kick first"*. Switch with the
tabs on the dock or `/tcd tank`.

**Three actions on one button.** Every button can, at the same time,
- send a chat message,
- place a raid marker on your current target,
- fire one of the game's pings.

**The channel is chosen for you.** The same key goes to instance chat in a
keystone, to raid chat in a raid and to `/say` when you are alone. This is
where most callout addons get it wrong: a button hard-wired to `RAID` sends
**nothing** in a five-player group – and does not tell you. Here every
channel falls back in order instead of disappearing.

**Placeholders.** `%t` target, `%f` focus, `%m` mouseover, `%p` yourself. If
the unit does not exist, the line reads *"no target"* rather than trailing
off.

**In-game editor.** Add, edit, reorder and delete buttons without touching a
single `.lua` file. Label, message, channel, icon, raid marker and ping sit
side by side as fields.

## It works during combat

Other action bars report *"not while in combat"* in the middle of a pull. The
reason: as soon as a button can cast a spell it needs a secure template, and
secure frames must not be touched in combat.

No button here casts anything – chat message, raid marker and ping are all
unprotected. That is why switching profiles, changing the size or direction,
and even dragging the dock all work mid-pull. There is not a single line in
this addon that defers work "until after combat".

## Commands

| Command | Effect |
|---|---|
| `/tcd` | show or hide the dock |
| `/tcd config` | open the editor |
| `/tcd tank` · `healer` · `dps` | switch profile |
| `/tcd lock` | lock or unlock the dock for dragging |
| `/tcd reset` | move the dock back to the centre |
| `/tcd defaults` | restore the built-in callouts of this profile |
| `/tcd minimap` | show or hide the minimap button |
| `/tcd doctor` | self-check – start here when something does not work |
| `/tcd help` | all commands |

`/tacticaldock` does the same as `/tcd`.

On the dock itself: **shift-click** or **right-click** a button to open the
editor at exactly that button.

## On the addon rules

This addon automates **nothing**. There is no timer that sends anything, no
game event a message hangs on, no repetition and no queue. A callout only
ever happens where a human presses a button – which is also the condition
Blizzard attaches to the ping API.

No button can cast a spell. That is not a restriction bolted on afterwards;
it is the design decision the combat behaviour above follows from.

## What it does *not* do

Being honest here matters more than a list that looks complete:

- **Marking needs permission.** Without lead or assist in a group,
  `SetRaidTarget` does nothing. The addon checks first and says so once – the
  chat message still goes out.
- **The ping may stay silent.** `C_Ping` is the youngest and least stable of
  the interfaces used here. If the ping wheel is disabled in the game options,
  or the location does not allow it, the ping is skipped – never the callout.
  `/tcd doctor` tells you which of the two applies.
- **255 characters is the limit.** The server takes no longer chat line.
  Longer texts are trimmed in the editor so you notice there, not in front of
  your group.
- **No whispers, no guild chat.** A whisper would need a target a button
  cannot know; guild chat is the wrong place for a callout to the group you
  are currently standing in.
- **No broker support.** Titan Panel and ChocolateBar will not find this
  addon – that would need LibDataBroker, and this addon deliberately ships
  without any external library.
- **It does not read the fight.** The addon does not know a patrol is coming.
  It makes calling things out fast, not noticing them.

## Installing

1. Put the `TacticalCalloutDock` folder into
   `World of Warcraft\_retail_\Interface\AddOns\`.
2. `/reload` or restart WoW.
3. `/tcd doctor` shows whether everything is actually in place.

For development, `tools\junction.cmd` creates a junction from the project
folder into the AddOns directory, so there is only ever one copy of the files.

## Development

```sh
./tools/test.sh          # syntax, .toc load list and logic tests
./tools/test.sh --syntax # syntax only
luacheck .               # style check
```

`tools/test.sh` builds Lua 5.1 into `.werkzeuge/` on first run – WoW runs on
5.1, and testing against a system 5.4 says little. After that it works
offline.

Layout: `Logik/` computes and decides and needs no WoW, which is what makes it
testable. `UI/` draws. `Daten/Vorgaben.lua` holds the built-in callouts,
`Locales/` the texts. `Logik/Kompat.lua` is the only place that touches WoW
interfaces.

Note on the source: folder names, comments and identifiers are German – that
is the house style across these addons. The player-facing strings are in
`Locales/` in both English and German.

## License

MIT – see [LICENSE](LICENSE).
