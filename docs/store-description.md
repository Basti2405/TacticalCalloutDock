# Beschreibungstexte für die Verteilplattformen

Diese Datei wird **nicht** mit ausgeliefert (siehe `.pkgmeta`). Sie enthält die
Texte zum Einfügen auf CurseForge, Wago und WoWInterface.

CurseForge verlangt eine **englische**, grammatikalisch saubere Beschreibung —
unabhängig davon, dass das Addon auch Deutsch spricht. Deshalb ist der
Haupttext englisch; die deutsche Fassung steht darunter und kann bei Wago
zusätzlich verwendet werden.

Nicht in die Beschreibung aufnehmen: Spenden- oder Partnerlinks im Kopfbereich.
Blizzards Addon-Policy untersagt das Einwerben von Spenden; CurseForge duldet
dezente Links ausschließlich am Seitenende.

---

## Summary (eine Zeile, für die Projektliste)

```
A movable dock of one-click tactical callouts for Mythic+ and raids: chat message, raid marker and ping in a single click.
```

## Kategorien

- **Class:** Addons
- **Main category:** *Chat & Communication* — das ist der Kern: Das Addon
  schickt eine Chatzeile. Alles andere hängt daran.
- Ergänzend passend: *Miscellaneous*, *Group Utility*

Bewusst **nicht** *Combat*: Dort erwartet man Rotationshilfen und
Kampfauswertung. Wer das Addon dort sucht und findet, ist enttäuscht — und wer
es dort einordnet, weckt genau den Verdacht der Automatisierung, den die
Beschreibung anschließend ausräumen muss.

---

## Description (English — für CurseForge)

```
## Tactical Callout Dock

In a keystone the callout is often more important than the rotation: *"wait for
the patrol"*, *"pulling around the corner"*, *"need mana"*. The trouble is that
typing needs both hands — and by the time the line is on screen, the pull is
over.

Tactical Callout Dock puts a small, freely movable bar on your screen. One
click, and the callout is in the right channel, the skull is on the target and
the ping is placed.

### Three actions on one button

Every button can do all three at once:

* **Send a chat message**, with placeholders for `%t` target, `%f` focus,
  `%m` mouseover and `%p` yourself. If the unit does not exist, the line reads
  "no target" rather than trailing off into nothing.
* **Place a raid marker** on your current target.
* **Fire one of the game's pings** — attack, warning, on my way, assist.

### The channel is chosen for you

This is where most callout addons get it wrong: a button hard-wired to `RAID`
sends **nothing** in a five-player group, and does not tell you. You press it,
see nothing, and assume the addon is broken.

Here the same key goes to instance chat in a keystone, to raid chat in a raid,
to party chat in a group and to `/say` when you are alone. Fixed channels fall
back in order too: a raid warning without lead becomes ordinary raid chat
instead of disappearing.

### Three role profiles, ready to use

Tank, healer and damage, eight callouts each, taken from actual keystone runs —
from *"skipping this pack - invisibility now"* to *"interrupts ready - I kick
first"*. Switch with the tabs on the dock or `/tcd tank`.

### Edit everything in game

Add, edit, reorder and delete buttons without touching a single Lua file.
Label, message, channel, icon, raid marker and ping sit side by side as fields.
Direction, button size, spacing, background opacity, scale and wrapping are all
adjustable.

### It works during combat

Other action bars report "not while in combat" in the middle of a pull. The
reason: as soon as a button can cast a spell it needs a secure template, and
secure frames must not be touched in combat.

No button here casts anything — chat message, raid marker and ping are all
unprotected functions. That is why switching profiles, changing size or
direction, and even dragging the dock all work mid-pull. There is not a single
line in this addon that defers work until after combat.

### Compatible with the Midnight addon rules

**It automates nothing.** There is no timer that sends anything, no game event
a message hangs on, no repetition and no queue. A callout only ever happens
where a human presses a button — which is also the condition Blizzard attaches
to the ping API.

No button can cast a spell. That is not a restriction added afterwards; it is
the design decision the combat behaviour above follows from.

### Honest about its limits

* Marking needs lead or assist in a group. The addon checks first and says so
  once — the chat message still goes out.
* The ping may stay silent if the ping wheel is disabled in your game options.
  The callout never is. `/tcd doctor` tells you which case applies.
* 255 characters is the server's limit for a chat line. Longer texts are
  trimmed in the editor, so you notice there and not in front of your group.
* No whispers and no guild chat: a whisper would need a target a button cannot
  know.
* No broker support — the addon deliberately ships without any external
  library, so Titan Panel and ChocolateBar will not find it. The minimap button
  is built in.

### Languages

English and German, including the callouts themselves — on a German realm
nobody wants to send English lines to their group. The interface follows your
game client. After the first login the texts belong to you and are never
overwritten by an update.

### Commands

* `/tcd` — show or hide the dock
* `/tcd config` — open the editor
* `/tcd tank` | `healer` | `dps` — switch profile
* `/tcd lock` — lock or unlock the dock for dragging
* `/tcd reset` — move the dock back to the centre of the screen
* `/tcd defaults` — restore the built-in callouts of this profile
* `/tcd minimap` — show or hide the minimap button
* `/tcd doctor` — self-check; start here when something does not work

`/tacticaldock` does the same as `/tcd`. On the dock itself, shift-click or
right-click a button to open the editor at exactly that button.

### Source code and issues

https://github.com/Basti2405/TacticalCalloutDock

MIT licensed. Built and verified against patch 12.1.0 (interface 120100).
```

---

## Beschreibung (Deutsch — für Wago, optional)

```
## Tactical Callout Dock

Im Schlüsselstein ist die Ansage oft wichtiger als die Rotation: „Warten,
Patrouille", „LoS-Pull um die Ecke", „Brauche Mana". Nur hat man beim Tippen
beide Hände am Charakter — und wenn die Zeile endlich dasteht, ist der Pull
gelaufen.

Tactical Callout Dock legt eine kleine, frei verschiebbare Leiste auf den
Bildschirm. Ein Klick, und die Ansage steht im richtigen Kanal, der
Totenschädel sitzt auf dem Ziel und der Ping ist gesetzt.

### Drei Aktionen auf einem Knopf

* **Chatnachricht** mit Platzhaltern: `%t` Ziel, `%f` Fokus, `%m`
  Mauszeigerziel, `%p` du selbst. Gibt es das Ziel nicht, steht dort „kein
  Ziel" statt einer Lücke.
* **Zielmarkierung** auf dem aktuellen Ziel.
* **Ping** des Spiels — Angriff, Warnung, bin unterwegs, Hilfe.

### Der Kanal stimmt von selbst

Hier liegen die meisten Ansage-Addons daneben: Ein fest auf `RAID` gestellter
Knopf sendet in einer Fünfergruppe **nichts** — und meldet das auch nicht.
Dieselbe Taste geht hier je nach Lage in Instanzchat, Schlachtzug, Gruppe oder
/sagen. Auch fest eingestellte Kanäle fallen geordnet zurück, statt ins Leere
zu senden.

### Drei Rollenprofile, fertig bestückt

Tank, Heiler und Schaden mit je acht Ansagen aus dem echten
Schlüsselstein-Alltag. Umschaltbar über Reiter an der Leiste oder `/tcd tank`.

### Editor im Spiel

Knöpfe anlegen, bearbeiten, umsortieren, löschen — ohne eine einzige Lua-Datei
anzufassen. Beschriftung, Nachricht, Kanal, Symbol, Zielmarkierung und Ping
stehen als Felder nebeneinander.

### Es arbeitet auch im Kampf

Kein Knopf wirkt eine Fähigkeit, also braucht keiner eine geschützte Vorlage.
Profilwechsel, Größe, Ausrichtung und selbst das Verschieben funktionieren
mitten im Pull. Es gibt keine Zeile, die etwas „später nachholt".

### Zu den Addon-Regeln

Es automatisiert nichts: kein Timer, kein Spielereignis, keine Wiederholung.
Eine Ansage entsteht nur dort, wo ein Mensch auf einen Knopf drückt — genau
das verlangt Blizzard für die Ping-Schnittstelle.

### Befehle

`/tcd` Leiste ein/aus · `/tcd config` Editor · `/tcd tank`|`heiler`|`dps`
Profil · `/tcd lock` feststellen · `/tcd reset` zurück in die Mitte ·
`/tcd defaults` Ansagen zurücksetzen · `/tcd doctor` Selbstdiagnose

Quelltext: https://github.com/Basti2405/TacticalCalloutDock — MIT.
```

---

## Changelog beim Datei-Upload

Das Feld hat bei der **Erstveröffentlichung** eine andere Aufgabe als später:
Dort kannte niemand das Addon vorher, ein Änderungsprotokoll liefe also ins
Leere. Hinein gehört, was das Addon kann und wogegen es geprüft ist.

### Für den ersten Upload (v0.1.0)

```
**First public release.**

A movable dock of one-click tactical callouts for Mythic+ and raids.

* Three actions per button: chat message, raid marker on your target, and one
  of the game's pings — from a single click.
* Automatic channel selection: instance chat in a keystone, raid chat in a
  raid, party chat in a group, `/say` when alone. Channels that are not
  possible right now fall back in order instead of sending into the void.
* Placeholders `%t` target, `%f` focus, `%m` mouseover, `%p` yourself, with a
  readable substitute when the unit does not exist.
* Three role profiles (tank, healer, damage) with eight prepared callouts each.
* An in-game editor: add, edit, reorder and delete buttons. No Lua editing.
* Horizontal or vertical layout with adjustable button size, spacing,
  background opacity, scale and wrapping. Position is saved.
* `/tcd doctor` — a self-check covering every game function the addon needs,
  your current group state, whether you may place markers at all, and where a
  callout on "automatic" would go right now.

English and German, including the callouts themselves. The interface follows
your game client.

Built and verified against **patch 12.1.0** (interface 120100).

Automates nothing: no timer, no game event a message hangs on, no repetition.
A callout only ever happens where a human presses a button. No button casts a
spell, which is why the dock stays fully usable during combat.
```

### Für spätere Uploads

Sobald die Projekt-ID in der `.toc` steht, füllt der Packager dieses Feld
selbst — er nimmt dafür `CHANGELOG.md` (so eingestellt über `manual-changelog`
in `.pkgmeta`). Zu beachten: Er lädt die **ganze** Datei hoch, nicht nur den
neuesten Abschnitt.

---

## Bildmaterial

**Logo** — Pflicht, mindestens 400×400 px, PNG, 1:1. Liegt fertig als
`docs/logo.png` (512×512, aus `docs/logo.svg` erzeugt). Das In-Game-Icon der
`.toc` (`Ability_Warrior_RallyingCry`) darf **nicht** als Projektlogo dienen —
es ist Blizzard-Material.

**Screenshots** — für WoW-Addons nicht zwingend, aber der wichtigste Grund,
warum jemand auf „Installieren" klickt. Drei liegen fertig unter
`docs/bilder/` und sind auf der Projektseite eingebunden:
`leiste.png` (die Leiste im Tank-Profil), `tooltip.png` (Tooltip mit
Nachricht, Zielkanal und Markierung) und `editor.jpg` (der Editor).

Für CurseForge sind sie **klein** (477 bis 860 Pixel breit, weil aus dem
laufenden Spiel zugeschnitten). Für die Projektseite reicht das; wer sie dort
hochlädt, sollte sie in voller Bildschirmauflösung neu aufnehmen.

Diese vier zeigen genau das, was die Beschreibung behauptet:

1. **Die Leiste in einem Schlüsselstein**, waagerecht über den Aktionsleisten,
   mit dem Schaden-Profil. Das ist das Bild, das erklärt, worum es geht.
2. **Der Editor**, geöffnet auf einem Knopf. Beweist die Behauptung „ohne
   Lua-Datei bearbeiten". Liegt als `docs/bilder/editor.jpg` vor.
3. **Der Chat direkt nach einem Klick**, mit der Ansage im Instanzchat und dem
   Totenschädel auf dem Ziel im selben Bild. Zeigt die drei Aktionen auf
   einmal.
4. **`/tcd doctor`** im Chatfenster. Das ist das Bild, das Vertrauen schafft:
   Man sieht, dass das Addon über sich selbst Auskunft gibt.

Noch nicht vorhanden — sie brauchen einen laufenden Client. Ohne Screenshots
lässt sich das Projekt anlegen, es sieht auf der Übersichtsseite aber leer aus.

---

## Ablauf der Veröffentlichung

Der Teil, den nur Sebastian über seine Konten erledigen kann — in dieser
Reihenfolge, weil jeder Schritt den nächsten freischaltet.

**1. Projekt auf CurseForge anlegen.**
<https://legacy.curseforge.com/wow/addons> → *Start Project*. Name
„Tactical Callout Dock", Summary und Description aus dieser Datei, Kategorie
*Chat & Communication*, Logo `docs/logo.png`. Danach steht die Projekt-ID in
der URL bzw. auf der Projektseite.

**2. Die ID in die `.toc` eintragen.** Dort steht sie auskommentiert bereit:

```
## X-Curse-Project-ID: <die Zahl>
```

Erst dann lädt der Packager überhaupt zu CurseForge hoch — vorher entsteht bei
einem Tag nur ein GitHub-Release.

**3. Den API-Schlüssel hinterlegen.**
CurseForge → *My API Tokens* → Token erzeugen. Dann im Repository unter
*Settings → Secrets and variables → Actions* als `CF_API_KEY` speichern. Per
Kommandozeile geht es auch, ohne dass der Schlüssel im Verlauf landet:

```sh
gh secret set CF_API_KEY --repo Basti2405/TacticalCalloutDock
```

Der Befehl fragt den Wert danach interaktiv ab.

**4. Erst jetzt den Versions-Tag setzen.**

```sh
git tag v0.1.0 && git push origin v0.1.0
```

Der Release-Workflow prüft, dass der Tag zur Version in der `.toc` passt, lässt
die Tests laufen, baut das Paket und lädt es hoch.

**Vorher unbedingt:** das Addon einmal im Spiel starten und `/tcd doctor`
ansehen. Ein Paket, das beim ersten Login einen Lua-Fehler wirft, ist schlechter
als gar kein Paket — und die erste Bewertung auf CurseForge bleibt stehen.

**Später, optional:** Wago (`WAGO_API_TOKEN`, `X-Wago-ID`) und WoWInterface
(`WOWI_API_TOKEN`, `X-WoWI-ID`) nach demselben Muster. Beide Zeilen stehen in
der `.toc` ebenfalls auskommentiert bereit; der Workflow reicht die Schlüssel
schon durch.
