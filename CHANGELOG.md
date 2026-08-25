# Änderungen

## 1.1.0

Eine Fassung über das Aussehen. Am Funktionsumfang ändert sich nichts – an
dem, was man davon lesen kann, alles.

- **Die Aufklappmenüs sind wieder lesbar.** Ihr Hintergrund war durchsichtig,
  und die Ursache war nicht die Farbe: Die Liste lag in derselben Ebene wie
  das Fenster und bekam ihren Rang vom Formular vererbt – also einen
  *niedrigeren* als die Eingabefelder, über die sie sich legt. WoW hat die
  Felder folglich über die Liste gezeichnet; was wie ein durchscheinender
  Hintergrund aussah, waren fremde Bedienelemente. Die Liste liegt jetzt in
  einer eigenen, höheren Ebene, ist vollständig undurchsichtig und wirft einen
  Schatten, damit man sieht, dass sie davor liegt.
- **Pixelgenaue Ränder.** WoW zeichnet die Oberfläche auf einer gedachten
  Fläche von 768 Einheiten Höhe. Auf einem 1440p-Monitor landet ein Rand der
  Breite 1 damit auf 1,875 Bildpunkten und verschmiert über zwei Reihen –
  das ist der eigentliche Grund, warum selbstgebaute Oberflächen weich
  aussehen. Jeder Rand wird jetzt aus der echten Bildschirmauflösung
  zurückgerechnet und trifft genau eine Punktreihe. Auflösungs- und
  Skalierungswechsel im laufenden Spiel werden nachgezogen.
- **Ein einheitliches Bild.** Bis 1.0 mischten sich drei fremde Handschriften:
  Blizzards Knopf mit gelber Schrift auf rotbraunem Metall, sein Eingabefeld
  mit goldenem Rahmen, sein Kontrollkasten mit einem dritten Stil. Knöpfe,
  Felder, Kästen, Reiter und Auswahllisten sind jetzt selbst gebaut, auf einer
  Palette aus fünf Graustufen und genau einer Akzentfarbe.
- **Der Editor hat eine Kopfzeile** mit Titel, aktivem Profil und
  Schließen-Kreuz; das Fenster wird an ihr gezogen. Die Reiter sind
  Unterstrich-Reiter statt gefüllter Kacheln, die Knopfliste hat eine eigene
  Nummernspalte und einen Zähler, und neben dem Symbolfeld steht eine
  Vorschau – ein Pfad, den es nicht gibt, fällt damit sofort auf statt erst
  an der Leiste.
- **Schmalere Schrift für alles Kleine.** Sie bringt bei gleicher Höhe rund
  ein Fünftel mehr Zeichen in dieselbe Breite. Deutsche Beschriftungen passen
  damit auf Knöpfe, auf denen vorher „Sch..“ stand.
- **Die Leiste** bekommt einen harten Rand statt eines weichen dunklen Saums,
  ein Aufleuchten in der Akzentfarbe unter der Maus und eine sichtbare
  Reaktion auf den Klick.
- **Der Minikarten-Knopf** zeigt jetzt, ob die Leiste eingeblendet ist –
  vorher sah er in beiden Fällen gleich aus.
- `/tcd doctor` nennt Bildschirmauflösung und Punktbreite. Damit ist
  „sieht unscharf aus“ eine beantwortbare Frage.

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
