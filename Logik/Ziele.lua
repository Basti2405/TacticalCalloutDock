-- Logik/Ziele.lua - wohin die Ansage geht und was in ihr steht
--
-- ===========================================================================
-- ZWEI FRAGEN, EINE DATEI
-- ---------------------------------------------------------------------------
-- 1. WELCHER KANAL?  Der haeufigste Fehler in Ansage-Addons: ein Knopf ist
--    fest auf PARTY eingestellt, und im Schlachtzug hoert ihn niemand.
--    Schlimmer noch - SendChatMessage("...", "RAID") ausserhalb eines
--    Schlachtzugs verschwindet spurlos. Der Spieler drueckt, sieht nichts und
--    haelt das Addon fuer kaputt. Deshalb pruefen wir JEDEN Kanal gegen die
--    Lage und fallen geordnet zurueck, statt ins Leere zu senden.
--
-- 2. WAS STEHT DRIN?  Die Platzhalter. "Fokus Totenschaedel %t" muss den
--    Namen des Ziels einsetzen - und wenn es kein Ziel gibt, etwas Lesbares,
--    nicht nichts. Aus "Fokus Totenschaedel " wird die Gruppe nicht schlau.
--
-- Beides ohne jeden Rahmen und ohne jede Oberflaeche, damit
-- Tests\logik-test.lua es ohne WoW pruefen kann.
-- ===========================================================================
local addonName, TCD = ...

TCD.Ziele = {}
local Z = TCD.Ziele
local A = TCD.API

-- ---------------------------------------------------------------------------
-- Die Kanaele, die im Editor zur Wahl stehen
-- ---------------------------------------------------------------------------
-- Reihenfolge = Reihenfolge in der Auswahlliste. AUTO steht vorn, weil es in
-- den allermeisten Faellen die richtige Antwort ist.
--
-- Bewusst NICHT dabei: Fluestern und Gildenchat. Fluestern braucht ein Ziel,
-- das ein Knopf nicht kennen kann; der Gildenchat ist der falsche Ort fuer
-- eine Ansage an die Gruppe, in der man gerade steht.
Z.KANAELE = {
    { schluessel = "AUTO",          label = "CH_AUTO" },
    { schluessel = "SAY",           label = "CH_SAY" },
    { schluessel = "YELL",          label = "CH_YELL" },
    { schluessel = "PARTY",         label = "CH_PARTY" },
    { schluessel = "RAID",          label = "CH_RAID" },
    { schluessel = "RAID_WARNING",  label = "CH_RAID_WARNING" },
    { schluessel = "INSTANCE_CHAT", label = "CH_INSTANCE_CHAT" },
    { schluessel = "EMOTE",         label = "CH_EMOTE" },
}

-- Schluessel -> Locale-Schluessel, fuer Tooltip und Diagnose.
Z.KANALNAME = {}
for _, eintrag in ipairs(Z.KANAELE) do
    Z.KANALNAME[eintrag.schluessel] = eintrag.label
end

-- LE_PARTY_CATEGORY_INSTANCE ist eine Konstante des Spiels (Wert 2). Sie
-- ueber _G zu holen statt sie hinzuschreiben, kostet nichts und ueberlebt
-- den Tag, an dem Blizzard die Zahl aendert. Der Rueckfall auf 2 ist fuer
-- die Tests da, die ohne WoW laufen.
local KATEGORIE_INSTANZ = _G.LE_PARTY_CATEGORY_INSTANCE or 2

-- ---------------------------------------------------------------------------
-- In was fuer einer Gruppe stecke ich gerade?
-- ---------------------------------------------------------------------------
-- Liefert "INSTANCE", "RAID", "PARTY" oder "SOLO".
--
-- Die Reihenfolge ist wichtig und nicht beliebig: Eine Schluesselstein- oder
-- Schlachtzugsbrowser-Gruppe ist GLEICHZEITIG eine Gruppe und eine
-- Instanzgruppe. Wer zuerst auf IsInGroup() prueft, landet im Gruppenchat -
-- den in einer Instanzgruppe aber nicht alle sehen.
function Z.Gruppenlage()
    if A.Ruf("InGruppe", KATEGORIE_INSTANZ) then
        return "INSTANCE"
    end
    if A.Ruf("InSchlachtzug") then
        return "RAID"
    end
    if A.Ruf("InGruppe") then
        return "PARTY"
    end
    return "SOLO"
end

-- ---------------------------------------------------------------------------
-- Den tatsaechlichen Kanal bestimmen
-- ---------------------------------------------------------------------------
-- Rueckgabe: kanal, ersetzt
--   kanal    was SendChatMessage bekommt
--   ersetzt  true, wenn es NICHT der gewuenschte Kanal ist
--
-- "ersetzt" ist der Grund, warum die Funktion zwei Werte liefert: Wer fest
-- RAID eingestellt hat und allein herumlaeuft, soll einmal den Hinweis
-- bekommen, dass die Ansage in /sagen gelandet ist - sonst wundert er sich
-- ueber die Blicke der Umstehenden.
function Z.KanalBestimmen(wunsch)
    local lage = Z.Gruppenlage()

    -- Automatik: die Lage entscheidet.
    if wunsch == nil or wunsch == "AUTO" then
        if lage == "INSTANCE" then return "INSTANCE_CHAT", false end
        if lage == "RAID"     then return "RAID", false end
        if lage == "PARTY"    then return "PARTY", false end
        return "SAY", false
    end

    -- Diese beiden gehen immer - sie brauchen keine Gruppe.
    if wunsch == "SAY" or wunsch == "YELL" or wunsch == "EMOTE" then
        return wunsch, false
    end

    if wunsch == "INSTANCE_CHAT" then
        if lage == "INSTANCE" then return "INSTANCE_CHAT", false end
        -- Keine Instanzgruppe: dann eben die Gruppe, die es gibt.
        if lage == "RAID"  then return "RAID", true end
        if lage == "PARTY" then return "PARTY", true end
        return "SAY", true
    end

    if wunsch == "RAID" or wunsch == "RAID_WARNING" then
        -- Eine Schlachtzugswarnung darf nur, wer Anfuehrer oder Assistent
        -- ist. Ohne das Recht sendet der Server nichts - und meldet auch
        -- nichts. Deshalb hier abfangen und in den normalen Kanal legen.
        if wunsch == "RAID_WARNING" and not A.DarfMarkieren() then
            wunsch = "RAID"
        end

        -- "ersetzt" bleibt hier false, auch wenn RAID_WARNING gerade zu RAID
        -- geworden ist: Die Ansage ist beim richtigen Publikum gelandet, nur
        -- ohne den Banner. Dafuer den Spieler mitten im Pull anzusprechen,
        -- waere mehr Stoerung als Nutzen.
        if lage == "RAID" then return wunsch, false end
        if lage == "INSTANCE" then return "INSTANCE_CHAT", true end
        if lage == "PARTY" then return "PARTY", true end
        return "SAY", true
    end

    if wunsch == "PARTY" then
        if lage == "INSTANCE" then return "INSTANCE_CHAT", true end
        if lage == "RAID"  then return "RAID", true end
        if lage == "PARTY" then return "PARTY", false end
        return "SAY", true
    end

    -- Unbekannter Kanal aus einer von Hand editierten Datei.
    return "SAY", true
end

-- ===========================================================================
-- Platzhalter
-- ===========================================================================
-- %t  Ziel        %f  Fokus        %m  Mouseover        %p  du selbst
-- %%  ein echtes Prozentzeichen
--
-- Alles andere bleibt stehen, wie es dasteht: Aus "%x" wird "%x". Das ist
-- Absicht - ein Addon, das unbekannte Platzhalter verschluckt, macht aus
-- einem Tippfehler eine unvollstaendige Ansage.
--
-- Der Ersatz laeuft in EINEM Durchgang ueber gsub mit einer Funktion. Zwei
-- Gruende: Ein eingesetzter Spielername kann selbst kein Platzhalter mehr
-- werden, und das Ergebnis einer Ersatzfunktion wird von gsub nicht noch
-- einmal als Muster gelesen (bei einem Ersatz-STRING waere ein "%" darin ein
-- Fehler - Spielernamen enthalten zwar keinen, Spielertexte schon).
--
-- Einschraenkung, die man kennen muss: "50%mana" wird zu "50<Mouseover>ana".
-- Wer ein Prozentzeichen direkt vor einem Buchstaben braucht, schreibt "%%".
-- ---------------------------------------------------------------------------

-- Den Namen einer Einheit holen, oder den Ersatztext, wenn es sie nicht gibt.
local function einheitName(einheit, ersatzSchluessel)
    local L = TCD.L

    if A.Ruf("EinheitDa", einheit) then
        local name = A.Ruf("EinheitName", einheit)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    return L[ersatzSchluessel]
end

function Z.PlatzhalterFuellen(vorlage)
    if type(vorlage) ~= "string" or vorlage == "" then return "" end

    -- Ohne Prozentzeichen ist nichts zu tun - das ist der Normalfall und
    -- spart den ganzen Durchlauf.
    if not vorlage:find("%%") then return vorlage end

    local ersetzt = vorlage:gsub("%%(.)", function(zeichen)
        if zeichen == "t" then
            return einheitName("target", "SUB_NO_TARGET")
        elseif zeichen == "f" then
            return einheitName("focus", "SUB_NO_FOCUS")
        elseif zeichen == "m" then
            return einheitName("mouseover", "SUB_NO_MOUSEOVER")
        elseif zeichen == "p" then
            local name = A.Ruf("EinheitName", "player")
            return type(name) == "string" and name or "?"
        elseif zeichen == "%" then
            return "%"
        end

        -- Unbekannt: unveraendert stehen lassen.
        return "%" .. zeichen
    end)

    -- Der Server nimmt 255 Zeichen. Ein eingesetzter langer Name kann eine
    -- Zeile, die im Editor noch passte, darueber schieben.
    if #ersetzt > 255 then
        ersetzt = ersetzt:sub(1, 255)
    end

    return ersetzt
end
