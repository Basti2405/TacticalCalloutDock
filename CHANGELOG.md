# Änderungen

## 0.1.0

Erste Fassung.

- **Verschiebbare Ansageleiste.** Waagerecht oder senkrecht, mit
  einstellbarer Knopfgröße, Abstand, Deckkraft, Skalierung und Umbruch.
  Position bleibt über Sitzungen hinweg erhalten.
- **Drei Rollenprofile** mit je acht vorbereiteten Mythik+-Ansagen für Tank,
  Heiler und Schaden – umschaltbar über Reiter an der Leiste oder
  `/tcd tank` / `/tcd heiler` / `/tcd dps`.
- **Drei Aktionen je Knopf:** Chatnachricht, Zielmarkierung und Ping –
  einzeln oder zusammen, ausgelöst durch einen einzigen Klick.
- **Automatische Kanalwahl.** Dieselbe Taste geht im Schlüsselstein in den
  Instanzchat, im Schlachtzug in den Schlachtzugschat und allein in /sagen.
  Ein Kanal, der gerade nicht möglich ist, fällt geordnet zurück statt ins
  Leere zu senden.
- **Platzhalter** `%t` (Ziel), `%f` (Fokus), `%m` (Mauszeigerziel) und `%p`
  (man selbst), mit lesbarem Ersatztext, wenn es das Ziel nicht gibt.
- **Editor im Spiel.** Knöpfe anlegen, bearbeiten, umsortieren und löschen,
  ohne eine `.lua` anzufassen.
- **Wiederholsperre** von 1,5 Sekunden je Knopf, einstellbar, gegen die
  Chatdrosselung des Servers.
- Knopf an der Minikarte, `/tcd doctor` als Selbstdiagnose.
- Deutsch und Englisch, einschließlich der Ansagen selbst.
