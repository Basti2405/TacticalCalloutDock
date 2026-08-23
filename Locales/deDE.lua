-- Locales/deDE.lua - Deutsch
--
-- luacheck: max_line_length 400
--
-- Diese Datei ueberschreibt nur einzelne Schluessel aus enUS.lua. Was hier
-- fehlt, bleibt englisch - das ist gewollt und kein Fehler.
--
-- HIER stehen die echten Umlaute. Im uebrigen Quelltext wird "ue", "oe", "ae"
-- geschrieben; nur das, was der Spieler liest, bekommt richtige Zeichen.
-- Die Datei ist deshalb UTF-8 ohne BOM - WoW erwartet das so.
local addonName, TCD = ...

local L = TCD.L

-- ---------------------------------------------------------------------------
-- Meldungen im Chatfenster
-- ---------------------------------------------------------------------------
L.MSG_LOADED           = "geladen. %s zeigt die Leiste, %s öffnet den Editor."
L.MSG_THROTTLED        = "Langsam – diese Ansage ging vor weniger als %.1f Sekunden schon einmal raus."
L.MSG_NO_MARK_RIGHT    = "Zum Markieren brauchst du in der Gruppe Anführer- oder Assistentenrecht."
L.MSG_NO_TARGET_MARK   = "Kein Ziel zum Markieren."
L.MSG_PING_MISSING     = "Dieser Client bietet die Ping-Schnittstelle nicht – der Ping wurde übersprungen."
L.MSG_PING_BLOCKED     = "Das Spiel hat den Ping abgelehnt (Pings sind aus oder hier nicht möglich)."
L.MSG_EMPTY_MESSAGE    = "Dieser Knopf hat keinen Nachrichtentext – es wurde nichts gesendet."
L.MSG_DOCK_LOCKED      = "Leiste festgestellt."
L.MSG_DOCK_UNLOCKED    = "Leiste gelöst – mit der linken Maustaste verschieben."
L.MSG_DOCK_SHOWN       = "Leiste eingeblendet."
L.MSG_DOCK_HIDDEN      = "Leiste ausgeblendet."
L.MSG_PROFILE_SWITCHED = "Profil: %s"
L.MSG_PROFILE_UNKNOWN  = "Kein Profil namens „%s\". Vorhanden: %s"
L.MSG_RESET_DONE       = "Position zurückgesetzt, Leiste gelöst."
L.MSG_RESET_PROFILE    = "Profil „%s\" auf die mitgelieferten Ansagen zurückgesetzt."
L.MSG_NOT_IN_GROUP     = "Nicht in einer Gruppe – die Ansage ging in /sagen."

-- ---------------------------------------------------------------------------
-- Slash-Hilfe
-- ---------------------------------------------------------------------------
L.HELP_TITLE    = "Befehle:"
L.HELP_TOGGLE   = "Leiste ein- oder ausblenden"
L.HELP_CONFIG   = "Editor öffnen"
L.HELP_LOCK     = "Leiste feststellen oder zum Verschieben lösen"
L.HELP_ROLE     = "Profil wechseln (tank / heiler / dps oder ein eigener Name)"
L.HELP_RESET    = "Leiste zurück in die Bildschirmmitte holen"
L.HELP_DEFAULTS = "die mitgelieferten Ansagen des aktuellen Profils wiederherstellen"
L.HELP_MINIMAP  = "Knopf an der Minikarte ein- oder ausblenden"
L.HELP_DOCTOR   = "Selbstdiagnose – bei Problemen zuerst"
L.HELP_HELP     = "diese Liste"

-- ---------------------------------------------------------------------------
-- Rollen
-- ---------------------------------------------------------------------------
L.ROLE_TANK    = "Tank"
L.ROLE_HEALER  = "Heiler"
L.ROLE_DAMAGER = "Schaden"

-- ---------------------------------------------------------------------------
-- Kanaele
-- ---------------------------------------------------------------------------
L.CH_AUTO          = "Automatisch"
L.CH_AUTO_DESC     = "Instanzchat, Schlachtzug, Gruppe oder Sagen – je nachdem, was gerade passt."
L.CH_SAY           = "Sagen"
L.CH_YELL          = "Schreien"
L.CH_PARTY         = "Gruppe"
L.CH_RAID          = "Schlachtzug"
L.CH_RAID_WARNING  = "Schlachtzugswarnung"
L.CH_INSTANCE_CHAT = "Instanz"
L.CH_EMOTE         = "Emote"

-- ---------------------------------------------------------------------------
-- Zielmarkierungen. Die Namen sind die aus dem Spiel.
-- ---------------------------------------------------------------------------
L.MARK_NONE  = "Keine Markierung"
L.MARK_1     = "Stern"
L.MARK_2     = "Kreis"
L.MARK_3     = "Diamant"
L.MARK_4     = "Dreieck"
L.MARK_5     = "Mond"
L.MARK_6     = "Quadrat"
L.MARK_7     = "Kreuz"
L.MARK_8     = "Totenschädel"

-- ---------------------------------------------------------------------------
-- Pings
-- ---------------------------------------------------------------------------
L.PING_NONE     = "Kein Ping"
L.PING_ATTACK   = "Angriff"
L.PING_WARNING  = "Warnung"
L.PING_ONMYWAY  = "Bin unterwegs"
L.PING_ASSIST   = "Hilfe"

-- ---------------------------------------------------------------------------
-- Der Editor
-- ---------------------------------------------------------------------------
L.CFG_TITLE        = "Tactical Callout Dock – Editor"
L.CFG_TAB_BUTTONS  = "Knöpfe"
L.CFG_TAB_LAYOUT   = "Leiste"
L.CFG_PROFILE      = "Profil"
L.CFG_LIST         = "Knöpfe in diesem Profil"
L.CFG_ADD          = "Hinzufügen"
L.CFG_DELETE       = "Löschen"
L.CFG_UP           = "Hoch"
L.CFG_DOWN         = "Runter"
L.CFG_CLOSE        = "Schließen"
L.CFG_DEFAULTS     = "Mitgelieferte Ansagen wiederherstellen"
L.CFG_NEW_LABEL    = "Neu"
L.CFG_NEW_MESSAGE  = "Hier deine Ansage eintragen"
L.CFG_EMPTY        = "Noch keine Knöpfe. „Hinzufügen\" legt einen an."

L.CFG_LABEL        = "Beschriftung"
L.CFG_LABEL_TIP    = "Kurzer Text unter dem Symbol. Zwei bis drei Zeichen lesen sich bei kleinen Knöpfen am besten."
L.CFG_MESSAGE      = "Chatnachricht"
L.CFG_MESSAGE_TIP  = "Was in den Chat geht. Leer lassen für einen Knopf, der nur markiert oder pingt."
L.CFG_CHANNEL      = "Kanal"
L.CFG_ICON         = "Symbol"
L.CFG_ICON_TIP     = "Ein Texturpfad wie Interface\\Icons\\Ability_Kick oder eine Datei-ID als Zahl."
L.CFG_MARKER       = "Zielmarkierung"
L.CFG_MARKER_TIP   = "Wird auf dein aktuelles Ziel gesetzt. In der Gruppe braucht es Anführer- oder Assistentenrecht."
L.CFG_PING         = "Ping"
L.CFG_PING_TIP     = "Benutzt das Ping-Rad des Spiels. Löst nur bei einem echten Mausklick aus, nie von selbst."
L.CFG_PLACEHOLDERS = "Platzhalter: %t Ziel, %f Fokus, %m Mauszeigerziel, %p du selbst"
L.CFG_PREVIEW      = "Vorschau:"

L.CFG_LAYOUT_DIR   = "Ausrichtung"
L.CFG_HORIZONTAL   = "Waagerecht"
L.CFG_VERTICAL     = "Senkrecht"
L.CFG_SIZE         = "Knopfgröße"
L.CFG_PADDING      = "Abstand"
L.CFG_OPACITY      = "Deckkraft des Hintergrunds"
L.CFG_WRAP         = "Knöpfe je Reihe"
L.CFG_WRAP_TIP     = "0 lässt alles in einer einzigen Reihe bzw. Spalte."
L.CFG_SHOW_LABELS  = "Beschriftungen anzeigen"
L.CFG_LOCKED       = "Position feststellen"
L.CFG_SCALE        = "Skalierung"
L.CFG_THROTTLE     = "Wiederholsperre (Sekunden)"
L.CFG_THROTTLE_TIP = "Verhindert, dass derselbe Knopf zweimal kurz hintereinander feuert. Schützt vor der Chatsperre des Servers."
L.CFG_HIDE_SOLO    = "Leiste außerhalb einer Gruppe ausblenden"

-- ---------------------------------------------------------------------------
-- Tooltips
-- ---------------------------------------------------------------------------
L.TIP_CLICK      = "Linksklick: senden"
L.TIP_SHIFT      = "Umschalt-Klick: diesen Knopf bearbeiten"
L.TIP_DRAG       = "Mit der linken Maustaste ziehen, um die Leiste zu verschieben."
L.TIP_MINIMAP    = "Linksklick: Leiste ein/aus"
L.TIP_MINIMAP2   = "Rechtsklick: Editor"
L.TIP_SENDS_TO   = "Geht an: %s"
L.TIP_WILL_MARK  = "Markiert dein Ziel: %s"
L.TIP_WILL_PING  = "Ping: %s"

-- ---------------------------------------------------------------------------
-- Ersatztexte fuer Platzhalter ohne Ziel
-- ---------------------------------------------------------------------------
L.SUB_NO_TARGET    = "kein Ziel"
L.SUB_NO_FOCUS     = "kein Fokus"
L.SUB_NO_MOUSEOVER = "kein Mauszeigerziel"

-- ---------------------------------------------------------------------------
-- Selbstdiagnose
-- ---------------------------------------------------------------------------
L.DOC_TITLE      = "Selbstdiagnose"
L.DOC_VERSION    = "Version %s, Schnittstelle %s, Client %s"
L.DOC_LOCALE     = "Sprache des Clients: %s"
L.DOC_API_OK     = "|cff59d98cok|r   %s  (%s)"
L.DOC_API_FAIL   = "|cffe74c3cFEHLT|r  %s"
L.DOC_API_OPT    = "|cfff1c40fnicht da|r  %s  (entbehrlich – %s)"
L.DOC_PING_NOTE  = "Pings werden dann einfach übersprungen"
L.DOC_GROUP      = "Gruppe: %s"
L.DOC_GROUP_NONE = "allein"
L.DOC_GROUP_PARTY = "Gruppe"
L.DOC_GROUP_RAID  = "Schlachtzug"
L.DOC_GROUP_INSTANCE = "Instanzgruppe"
L.DOC_MARK_RIGHT = "Darf markieren: %s"
L.DOC_YES        = "ja"
L.DOC_NO         = "nein"
L.DOC_PROFILE    = "Aktives Profil: %s (%d Knöpfe)"
L.DOC_CHANNEL    = "Eine Ansage auf „Automatisch\" ginge gerade an: %s"
L.DOC_SUMMARY_OK = "Alles, was die Leiste braucht, ist vorhanden."
L.DOC_SUMMARY_BAD = "%d benötigte Funktion(en) fehlen – so kann die Leiste nicht arbeiten. Bitte die Zeilen oben melden."

-- ===========================================================================
-- Die Vorgabe-Ansagen auf Deutsch
-- ---------------------------------------------------------------------------
-- Absichtlich in der Sprache, die im Schlüsselstein tatsächlich gesprochen
-- wird: Wer auf einem deutschen Realm spielt, will keine englischen Zeilen in
-- den Gruppenchat schicken. Wer es doch will, ändert sie im Editor – nach dem
-- ersten Start gehören die Texte dem Spieler und werden nicht mehr aus dieser
-- Datei nachgezogen.
-- ===========================================================================

-- Tank ----------------------------------------------------------------------
L.LBL_T_LOS       = "LoS"
L.SAY_T_LOS       = "Ziehe um die Ecke – Sichtlinie, bleibt hinter mir"
L.LBL_T_PATROL    = "Pat"
L.SAY_T_PATROL    = "Warten, Patrouille kommt"
L.LBL_T_SKIP      = "Skip"
L.SAY_T_SKIP      = "Gruppe wird geskippt – Unsichtbarkeit jetzt"
L.LBL_T_GATHER    = "Warte"
L.SAY_T_GATHER    = "Sammle noch ein – bitte noch nicht anfangen"
L.LBL_T_BIGPULL   = "Groß"
L.SAY_T_BIGPULL   = "Großer Pull – Cooldowns bitte"
L.LBL_T_SKULL     = "Schädel"
L.SAY_T_SKULL     = "Fokus Totenschädel %t"
L.LBL_T_KITE      = "Kite"
L.SAY_T_KITE      = "Ich kite den – bitte nicht spotten"
L.LBL_T_EXTERNAL  = "Hilfe"
L.SAY_T_EXTERNAL  = "Bin tief – externen Cooldown bitte"

-- Heiler --------------------------------------------------------------------
L.LBL_H_MANA      = "Mana"
L.SAY_H_MANA      = "Brauche Mana – kurze Pause bitte"
L.LBL_H_DRINK     = "Trinken"
L.SAY_H_DRINK     = "Ich trinke, einen Moment"
L.LBL_H_DEFS      = "Defs"
L.SAY_H_DEFS      = "Defensives jetzt – gleich kommt viel Schaden"
L.LBL_H_DISPEL    = "Disp"
L.SAY_H_DISPEL    = "Ich entzaubere – bitte auseinander"
L.LBL_H_REZ       = "Rez"
L.SAY_H_REZ       = "Bin tot – Kampfrez bitte"
L.LBL_H_PATROL    = "Pat"
L.SAY_H_PATROL    = "Warten, Patrouille kommt"
L.LBL_H_STOP      = "Stopp"
L.SAY_H_STOP      = "Bitte noch nicht pullen"
L.LBL_H_LUST      = "Lust"
L.SAY_H_LUST      = "Kampfrausch bei diesem Pull"

-- Schaden -------------------------------------------------------------------
L.LBL_D_KICK      = "Kick"
L.SAY_D_KICK      = "Unterbrecher stehen – ich kicke zuerst"
L.LBL_D_SKULL     = "Schädel"
L.SAY_D_SKULL     = "Fokus Totenschädel %t"
L.LBL_D_CROSS     = "Kreuz"
L.SAY_D_CROSS     = "Kreuz ist das zweite Ziel"
L.LBL_D_CC        = "CC"
L.SAY_D_CC        = "Mond ist unter Kontrolle – bitte nicht brechen"
L.LBL_D_CDS       = "CDs"
L.SAY_D_CDS       = "Meine Cooldowns sind bereit – los"
L.LBL_D_OMW       = "Komme"
L.SAY_D_OMW       = "Bin unterwegs"
L.LBL_D_ADDS      = "Adds"
L.SAY_D_ADDS      = "Adds kommen auf meiner Seite"
L.LBL_D_HOLD      = "Halt"
L.SAY_D_HOLD      = "Meine Cooldowns sind unten – kurz halten"
