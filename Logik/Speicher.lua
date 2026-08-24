-- Logik/Speicher.lua - die gespeicherten Einstellungen
--
-- ===========================================================================
-- WARUM DAS HIER MEHR IST ALS EIN  db = db or {}
-- ---------------------------------------------------------------------------
-- SavedVariables sind eine Lua-DATEI auf der Festplatte des Spielers. Drei
-- Dinge folgen daraus, und alle drei sind schon Leuten passiert:
--
--   1. Sie ueberlebt Addon-Updates. Was in Fassung 1 "groesse" hiess, ist in
--      Fassung 2 vielleicht weg - der alte Wert steht trotzdem noch da.
--   2. Sie ist von Hand editierbar. Wer dort  groesse = "gross"  eintraegt,
--      bekommt ohne Pruefung einen Lua-Fehler mitten im Aufbau der Leiste.
--   3. Sie kann halb geschrieben sein, wenn der Client abgestuerzt ist.
--
-- Deshalb wird hier NICHTS geglaubt: Jeder Wert wird gegen die Vorgabe
-- geprueft, und was nicht passt, wird still ersetzt. Ein Addon, das wegen
-- einer kaputten Einstellung gar nicht mehr startet, ist schlimmer als eines,
-- das eine Einstellung vergisst.
--
-- Ace-Datenbank gibt es hier bewusst nicht (siehe Kopf der .toc). Profile
-- macht dieses Addon selbst - es braucht genau eine Ebene davon.
-- ===========================================================================
local addonName, TCD = ...

TCD.Speicher = {}
local S = TCD.Speicher
local A = TCD.API

-- ---------------------------------------------------------------------------
-- Die Vorgaben
-- ---------------------------------------------------------------------------
-- Alles, was NICHT in den Profilen steht. Die Knoepfe selbst kommen aus
-- Daten\Vorgaben.lua und werden erst beim ersten Start hineinkopiert.
local VORGABE = {
    -- Fassungsnummer der Datenstruktur, nicht die des Addons. Sie wird erst
    -- gebraucht, wenn einmal wirklich umgebaut werden muss.
    version = 1,

    dock = {
        -- Ankerpunkt. Absichtlich CENTER und ein Stueck nach unten: die
        -- Bildschirmmitte ist der einzige Ort, der auf jeder Aufloesung
        -- sichtbar ist. Wer die Leiste am Rand haben will, zieht sie hin.
        punkt    = "CENTER",
        relPunkt = "CENTER",
        x        = 0,
        y        = -180,

        ausrichtung    = "horizontal",  -- oder "vertikal"
        groesse        = 34,            -- Kantenlaenge eines Knopfes
        abstand        = 4,             -- Luft zwischen zwei Knoepfen
        deckkraft      = 0.55,          -- Hintergrund; 0 = voellig durchsichtig
        umbruch        = 0,             -- Knoepfe je Reihe; 0 = alles in eine
        skalierung     = 1.0,
        beschriftungen = true,
        gesperrt       = false,
        sichtbar       = true,

        -- Wer nur im Schluesselstein ansagt, will die Leiste beim Questen
        -- nicht sehen. Aus, weil "mein Addon ist verschwunden" die
        -- unangenehmere Ueberraschung waere.
        nurGruppe = false,
    },

    minimap = {
        winkel    = 205,   -- Grad auf dem Kreis
        versteckt = false,
    },

    -- Wiederholungssperre je Knopf. 1,5 Sekunden ist kein Gaengelband, sondern
    -- Schutz: Der Server drosselt Chatnachrichten selbst, und wer dort
    -- anlaeuft, verliert im Zweifel die Verbindung. Wer es nicht will,
    -- stellt im Editor 0 ein.
    drosselung = 1.5,

    aktiv = "DAMAGER",
}

-- ===========================================================================
-- Werkzeug: pruefen und ergaenzen
-- ===========================================================================

-- Fehlende Schluessel aus der Vorgabe nachtragen, vorhandene in Ruhe lassen.
local function ergaenzen(ziel, vorgabe)
    for schluessel, wert in pairs(vorgabe) do
        if type(wert) == "table" then
            if type(ziel[schluessel]) ~= "table" then
                ziel[schluessel] = {}
            end
            ergaenzen(ziel[schluessel], wert)
        elseif ziel[schluessel] == nil then
            ziel[schluessel] = wert
        end
    end
end

-- Eine Zahl in ihre Grenzen zwingen. Liefert die Vorgabe, wenn dort gar
-- keine Zahl steht - genau der Fall "von Hand editiert".
local function zahl(wert, min, max, vorgabe)
    if type(wert) ~= "number" or wert ~= wert then return vorgabe end
    if wert < min then return min end
    if wert > max then return max end
    return wert
end

local function wahrheit(wert, vorgabe)
    if type(wert) ~= "boolean" then return vorgabe end
    return wert
end

local function text(wert, vorgabe)
    if type(wert) ~= "string" then return vorgabe end
    return wert
end

-- ---------------------------------------------------------------------------
-- Einen einzelnen Knopf geradeziehen
-- ---------------------------------------------------------------------------
-- Wird auch vom Editor benutzt, bevor eine Aenderung uebernommen wird. So
-- gibt es genau eine Stelle, die entscheidet, was ein gueltiger Knopf ist.
function S.KnopfPruefen(knopf)
    if type(knopf) ~= "table" then return nil end

    local sauber = {
        beschriftung = text(knopf.beschriftung, ""),
        text         = text(knopf.text, ""),
        kanal        = text(knopf.kanal, "AUTO"),
        marke        = zahl(knopf.marke, 0, 8, 0),
        ping         = type(knopf.ping) == "string" and knopf.ping or nil,
    }

    -- Die Beschriftung darf lang sein, sie wird beim Zeichnen abgeschnitten -
    -- aber nicht endlos: Eine Beschriftung mit 400 Zeichen ist ein Versehen.
    if #sauber.beschriftung > 24 then
        sauber.beschriftung = sauber.beschriftung:sub(1, 24)
    end

    -- Eine Chatzeile darf 255 Zeichen haben. Laenger schickt der Server nicht,
    -- er schneidet ab - und zwar mitten im Wort. Lieber hier kuerzen, dann
    -- sieht man es schon im Editor.
    if #sauber.text > 255 then
        sauber.text = sauber.text:sub(1, 255)
    end

    -- Das Symbol darf ein Pfad oder eine Datei-ID sein. Beides ist gueltig,
    -- eine Zahl in einem String ("134400") ist es nicht - die wuerde WoW als
    -- Pfad lesen und ein leeres Feld zeigen.
    local symbol = knopf.symbol
    if type(symbol) == "number" then
        sauber.symbol = symbol
    elseif type(symbol) == "string" and symbol ~= "" then
        sauber.symbol = tonumber(symbol) or symbol
    else
        sauber.symbol = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    return sauber
end

-- ===========================================================================
-- Aufsetzen
-- ===========================================================================
-- Wird EINMAL aus Core.lua bei ADDON_LOADED gerufen - vorher gibt es die
-- gespeicherte Tabelle noch gar nicht.
function S.Aufsetzen()
    _G.TacticalCalloutDockDB = _G.TacticalCalloutDockDB or {}
    local db = _G.TacticalCalloutDockDB

    ergaenzen(db, VORGABE)

    -- Zahlenwerte in ihre Grenzen holen.
    local d = db.dock
    d.groesse    = zahl(d.groesse, 16, 96, VORGABE.dock.groesse)
    d.abstand    = zahl(d.abstand, 0, 32, VORGABE.dock.abstand)
    d.deckkraft  = zahl(d.deckkraft, 0, 1, VORGABE.dock.deckkraft)
    d.umbruch    = zahl(d.umbruch, 0, 24, VORGABE.dock.umbruch)
    d.skalierung = zahl(d.skalierung, 0.5, 2.0, VORGABE.dock.skalierung)
    d.x          = zahl(d.x, -4000, 4000, VORGABE.dock.x)
    d.y          = zahl(d.y, -4000, 4000, VORGABE.dock.y)

    d.beschriftungen = wahrheit(d.beschriftungen, true)
    d.gesperrt       = wahrheit(d.gesperrt, false)
    d.sichtbar       = wahrheit(d.sichtbar, true)
    d.nurGruppe      = wahrheit(d.nurGruppe, false)

    if d.ausrichtung ~= "horizontal" and d.ausrichtung ~= "vertikal" then
        d.ausrichtung = VORGABE.dock.ausrichtung
    end

    -- Ankerpunkte kommen als Zeichenkette aus der Datei. Ein Tippfehler dort
    -- laesst SetPoint werfen, und zwar bevor die Leiste je sichtbar war.
    local punkte = {
        CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
        TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
    }
    if not punkte[d.punkt] then d.punkt = VORGABE.dock.punkt end
    if not punkte[d.relPunkt] then d.relPunkt = VORGABE.dock.relPunkt end

    db.minimap.winkel    = zahl(db.minimap.winkel, 0, 360, VORGABE.minimap.winkel)
    db.minimap.versteckt = wahrheit(db.minimap.versteckt, false)

    db.drosselung = zahl(db.drosselung, 0, 10, VORGABE.drosselung)

    -- ---------------------------------------------------------------------
    -- Die Profile
    -- ---------------------------------------------------------------------
    -- Beim allerersten Start werden alle drei Rollen mit ihren Vorgaben
    -- gefuellt - nicht nur die eigene. Wer als Schaden anfaengt und spaeter
    -- einen Tank hochzieht, findet dessen Ansagen dann schon fertig vor.
    db.profile = type(db.profile) == "table" and db.profile or {}

    for _, rolle in ipairs(TCD.Vorgaben.ROLLEN) do
        if type(db.profile[rolle]) ~= "table" then
            db.profile[rolle] = TCD.Vorgaben.Erzeugen(rolle)
        end
    end

    -- Jeden Knopf jedes Profils geradeziehen. Das ist der Durchlauf, der
    -- eine von Hand verbogene Datei wieder benutzbar macht.
    for _, liste in pairs(db.profile) do
        if type(liste) == "table" then
            local sauber = {}
            for _, knopf in ipairs(liste) do
                local geprueft = S.KnopfPruefen(knopf)
                if geprueft then sauber[#sauber + 1] = geprueft end
            end
            -- In derselben Tabelle ersetzen, damit Verweise darauf gueltig
            -- bleiben.
            for i = #liste, 1, -1 do liste[i] = nil end
            for i, knopf in ipairs(sauber) do liste[i] = knopf end
        end
    end

    -- Beim allerersten Start das Profil nehmen, das zur Rolle passt.
    if type(db.aktiv) ~= "string" or type(db.profile[db.aktiv]) ~= "table" then
        db.aktiv = A.RolleRaten()
        if type(db.profile[db.aktiv]) ~= "table" then
            db.aktiv = "DAMAGER"
        end
    end

    S.db = db
    return db
end

-- ===========================================================================
-- Zugriff
-- ===========================================================================

function S.Dock()
    return S.db.dock
end

function S.AktiveListe()
    return S.db.profile[S.db.aktiv]
end

function S.AktivesProfil()
    return S.db.aktiv
end

-- Alle Profilnamen, die Rollen zuerst und in fester Reihenfolge. Eigene
-- Profile (vom Spieler angelegte) haengen alphabetisch hinten dran, damit
-- die Reiterleiste nicht bei jedem Login anders aussieht - pairs() hat keine
-- verlaessliche Reihenfolge.
function S.ProfilNamen()
    local namen, gesehen = {}, {}

    for _, rolle in ipairs(TCD.Vorgaben.ROLLEN) do
        if S.db.profile[rolle] then
            namen[#namen + 1] = rolle
            gesehen[rolle] = true
        end
    end

    local rest = {}
    for name in pairs(S.db.profile) do
        if not gesehen[name] then rest[#rest + 1] = name end
    end
    table.sort(rest)

    for _, name in ipairs(rest) do namen[#namen + 1] = name end
    return namen
end

-- Liefert true, wenn wirklich gewechselt wurde.
function S.ProfilWaehlen(name)
    if type(S.db.profile[name]) ~= "table" then return false end
    if S.db.aktiv == name then return false end
    S.db.aktiv = name
    return true
end

-- ===========================================================================
-- Knoepfe bearbeiten - das, was der Editor aufruft
-- ===========================================================================

function S.KnopfHinzufuegen()
    local L = TCD.L
    local liste = S.AktiveListe()

    liste[#liste + 1] = S.KnopfPruefen({
        beschriftung = L.CFG_NEW_LABEL,
        text         = L.CFG_NEW_MESSAGE,
        kanal        = "AUTO",
        symbol       = "Interface\\Icons\\INV_Misc_QuestionMark",
        marke        = 0,
    })

    return #liste
end

function S.KnopfLoeschen(index)
    local liste = S.AktiveListe()
    if not liste[index] then return false end
    table.remove(liste, index)
    return true
end

-- richtung: -1 nach vorn, +1 nach hinten. Liefert den neuen Index oder nil,
-- wenn der Knopf schon am Ende war.
function S.KnopfVerschieben(index, richtung)
    local liste = S.AktiveListe()
    local ziel = index + richtung

    if not liste[index] or not liste[ziel] then return nil end

    liste[index], liste[ziel] = liste[ziel], liste[index]
    return ziel
end

function S.KnopfSetzen(index, knopf)
    local liste = S.AktiveListe()
    if not liste[index] then return false end

    local geprueft = S.KnopfPruefen(knopf)
    if not geprueft then return false end

    liste[index] = geprueft
    return true
end

-- ---------------------------------------------------------------------------
-- Zuruecksetzen
-- ---------------------------------------------------------------------------
-- Nur das aktive Profil und nur die Knoepfe - Position, Groesse und die
-- anderen Profile bleiben. Wer "alles zurueck" will, loescht die
-- SavedVariables; das steht so auch im README.
function S.ProfilZuruecksetzen()
    local name = S.db.aktiv
    if not TCD.Vorgaben[name] then return false end

    S.db.profile[name] = TCD.Vorgaben.Erzeugen(name)
    return true
end

function S.PositionZuruecksetzen()
    local d = S.db.dock
    d.punkt, d.relPunkt = "CENTER", "CENTER"
    d.x, d.y = VORGABE.dock.x, VORGABE.dock.y
    d.gesperrt = false
end

-- Fuer die Tests: die Vorgabetabelle ist sonst von aussen nicht erreichbar.
S.VORGABE = VORGABE
