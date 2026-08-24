-- Daten/Vorgaben.lua - die mitgelieferten Ansagen je Rolle
--
-- ===========================================================================
-- WAS HIER STEHT UND WAS NICHT
-- ---------------------------------------------------------------------------
-- Reine Daten. Hier wird nichts berechnet und nichts gesendet. Das ist die
-- Datei, die man zu einer neuen Saison anfasst.
--
-- Die TEXTE stehen NICHT hier, sondern in Locales\ - hier stehen nur ihre
-- Schluessel. Grund: Die Ansage geht in den Gruppenchat, und auf einem
-- deutschen Realm will niemand englische Zeilen schicken.
--
-- WICHTIG: Diese Liste wird beim ersten Start EINMAL in die gespeicherten
-- Einstellungen kopiert (Logik\Speicher.lua). Danach gehoeren die Knoepfe dem
-- Spieler. Wer hier spaeter etwas aendert, aendert damit NICHT die Leiste
-- eines Spielers, der schon einmal eingeloggt war - das ist Absicht, sonst
-- wuerde eine Aenderung im Editor beim naechsten Patch verschwinden. Zurueck
-- auf diese Vorgaben kommt man mit  /tcd defaults .
--
-- Aufbau eines Eintrags:
--   lbl     Schluessel der Beschriftung unter dem Symbol
--   say     Schluessel des Nachrichtentextes (nil = Knopf sendet nichts)
--   symbol  Texturpfad oder Datei-ID
--   marke   1..8 setzt eine Zielmarkierung, 0/nil laesst es
--   ping    "ATTACK" | "WARNING" | "ONMYWAY" | "ASSIST" | nil
--
-- Der Kanal fehlt mit Absicht: Alle Vorgaben laufen auf "AUTO". Die eine
-- Taste soll im Schluesselstein in den Instanzchat gehen und im Schlachtzug
-- in den Raidchat, ohne dass man zwei Knoepfe dafuer braucht.
-- ===========================================================================
local addonName, TCD = ...

TCD.Vorgaben = {}
local V = TCD.Vorgaben

-- Der Pfad zu den Zielmarkierungs-Symbolen des Spiels. Ein Knopf, der den
-- Totenschaedel setzt, traegt genau dieses Bild - das muss man nicht lesen,
-- das erkennt man.
local function markeSymbol(index)
    return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index
end

-- ---------------------------------------------------------------------------
-- Tank
-- ---------------------------------------------------------------------------
-- Der rote Faden: Ein Tank sagt an, WAS ER GLEICH TUT. Die Gruppe kann sich
-- darauf einstellen - das ist der ganze Zweck. Deshalb stehen "LoS", "Skip"
-- und "Gross" vorne: die drei Situationen, in denen ein stiller Tank die
-- Gruppe zuverlaessig ins Verderben zieht.
V.TANK = {
    { lbl = "LBL_T_LOS",      say = "SAY_T_LOS",      symbol = "Interface\\Icons\\Ability_Rogue_Sprint" },
    { lbl = "LBL_T_PATROL",   say = "SAY_T_PATROL",   symbol = "Interface\\Icons\\Spell_Nature_TimeStop" },
    { lbl = "LBL_T_SKIP",     say = "SAY_T_SKIP",     symbol = "Interface\\Icons\\Ability_Stealth" },
    { lbl = "LBL_T_GATHER",   say = "SAY_T_GATHER",   symbol = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
    { lbl = "LBL_T_BIGPULL",  say = "SAY_T_BIGPULL",  symbol = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    { lbl = "LBL_T_SKULL",    say = "SAY_T_SKULL",    symbol = markeSymbol(8), marke = 8 },
    { lbl = "LBL_T_KITE",     say = "SAY_T_KITE",     symbol = "Interface\\Icons\\Ability_Druid_Dash" },
    { lbl = "LBL_T_EXTERNAL", say = "SAY_T_EXTERNAL", symbol = "Interface\\Icons\\Ability_Warrior_Shieldwall" },
}

-- ---------------------------------------------------------------------------
-- Heiler
-- ---------------------------------------------------------------------------
-- Ein Heiler sagt vor allem eines an: WANN ER NICHT KANN. "Mana" und "Stopp"
-- sind die zwei Knoepfe, die einen Wipe verhindern - und genau die, die man
-- im Kampf nicht tippen kann, weil beide Haende belegt sind.
V.HEALER = {
    { lbl = "LBL_H_MANA",   say = "SAY_H_MANA",   symbol = "Interface\\Icons\\INV_Potion_76" },
    { lbl = "LBL_H_DRINK",  say = "SAY_H_DRINK",  symbol = "Interface\\Icons\\INV_Drink_18" },
    { lbl = "LBL_H_DEFS",   say = "SAY_H_DEFS",   symbol = "Interface\\Icons\\Ability_Warrior_Shieldwall" },
    { lbl = "LBL_H_DISPEL", say = "SAY_H_DISPEL", symbol = "Interface\\Icons\\Spell_Holy_DispelMagic" },
    { lbl = "LBL_H_REZ",    say = "SAY_H_REZ",    symbol = "Interface\\Icons\\Spell_Holy_Resurrection",
      ping = "ASSIST" },
    { lbl = "LBL_H_PATROL", say = "SAY_H_PATROL", symbol = "Interface\\Icons\\Spell_Nature_TimeStop" },
    { lbl = "LBL_H_STOP",   say = "SAY_H_STOP",   symbol = "Interface\\Icons\\Spell_Frost_Stun" },
    { lbl = "LBL_H_LUST",   say = "SAY_H_LUST",   symbol = "Interface\\Icons\\Spell_Nature_BloodLust" },
}

-- ---------------------------------------------------------------------------
-- Schaden
-- ---------------------------------------------------------------------------
-- Hier liegt der Schwerpunkt auf ZIELEN: Wer im Schluesselstein Schaden
-- faehrt, streitet sich mit der Gruppe fast nur darueber, was zuerst stirbt
-- und was am Leben bleiben soll. Drei der acht Knoepfe setzen deshalb eine
-- Markierung, statt sie nur zu benennen.
V.DAMAGER = {
    { lbl = "LBL_D_KICK",  say = "SAY_D_KICK",  symbol = "Interface\\Icons\\Ability_Kick" },
    { lbl = "LBL_D_SKULL", say = "SAY_D_SKULL", symbol = markeSymbol(8), marke = 8 },
    { lbl = "LBL_D_CROSS", say = "SAY_D_CROSS", symbol = markeSymbol(7), marke = 7 },
    { lbl = "LBL_D_CC",    say = "SAY_D_CC",    symbol = markeSymbol(5), marke = 5 },
    { lbl = "LBL_D_CDS",   say = "SAY_D_CDS",   symbol = "Interface\\Icons\\Ability_Warrior_RallyingCry" },
    { lbl = "LBL_D_OMW",   say = "SAY_D_OMW",   symbol = "Interface\\Icons\\Ability_Hunter_Pathfinding",
      ping = "ONMYWAY" },
    { lbl = "LBL_D_ADDS",  say = "SAY_D_ADDS",  symbol = "Interface\\Icons\\Ability_Warrior_Charge", ping = "WARNING" },
    { lbl = "LBL_D_HOLD",  say = "SAY_D_HOLD",  symbol = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
}

-- Die Reihenfolge der Reiter im Dock und im Editor.
V.ROLLEN = { "TANK", "HEALER", "DAMAGER" }

-- Rollenschluessel -> Locale-Schluessel der Beschriftung
V.ROLLENNAME = {
    TANK    = "ROLE_TANK",
    HEALER  = "ROLE_HEALER",
    DAMAGER = "ROLE_DAMAGER",
}

-- ---------------------------------------------------------------------------
-- Eine frische Knopfliste fuer eine Rolle bauen
-- ---------------------------------------------------------------------------
-- Loest die Locale-Schluessel auf und liefert eine NEUE Tabelle. Neu ist
-- wichtig: Die Rueckgabe wandert in die gespeicherten Einstellungen, und wer
-- dort spaeter einen Text aendert, darf damit nicht die Vorlage veraendern.
function V.Erzeugen(rolle)
    local L = TCD.L
    local vorlage = V[rolle] or V.DAMAGER
    local liste = {}

    for i, eintrag in ipairs(vorlage) do
        liste[i] = {
            beschriftung = L[eintrag.lbl],
            text         = eintrag.say and L[eintrag.say] or "",
            kanal        = "AUTO",
            symbol       = eintrag.symbol,
            marke        = eintrag.marke or 0,
            ping         = eintrag.ping,
        }
    end

    return liste
end
