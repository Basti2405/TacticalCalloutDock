-- .luacheckrc - Einstellungen fuer luacheck
--
-- Aufruf:  luacheck .
-- Ohne diese Datei meldet luacheck jede WoW-Funktion als "undefined global",
-- weil sie erst zur Laufzeit vom Spiel bereitgestellt wird.
--
-- ===========================================================================
-- WARUM DIE LISTE HIER SO KURZ IST
-- ---------------------------------------------------------------------------
-- In StatCompass und TacticalDebrief steht an dieser Stelle eine lange Liste
-- von WoW-Funktionen. Hier nicht - und das ist kein Versehen, sondern ein
-- Nebeneffekt von Logik\Kompat.lua: Dort werden die WoW-Schnittstellen ueber
-- ZEICHENKETTEN aufgeloest ( _G["SendChatMessage"] ), nicht direkt
-- aufgerufen. Fuer luacheck sind das gar keine globalen Zugriffe.
--
-- Uebrig bleibt, was die Oberflaeche unmittelbar anfasst: CreateFrame und
-- eine Handvoll Rahmen, die es im Spiel immer gibt.
-- ===========================================================================

-- WoW laeuft auf Lua 5.1.
std = "lua51"

-- WoW gibt Addon-Dateien zwei versteckte Argumente ueber "..." mit:
--     local addonName, TCD = ...
-- Den Namen braucht fast keine Datei, die Zuweisung muss aber dastehen, damit
-- TCD das ZWEITE Argument bekommt. "unused_args" greift dafuer nicht - das
-- sind keine Funktionsargumente, sondern lokale Variablen. Darum unten die
-- 211er-Regel gezielt fuer diesen einen Namen.
unused_args = false

ignore = {
    -- unbenutzte Variable - nur fuer addonName, siehe oben.
    "211/addonName",

    -- "self" schattet "self". WoW-Idiom: ein Frame-Handler bekommt seinen
    -- Frame als self uebergeben, und definiert wird er innerhalb einer
    -- Methode, die selbst ein self hat.
    "431/self",
    "432/self",
}

max_line_length = 120

-- ---------------------------------------------------------------------------
-- Globals, die WoW bereitstellt (nur lesen)
-- ---------------------------------------------------------------------------
read_globals = {
    -- Ausgabe und Zeichenketten. In WoW sind das Globals, in reinem Lua 5.1
    -- nicht - deshalb muessen sie hier stehen.
    "format", "wipe", "strtrim", "tinsert",

    -- Rahmen und Oberflaeche. Das ist alles, was dieses Addon direkt anfasst.
    "CreateFrame", "UIParent", "GameTooltip", "Minimap",

    -- Escape soll den Editor schliessen. Die Liste ist eine Tabelle des
    -- Spiels, in die man seinen Rahmennamen eintraegt.
    "UISpecialFrames",

    -- Tastatur und Maus. Beides wird nur im OnClick gefragt.
    "IsShiftKeyDown", "GetCursorPosition",
}

-- ---------------------------------------------------------------------------
-- Globals, die dieses Addon selbst setzt (lesen und schreiben)
-- ---------------------------------------------------------------------------
globals = {
    "TacticalCalloutDock",     -- Core.lua macht den Namensraum global erreichbar
    "TacticalCalloutDockDB",   -- SavedVariables

    "SLASH_TACTICALCALLOUTDOCK1",
    "SLASH_TACTICALCALLOUTDOCK2",
    "SlashCmdList",
}

-- ---------------------------------------------------------------------------
-- Sonderfaelle
-- ---------------------------------------------------------------------------
files["Tests/logik-test.lua"] = {
    -- Der Test baut die WoW-Umgebung absichtlich selbst nach und setzt dafuer
    -- Globals. Das ist hier kein Fehler, sondern der Zweck der Datei.
    globals = {
        "GetTime", "wipe", "strtrim", "format",
        "SendChatMessage", "SetRaidTarget",
        "UnitExists", "UnitName",
        "IsInGroup", "IsInRaid", "GetNumGroupMembers",
        "UnitIsGroupLeader", "UnitIsGroupAssistant", "UnitGroupRolesAssigned",
        "InCombatLockdown", "GetLocale", "GetBuildInfo", "GetInstanceInfo",
        "C_AddOns", "C_SpecializationInfo", "C_Ping", "Enum",
        "LE_PARTY_CATEGORY_INSTANCE",
        "CreateFrame", "UIParent", "GameTooltip", "Minimap", "UISpecialFrames",
        "IsShiftKeyDown",
        "TacticalCalloutDockDB",
    },
}

files["Locales/*.lua"] = {
    -- Ein Satz gehoert in eine Zeile, siehe den Kopf von Locales/enUS.lua.
    max_line_length = 400,
}
