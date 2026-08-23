-- Logik/Kompat.lua - Bruecke zu den WoW-Schnittstellen
--
-- ===========================================================================
-- WOZU DIESE DATEI?
-- ---------------------------------------------------------------------------
-- Damit KEINE andere Datei dieses Addons eine WoW-Funktion direkt aufruft.
-- Der Grund ist bei diesem Addon ein anderer als bei einem Auswertungsaddon:
--
-- 1. DIE PING-SCHNITTSTELLE IST DER WACKELIGSTE TEIL.  C_Ping  ist jung,
--    verhaeltnismaessig selten benutzt und an Bedingungen geknuepft, die sich
--    aendern koennen (Hardware-Ereignis, aktiviertes Ping-Rad, erlaubter
--    Kontext). Sie darf deshalb NIE das Senden der Chatnachricht gefaehrden:
--    Wer auf "Fokus Totenschaedel" drueckt, soll die Ansage in der Gruppe
--    sehen, auch wenn der Ping stumm bleibt.
--
-- 2. BLIZZARD RAEUMT UM.  GetAddOnMetadata  ist nach  C_AddOns  gewandert,
--    GetSpecialization nach  C_SpecializationInfo . Ein Addon, das nur die
--    alte Form kennt, stuerzt dabei nicht ab - es wird STILL FALSCH. Genau
--    das ist die unangenehmste Sorte Bug.
--
-- Diese Datei
--   * sucht fuer jeden Zweck die erste vorhandene Fassung aus einer Liste,
--   * merkt sich, WELCHE sie genommen hat (fuer  /tcd doctor ),
--   * faengt Fehler beim Aufruf ab und merkt sich den ersten je Zweck.
--
-- Kommt in einem spaeteren Patch eine dritte Schreibweise dazu, ist das eine
-- neue Zeile in der Kandidatenliste - und sonst nichts.
-- ===========================================================================
local addonName, TCD = ...

TCD.API = TCD.API or {}
local A = TCD.API

-- Aufgeloeste Funktionen: zweck -> Funktion (oder nil)
A.fn = {}

-- Woher stammt sie? zweck -> "C_AddOns.GetAddOnMetadata" oder false, wenn gar
-- nichts gefunden wurde. Liest  /tcd doctor  aus.
A.quelle = {}

-- Ist der Zweck fuer die Kernaufgabe entbehrlich? zweck -> true
--
-- Der Unterschied ist wichtig, damit die Diagnose nicht Alarm schlaegt, wo
-- keiner noetig ist: Ohne SendChatMessage kann das Addon gar nichts - ohne
-- C_Ping fehlt bloss der Ping, und die Ansage geht trotzdem raus.
A.optional = {}

-- ---------------------------------------------------------------------------
-- Eine Funktion in der Umgebung suchen
-- ---------------------------------------------------------------------------
-- Ein Kandidat ist entweder "SendChatMessage" (global) oder
-- "C_Ping.SendMacroPing" (Feld in einer Tabelle). Der Punkt in der Mitte
-- entscheidet, wie gesucht wird.
local function aufloesen(pfad)
    local tabelle, feld = pfad:match("^([%w_]+)%.([%w_]+)$")

    if tabelle then
        local t = _G[tabelle]
        if type(t) == "table" and type(t[feld]) == "function" then
            return t[feld], t
        end
        return nil
    end

    if type(_G[pfad]) == "function" then
        return _G[pfad]
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Einen Zweck an die erste vorhandene Fassung binden
-- ---------------------------------------------------------------------------
-- Reihenfolge in der Liste = Vorrang. Die NEUE Schreibweise steht immer
-- vorne: wenn beide existieren (Uebergangsphase eines Patches), ist die neue
-- die, die den Patch danach ueberlebt.
--
-- "selbst" merkt sich die Tabelle, in der die Funktion steckt. C_Ping-
-- Funktionen erwarten sie NICHT als erstes Argument, hier wird sie nur fuer
-- die Diagnose behalten.
local function binden(zweck, kandidaten, optional)
    A.optional[zweck] = optional or nil

    for _, pfad in ipairs(kandidaten) do
        local fn = aufloesen(pfad)
        if fn then
            A.fn[zweck] = fn
            A.quelle[zweck] = pfad
            return
        end
    end

    A.fn[zweck] = nil
    A.quelle[zweck] = false
end

-- ---------------------------------------------------------------------------
-- Kandidatenlisten: das Unverzichtbare
-- ---------------------------------------------------------------------------
binden("ChatSenden",      { "SendChatMessage" })
binden("KampfSperre",     { "InCombatLockdown" })
binden("Zeit",            { "GetTime" })
binden("EinheitDa",       { "UnitExists" })
binden("EinheitName",     { "UnitName" })
binden("InGruppe",        { "IsInGroup" })
binden("InSchlachtzug",   { "IsInRaid" })

-- ---------------------------------------------------------------------------
-- Kandidatenlisten: entbehrlich
-- ---------------------------------------------------------------------------
-- Alles hier drunter kostet im Zweifel eine Bequemlichkeit, nie die
-- Grundfunktion.
binden("MarkeSetzen",     { "SetRaidTarget" },                              true)
binden("MarkeLesen",      { "GetRaidTargetIndex" },                         true)
binden("IstAnfuehrer",    { "UnitIsGroupLeader" },                          true)
binden("IstAssistent",    { "UnitIsGroupAssistant" },                       true)
binden("GruppenGroesse",  { "GetNumGroupMembers" },                         true)
binden("InstanzInfo",     { "GetInstanceInfo" },                            true)
binden("Sprache",         { "GetLocale" },                                  true)
binden("Bauinfo",         { "GetBuildInfo" },                               true)
binden("AddonMetadaten",  { "C_AddOns.GetAddOnMetadata", "GetAddOnMetadata" }, true)
binden("ZugewieseneRolle", { "UnitGroupRolesAssigned" },                    true)
binden("SpezIndex",       { "C_SpecializationInfo.GetSpecialization", "GetSpecialization" }, true)
binden("SpezRolle",       { "C_SpecializationInfo.GetSpecializationRole", "GetSpecializationRole" }, true)

-- Die Ping-Schnittstelle. Siehe Kopf der Datei: das hier ist der Teil, dem am
-- ehesten etwas zustoesst.
binden("PingSenden",      { "C_Ping.SendMacroPing" },                       true)
binden("PingSystemAn",    { "C_Ping.IsPingSystemEnabled" },                 true)
binden("PingErlaubt",     { "C_Ping.CanSendPing" },                         true)

-- ---------------------------------------------------------------------------
-- Aufrufen, ohne dass ein Fehler das Addon mitreisst
-- ---------------------------------------------------------------------------
-- Der Fehler wird nur EINMAL je Zweck gemerkt. Sonst haette man bei einem
-- Knopf, den jemand im Kampf mehrfach drueckt, eine Fehlermeldung pro Klick.
A.fehler = {}

function A.Ruf(zweck, ...)
    local fn = A.fn[zweck]
    if not fn then return nil end

    local ok, a, b, c, d, e, f = pcall(fn, ...)
    if not ok then
        if not A.fehler[zweck] then
            A.fehler[zweck] = tostring(a)
        end
        return nil
    end
    return a, b, c, d, e, f
end

-- Gab es fuer diesen Zweck schon einmal einen Fehler? Der Unterschied zu
-- "gar nicht vorhanden" zaehlt in der Diagnose: eine Funktion, die da ist,
-- aber wirft, ist ein anderer Befund als eine, die es nicht mehr gibt.
function A.Vorhanden(zweck)
    return A.fn[zweck] ~= nil
end

-- ===========================================================================
-- Huellen fuer das, was oft gebraucht wird
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Darf ich in dieser Gruppe ueberhaupt markieren?
-- ---------------------------------------------------------------------------
-- Allein: immer. In der Gruppe: nur Anfuehrer und Assistenten. Diese Frage
-- wird VOR dem Setzen gestellt, damit der Spieler eine verstaendliche
-- Meldung bekommt statt eines stillen Nichts.
function A.DarfMarkieren()
    if not A.Ruf("InGruppe") then return true end
    if A.Ruf("IstAnfuehrer", "player") then return true end
    if A.Ruf("IstAssistent", "player") then return true end
    return false
end

-- ---------------------------------------------------------------------------
-- Die Rolle des Spielers erraten
-- ---------------------------------------------------------------------------
-- Nur fuer die EINE Frage: welches Profil zeigen wir beim allerersten Start?
-- Zwei Quellen, in dieser Reihenfolge:
--   1. die in der Gruppe zugewiesene Rolle - die ist das, was der Spieler
--      gerade tatsaechlich tut,
--   2. die Rolle der Spezialisierung - richtig, solange niemand als Heiler
--      angemeldet Schaden faehrt.
-- Kommt nichts heraus, wird es "DAMAGER": die haeufigste Rolle, und ein
-- falsch geratenes Profil kostet einen Klick, keinen Schaden.
function A.RolleRaten()
    local zugewiesen = A.Ruf("ZugewieseneRolle", "player")
    if zugewiesen == "TANK" or zugewiesen == "HEALER" or zugewiesen == "DAMAGER" then
        return zugewiesen
    end

    local index = A.Ruf("SpezIndex")
    if index then
        local rolle = A.Ruf("SpezRolle", index)
        if rolle == "TANK" or rolle == "HEALER" or rolle == "DAMAGER" then
            return rolle
        end
    end

    return "DAMAGER"
end

-- ---------------------------------------------------------------------------
-- Welche Ping-Arten kennt dieser Client?
-- ---------------------------------------------------------------------------
-- Enum.PingSubjectType gibt es erst, seit es das Ping-Rad gibt. Die Namen
-- werden hier EINMAL nachgeschlagen und gemerkt - der Editor baut daraus
-- seine Auswahlliste, und was der Client nicht kennt, steht dort erst gar
-- nicht drin. Besser eine kurze Liste als ein Eintrag, der nichts tut.
local pingArten
function A.PingArten()
    if pingArten then return pingArten end

    pingArten = {}

    local enum = _G.Enum
    local typen = enum and enum.PingSubjectType
    if type(typen) ~= "table" then return pingArten end

    -- Reihenfolge ist Absicht: so stehen sie auch im Ping-Rad des Spiels.
    local bekannt = { "Attack", "Warning", "OnMyWay", "Assist" }
    for _, name in ipairs(bekannt) do
        local wert = typen[name]
        if type(wert) == "number" then
            pingArten[#pingArten + 1] = { schluessel = name:upper(), wert = wert }
        end
    end

    return pingArten
end

-- Den Enum-Wert zu einem gespeicherten Schluessel ("ATTACK") finden.
function A.PingWert(schluessel)
    if not schluessel then return nil end
    for _, art in ipairs(A.PingArten()) do
        if art.schluessel == schluessel then return art.wert end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Einen Ping absetzen
-- ---------------------------------------------------------------------------
-- Rueckgabe:  true  gesendet
--             "MISSING"  der Client kennt die Schnittstelle nicht
--             "BLOCKED"  es gibt sie, sie hat aber abgelehnt
--
-- Der Unterschied ist der Grund fuer die drei Rueckgaben statt eines
-- Wahrheitswerts: "gibt es hier nicht" ist eine Eigenschaft des Clients und
-- wird einmal gemeldet, "hat abgelehnt" ist eine Eigenschaft der Situation
-- (Ping-Rad aus, falscher Ort) und darf den Spieler nicht bei jedem Klick
-- belaestigen.
--
-- WICHTIG ZUR REGELKONFORMITAET: Diese Funktion wird ausschliesslich aus dem
-- OnClick eines Knopfes gerufen, also im Hardware-Ereignis. Sie steht an
-- keinem Timer und an keinem Spielereignis - genau das verlangt Blizzard
-- fuer C_Ping.
function A.PingAbsetzen(schluessel)
    if not A.Vorhanden("PingSenden") then return "MISSING" end

    local wert = A.PingWert(schluessel)
    if not wert then return "MISSING" end

    -- Wenn der Client sagen kann, dass das Ping-Rad aus ist, fragen wir
    -- vorher - das erspart einen Fehlversuch.
    if A.Vorhanden("PingSystemAn") then
        local an = A.Ruf("PingSystemAn")
        if an == false then return "BLOCKED" end
    end

    local ok = A.Ruf("PingSenden", { type = wert })
    if ok == false then return "BLOCKED" end

    -- A.Ruf liefert nil, wenn der Aufruf geworfen hat. Eine Funktion ohne
    -- Rueckgabewert liefert allerdings ebenfalls nil - deshalb entscheidet
    -- hier der gemerkte Fehler, nicht der Rueckgabewert.
    if A.fehler["PingSenden"] then return "BLOCKED" end

    return true
end

-- ---------------------------------------------------------------------------
-- Wie viele Zwecke sind nicht aufloesbar - und wie viele davon sind wichtig?
-- ---------------------------------------------------------------------------
function A.FehlendeAnzahl()
    local wichtig, gesamt = 0, 0
    for zweck, quelle in pairs(A.quelle) do
        if quelle == false then
            gesamt = gesamt + 1
            if not A.optional[zweck] then
                wichtig = wichtig + 1
            end
        end
    end
    return wichtig, gesamt
end
