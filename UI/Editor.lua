-- UI/Editor.lua - der Editor: Knoepfe anlegen, aendern, umsortieren, loeschen
--
-- ===========================================================================
-- WARUM HIER SO VIEL SELBST GEBAUT IST
-- ---------------------------------------------------------------------------
-- Blizzards Oberflaechenvorlagen sind unterschiedlich verlaesslich. Nachgezaehlt
-- in einer Installation mit 115 Addons (Stand 12.1.0), wie viele davon eine
-- Vorlage ueberhaupt noch benutzen:
--
--   BackdropTemplate ........ 485      UICheckButtonTemplate .... 15
--   UIPanelButtonTemplate ... 135      OptionsSliderTemplate ..... 1
--   InputBoxTemplate ......... 56      UIDropDownMenuTemplate ... 32 (veraltet)
--
-- Was breit benutzt wird, verschwindet nicht ueber Nacht - das wird hier
-- benutzt. Was kaum noch jemand anfasst (Schieberegler) oder was Blizzard
-- ausdruecklich abgeloest hat (das alte Aufklappmenue), ist hier selbst
-- gebaut: ein Zahlenfeld mit zwei Schrittknoepfen statt eines Reglers, eine
-- eigene Auswahlliste statt UIDropDownMenu, eine eigene Liste mit Mausrad
-- statt eines Scrollrahmens.
--
-- Das kostet etwa 150 Zeilen und spart den Tag, an dem eine Vorlage
-- verschwindet und das Addon beim Oeffnen des Editors einen Fehler wirft.
-- ===========================================================================
local addonName, TCD = ...

TCD.Editor = {}
local E = TCD.Editor
local L = TCD.L
local S = TCD.Speicher

local fenster           -- der Hauptrahmen
local gewaehlt = 1      -- welcher Knopf gerade bearbeitet wird
local versatz  = 0      -- erste sichtbare Zeile der Liste
local felder   = {}     -- die Eingabefelder des Formulars
local zeilen   = {}     -- die Zeilen der Knopfliste
local schalter = {}     -- die Kontrollkaesten des Leisten-Reiters
local reiterAktiv = "BUTTONS"

local ZEILEN_SICHTBAR = 11
local ZEILEN_HOEHE    = 24

-- ===========================================================================
-- BAUSTEINE
-- ===========================================================================

-- Eine Ueberschrift.
local function beschriftung(eltern, text, schriftart)
    local fs = eltern:CreateFontString(nil, "OVERLAY", schriftart or "GameFontNormalSmall")
    fs:SetText(text)
    return fs
end

-- Ein einzeiliges Eingabefeld.
local function eingabe(eltern, breite, hoehe)
    local box = CreateFrame("EditBox", nil, eltern, "InputBoxTemplate")
    box:SetSize(breite, hoehe or 22)
    box:SetAutoFocus(false)
    box:SetFontObject("ChatFontNormal")
    box:SetTextInsets(4, 4, 0, 0)

    -- Escape gibt den Fokus frei, statt das Fenster zu schliessen. Wer
    -- mitten in einem Text steckt, will nicht bei jedem Vertipper von vorn
    -- anfangen.
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    return box
end

-- Ein Kontrollkasten mit Beschriftung rechts daneben.
local function kasten(eltern, text, beiAenderung)
    local k = CreateFrame("CheckButton", nil, eltern, "UICheckButtonTemplate")
    k:SetSize(22, 22)
    k.text = k:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    k.text:SetPoint("LEFT", k, "RIGHT", 2, 0)
    k.text:SetText(text)
    k:SetScript("OnClick", function(self) beiAenderung(self:GetChecked() and true or false) end)
    return k
end

-- Ein normaler Knopf.
local function knopf(eltern, text, breite, beiKlick)
    local b = CreateFrame("Button", nil, eltern, "UIPanelButtonTemplate")
    b:SetSize(breite, 22)
    b:SetText(text)
    b:SetScript("OnClick", beiKlick)
    return b
end

-- ---------------------------------------------------------------------------
-- Ein Zahlenfeld mit zwei Schrittknoepfen
-- ---------------------------------------------------------------------------
-- Ersetzt den Schieberegler. Zwei Vorteile ausser der Patchfestigkeit: Man
-- kann einen Wert genau eintippen statt ihn zu treffen, und man sieht ihn
-- immer als Zahl - bei einem Regler muss man dafuer den Griff anfassen.
local function zahlenfeld(eltern, text, min, max, schritt, holen, setzen)
    local halter = CreateFrame("Frame", nil, eltern)
    halter:SetSize(210, 24)

    local titel = beschriftung(halter, text)
    titel:SetPoint("LEFT", 0, 0)
    titel:SetWidth(120)
    titel:SetJustifyH("LEFT")

    local box = eingabe(halter, 44, 20)
    box:SetPoint("LEFT", halter, "LEFT", 124, 0)
    box:SetNumeric(false)   -- Kommazahlen (Deckkraft, Skalierung) sollen gehen
    box:SetJustifyH("CENTER")

    local function anzeigen()
        local wert = holen()
        -- Ganze Zahlen ohne Komma zeigen: "34" liest sich besser als "34.0".
        if schritt >= 1 then
            box:SetText(tostring(math.floor(wert + 0.5)))
        else
            box:SetText(format("%.2f", wert))
        end
        box:SetCursorPosition(0)
    end

    local function uebernehmen(wert)
        if type(wert) ~= "number" or wert ~= wert then anzeigen() return end
        if wert < min then wert = min end
        if wert > max then wert = max end
        setzen(wert)
        anzeigen()
        TCD.Dock.Aufbauen()
    end

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        uebernehmen(tonumber(self:GetText()))
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() anzeigen() end)

    local runter = knopf(halter, "-", 22, function() uebernehmen(holen() - schritt) end)
    runter:SetPoint("LEFT", box, "RIGHT", 4, 0)

    local hoch = knopf(halter, "+", 22, function() uebernehmen(holen() + schritt) end)
    hoch:SetPoint("LEFT", runter, "RIGHT", 2, 0)

    halter.Auffrischen = anzeigen
    return halter
end

-- ---------------------------------------------------------------------------
-- Eine eigene Auswahlliste
-- ---------------------------------------------------------------------------
-- Ersatz fuer UIDropDownMenu. Der Knopf zeigt den aktuellen Wert; ein Klick
-- klappt die Liste darunter auf. Bewusst schlicht: kein Untermenue, keine
-- Bilder, keine Tastatursteuerung - fuer acht Kanaele und neun Markierungen
-- braucht es das nicht.
--
-- eintraege: Liste von { wert = ..., text = "..." }
local function auswahl(eltern, breite, eintraege, holen, setzen)
    local halter = CreateFrame("Frame", nil, eltern)
    halter:SetSize(breite, 22)

    local anzeige = CreateFrame("Button", nil, halter, "UIPanelButtonTemplate")
    anzeige:SetAllPoints()
    anzeige:GetFontString():SetJustifyH("LEFT")
    anzeige:GetFontString():SetPoint("LEFT", 6, 0)

    local liste = CreateFrame("Frame", nil, halter, "BackdropTemplate")
    liste:SetPoint("TOPLEFT", anzeige, "BOTTOMLEFT", 0, -2)
    liste:SetWidth(breite)
    liste:SetFrameStrata("DIALOG")
    liste:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    liste:SetBackdropColor(0.06, 0.08, 0.11, 0.98)
    liste:SetBackdropBorderColor(0.35, 0.45, 0.55, 1)
    liste:Hide()

    local function text_zu(wert)
        for _, e in ipairs(eintraege) do
            if e.wert == wert then return e.text end
        end
        return tostring(wert)
    end

    local function anzeigen()
        anzeige:SetText(text_zu(holen()))
    end

    local function zuklappen()
        liste:Hide()
    end

    for i, e in ipairs(eintraege) do
        local zeile = CreateFrame("Button", nil, liste)
        zeile:SetSize(breite - 2, 18)
        zeile:SetPoint("TOPLEFT", 1, -((i - 1) * 18) - 1)

        zeile.hell = zeile:CreateTexture(nil, "HIGHLIGHT")
        zeile.hell:SetAllPoints()
        zeile.hell:SetColorTexture(0.2, 0.5, 0.8, 0.4)

        zeile.text = zeile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        zeile.text:SetPoint("LEFT", 5, 0)
        zeile.text:SetText(e.text)

        zeile:SetScript("OnClick", function()
            setzen(e.wert)
            anzeigen()
            zuklappen()
        end)
    end

    liste:SetHeight(#eintraege * 18 + 2)

    anzeige:SetScript("OnClick", function()
        if liste:IsShown() then zuklappen() else liste:Show() end
    end)

    halter.Auffrischen = anzeigen
    halter.Zuklappen   = zuklappen
    return halter
end

-- ===========================================================================
-- DIE AUSWAHLLISTEN DES FORMULARS
-- ===========================================================================
-- Einmal gebaut, nicht bei jedem Oeffnen: Was der Client kennt, aendert sich
-- waehrend einer Sitzung nicht.

local function kanalEintraege()
    local liste = {}
    for _, k in ipairs(TCD.Ziele.KANAELE) do
        liste[#liste + 1] = { wert = k.schluessel, text = L[k.label] }
    end
    return liste
end

local function markeEintraege()
    local liste = { { wert = 0, text = L.MARK_NONE } }
    for i = 1, 8 do
        -- Das Symbol steht mit im Text: In einer Liste aus acht Wortmarken
        -- sucht man sonst "Kreuz" statt es zu sehen.
        liste[#liste + 1] = {
            wert = i,
            text = format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:14|t %s", i, L["MARK_" .. i]),
        }
    end
    return liste
end

-- Nur die Ping-Arten, die dieser Client wirklich kennt (siehe
-- Logik\Kompat.lua). Ein Eintrag, der nichts tut, gehoert nicht in die Liste.
local function pingEintraege()
    local liste = { { wert = false, text = L.PING_NONE } }
    for _, art in ipairs(TCD.API.PingArten()) do
        liste[#liste + 1] = { wert = art.schluessel, text = L["PING_" .. art.schluessel] }
    end
    return liste
end

-- ===========================================================================
-- Zugriff auf den gerade bearbeiteten Knopf
-- ===========================================================================
local function aktuell()
    local liste = S.AktiveListe()
    if not liste then return nil end
    if gewaehlt < 1 then gewaehlt = 1 end
    if gewaehlt > #liste then gewaehlt = #liste end
    return liste[gewaehlt]
end

-- Eine Aenderung am aktuellen Knopf uebernehmen und ueberall sichtbar machen.
local function aendern(feld, wert)
    local eintrag = aktuell()
    if not eintrag then return end

    eintrag[feld] = wert

    -- Ueber KnopfSetzen, damit die Pruefungen aus Logik\Speicher.lua greifen -
    -- sonst koennte man hier eine 300 Zeichen lange Nachricht eintragen, die
    -- der Server spaeter stumm abschneidet.
    S.KnopfSetzen(gewaehlt, eintrag)

    TCD.Dock.Aufbauen()
    E:Auffrischen()
end

-- ===========================================================================
-- Die Knopfliste (links)
-- ===========================================================================
local function listeAuffrischen()
    local liste = S.AktiveListe() or {}
    local anzahl = #liste

    -- Der Versatz darf nie so gross werden, dass die Liste leer aussieht,
    -- obwohl Knoepfe da sind - das passiert nach dem Loeschen des letzten.
    local maxVersatz = math.max(0, anzahl - ZEILEN_SICHTBAR)
    if versatz > maxVersatz then versatz = maxVersatz end
    if versatz < 0 then versatz = 0 end

    for i = 1, ZEILEN_SICHTBAR do
        local zeile = zeilen[i]
        local index = i + versatz
        local eintrag = liste[index]

        if eintrag then
            zeile.index = index
            zeile.symbol:SetTexture(eintrag.symbol)
            zeile.text:SetText(format("%d. %s", index, eintrag.beschriftung ~= "" and eintrag.beschriftung or "-"))

            if index == gewaehlt then
                zeile.grund:SetColorTexture(0.20, 0.60, 0.85, 0.55)
            else
                zeile.grund:SetColorTexture(0, 0, 0, 0)
            end

            zeile:Show()
        else
            zeile:Hide()
        end
    end

    fenster.leerHinweis:SetShown(anzahl == 0)
end

-- ===========================================================================
-- Das Formular (rechts)
-- ===========================================================================
local function formularAuffrischen()
    local eintrag = aktuell()

    if not eintrag then
        for _, feld in pairs(felder) do
            if feld.SetText then feld:SetText("") end
            if feld.Auffrischen then feld.Auffrischen() end
            feld:Hide()
        end
        return
    end

    for _, feld in pairs(felder) do feld:Show() end

    felder.beschriftung:SetText(eintrag.beschriftung or "")
    felder.beschriftung:SetCursorPosition(0)

    felder.text:SetText(eintrag.text or "")
    felder.text:SetCursorPosition(0)

    felder.symbol:SetText(tostring(eintrag.symbol or ""))
    felder.symbol:SetCursorPosition(0)

    felder.kanal.Auffrischen()
    felder.marke.Auffrischen()
    felder.ping.Auffrischen()
end

-- ===========================================================================
-- Der Leisten-Reiter
-- ===========================================================================
local function layoutAuffrischen()
    local d = S.Dock()

    for _, feld in pairs(schalter) do
        if feld.Auffrischen then feld.Auffrischen() end
    end

    schalter.beschriftungen:SetChecked(d.beschriftungen)
    schalter.gesperrt:SetChecked(d.gesperrt)
    schalter.nurGruppe:SetChecked(d.nurGruppe)
end

-- ===========================================================================
-- Reiter umschalten
-- ===========================================================================
local function reiterZeigen(welcher)
    reiterAktiv = welcher

    fenster.bereichKnoepfe:SetShown(welcher == "BUTTONS")
    fenster.bereichLayout:SetShown(welcher == "LAYOUT")

    fenster.reiterKnoepfe.grund:SetColorTexture(
        welcher == "BUTTONS" and 0.20 or 0, welcher == "BUTTONS" and 0.60 or 0,
        welcher == "BUTTONS" and 0.85 or 0, welcher == "BUTTONS" and 0.8 or 0.35)
    fenster.reiterLayout.grund:SetColorTexture(
        welcher == "LAYOUT" and 0.20 or 0, welcher == "LAYOUT" and 0.60 or 0,
        welcher == "LAYOUT" and 0.85 or 0, welcher == "LAYOUT" and 0.8 or 0.35)

    E:Auffrischen()
end

-- ===========================================================================
-- Das Fenster bauen
-- ===========================================================================
-- Laeuft genau einmal, beim ersten Oeffnen. Danach wird nur noch
-- aufgefrischt - ein Fenster, das bei jedem Oeffnen neu entsteht, verliert
-- seine Position und laesst Rahmen zurueck.
local function fensterBauen()
    if fenster then return end

    fenster = CreateFrame("Frame", "TacticalCalloutDockEditor", UIParent, "BackdropTemplate")
    fenster:SetSize(620, 486)
    fenster:SetPoint("CENTER")
    fenster:SetFrameStrata("DIALOG")
    fenster:SetMovable(true)
    fenster:EnableMouse(true)
    fenster:RegisterForDrag("LeftButton")
    fenster:SetScript("OnDragStart", fenster.StartMoving)
    fenster:SetScript("OnDragStop", fenster.StopMovingOrSizing)
    fenster:SetClampedToScreen(true)

    fenster:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    fenster:SetBackdropColor(0.05, 0.07, 0.10, 0.96)
    fenster:SetBackdropBorderColor(0.25, 0.35, 0.45, 1)

    -- Escape schliesst das Fenster. UISpecialFrames verlangt den GLOBALEN
    -- Namen des Rahmens - ein lokaler Verweis reicht nicht.
    tinsert(UISpecialFrames, "TacticalCalloutDockEditor")

    -- Ein Klick irgendwo im Fenster klappt offene Auswahllisten zu. Ohne das
    -- bleibt eine Liste stehen, bis man sie noch einmal trifft.
    fenster:SetScript("OnMouseDown", function()
        for _, feld in pairs(felder) do
            if feld.Zuklappen then feld.Zuklappen() end
        end
        for _, feld in pairs(schalter) do
            if feld.Zuklappen then feld.Zuklappen() end
        end
    end)

    -- ---------------------------------------------------------------------
    -- Kopf
    -- ---------------------------------------------------------------------
    local titel = beschriftung(fenster, L.CFG_TITLE, "GameFontNormalLarge")
    titel:SetPoint("TOPLEFT", 16, -14)

    local zu = knopf(fenster, L.CFG_CLOSE, 80, function() E:Schliessen() end)
    zu:SetPoint("TOPRIGHT", -14, -12)

    -- Das aktive Profil. Es steht hier und nicht nur an der Leiste, damit man
    -- beim Bearbeiten sieht, wessen Knoepfe man gerade vor sich hat.
    fenster.profil = beschriftung(fenster, "", "GameFontHighlightSmall")
    fenster.profil:SetPoint("TOPLEFT", 16, -38)

    -- ---------------------------------------------------------------------
    -- Reiter
    -- ---------------------------------------------------------------------
    local function reiterBauen(text, x, welcher)
        local r = CreateFrame("Button", nil, fenster)
        r:SetSize(110, 20)
        r:SetPoint("TOPLEFT", x, -58)

        r.grund = r:CreateTexture(nil, "BACKGROUND")
        r.grund:SetAllPoints()

        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.text:SetPoint("CENTER")
        r.text:SetText(text)

        r:SetScript("OnClick", function() reiterZeigen(welcher) end)
        return r
    end

    fenster.reiterKnoepfe = reiterBauen(L.CFG_TAB_BUTTONS, 16, "BUTTONS")
    fenster.reiterLayout  = reiterBauen(L.CFG_TAB_LAYOUT, 130, "LAYOUT")

    -- =====================================================================
    -- Bereich "Knoepfe"
    -- =====================================================================
    local B = CreateFrame("Frame", nil, fenster)
    B:SetPoint("TOPLEFT", 0, -84)
    B:SetPoint("BOTTOMRIGHT", 0, 0)
    fenster.bereichKnoepfe = B

    local listenTitel = beschriftung(B, L.CFG_LIST)
    listenTitel:SetPoint("TOPLEFT", 16, -4)

    -- Der Listenrahmen. Mausrad statt Scrollrahmen (siehe Kopf der Datei).
    local listenRahmen = CreateFrame("Frame", nil, B, "BackdropTemplate")
    listenRahmen:SetPoint("TOPLEFT", 14, -22)
    listenRahmen:SetSize(232, ZEILEN_SICHTBAR * ZEILEN_HOEHE + 4)
    listenRahmen:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    listenRahmen:SetBackdropColor(0, 0, 0, 0.35)
    listenRahmen:SetBackdropBorderColor(0.2, 0.28, 0.36, 1)
    listenRahmen:EnableMouseWheel(true)
    listenRahmen:SetScript("OnMouseWheel", function(_, richtung)
        versatz = versatz - richtung
        listeAuffrischen()
    end)

    fenster.leerHinweis = beschriftung(listenRahmen, L.CFG_EMPTY, "GameFontDisableSmall")
    fenster.leerHinweis:SetPoint("TOPLEFT", 8, -8)
    fenster.leerHinweis:SetWidth(210)
    fenster.leerHinweis:SetJustifyH("LEFT")

    for i = 1, ZEILEN_SICHTBAR do
        local zeile = CreateFrame("Button", nil, listenRahmen)
        zeile:SetSize(228, ZEILEN_HOEHE)
        zeile:SetPoint("TOPLEFT", 2, -((i - 1) * ZEILEN_HOEHE) - 2)

        zeile.grund = zeile:CreateTexture(nil, "BACKGROUND")
        zeile.grund:SetAllPoints()

        zeile.hell = zeile:CreateTexture(nil, "HIGHLIGHT")
        zeile.hell:SetAllPoints()
        zeile.hell:SetColorTexture(1, 1, 1, 0.12)

        zeile.symbol = zeile:CreateTexture(nil, "ARTWORK")
        zeile.symbol:SetSize(18, 18)
        zeile.symbol:SetPoint("LEFT", 4, 0)
        zeile.symbol:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        zeile.text = zeile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        zeile.text:SetPoint("LEFT", zeile.symbol, "RIGHT", 6, 0)
        zeile.text:SetPoint("RIGHT", -4, 0)
        zeile.text:SetJustifyH("LEFT")
        zeile.text:SetWordWrap(false)

        zeile:SetScript("OnClick", function(self)
            gewaehlt = self.index
            E:Auffrischen()
        end)

        zeilen[i] = zeile
    end

    -- Die Knoepfe unter der Liste.
    local hinzu = knopf(B, L.CFG_ADD, 76, function()
        gewaehlt = S.KnopfHinzufuegen()
        -- Zum neuen Knopf springen, sonst legt man ihn blind am Ende an.
        versatz = math.max(0, gewaehlt - ZEILEN_SICHTBAR)
        TCD.Dock.Aufbauen()
        E:Auffrischen()
    end)
    hinzu:SetPoint("TOPLEFT", listenRahmen, "BOTTOMLEFT", 0, -6)

    local weg = knopf(B, L.CFG_DELETE, 76, function()
        if S.KnopfLoeschen(gewaehlt) then
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    weg:SetPoint("LEFT", hinzu, "RIGHT", 4, 0)

    -- ---------------------------------------------------------------------
    -- Zweite Reihe: Hoch und Runter
    -- ---------------------------------------------------------------------
    -- Erst standen alle vier nebeneinander. Im Spiel war "Runter" halb
    -- abgeschnitten, und breiter durfte die Reihe nicht werden: Sie muss
    -- unter die 232 Pixel breite Liste passen, sonst ragt sie in das Formular
    -- rechts daneben. Deutsche Beschriftungen sind laenger als englische -
    -- eine Reihe, die auf Englisch gerade noch passt, passt auf Deutsch nicht
    -- mehr. Zwei Reihen loesen das, ohne von der Sprache abzuhaengen.
    local hoch = knopf(B, L.CFG_UP, 76, function()
        local neu = S.KnopfVerschieben(gewaehlt, -1)
        if neu then
            gewaehlt = neu
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    hoch:SetPoint("TOPLEFT", hinzu, "BOTTOMLEFT", 0, -4)

    local runter = knopf(B, L.CFG_DOWN, 76, function()
        local neu = S.KnopfVerschieben(gewaehlt, 1)
        if neu then
            gewaehlt = neu
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    runter:SetPoint("LEFT", hoch, "RIGHT", 4, 0)

    -- ---------------------------------------------------------------------
    -- Das Formular
    -- ---------------------------------------------------------------------
    local X = 264
    local y = -4

    -- Eine Beschriftung mit Erklaerung darueber. FontStrings nehmen keine
    -- Maus-Ereignisse an - deshalb liegt ein unsichtbarer Rahmen darauf, der
    -- den Tooltip traegt. Das "(?)" dahinter ist der Hinweis, dass es
    -- ueberhaupt etwas zu lesen gibt; ohne ihn findet den Tooltip niemand.
    local function reihe(text, tipp, hoehe)
        local fs = beschriftung(B, text)
        fs:SetPoint("TOPLEFT", X, y)

        if tipp then
            fs:SetText(text .. " |cff7b90a5(?)|r")

            local fang = CreateFrame("Frame", nil, B)
            fang:SetPoint("TOPLEFT", fs, "TOPLEFT", 0, 2)
            fang:SetSize(fs:GetStringWidth() + 4, 16)
            fang:EnableMouse(true)
            fang:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(text, 1, 1, 1)
                GameTooltip:AddLine(tipp, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            fang:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        y = y - 18
        local merk = y
        y = y - (hoehe or 26)
        return merk
    end

    local yBeschriftung = reihe(L.CFG_LABEL, L.CFG_LABEL_TIP)
    felder.beschriftung = eingabe(B, 330)
    felder.beschriftung:SetPoint("TOPLEFT", X, yBeschriftung)
    felder.beschriftung:SetScript("OnEditFocusLost", function(self)
        aendern("beschriftung", self:GetText())
    end)

    local yText = reihe(L.CFG_MESSAGE, L.CFG_MESSAGE_TIP)
    felder.text = eingabe(B, 330)
    felder.text:SetPoint("TOPLEFT", X, yText)
    felder.text:SetScript("OnEditFocusLost", function(self)
        aendern("text", self:GetText())
    end)

    local yKanal = reihe(L.CFG_CHANNEL, L.CH_AUTO_DESC)
    felder.kanal = auswahl(B, 180, kanalEintraege(),
        function() local k = aktuell() return k and k.kanal or "AUTO" end,
        function(wert) aendern("kanal", wert) end)
    felder.kanal:SetPoint("TOPLEFT", X, yKanal)

    local ySymbol = reihe(L.CFG_ICON, L.CFG_ICON_TIP)
    felder.symbol = eingabe(B, 330)
    felder.symbol:SetPoint("TOPLEFT", X, ySymbol)
    felder.symbol:SetScript("OnEditFocusLost", function(self)
        aendern("symbol", self:GetText())
    end)

    local yMarke = reihe(L.CFG_MARKER, L.CFG_MARKER_TIP)
    felder.marke = auswahl(B, 180, markeEintraege(),
        function() local k = aktuell() return k and k.marke or 0 end,
        function(wert) aendern("marke", wert) end)
    felder.marke:SetPoint("TOPLEFT", X, yMarke)

    local yPing = reihe(L.CFG_PING, L.CFG_PING_TIP)
    felder.ping = auswahl(B, 180, pingEintraege(),
        function() local k = aktuell() return k and k.ping or false end,
        function(wert) aendern("ping", wert or nil) end)
    felder.ping:SetPoint("TOPLEFT", X, yPing)

    -- Der Platzhalter-Spickzettel. Er steht unten und klein: Man braucht ihn
    -- beim ersten Mal und danach nie wieder.
    local hinweis = beschriftung(B, L.CFG_PLACEHOLDERS, "GameFontDisableSmall")
    hinweis:SetPoint("TOPLEFT", X, y - 6)
    hinweis:SetWidth(330)
    hinweis:SetJustifyH("LEFT")

    -- =====================================================================
    -- Bereich "Leiste"
    -- =====================================================================
    local Y = CreateFrame("Frame", nil, fenster)
    Y:SetPoint("TOPLEFT", 0, -84)
    Y:SetPoint("BOTTOMRIGHT", 0, 0)
    Y:Hide()
    fenster.bereichLayout = Y

    local zy = -8

    local function setzeZahlenfeld(feld)
        feld:SetPoint("TOPLEFT", 16, zy)
        zy = zy - 28
    end

    schalter.ausrichtung = auswahl(Y, 180, {
        { wert = "horizontal", text = L.CFG_HORIZONTAL },
        { wert = "vertikal",   text = L.CFG_VERTICAL },
    }, function() return S.Dock().ausrichtung end,
       function(wert) S.Dock().ausrichtung = wert TCD.Dock.Aufbauen() end)
    local ausTitel = beschriftung(Y, L.CFG_LAYOUT_DIR)
    ausTitel:SetPoint("TOPLEFT", 16, zy)
    ausTitel:SetWidth(120)
    ausTitel:SetJustifyH("LEFT")
    schalter.ausrichtung:SetPoint("TOPLEFT", 140, zy + 4)
    zy = zy - 30

    schalter.groesse = zahlenfeld(Y, L.CFG_SIZE, 16, 96, 2,
        function() return S.Dock().groesse end,
        function(w) S.Dock().groesse = w end)
    setzeZahlenfeld(schalter.groesse)

    schalter.abstand = zahlenfeld(Y, L.CFG_PADDING, 0, 32, 1,
        function() return S.Dock().abstand end,
        function(w) S.Dock().abstand = w end)
    setzeZahlenfeld(schalter.abstand)

    schalter.deckkraft = zahlenfeld(Y, L.CFG_OPACITY, 0, 1, 0.05,
        function() return S.Dock().deckkraft end,
        function(w) S.Dock().deckkraft = w end)
    setzeZahlenfeld(schalter.deckkraft)

    schalter.umbruch = zahlenfeld(Y, L.CFG_WRAP, 0, 24, 1,
        function() return S.Dock().umbruch end,
        function(w) S.Dock().umbruch = w end)
    setzeZahlenfeld(schalter.umbruch)

    schalter.skalierung = zahlenfeld(Y, L.CFG_SCALE, 0.5, 2.0, 0.05,
        function() return S.Dock().skalierung end,
        function(w) S.Dock().skalierung = w end)
    setzeZahlenfeld(schalter.skalierung)

    schalter.drosselung = zahlenfeld(Y, L.CFG_THROTTLE, 0, 10, 0.5,
        function() return S.db.drosselung end,
        function(w) S.db.drosselung = w end)
    setzeZahlenfeld(schalter.drosselung)

    zy = zy - 6

    schalter.beschriftungen = kasten(Y, L.CFG_SHOW_LABELS, function(an)
        S.Dock().beschriftungen = an
        TCD.Dock.Aufbauen()
    end)
    schalter.beschriftungen:SetPoint("TOPLEFT", 16, zy)
    zy = zy - 26

    schalter.gesperrt = kasten(Y, L.CFG_LOCKED, function(an)
        S.Dock().gesperrt = an
    end)
    schalter.gesperrt:SetPoint("TOPLEFT", 16, zy)
    zy = zy - 26

    schalter.nurGruppe = kasten(Y, L.CFG_HIDE_SOLO, function(an)
        S.Dock().nurGruppe = an
        TCD.Dock.SichtbarkeitPruefen()
    end)
    schalter.nurGruppe:SetPoint("TOPLEFT", 16, zy)
    zy = zy - 34

    -- Der Weg zurueck zu den mitgelieferten Ansagen. Bewusst hier unten und
    -- nicht neben "Loeschen": Ein Fehlgriff kostet die eigenen Texte.
    local zurueck = knopf(Y, L.CFG_DEFAULTS, 260, function()
        if S.ProfilZuruecksetzen() then
            gewaehlt, versatz = 1, 0
            TCD.Dock.Aufbauen()
            E:Auffrischen()
            TCD.Sagen(format(L.MSG_RESET_PROFILE, S.AktivesProfil()))
        end
    end)
    zurueck:SetPoint("TOPLEFT", 16, zy)

    -- ---------------------------------------------------------------------
    -- Die beiden Erklaerungen rechts neben den Feldern
    -- ---------------------------------------------------------------------
    -- Sie haengen am jeweiligen Feld, NICHT an einem festen Y-Wert. Vorher
    -- stand der Umbruch-Hinweis neben "Deckkraft" - er war stehen geblieben,
    -- als ein Feld darueber dazukam, und erklaerte damit die falsche Zeile.
    -- Ein Hinweis am falschen Ort ist schlimmer als keiner.
    local umbruchHinweis = beschriftung(Y, L.CFG_WRAP_TIP, "GameFontDisableSmall")
    umbruchHinweis:SetPoint("TOPLEFT", schalter.umbruch, "TOPRIGHT", 30, -4)
    umbruchHinweis:SetWidth(330)
    umbruchHinweis:SetJustifyH("LEFT")

    -- Die Wiederholsperre braucht ihre Erklaerung sichtbar, nicht im Tooltip:
    -- Eine Sperre, die man nicht versteht, stellt man auf 0.
    local drossHinweis = beschriftung(Y, L.CFG_THROTTLE_TIP, "GameFontDisableSmall")
    drossHinweis:SetPoint("TOPLEFT", schalter.drosselung, "TOPRIGHT", 30, -4)
    drossHinweis:SetWidth(330)
    drossHinweis:SetJustifyH("LEFT")

    reiterZeigen("BUTTONS")
end

-- ===========================================================================
-- Oeffnen, Auffrischen, Schliessen
-- ===========================================================================

function E:Auffrischen()
    if not fenster or not fenster:IsShown() then return end

    local name = S.AktivesProfil()
    local anzeige = TCD.Vorgaben.ROLLENNAME[name]
    fenster.profil:SetText(format("%s: |cff33ccff%s|r", L.CFG_PROFILE, anzeige and L[anzeige] or name))

    if reiterAktiv == "BUTTONS" then
        listeAuffrischen()
        formularAuffrischen()
    else
        layoutAuffrischen()
    end
end

-- index: welcher Knopf gleich bearbeitet werden soll (Umschalt-Klick auf der
-- Leiste). Ohne Angabe bleibt die bisherige Auswahl stehen.
function E:Oeffnen(index)
    fensterBauen()

    if index then
        gewaehlt = index
        versatz = math.max(0, index - ZEILEN_SICHTBAR)
        reiterAktiv = "BUTTONS"
        reiterZeigen("BUTTONS")
    end

    fenster:Show()
    E:Auffrischen()
end

function E:Schliessen()
    if fenster then fenster:Hide() end
end

function E:Umschalten()
    if fenster and fenster:IsShown() then
        E:Schliessen()
    else
        E:Oeffnen()
    end
end
