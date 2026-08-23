-- Tests/logik-test.lua - die Logik ohne WoW pruefen
--
-- ===========================================================================
-- WARUM DAS UEBERHAUPT GEHT
-- ---------------------------------------------------------------------------
-- Dieses Addon trifft bei jedem Klick drei Entscheidungen: In welchen Kanal
-- geht die Ansage? Was steht nach dem Einsetzen der Platzhalter darin? Und
-- greift die Wiederholsperre? Alle drei haengen an Eingabewerten, nicht an
-- einem laufenden Client - genau deshalb liegen sie in Logik\ und nicht in
-- UI\ .
--
-- Gebaut wird eine WoW-Umgebung, die gerade so gross ist, dass die geprueften
-- Dateien laden und die Entscheidungen fallen koennen: ein paar
-- Einheitenfunktionen, eine Gruppe, die man von Hand umstellt, und eine Uhr,
-- die stillsteht, bis der Test sie stellt.
--
-- BESONDERS WICHTIG hier: SendChatMessage ist eine Attrappe, die nur
-- mitschreibt. So laesst sich pruefen, WAS gesendet worden WAERE - im Spiel
-- selbst kann man das nur lesen, indem man es tatsaechlich in eine Gruppe
-- schickt.
--
-- Aufruf ueber tools/test.sh (das baut Lua 5.1 dazu). Von Hand:
--     TCDPFAD=. lua Tests/logik-test.lua
-- ===========================================================================

local PFAD = os.getenv("TCDPFAD") or "."

-- ===========================================================================
-- Die WoW-Umgebung nachbauen
-- ===========================================================================

-- Eine Uhr, die stillsteht. Mit einer echten waere jede Aussage ueber die
-- Wiederholsperre von der Laufzeit des Rechners abhaengig.
local UHR = 1000

function GetTime() return UHR end

function wipe(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

function strtrim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

format = string.format

-- Der steuerbare Zustand der Testwelt.
local welt = {
    gruppe      = "SOLO",   -- SOLO | PARTY | RAID | INSTANCE
    anfuehrer   = true,
    ziel        = "Zielperson",
    fokus       = nil,
    mouseover   = nil,
    pingSystem  = true,
}

-- Was die Attrappen mitgeschrieben haben.
local mitschrift = { chat = {}, marken = {}, pings = {} }

local function mitschriftLeeren()
    mitschrift.chat, mitschrift.marken, mitschrift.pings = {}, {}, {}
end

function SendChatMessage(text, kanal)
    mitschrift.chat[#mitschrift.chat + 1] = { text = text, kanal = kanal }
end

function SetRaidTarget(einheit, index)
    mitschrift.marken[#mitschrift.marken + 1] = { einheit = einheit, index = index }
end

function UnitExists(einheit)
    if einheit == "target"    then return welt.ziel ~= nil end
    if einheit == "focus"     then return welt.fokus ~= nil end
    if einheit == "mouseover" then return welt.mouseover ~= nil end
    if einheit == "player"    then return true end
    return false
end

function UnitName(einheit)
    if einheit == "target"    then return welt.ziel end
    if einheit == "focus"     then return welt.fokus end
    if einheit == "mouseover" then return welt.mouseover end
    if einheit == "player"    then return "Testspieler" end
    return nil
end

-- LE_PARTY_CATEGORY_INSTANCE ist 2. IsInGroup(2) fragt "bin ich in einer
-- Instanzgruppe?", IsInGroup() fragt "bin ich ueberhaupt in einer Gruppe?".
LE_PARTY_CATEGORY_INSTANCE = 2

function IsInGroup(kategorie)
    if kategorie == LE_PARTY_CATEGORY_INSTANCE then
        return welt.gruppe == "INSTANCE"
    end
    return welt.gruppe ~= "SOLO"
end

function IsInRaid() return welt.gruppe == "RAID" end
function GetNumGroupMembers() return welt.gruppe == "SOLO" and 0 or 5 end

function UnitIsGroupLeader() return welt.anfuehrer end
function UnitIsGroupAssistant() return false end
function UnitGroupRolesAssigned() return "DAMAGER" end

function InCombatLockdown() return false end
function GetLocale() return "deDE" end
function GetBuildInfo() return "12.1.0", "60000", "Jan 1 2026", 120100 end
function GetInstanceInfo() return "Testinstanz", "party" end

C_AddOns = {
    GetAddOnMetadata = function(_, feld)
        if feld == "Version" then return "0.1.0" end
        if feld == "Interface" then return "120100" end
        return nil
    end,
}

C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationRole = function() return "DAMAGER" end,
}

-- Die Ping-Schnittstelle. Genau so aufgebaut wie im Spiel: ein Enum mit den
-- Ping-Arten und eine Funktion, die eine Tabelle entgegennimmt.
Enum = {
    PingSubjectType = { Attack = 0, Warning = 1, OnMyWay = 2, Assist = 3 },
}

C_Ping = {
    SendMacroPing = function(info)
        mitschrift.pings[#mitschrift.pings + 1] = info and info.type
        return true
    end,
    IsPingSystemEnabled = function() return welt.pingSystem end,
}

-- CreateFrame-Attrappe. Sie muss nur so viel koennen, wie die geprueften
-- Dateien BEIM LADEN verlangen - keine der hier geprueften Funktionen baut
-- einen Rahmen.
function CreateFrame()
    local f = {}
    setmetatable(f, { __index = function() return function() end end })
    return f
end

UIParent = CreateFrame()
GameTooltip = CreateFrame()
Minimap = CreateFrame()
UISpecialFrames = {}

function IsShiftKeyDown() return false end

-- ===========================================================================
-- Die Dateien laden
-- ===========================================================================
-- In derselben Reihenfolge wie in der .toc - und mit demselben "..."-Trick:
-- WoW gibt jeder Addon-Datei den Addon-Namen und eine gemeinsame Tabelle mit.
local TCD = {}

local function laden(datei)
    local pfad = PFAD .. "/" .. datei
    local brocken, fehler = loadfile(pfad)
    if not brocken then
        print("  Ladefehler in " .. datei .. ": " .. tostring(fehler))
        os.exit(1)
    end
    brocken("TacticalCalloutDock", TCD)
end

laden("Locales/enUS.lua")
laden("Locales/deDE.lua")
laden("Logik/Kompat.lua")
laden("Daten/Vorgaben.lua")
laden("Logik/Speicher.lua")
laden("Logik/Ziele.lua")
laden("Logik/Ausloesen.lua")
laden("Logik/Diagnose.lua")
laden("UI/Knopf.lua")
laden("UI/Dock.lua")

TCD.Sagen = function() end

-- ===========================================================================
-- Pruefwerkzeug
-- ===========================================================================
local bestanden, gescheitert = 0, 0

local function melde(ok, was, zusatz)
    if ok then
        bestanden = bestanden + 1
    else
        gescheitert = gescheitert + 1
        print("  FEHLGESCHLAGEN: " .. was .. (zusatz and ("  [" .. tostring(zusatz) .. "]") or ""))
    end
end

local function gleich(ist, soll, was)
    melde(ist == soll, was, "ist: " .. tostring(ist) .. " / soll: " .. tostring(soll))
end

local function abschnitt(titel)
    print("")
    print("  --- " .. titel)
end

-- ===========================================================================
-- 1. Sprachdateien
-- ===========================================================================
abschnitt("Sprachdateien")

do
    -- enUS legt TCD.L selbst an und ist die Grundlage.
    local nurEn = {}
    loadfile(PFAD .. "/Locales/enUS.lua")("x", nurEn)

    local enSchluessel = {}
    for k in pairs(nurEn.L) do enSchluessel[k] = true end

    -- deDE dagegen SETZT nur - es erwartet ein vorhandenes TCD.L, weil enUS
    -- im Spiel davor laedt. Fuer die Pruefung bekommt es eine leere Tabelle:
    -- Danach steht darin genau das, was deDE selbst beisteuert.
    --
    -- Der Zweck: Ein Tippfehler in deDE.lua legt einen Schluessel an, den
    -- niemand liest. Im Spiel faellt das nie auf - der englische Text bleibt
    -- einfach stehen, und niemand weiss, warum.
    local reineDe = { L = {} }
    loadfile(PFAD .. "/Locales/deDE.lua")("x", reineDe)

    local unbekannt = {}
    for schluessel in pairs(reineDe.L) do
        if not enSchluessel[schluessel] then
            unbekannt[#unbekannt + 1] = schluessel
        end
    end
    table.sort(unbekannt)
    melde(#unbekannt == 0, "deDE setzt nur Schluessel, die enUS kennt", table.concat(unbekannt, ", "))

    local anzahl = 0
    for _ in pairs(nurEn.L) do anzahl = anzahl + 1 end
    melde(anzahl > 100, "enUS enthaelt die erwartete Menge Schluessel", anzahl)

    -- Ein fehlender Schluessel liefert seinen eigenen Namen zurueck, statt
    -- nil - sonst waere jeder Tippfehler ein Absturz beim Aufbau der Leiste.
    gleich(nurEn.L.GIBT_ES_NICHT, "GIBT_ES_NICHT", "fehlender Schluessel liefert seinen Namen")
end

-- ===========================================================================
-- 2. Vorgaben
-- ===========================================================================
abschnitt("Vorgaben")

do
    for _, rolle in ipairs(TCD.Vorgaben.ROLLEN) do
        local liste = TCD.Vorgaben.Erzeugen(rolle)
        melde(#liste >= 6, "Profil " .. rolle .. " bringt Knoepfe mit", #liste)

        local alleMitText = true
        for _, knopf in ipairs(liste) do
            if type(knopf.text) ~= "string" or knopf.text == "" then alleMitText = false end
            if knopf.kanal ~= "AUTO" then alleMitText = false end
        end
        melde(alleMitText, "Profil " .. rolle .. ": jeder Knopf hat Text und laeuft auf AUTO")
    end

    -- Zwei Aufrufe duerfen sich NICHT dieselbe Tabelle teilen: Sonst wuerde
    -- eine Aenderung im Editor die Vorlage veraendern.
    local a = TCD.Vorgaben.Erzeugen("TANK")
    local b = TCD.Vorgaben.Erzeugen("TANK")
    a[1].text = "geaendert"
    melde(b[1].text ~= "geaendert", "Erzeugen() liefert jedes Mal frische Tabellen")
end

-- ===========================================================================
-- 3. Speicher
-- ===========================================================================
abschnitt("Speicher")

do
    TacticalCalloutDockDB = nil
    local db = TCD.Speicher.Aufsetzen()

    melde(type(db.profile.TANK) == "table", "beim ersten Start werden alle Rollen angelegt")
    gleich(db.dock.ausrichtung, "horizontal", "Vorgabe der Ausrichtung")

    -- Der Fall "von Hand editierte Datei": lauter Unsinn in den Feldern.
    TacticalCalloutDockDB = {
        dock = {
            groesse = "riesig", abstand = -5, deckkraft = 17,
            punkt = "IRGENDWO", ausrichtung = "diagonal", skalierung = 99,
        },
        drosselung = "viel",
        aktiv = "GIBTESNICHT",
        profile = { TANK = { { beschriftung = 5, text = string.rep("x", 400), marke = 99 } } },
    }
    db = TCD.Speicher.Aufsetzen()

    gleich(db.dock.groesse, TCD.Speicher.VORGABE.dock.groesse, "unsinnige Groesse faellt auf die Vorgabe zurueck")
    gleich(db.dock.abstand, 0, "negativer Abstand wird auf das Minimum gezogen")
    gleich(db.dock.deckkraft, 1, "Deckkraft ueber 1 wird gekappt")
    gleich(db.dock.punkt, "CENTER", "unbekannter Ankerpunkt faellt auf CENTER zurueck")
    gleich(db.dock.ausrichtung, "horizontal", "unbekannte Ausrichtung faellt zurueck")
    gleich(db.dock.skalierung, 2.0, "Skalierung wird gekappt")
    gleich(db.drosselung, TCD.Speicher.VORGABE.drosselung, "unsinnige Drosselung faellt zurueck")
    melde(db.profile[db.aktiv] ~= nil, "unbekanntes aktives Profil wird ersetzt", db.aktiv)

    local knopf = db.profile.TANK[1]
    gleich(knopf.beschriftung, "", "Beschriftung, die kein Text ist, wird geleert")
    gleich(#knopf.text, 255, "zu langer Nachrichtentext wird auf 255 Zeichen gekuerzt")
    gleich(knopf.marke, 8, "Markierung ausserhalb 0..8 wird gekappt")

    -- Bearbeiten
    TacticalCalloutDockDB = nil
    TCD.Speicher.Aufsetzen()
    TCD.Speicher.ProfilWaehlen("TANK")

    local vorher = #TCD.Speicher.AktiveListe()
    local neu = TCD.Speicher.KnopfHinzufuegen()
    gleich(neu, vorher + 1, "Hinzufuegen haengt hinten an")

    local ersterText = TCD.Speicher.AktiveListe()[1].text
    local ziel = TCD.Speicher.KnopfVerschieben(1, 1)
    gleich(ziel, 2, "Verschieben liefert den neuen Index")
    gleich(TCD.Speicher.AktiveListe()[2].text, ersterText, "der Knopf ist wirklich gewandert")

    gleich(TCD.Speicher.KnopfVerschieben(1, -1), nil, "der erste Knopf laesst sich nicht weiter nach oben schieben")

    melde(TCD.Speicher.KnopfLoeschen(neu), "Loeschen meldet Erfolg")
    gleich(#TCD.Speicher.AktiveListe(), vorher, "nach dem Loeschen ist die alte Laenge wieder da")
    gleich(TCD.Speicher.KnopfLoeschen(999), false, "Loeschen eines nicht vorhandenen Knopfes scheitert sauber")

    -- Die Reihenfolge der Profilnamen muss stabil sein - pairs() waere es nicht.
    local namen = TCD.Speicher.ProfilNamen()
    gleich(namen[1], "TANK", "Profilreihenfolge beginnt mit TANK")
    gleich(namen[3], "DAMAGER", "Profilreihenfolge endet mit DAMAGER")
end

-- ===========================================================================
-- 4. Kanalwahl
-- ===========================================================================
abschnitt("Kanalwahl")

do
    local KB = TCD.Ziele.KanalBestimmen

    -- Automatik in jeder Lage. Das ist die Tabelle, die im Spiel darueber
    -- entscheidet, ob die Gruppe die Ansage ueberhaupt liest.
    welt.gruppe = "SOLO";     gleich(KB("AUTO"), "SAY", "AUTO allein -> SAY")
    welt.gruppe = "PARTY";    gleich(KB("AUTO"), "PARTY", "AUTO in der Gruppe -> PARTY")
    welt.gruppe = "RAID";     gleich(KB("AUTO"), "RAID", "AUTO im Schlachtzug -> RAID")
    welt.gruppe = "INSTANCE"; gleich(KB("AUTO"), "INSTANCE_CHAT", "AUTO in der Instanzgruppe -> INSTANCE_CHAT")

    -- Der eigentliche Grund fuer die ganze Funktion: Eine Instanzgruppe ist
    -- GLEICHZEITIG eine Gruppe. Wer zuerst auf IsInGroup() prueft, landet im
    -- Gruppenchat - den dort nicht alle sehen.
    welt.gruppe = "INSTANCE"
    gleich(TCD.Ziele.Gruppenlage(), "INSTANCE", "Instanzgruppe wird vor Gruppe erkannt")

    -- Fest eingestellte Kanaele, die gerade nicht gehen.
    welt.gruppe = "SOLO"
    local kanal, ersetzt = KB("RAID")
    gleich(kanal, "SAY", "RAID allein faellt auf SAY zurueck")
    gleich(ersetzt, true, "und meldet, dass ersetzt wurde")

    kanal, ersetzt = KB("PARTY")
    gleich(kanal, "SAY", "PARTY allein faellt auf SAY zurueck")

    welt.gruppe = "PARTY"
    gleich(KB("RAID"), "PARTY", "RAID in einer Gruppe wird zu PARTY")
    gleich(KB("INSTANCE_CHAT"), "PARTY", "INSTANCE_CHAT ohne Instanzgruppe wird zu PARTY")

    welt.gruppe = "INSTANCE"
    gleich(KB("PARTY"), "INSTANCE_CHAT", "PARTY in der Instanzgruppe wird zu INSTANCE_CHAT")

    -- Schlachtzugswarnung ohne Recht: Der Server sendet sonst nichts und
    -- meldet auch nichts.
    welt.gruppe = "RAID"
    welt.anfuehrer = true
    gleich(KB("RAID_WARNING"), "RAID_WARNING", "mit Anfuehrerrecht geht die Warnung durch")
    welt.anfuehrer = false
    gleich(KB("RAID_WARNING"), "RAID", "ohne Recht wird aus der Warnung normaler Schlachtzugschat")
    welt.anfuehrer = true

    -- Die drei, die immer gehen.
    welt.gruppe = "SOLO"
    gleich(KB("SAY"), "SAY", "SAY geht immer")
    gleich(KB("YELL"), "YELL", "YELL geht immer")
    gleich(KB("EMOTE"), "EMOTE", "EMOTE geht immer")

    gleich(KB("QUATSCH"), "SAY", "ein unbekannter Kanal landet in SAY")
end

-- ===========================================================================
-- 5. Platzhalter
-- ===========================================================================
abschnitt("Platzhalter")

do
    local P = TCD.Ziele.PlatzhalterFuellen

    welt.ziel = "Erzmagier"
    gleich(P("Fokus %t"), "Fokus Erzmagier", "%t setzt den Zielnamen ein")

    welt.ziel = nil
    gleich(P("Fokus %t"), "Fokus " .. TCD.L.SUB_NO_TARGET, "ohne Ziel steht ein lesbarer Ersatz da")

    welt.fokus = "Zweitziel"
    gleich(P("Kick %f"), "Kick Zweitziel", "%f setzt den Fokus ein")
    welt.fokus = nil

    gleich(P("Ich bin %p"), "Ich bin Testspieler", "%p setzt den eigenen Namen ein")

    gleich(P("ohne alles"), "ohne alles", "Text ohne Platzhalter bleibt unveraendert")
    gleich(P("100%% sicher"), "100% sicher", "%% wird zu einem echten Prozentzeichen")
    gleich(P("%x bleibt"), "%x bleibt", "unbekannter Platzhalter bleibt stehen")
    gleich(P(""), "", "leerer Text bleibt leer")

    welt.ziel = "Zielperson"

    -- Ein sehr langer Name darf die Zeile nicht ueber die Servergrenze
    -- schieben.
    welt.ziel = string.rep("N", 300)
    melde(#P("Fokus %t") <= 255, "eingesetzter Langname wird auf 255 Zeichen gekuerzt")
    welt.ziel = "Zielperson"
end

-- ===========================================================================
-- 6. Der Klick
-- ===========================================================================
abschnitt("Ausloesen")

do
    TacticalCalloutDockDB = nil
    TCD.Speicher.Aufsetzen()
    TCD.Ausloesen.SperrenVergessen()
    TCD.Ausloesen.HinweiseVergessen()

    welt.gruppe = "INSTANCE"
    welt.anfuehrer = true
    welt.ziel = "Zielperson"
    mitschriftLeeren()

    local knopf = {
        beschriftung = "Test",
        text = "Fokus Totenschaedel %t",
        kanal = "AUTO",
        marke = 8,
        ping = "ONMYWAY",
    }

    UHR = 1000
    local ergebnis = TCD.Ausloesen.Knopf(knopf, UHR)

    gleich(ergebnis.gesendet, true, "die Ansage wurde abgeschickt")
    gleich(mitschrift.chat[1].kanal, "INSTANCE_CHAT", "sie ging in den Instanzchat")
    gleich(mitschrift.chat[1].text, "Fokus Totenschaedel Zielperson", "mit eingesetztem Platzhalter")

    gleich(ergebnis.marke, true, "die Markierung wurde gesetzt")
    gleich(mitschrift.marken[1].index, 8, "und zwar der Totenschaedel")
    gleich(mitschrift.marken[1].einheit, "target", "auf das aktuelle Ziel")

    gleich(ergebnis.ping, true, "der Ping ging raus")
    gleich(mitschrift.pings[1], Enum.PingSubjectType.OnMyWay, "mit der richtigen Ping-Art")

    -- Die Reihenfolge ist Absicht: erst markieren, dann sagen. Sonst schaut
    -- die Gruppe hin, bevor der Schaedel steht.
    melde(#mitschrift.marken == 1 and #mitschrift.chat == 1, "Markierung und Ansage genau einmal")

    -- ---------------------------------------------------------------------
    -- Wiederholsperre
    -- ---------------------------------------------------------------------
    mitschriftLeeren()
    ergebnis = TCD.Ausloesen.Knopf(knopf, UHR + 0.5)
    gleich(ergebnis.gedrosselt, true, "der zweite Klick kurz danach wird gesperrt")
    gleich(#mitschrift.chat, 0, "und es wird wirklich nichts gesendet")
    gleich(#mitschrift.marken, 0, "auch die Markierung unterbleibt")

    mitschriftLeeren()
    ergebnis = TCD.Ausloesen.Knopf(knopf, UHR + 5)
    gleich(ergebnis.gedrosselt, nil, "nach Ablauf der Sperre geht es wieder")
    gleich(#mitschrift.chat, 1, "und es wird wieder gesendet")

    -- ---------------------------------------------------------------------
    -- Fehlende Rechte und fehlendes Ziel
    -- ---------------------------------------------------------------------
    TCD.Ausloesen.SperrenVergessen()
    TCD.Ausloesen.HinweiseVergessen()
    mitschriftLeeren()

    welt.gruppe = "PARTY"
    welt.anfuehrer = false
    local ergebnis2, hinweise = TCD.Ausloesen.Knopf(knopf, UHR + 20)

    gleich(ergebnis2.marke, "NORIGHT", "ohne Markierrecht wird nicht markiert")
    gleich(#mitschrift.marken, 0, "und SetRaidTarget gar nicht erst gerufen")
    gleich(ergebnis2.gesendet, true, "die Ansage geht trotzdem raus")
    melde(#hinweise >= 1, "der Spieler bekommt dazu einen Hinweis")

    -- Derselbe Fall noch einmal: der Hinweis darf sich NICHT wiederholen.
    TCD.Ausloesen.SperrenVergessen()
    local _, hinweise2 = TCD.Ausloesen.Knopf(knopf, UHR + 30)
    local nochmal = false
    for _, h in ipairs(hinweise2) do
        if h.schluessel == "MSG_NO_MARK_RIGHT" then nochmal = true end
    end
    melde(not nochmal, "derselbe Hinweis kommt kein zweites Mal")

    welt.anfuehrer = true
    TCD.Ausloesen.SperrenVergessen()
    TCD.Ausloesen.HinweiseVergessen()
    mitschriftLeeren()

    welt.ziel = nil
    local ergebnis3 = TCD.Ausloesen.Knopf(knopf, UHR + 40)
    gleich(ergebnis3.marke, "NOTARGET", "ohne Ziel wird nicht markiert")
    gleich(ergebnis3.gesendet, true, "die Ansage geht auch ohne Ziel raus")
    welt.ziel = "Zielperson"

    -- ---------------------------------------------------------------------
    -- Ein Knopf, der nur markiert
    -- ---------------------------------------------------------------------
    TCD.Ausloesen.SperrenVergessen()
    mitschriftLeeren()

    local nurMarke = { beschriftung = "M", text = "", kanal = "AUTO", marke = 7 }
    local ergebnis4 = TCD.Ausloesen.Knopf(nurMarke, UHR + 50)
    gleich(ergebnis4.gesendet, nil, "ein Knopf ohne Text sendet nichts")
    gleich(#mitschrift.marken, 1, "markiert aber trotzdem")
    gleich(ergebnis4.leer, nil, "und gilt nicht als leerer Knopf")

    -- Ein Knopf, der wirklich nichts tut - fast immer ein Versehen.
    TCD.Ausloesen.SperrenVergessen()
    local ergebnis5 = TCD.Ausloesen.Knopf({ text = "", marke = 0 }, UHR + 60)
    gleich(ergebnis5.leer, true, "ein Knopf ohne alles wird als leer erkannt")

    -- ---------------------------------------------------------------------
    -- Ping abgeschaltet
    -- ---------------------------------------------------------------------
    TCD.Ausloesen.SperrenVergessen()
    TCD.Ausloesen.HinweiseVergessen()
    mitschriftLeeren()

    welt.pingSystem = false
    local ergebnis6 = TCD.Ausloesen.Knopf(knopf, UHR + 70)
    gleich(ergebnis6.ping, "BLOCKED", "abgeschaltetes Ping-Rad wird erkannt")
    gleich(#mitschrift.pings, 0, "und es wird nicht gepingt")
    gleich(ergebnis6.gesendet, true, "die Ansage geht auch ohne Ping raus")
    welt.pingSystem = true
end

-- ===========================================================================
-- 7. Anordnung der Leiste
-- ===========================================================================
abschnitt("Anordnung")

do
    local An = TCD.Dock.Anordnung

    local s, z = An(8, "horizontal", 0)
    melde(s == 8 and z == 1, "waagerecht ohne Umbruch: eine Reihe", s .. "x" .. z)

    s, z = An(8, "vertikal", 0)
    melde(s == 1 and z == 8, "senkrecht ohne Umbruch: eine Spalte", s .. "x" .. z)

    s, z = An(8, "horizontal", 4)
    melde(s == 4 and z == 2, "waagerecht mit Umbruch 4: zwei Reihen zu vier", s .. "x" .. z)

    s, z = An(7, "horizontal", 4)
    melde(s == 4 and z == 2, "sieben Knoepfe brauchen ebenfalls zwei Reihen", s .. "x" .. z)

    s, z = An(8, "vertikal", 4)
    melde(s == 2 and z == 4, "senkrecht mit Umbruch 4: zwei Spalten zu vier", s .. "x" .. z)

    s, z = An(0, "horizontal", 0)
    melde(s == 0 and z == 0, "keine Knoepfe, keine Anordnung")

    s, z = An(3, "horizontal", 10)
    melde(s == 3 and z == 1, "ein Umbruch groesser als die Anzahl aendert nichts", s .. "x" .. z)
end

-- ===========================================================================
-- 8. Selbstdiagnose
-- ===========================================================================
abschnitt("Selbstdiagnose")

do
    local zeilen = TCD.Diagnose.Zeilen()
    melde(#zeilen > 10, "die Diagnose liefert einen Bericht", #zeilen)

    local text = table.concat(zeilen, "\n")
    melde(text:find("ChatSenden"), "sie nennt die wichtigste Schnittstelle")
    melde(text:find("0.1.0", 1, true), "sie nennt die Fassung")

    -- Alles Wichtige ist in der Testumgebung vorhanden - der Bericht muss
    -- also gruen ausfallen.
    local wichtig = TCD.API.FehlendeAnzahl()
    gleich(wichtig, 0, "in der Testumgebung fehlt keine wichtige Funktion")
end

-- ===========================================================================
-- Ergebnis
-- ===========================================================================
print("")
if gescheitert == 0 then
    print(("  %d Pruefungen bestanden."):format(bestanden))
    os.exit(0)
else
    print(("  %d bestanden, %d fehlgeschlagen."):format(bestanden, gescheitert))
    os.exit(1)
end
