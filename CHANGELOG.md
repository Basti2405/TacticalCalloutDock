# Änderungen

## 1.0

Erste Fassung.

- **Verschiebbare Ansageleiste.** Waagerecht oder senkrecht, mit
  einstellbarer Knopfgröße, Abstand, Deckkraft, Skalierung und Umbruch.
  Die Position bleibt über Sitzungen hinweg erhalten.
- **Drei Rollenprofile** mit je acht vorbereiteten Mythic+-Ansagen für Tank,
  Heiler und DPS – umschaltbar über die Reiter an der Leiste oder
  `/tcd tank` / `/tcd heiler` / `/tcd dps`.
- **Drei Aktionen je Knopf:** Chatnachricht, Zielmarkierung und Ping –
  einzeln oder zusammen, ausgelöst durch einen einzigen Klick.
- **Automatische Kanalwahl.** Dieselbe Taste geht im Key in den Instanzchat,
  im Raid in den Raidchat und allein in /sagen. Ein Kanal, der gerade nicht
  möglich ist, fällt geordnet zurück, statt ins Leere zu senden.
- **Platzhalter** `%t` (Ziel), `%f` (Fokus), `%m` (Mouseover) und `%p`
  (man selbst), mit lesbarem Ersatztext, wenn es das Ziel nicht gibt.
- **Editor im Spiel.** Knöpfe anlegen, bearbeiten, umsortieren und löschen,
  ohne eine `.lua` anzufassen.
- **Wiederholungssperre** von 1,5 Sekunden je Knopf, einstellbar, damit der
  Spamschutz des Servers nicht greift.
- Knopf an der Minikarte, `/tcd doctor` als Selbstdiagnose.
- Deutsch und Englisch, einschließlich der Ansagen selbst.
