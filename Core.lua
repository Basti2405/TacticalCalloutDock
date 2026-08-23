-- Core.lua - Kern des Addons "TacticalCalloutDock"
--
-- Haelt alles zusammen: gespeicherte Daten, Ereignisse, Slash-Befehle.
-- Laedt als LETZTE Datei, damit Daten, Logik und Oberflaeche schon
-- bereitstehen.
--
-- ===========================================================================
-- WIE WENIG HIER PASSIERT, IST DER PUNKT
-- ---------------------------------------------------------------------------
-- Dieses Addon lauscht auf drei Ereignisse, und keines davon sendet etwas:
--
--   ADDON_LOADED           einmal, um die Einstellungen zu laden
--   PLAYER_ENTERING_WORLD  einmal, um die Leiste aufzubauen
--   GROUP_ROSTER_UPDATE    um die Leiste ein-/auszublenden und die
--                          gemerkten Hinweise zu vergessen
--
-- Es gibt keinen Timer, keinen Kampflog-Handler und keine Reaktion auf
-- irgendetwas, das im Kampf geschieht. Eine Ansage entsteht ausschliesslich
-- dort, wo ein Mensch auf einen Knopf drueckt (UI\Knopf.lua).
-- ===========================================================================
local addonName, TCD = ...

local L = TCD.L

-- Global erreichbar machen, damit man im Spiel z. B. "/dump TacticalCalloutDock"
-- testen kann.
_G.TacticalCalloutDock = TCD

local PRAEFIX = "|cff33ccff" .. L.ADDON_NAME .. ":|r "

function TCD.Sagen(text)
    print(PRAEFIX .. text)
end

local sagen = TCD.Sagen

-- ===========================================================================
-- Ereignisse
-- ===========================================================================
local ereignisse = CreateFrame("Frame")
local aufgesetzt = false

ereignisse:RegisterEvent("ADDON_LOADED")
ereignisse:RegisterEvent("PLAYER_ENTERING_WORLD")
ereignisse:RegisterEvent("GROUP_ROSTER_UPDATE")

ereignisse:SetScript("OnEvent", function(_, ereignis, arg1)
    if ereignis == "ADDON_LOADED" then
        -- ADDON_LOADED kommt fuer JEDES Addon. Nur das eigene zaehlt - vorher
        -- gibt es die gespeicherte Tabelle noch gar nicht.
        if arg1 ~= addonName then return end

        TCD.Speicher.Aufsetzen()
        aufgesetzt = true

        ereignisse:UnregisterEvent("ADDON_LOADED")
        return
    end

    -- Die beiden folgenden koennen theoretisch vor ADDON_LOADED eintreffen,
    -- wenn ein anderes Addon beim Laden einen Fehler wirft. Ohne
    -- Einstellungen laesst sich nichts aufbauen.
    if not aufgesetzt then return end

    if ereignis == "PLAYER_ENTERING_WORLD" then
        TCD.Dock.Aufbauen()
        TCD.Minimap.Erzeugen()
        TCD.Minimap.SichtbarkeitPruefen()

        -- Der Willkommensgruss steht bewusst nur beim ersten Betreten der
        -- Welt, nicht nach jedem Zonenwechsel.
        if not TCD.begruesst then
            TCD.begruesst = true
            sagen(format(L.MSG_LOADED, "|cff33ccff/tcd|r", "|cff33ccff/tcd config|r"))
        end

    elseif ereignis == "GROUP_ROSTER_UPDATE" then
        -- Die Leiste kann von "nur in der Gruppe" abhaengen.
        TCD.Dock.SichtbarkeitPruefen()

        -- Neue Gruppe, neue Rechte: Wer eben noch nicht markieren durfte,
        -- darf es jetzt vielleicht. Die einmaligen Hinweise duerfen deshalb
        -- wieder kommen.
        TCD.Ausloesen.HinweiseVergessen()
    end
end)

-- ===========================================================================
-- Slash-Befehle
-- ===========================================================================

-- Profilnamen, die man tippen kann. Absichtlich mehrsprachig und kurz - wer
-- "/tcd heiler" eingibt, meint dasselbe wie "/tcd healer".
local PROFIL_KURZ = {
    tank    = "TANK",
    heal    = "HEALER",
    healer  = "HEALER",
    heiler  = "HEALER",
    dps     = "DAMAGER",
    damage  = "DAMAGER",
    schaden = "DAMAGER",
    dd      = "DAMAGER",
}

local function hilfeZeigen()
    sagen(L.HELP_TITLE)

    local zeilen = {
        { "/tcd",          L.HELP_TOGGLE },
        { "/tcd config",   L.HELP_CONFIG },
        { "/tcd lock",     L.HELP_LOCK },
        { "/tcd <profil>", L.HELP_ROLE },
        { "/tcd reset",    L.HELP_RESET },
        { "/tcd defaults", L.HELP_DEFAULTS },
        { "/tcd minimap",  L.HELP_MINIMAP },
        { "/tcd doctor",   L.HELP_DOCTOR },
        { "/tcd help",     L.HELP_HELP },
    }

    for _, zeile in ipairs(zeilen) do
        print(format("  |cff33ccff%s|r  %s", zeile[1], zeile[2]))
    end
end

local function befehl(eingabe)
    if not aufgesetzt then
        -- Kann vorkommen, wenn ein anderes Addon beim Laden abgebrochen ist.
        TCD.Speicher.Aufsetzen()
        aufgesetzt = true
    end

    local text = strtrim(eingabe or ""):lower()
    local wort, rest = text:match("^(%S*)%s*(.*)$")

    -- Ohne Argument: die Leiste ein- oder ausblenden. Das ist der Befehl, den
    -- man im Zweifel tippt, und deshalb der kuerzeste.
    if wort == "" then
        local an = TCD.Dock.Umschalten()
        sagen(an and L.MSG_DOCK_SHOWN or L.MSG_DOCK_HIDDEN)
        return
    end

    if wort == "config" or wort == "editor" or wort == "options" then
        TCD.Editor:Umschalten()
        return
    end

    if wort == "lock" or wort == "sperre" then
        local gesperrt = TCD.Dock.SperreUmschalten()
        sagen(gesperrt and L.MSG_DOCK_LOCKED or L.MSG_DOCK_UNLOCKED)
        return
    end

    if wort == "reset" then
        TCD.Dock.PositionZuruecksetzen()
        TCD.Dock.Aufbauen()
        sagen(L.MSG_RESET_DONE)
        return
    end

    if wort == "defaults" or wort == "vorgaben" then
        if TCD.Speicher.ProfilZuruecksetzen() then
            TCD.Dock.Aufbauen()
            TCD.Editor:Auffrischen()
            sagen(format(L.MSG_RESET_PROFILE, TCD.Speicher.AktivesProfil()))
        end
        return
    end

    if wort == "minimap" then
        local an = TCD.Minimap.Umschalten()
        sagen(an and L.MSG_DOCK_SHOWN or L.MSG_DOCK_HIDDEN)
        return
    end

    if wort == "doctor" or wort == "diagnose" then
        for _, zeile in ipairs(TCD.Diagnose.Zeilen()) do
            print(zeile)
        end
        return
    end

    if wort == "help" or wort == "hilfe" or wort == "?" then
        hilfeZeigen()
        return
    end

    -- ---------------------------------------------------------------------
    -- Alles Uebrige ist ein Profilname
    -- ---------------------------------------------------------------------
    local ziel = PROFIL_KURZ[wort]

    if not ziel then
        -- Auch ein selbst angelegtes Profil laesst sich so waehlen. Die
        -- Suche ist bewusst unabhaengig von Gross- und Kleinschreibung: Wer
        -- sein Profil "Mistweaver" nennt, tippt spaeter "mistweaver".
        for _, name in ipairs(TCD.Speicher.ProfilNamen()) do
            if name:lower() == wort then ziel = name break end
        end
    end

    if ziel and TCD.Speicher.ProfilWaehlen(ziel) then
        TCD.Dock.Aufbauen()
        TCD.Editor:Auffrischen()

        local anzeige = TCD.Vorgaben.ROLLENNAME[ziel]
        sagen(format(L.MSG_PROFILE_SWITCHED, anzeige and L[anzeige] or ziel))
        return
    end

    if ziel then
        -- Es gibt das Profil, es war nur schon aktiv.
        return
    end

    sagen(format(L.MSG_PROFILE_UNKNOWN, wort, table.concat(TCD.Speicher.ProfilNamen(), ", ")))
    if rest ~= "" then hilfeZeigen() end
end

SLASH_TACTICALCALLOUTDOCK1 = "/tcd"
SLASH_TACTICALCALLOUTDOCK2 = "/tacticaldock"
SlashCmdList["TACTICALCALLOUTDOCK"] = befehl
