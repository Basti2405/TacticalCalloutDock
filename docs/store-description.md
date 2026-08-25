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
from *"skipping this pack - shroud now"* to *"interrupts ready - I kick
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

Im Key ist die Ansage oft wichtiger als die Rotation: „Warten, Patrouille“,
„LoS-Pull um die Ecke“, „Brauche Mana“. Nur hat man beim Tippen beide Hände am
Charakter — und wenn die Zeile endlich dasteht, ist der Pull gelaufen.

Tactical Callout Dock legt eine kleine, frei verschiebbare Leiste auf den
Bildschirm. Ein Klick, und die Ansage steht im richtigen Kanal, der
Totenschädel sitzt auf dem Ziel und der Ping ist gesetzt.

### Drei Aktionen auf einem Knopf

* **Chatnachricht** mit Platzhaltern: `%t` Ziel, `%f` Fokus, `%m` Mouseover,
  `%p` du selbst. Gibt es das Ziel nicht, steht dort „kein Ziel“ statt einer
  Lücke.
* **Zielmarkierung** auf dem aktuellen Ziel.
* **Ping** des Spiels — Angriff, Warnung, bin unterwegs, Hilfe.

### Der Kanal stimmt von selbst

Hier liegen die meisten Ansage-Addons daneben: Ein fest auf `RAID` gestellter
Knopf sendet in einer Fünfergruppe **nichts** — und meldet das auch nicht.
Dieselbe Taste geht hier je nach Lage in Instanzchat, Raid, Gruppe oder /sagen.
Auch fest eingestellte Kanäle fallen geordnet zurück, statt ins Leere zu
senden.

### Drei Rollenprofile, fertig bestückt

Tank, Heiler und DPS mit je acht Ansagen aus dem echten Key-Alltag.
Umschaltbar über die Reiter an der Leiste oder `/tcd tank`.

### Editor im Spiel

Knöpfe anlegen, bearbeiten, umsortieren, löschen — ohne eine einzige Lua-Datei
anzufassen. Beschriftung, Nachricht, Kanal, Symbol, Zielmarkierung und Ping
stehen als Felder nebeneinander.

### Es arbeitet auch im Kampf

Kein Knopf wirkt eine Fähigkeit, also braucht keiner ein Secure Template.
Profilwechsel, Größe, Ausrichtung und selbst das Verschieben funktionieren
mitten im Pull. Es gibt keine Zeile, die etwas „später nachholt“.

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

### Für den ersten Upload (v1.0)

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
warum jemand auf „Installieren“ klickt.

**Was vorliegt:** vier Bilder unter `docs/bilder/`, auf der Projektseite
eingebunden — `leiste.png` (477×188), `leiste-heiler.png` (527×211),
`tooltip.png` (546×287) und `editor.png` (878×688). Alle sind aus dem
laufenden Spiel zugeschnitten. Die drei ersten sind für CurseForge **klein**;
`editor.png` ist am 24.08.2026 durch einen Zuschnitt aus einer 3440×1440-
Aufnahme ersetzt worden und zeigt seitdem den Editor ohne Vorschauzeile und
mit den Knöpfen in zwei Reihen.

**Was auf allen vier veraltet ist.** Die Aufnahmen stammen vom 23.08.2026,
die sprachliche Überarbeitung kam am 24.08. Sichtbar falsch sind deshalb:

| Auf dem Bild | Im Addon jetzt |
|---|---|
| Reiter „Schaden“ (alle vier) | „DPS“ |
| „Umschalt-Klick: diesen Knopf bearbeiten“ (beide Tooltips) | „Shift-Klick: …“ |
| „Ziehe um die Ecke – Sichtlinie …“ | „… – LoS-Pull …“ |
| „Profil: Schaden“, „%m Mauszeigerziel“ (Editor) | „DPS“, „%m Mouseover“ |
| rote Blizzard-Auswahlfelder (Editor) | eigene dunkle Felder mit weißem Text |

Die letzte Zeile wiegt am schwersten: Der Lesbarkeits-Fix (`a6f30ca`) wurde
sechs Minuten **nach** der Aufnahme committet. Das Bild zeigt also genau den
Zustand, den der Changelog als behoben ausweist.

### Neu aufnehmen — die Vorbereitung

Einmal im Spiel setzen, dann bleibt es gespeichert:

```
/console screenshotFormat png
/console screenshotQuality 10
```

PNG statt JPEG, weil eine Benutzeroberfläche aus scharfen Kanten und Text
besteht — genau das, woran JPEG scheitert. Die Bilder landen danach in
`World of Warcraft\_retail_\Screenshots\`. Aufgenommen wird mit `Druck`,
**nicht** mit `Alt`+`Z` — das blendet die Oberfläche aus, und die ist hier der
Inhalt. In voller Bildschirmauflösung aufnehmen; das Zuschneiden kommt danach.

### Die vier Bilder

1. **Die Leiste in einem Key**, waagerecht über den Aktionsleisten, DPS-Profil,
   Reiter sichtbar. Das Bild, das erklärt, worum es überhaupt geht.
2. **Der Editor**, geöffnet auf einem Knopf, sodass rechts Beschriftung,
   Nachricht, Kanal, Symbol, Zielmarkierung und Ping nebeneinander stehen.
   Belegt die Behauptung „ohne Lua-Datei bearbeiten“.
3. **Der Chat direkt nach einem Klick** — die Ansage im Instanzchat und der
   Totenschädel auf dem Ziel im selben Bild. Zeigt die drei Aktionen auf
   einmal. Dafür vorher ein Ziel anvisieren, sonst steht dort „kein Ziel“.
4. **`/tcd doctor`** im Chatfenster, am besten in einer Gruppe — dann stehen
   dort Gruppenlage, Markierrecht und der Kanal, in den eine Ansage gerade
   ginge. Das ist das Bild, das Vertrauen schafft.

Ein fünftes wäre der **Tooltip über einem Knopf** (Nachricht mit eingesetzten
Platzhaltern, Zielkanal, Markierung) — das ist die Fassung, die schon als
`tooltip.png` vorliegt und nur größer neu aufgenommen werden müsste.

### Danach

Die Rohbilder irgendwo im Projektordner ablegen; Zuschnitt, Größe, Benennung
und das Einbinden in `docs/index.html` sind Handarbeit, die nichts vom
laufenden Client braucht.

---

## Die Felder beim Anlegen — was wohin gehört

Damit das Formular in einem Durchgang durchläuft. Was hier nicht steht, bleibt
auf der Voreinstellung.

| Feld | Wert |
|---|---|
| **Project Name** | `Tactical Callout Dock` |
| **Summary** | die eine Zeile weiter oben (122 Zeichen, Grenze ist 255) |
| **Description** | der **englische** Block weiter oben, vollständig |
| **Class** | *Addons* |
| **Main Category** | *Chat & Communication* |
| **License** | *MIT* |
| **Project URL / Slug** | `tactical-callout-dock` |

Nach dem Anlegen, in den Projekteinstellungen:

| Feld | Wert |
|---|---|
| **Avatar / Logo** | `docs/curseforge/logo-kompakt-400.png` (400×400) |
| **Source URL** | <https://github.com/Basti2405/TacticalCalloutDock> |
| **Issues URL** | <https://github.com/Basti2405/TacticalCalloutDock/issues> |
| **Wiki / Website** | <https://basti2405.github.io/TacticalCalloutDock/> |
| **Donations** | leer lassen — siehe den Hinweis am Anfang dieser Datei |

**Screenshots** kommen als eigener Reiter am Projekt. Die vier unter
`docs/bilder/` sind aus dem laufenden Spiel geschnitten und entsprechend klein
(477 bis 860 Pixel breit). Für die Projektseite reicht das, auf CurseForge
wirken sie mager — dort besser in voller Bildschirmauflösung neu aufnehmen.

**Nicht vergessen:** Die **Projekt-ID** steht danach in der URL der
Projektseite und im Reiter *Overview*. Sie ist der einzige Wert, den das
Repository von hier braucht — weiter bei Schritt 2 unten.

---

## Ablauf der Veröffentlichung

**Stand 25.08.2026:** Es gibt zwei Tags. `v1.0` (24.08.) und `v1.1.0` (25.08.,
die Fassung über das Aussehen — siehe `CHANGELOG.md`). Beide haben ein
GitHub-Release, zu CurseForge ging bei keinem etwas, weil Projekt-ID und
`CF_API_KEY` bis heute fehlen.

**Das Verschieben eines verbrauchten Tags ist damit vom Tisch.** Solange die
Projekt-ID fehlt, sammelt sich der Rückstand auf GitHub; sobald sie eingetragen
ist, geht die *nächste* Version regulär hoch. Ein `git tag -f` auf eine
Fassung, die schon veröffentlicht ist, wäre der falsche Weg — die 1.1.0 ist
draußen, und wer sie heruntergeladen hat, soll nicht plötzlich anderen Inhalt
unter derselben Nummer haben.

Die verbleibenden Schritte kann nur Sebastian über seine Konten erledigen.

**1. Projekt auf CurseForge anlegen** (falls noch nicht geschehen).
<https://legacy.curseforge.com/wow/addons> → *Start Project*. Name
„Tactical Callout Dock“, Summary und Description aus dieser Datei, Kategorie
*Chat & Communication*, Logo `docs/curseforge/logo-kompakt-400.png`. Danach
steht die Projekt-ID in der URL bzw. auf der Projektseite. Solange das Projekt
auf Freischaltung wartet, ist es öffentlich nicht auffindbar — die ID gibt es
trotzdem schon.

**2. Die ID in die `.toc` eintragen.** Dort steht sie auskommentiert bereit;
das führende `# ` muss weg:

```
## X-Curse-Project-ID: <die Zahl>
```

Erst dann lädt der Packager überhaupt zu CurseForge hoch.

**3. Den API-Schlüssel hinterlegen.**
CurseForge → *My API Tokens* → Token erzeugen. Dann im Repository unter
*Settings → Secrets and variables → Actions* als `CF_API_KEY` speichern. Per
Kommandozeile geht es auch, ohne dass der Schlüssel im Verlauf landet:

```sh
gh secret set CF_API_KEY --repo Basti2405/TacticalCalloutDock
```

Der Befehl fragt den Wert danach interaktiv ab. Kontrolle mit `gh secret list`
— dort muss `CF_API_KEY` auftauchen (der Wert selbst bleibt verborgen).

**4. Einen neuen Tag setzen.**
Schritt 2 macht ohnehin einen Commit — die Projekt-ID steht in der `.toc`.
Danach die Nummer in der `.toc` um eine Stelle erhöhen und tagen:

```sh
git commit -am "CurseForge-Projekt-ID eingetragen"
git push origin main
git tag v1.1.1 && git push origin v1.1.1
```

Der Workflow läuft dann als **Tag-Lauf**: Er prüft den Tag gegen die `.toc`,
lässt die Tests laufen, baut das Paket und lädt es als reguläre Fassung zu
CurseForge.

Die 1.1.1 wäre damit die erste Fassung, die auf CurseForge erscheint — mit
`CHANGELOG.md` als Beschreibung sieht auch nachvollziehbar aus, was in 1.0 und
1.1.0 davor passiert ist.

*Nur zum Ausprobieren:* `gh workflow run release.yml --ref main` startet den
Workflow ohne Tag. Dann steht in `GITHUB_REF` der Zweig, der Tag-Abgleich wird
übersprungen und der Packager lädt eine **Alpha** hoch — brauchbar zum Testen
der Zugangsdaten, nicht für die Erstveröffentlichung.

**Vor jedem Upload:** das Addon einmal im Spiel starten und `/tcd doctor`
ansehen. Ein Paket, das beim ersten Login einen Lua-Fehler wirft, ist schlechter
als gar kein Paket — und die erste Bewertung auf CurseForge bleibt stehen.

**Später, optional:** Wago (`WAGO_API_TOKEN`, `X-Wago-ID`) und WoWInterface
(`WOWI_API_TOKEN`, `X-WoWI-ID`) nach demselben Muster. Beide Zeilen stehen in
der `.toc` ebenfalls auskommentiert bereit; der Workflow reicht die Schlüssel
schon durch.
