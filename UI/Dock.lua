-- UI/Dock.lua - die Leiste
--
-- ===========================================================================
-- WARUM DIESE LEISTE IM KAMPF NICHT EINFRIERT
-- ---------------------------------------------------------------------------
-- Fast jede Aktionsleiste in WoW muss im Kampf stillhalten: Sobald ein Knopf
-- eine Faehigkeit wirken kann, braucht er eine geschuetzte Vorlage, und
-- geschuetzte Rahmen darf man im Kampf weder verschieben noch neu anordnen.
-- Deshalb melden viele Addons "geht erst nach dem Kampf".
--
-- Hier ist das anders, und zwar aus einem einzigen Grund: Kein Knopf dieses
-- Addons wirkt etwas. Chatnachricht, Zielmarkierung und Ping sind
-- ungeschuetzte Funktionen. Damit sind auch die Rahmen ungeschuetzt, und
-- Groesse, Ausrichtung, Profilwechsel und selbst das Verschieben der Leiste
-- funktionieren mitten im Pull.
--
-- Diese Datei enthaelt deshalb bewusst KEIN "im Kampf spaeter"-Nachholen.
-- Solcher Code haette hier nur einen Zweck: sich falsch zu verhalten, sobald
-- ihn jemand braucht.
-- ===========================================================================
local addonName, TCD = ...

TCD.Dock = {}
local Dock = TCD.Dock
local L = TCD.L
local K = TCD.Knopf
local St = TCD.Stil
local F = St.FARBE

local rahmen        -- der Hauptrahmen
local reiterVorrat = {}

-- ---------------------------------------------------------------------------
-- Wie viele Spalten und Zeilen?
-- ---------------------------------------------------------------------------
-- Reine Rechnung, kein Rahmen - damit Tests\logik-test.lua sie ohne WoW
-- pruefen kann. Der Umbruch zaehlt immer in Laufrichtung: waagerecht sind es
-- Knoepfe je Zeile, senkrecht Knoepfe je Spalte.
function Dock.Anordnung(anzahl, ausrichtung, umbruch)
    if anzahl <= 0 then return 0, 0 end

    if umbruch == nil or umbruch <= 0 or umbruch >= anzahl then
        if ausrichtung == "vertikal" then
            return 1, anzahl
        end
        return anzahl, 1
    end

    local voll = math.ceil(anzahl / umbruch)

    if ausrichtung == "vertikal" then
        -- umbruch = Knoepfe je Spalte
        return voll, umbruch
    end

    -- umbruch = Knoepfe je Zeile
    return umbruch, voll
end

-- ---------------------------------------------------------------------------
-- Die Position sichern
-- ---------------------------------------------------------------------------
-- Nach jedem Ziehen. GetPoint liefert den Anker, wie ihn WoW gerade
-- tatsaechlich haelt - deshalb wird er hier ausgelesen und nicht mitgezaehlt.
local function positionSichern()
    local d = TCD.Speicher.Dock()
    local punkt, _, relPunkt, x, y = rahmen:GetPoint()

    d.punkt    = punkt or "CENTER"
    d.relPunkt = relPunkt or "CENTER"
    d.x        = x or 0
    d.y        = y or 0
end

local function positionAnwenden()
    local d = TCD.Speicher.Dock()
    rahmen:ClearAllPoints()
    rahmen:SetPoint(d.punkt, UIParent, d.relPunkt, d.x, d.y)
    rahmen:SetScale(d.skalierung)
end

-- ===========================================================================
-- Die Reiter fuer die Profile
-- ===========================================================================
-- Bewusst schmal und ohne Rahmen: Sie sollen die Leiste nicht dominieren. Wer
-- sie nicht braucht, hat trotzdem nur einen Streifen ueber den Knoepfen.
--
-- 16 statt der 14 Punkte von 1.0, und in der schmalen Schrift aus
-- UI\Stil.lua statt in GameFontNormalSmall. Beides zusammen macht die
-- Reiter LESBARER und trotzdem nicht groesser: Die schmale Schrift passt
-- bei gleicher Punktzahl in weniger Breite, die zwei Punkte mehr Hoehe
-- nehmen ihr das Gequetschte.
local REITER_HOEHE = 16

local function reiterHolen(index)
    local reiter = reiterVorrat[index]
    if reiter then return reiter end

    reiter = CreateFrame("Button", nil, rahmen)
    reiter:SetHeight(REITER_HOEHE)

    reiter.grund = St.Scharf(reiter:CreateTexture(nil, "BACKGROUND"))
    reiter.grund:SetAllPoints()

    reiter.hell = St.Scharf(reiter:CreateTexture(nil, "HIGHLIGHT"))
    reiter.hell:SetAllPoints()
    reiter.hell:SetColorTexture(1, 1, 1, 0.10)

    -- Der Strich an der UNTERkante des aktiven Reiters. Er sitzt dort, wo der
    -- Reiter die Leiste beruehrt, und bindet die beiden damit sichtbar
    -- zusammen - man sieht, dass diese Knoepfe zu diesem Reiter gehoeren.
    reiter.strich = St.Scharf(reiter:CreateTexture(nil, "ARTWORK"))
    reiter.strich:SetPoint("BOTTOMLEFT", 0, 0)
    reiter.strich:SetPoint("BOTTOMRIGHT", 0, 0)
    reiter.strich:SetColorTexture(St.Ent(F.akzent))
    reiter.strich:Hide()

    local function strichHoehe() reiter.strich:SetHeight(St.Pixel(reiter) * 2) end
    strichHoehe()
    St.NachSkalierung(strichHoehe)

    reiter.text = St.Text(reiter, nil, St.Klein)
    reiter.text:SetPoint("CENTER")
    reiter.text:SetJustifyH("CENTER")

    reiter:SetScript("OnClick", function(self)
        if TCD.Speicher.ProfilWaehlen(self.profil) then
            Dock.Aufbauen()
            TCD.Editor:Auffrischen()
        end
    end)

    reiterVorrat[index] = reiter
    return reiter
end

local function reiterAufbauen()
    local namen = TCD.Speicher.ProfilNamen()
    local aktiv = TCD.Speicher.AktivesProfil()
    local x = 0

    for i, name in ipairs(namen) do
        local reiter = reiterHolen(i)
        local anzeige = TCD.Vorgaben.ROLLENNAME[name]

        reiter.profil = name
        reiter.text:SetText(anzeige and L[anzeige] or name)
        reiter:SetWidth(reiter.text:GetStringWidth() + 18)

        -- Der aktive Reiter ist heller UND traegt den Strich. Zwei Merkmale
        -- statt einem, weil die Leiste bei Deckkraft 0 auf der Spielwelt
        -- liegt - und dort trifft eine Flaechenfarbe allein einmal auf
        -- Steinboden und einmal auf Schnee.
        if name == aktiv then
            reiter.grund:SetColorTexture(St.Ent(F.akzentTief, 0.92))
            reiter.text:SetFontObject(St.Normal)
            reiter.strich:Show()
        else
            reiter.grund:SetColorTexture(St.Ent(F.grund, 0.72))
            reiter.text:SetFontObject(St.Leise)
            reiter.strich:Hide()
        end

        reiter:ClearAllPoints()
        reiter:SetPoint("BOTTOMLEFT", rahmen, "TOPLEFT", x, 1)
        reiter:Show()

        x = x + reiter:GetWidth() + 2
    end

    -- Reiter, die ein frueheres Profil uebrig gelassen hat.
    local i = #namen + 1
    while reiterVorrat[i] do
        reiterVorrat[i]:Hide()
        i = i + 1
    end
end

-- ===========================================================================
-- Erzeugen
-- ===========================================================================
function Dock.Erzeugen()
    if rahmen then return rahmen end

    rahmen = CreateFrame("Frame", "TacticalCalloutDockFrame", UIParent)
    rahmen:SetFrameStrata("MEDIUM")
    rahmen:SetClampedToScreen(true)
    rahmen:SetMovable(true)
    rahmen:EnableMouse(true)
    rahmen:RegisterForDrag("LeftButton")

    rahmen:SetScript("OnDragStart", function(self)
        if TCD.Speicher.Dock().gesperrt then return end
        self:StartMoving()
    end)

    rahmen:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        positionSichern()
    end)

    -- Der Hinweis zum Verschieben liegt auf dem Hintergrund, nicht auf den
    -- Knoepfen: Wer ueber einem Knopf steht, will wissen, was der Knopf tut.
    rahmen:SetScript("OnEnter", function(self)
        if TCD.Speicher.Dock().gesperrt then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(L.ADDON_NAME, 1, 1, 1)
        GameTooltip:AddLine(L.TIP_DRAG, 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    rahmen:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Flaeche und Umriss werden hier EINMAL angelegt und in Dock.Aufbauen()
    -- nur umgefaerbt. Anders als SetBackdrop, das bei jedem Aufbau die ganze
    -- Randgeometrie neu erzeugt hat, kostet das Umfaerben nichts - und der
    -- Umriss bleibt punktgenau, weil er sich aus UI\Stil.lua selbst
    -- nachrechnet, wenn der Spieler die Aufloesung wechselt.
    St.Karte(rahmen, { grund = F.grund, grundAlpha = 0, rand = F.linieHell, randAlpha = 0 })

    TCD.dockRahmen = rahmen
    return rahmen
end

-- ===========================================================================
-- Aufbauen
-- ===========================================================================
-- Wird nach jeder Aenderung gerufen: Profilwechsel, Editor, Groesse,
-- Ausrichtung. Legt keine Rahmen an, die es schon gibt (siehe UI\Knopf.lua).
function Dock.Aufbauen()
    if not rahmen then Dock.Erzeugen() end

    local d = TCD.Speicher.Dock()
    local liste = TCD.Speicher.AktiveListe() or {}
    local anzahl = #liste

    -- Der Hintergrund. Deckkraft 0 heisst wirklich unsichtbar - dann bleibt
    -- nur die Knopfreihe stehen, und genau das wollen manche. Der Umriss geht
    -- mit: Ein Rahmen um nichts sieht aus wie ein Fehler.
    St.Faerben(rahmen, F.grund, F.linieHell,
        d.deckkraft,
        d.deckkraft > 0 and math.min(0.55, d.deckkraft + 0.15) or 0)

    local spalten, zeilen = Dock.Anordnung(anzahl, d.ausrichtung, d.umbruch)
    local rand = 4

    if anzahl == 0 then
        -- Eine leere Leiste braucht trotzdem eine Groesse, sonst laesst sie
        -- sich nicht mehr anfassen und der Editor ist unerreichbar.
        rahmen:SetSize(120, 24)
        K.RestVerstecken(1)
        reiterAufbauen()
        Dock.SichtbarkeitPruefen()
        return
    end

    for i = 1, anzahl do
        local knopfRahmen = K.Holen(rahmen, i)
        K.Bestuecken(knopfRahmen, liste[i], i, d.groesse, d.beschriftungen)

        -- Die Laufrichtung entscheidet, was sich zuerst fuellt: waagerecht
        -- die Zeile, senkrecht die Spalte.
        local spalte, zeile
        if d.ausrichtung == "vertikal" then
            zeile   = (i - 1) % zeilen
            spalte  = math.floor((i - 1) / zeilen)
        else
            spalte  = (i - 1) % spalten
            zeile   = math.floor((i - 1) / spalten)
        end

        knopfRahmen:ClearAllPoints()
        knopfRahmen:SetPoint(
            "TOPLEFT", rahmen, "TOPLEFT",
            rand + spalte * (d.groesse + d.abstand),
            -(rand + zeile * (d.groesse + d.abstand))
        )
    end

    K.RestVerstecken(anzahl + 1)

    rahmen:SetSize(
        rand * 2 + spalten * d.groesse + (spalten - 1) * d.abstand,
        rand * 2 + zeilen  * d.groesse + (zeilen  - 1) * d.abstand
    )

    positionAnwenden()
    reiterAufbauen()
    Dock.SichtbarkeitPruefen()
end

-- ===========================================================================
-- Sichtbarkeit
-- ===========================================================================
-- Zwei Schalter greifen ineinander: die ausdrueckliche Wahl des Spielers
-- (d.sichtbar) und die Bequemlichkeitsregel "nur in der Gruppe". Die Wahl
-- des Spielers gewinnt immer - eine Leiste, die man eingeschaltet hat und
-- die trotzdem wegbleibt, ist ein Fehlerbericht.
function Dock.SichtbarkeitPruefen()
    -- Der Minimap-Knopf zeigt den Zustand mit an. Der Aufruf steht VOR dem
    -- Ausstieg fuer "noch kein Rahmen": Beim Login ist der Knopf vor der
    -- Leiste da, und ein Knopf, der beim ersten Blick den falschen Zustand
    -- zeigt, ist schlimmer als keiner.
    if TCD.Minimap and TCD.Minimap.ZustandZeigen then
        TCD.Minimap.ZustandZeigen()
    end

    if not rahmen then return end

    local d = TCD.Speicher.Dock()

    if not d.sichtbar then
        rahmen:Hide()
        return
    end

    if d.nurGruppe and TCD.Ziele.Gruppenlage() == "SOLO" then
        rahmen:Hide()
        return
    end

    rahmen:Show()
end

function Dock.Umschalten()
    local d = TCD.Speicher.Dock()
    d.sichtbar = not d.sichtbar
    Dock.SichtbarkeitPruefen()
    return d.sichtbar
end

function Dock.SperreUmschalten()
    local d = TCD.Speicher.Dock()
    d.gesperrt = not d.gesperrt
    return d.gesperrt
end

function Dock.PositionZuruecksetzen()
    TCD.Speicher.PositionZuruecksetzen()
    if rahmen then positionAnwenden() end
end
