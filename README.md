# Tactical Callout Dock

**Taktische Ansagen für Mythik+ und Schlachtzüge – ein Klick statt einer
getippten Zeile mitten im Pull.**

Im Schlüsselstein ist die Ansage oft wichtiger als die Rotation: *„Warten,
Patrouille"*, *„LoS-Pull um die Ecke"*, *„Brauche Mana"*. Nur hat man beim
Tippen beide Hände am Charakter – und wenn die Zeile endlich dasteht, ist der
Pull gelaufen.

Dieses Addon legt eine kleine, frei verschiebbare Leiste auf den Bildschirm.
Ein Klick, und die Ansage steht im richtigen Kanal, der Totenschädel sitzt auf
dem Ziel und der Ping ist gesetzt.

## Was es tut

**Eine Leiste, die man dorthin schiebt, wo man hinsieht.** Waagerecht oder
senkrecht, Knopfgröße, Abstand, Deckkraft und Skalierung frei einstellbar,
mit Umbruch in mehrere Reihen. Die Position bleibt erhalten.

**Drei Rollenprofile, fertig bestückt.** Tank, Heiler und Schaden mit je acht
Ansagen aus dem echten Schlüsselstein-Alltag – von *„Gruppe wird geskippt –
Unsichtbarkeit jetzt"* bis *„Unterbrecher stehen – ich kicke zuerst"*.
Umschalten über die Reiter an der Leiste oder `/tcd tank`.

**Drei Aktionen auf einem Knopf.** Jeder Knopf kann gleichzeitig
- eine Chatnachricht senden,
- eine Zielmarkierung auf das aktuelle Ziel setzen,
- einen Ping des Spiels auslösen.

**Der Kanal stimmt von selbst.** Dieselbe Taste geht im Schlüsselstein in den
Instanzchat, im Schlachtzug in den Schlachtzugschat und allein in `/sagen`.
Das ist der Punkt, an dem die meisten Ansage-Addons danebenliegen: Ein fest
auf `RAID` gestellter Knopf sendet in einer Fünfergruppe **nichts** – und
meldet das auch nicht. Hier fällt jeder Kanal geordnet zurück, statt ins
Leere zu laufen.

**Platzhalter.** `%t` Ziel, `%f` Fokus, `%m` Mauszeigerziel, `%p` du selbst.
Gibt es das Ziel nicht, steht dort *„kein Ziel"* statt einer Lücke.

**Editor im Spiel.** Knöpfe anlegen, bearbeiten, umsortieren, löschen – ohne
eine einzige `.lua` anzufassen. Mit Vorschau der fertigen Zeile: Wer `%t`
tippt, sieht direkt darunter, welcher Name gleich im Chat steht.

## Es arbeitet auch im Kampf

Andere Aktionsleisten melden mitten im Pull *„geht erst nach dem Kampf"*.
Der Grund: Sobald ein Knopf eine Fähigkeit wirken kann, braucht er eine
geschützte Vorlage, und die darf im Kampf nicht angefasst werden.

Hier wirkt kein Knopf eine Fähigkeit – Chatnachricht, Zielmarkierung und Ping
sind ungeschützte Funktionen. Deshalb funktionieren Profilwechsel, Größe,
Ausrichtung und selbst das Verschieben der Leiste mitten im Kampf. Es gibt in
diesem Addon keine einzige Zeile, die etwas „später nachholt".

## Befehle

| Befehl | Wirkung |
|---|---|
| `/tcd` | Leiste ein- oder ausblenden |
| `/tcd config` | Editor öffnen |
| `/tcd tank` · `heiler` · `dps` | Profil wechseln |
| `/tcd lock` | Leiste feststellen oder zum Verschieben lösen |
| `/tcd reset` | Leiste zurück in die Bildschirmmitte |
| `/tcd defaults` | mitgelieferte Ansagen des Profils wiederherstellen |
| `/tcd minimap` | Knopf an der Minikarte ein-/ausblenden |
| `/tcd doctor` | Selbstdiagnose – bei Problemen zuerst |
| `/tcd help` | alle Befehle |

`/tacticaldock` tut dasselbe wie `/tcd`.

Direkt an der Leiste: **Umschalt-Klick** oder **Rechtsklick** auf einen Knopf
öffnet den Editor genau bei diesem Knopf.

## Zu den Addon-Regeln

Das Addon automatisiert **nichts**. Es gibt keinen Timer, der etwas sendet,
kein Spielereignis, an dem eine Nachricht hängt, keine Wiederholung und keine
Warteschlange. Eine Ansage entsteht ausschließlich dort, wo ein Mensch auf
einen Knopf drückt – das ist auch die Bedingung, an die Blizzard die
Ping-Schnittstelle knüpft.

Kein Knopf kann eine Fähigkeit wirken. Das ist keine Einschränkung, die
nachträglich eingebaut wurde, sondern die Entwurfsentscheidung, aus der die
Kampftauglichkeit oben überhaupt erst folgt.

## Was es *nicht* kann

Ehrlichkeit an der Stelle ist wichtiger als eine vollständig aussehende
Liste:

- **Markieren geht nur mit Recht dazu.** In einer Zufallsgruppe ohne
  Anführer- oder Assistentenrecht setzt `SetRaidTarget` nichts. Das Addon
  prüft das vorher und sagt es einmal – die Chatnachricht geht trotzdem raus.
- **Der Ping kann stumm bleiben.** `C_Ping` ist die jüngste und wackeligste
  der benutzten Schnittstellen. Ist das Ping-Rad in den Spieloptionen aus
  oder der Ort nicht dafür vorgesehen, wird der Ping übersprungen – nie die
  Ansage. `/tcd doctor` sagt, welcher der beiden Fälle vorliegt.
- **255 Zeichen sind das Ende.** Länger nimmt der Server keine Chatzeile an.
  Längere Texte werden schon im Editor gekürzt, damit man es dort sieht und
  nicht erst in der Gruppe.
- **Kein Flüstern, kein Gildenchat.** Flüstern bräuchte ein Ziel, das ein
  Knopf nicht kennen kann; der Gildenchat ist der falsche Ort für eine
  Ansage an die Gruppe, in der man gerade steht.
- **Keine Anbindung an Sammelleisten.** Titan Panel und ChocolateBar finden
  dieses Addon nicht – dafür bräuchte es LibDataBroker, und das Addon kommt
  bewusst ohne jede Fremdbibliothek aus.
- **Es liest den Kampf nicht mit.** Das Addon weiß nicht, ob gerade eine
  Patrouille kommt. Es macht das Ansagen schnell, nicht das Erkennen.

## Installieren

1. Den Ordner `TacticalCalloutDock` nach
   `World of Warcraft\_retail_\Interface\AddOns\` legen.
2. `/reload` oder WoW neu starten.
3. `/tcd doctor` zeigt, ob wirklich alles greift.

Zum Entwickeln legt `tools\junction.cmd` per Doppelklick eine Junction vom
Projektordner in das AddOns-Verzeichnis – so gibt es nur einen Dateistand.

## Entwicklung

```sh
./tools/test.sh          # Syntax, Ladeliste der .toc und Logiktests
./tools/test.sh --syntax # nur Syntax
luacheck .               # Stilprüfung
```

`tools/test.sh` baut sich beim ersten Lauf Lua 5.1 nach `.werkzeuge/` – WoW
läuft auf 5.1, und ein Test unter dem systemeigenen 5.4 sagt wenig aus.
Danach läuft alles ohne Netz.

Aufbau: `Logik/` rechnet und entscheidet und kommt ohne WoW aus – deshalb ist
es testbar. `UI/` zeichnet. `Daten/Vorgaben.lua` hält die mitgelieferten
Ansagen, `Locales/` die Texte. `Logik/Kompat.lua` ist die einzige Stelle, die
WoW-Schnittstellen anfasst.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
