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
-- Bis Fassung 1.0 hat dieses Fenster die drei oberen benutzt und nur die
-- unteren selbst gebaut. Das war ein Kompromiss - und man hat ihn gesehen:
-- Blizzards Knopf bringt gelbe Schrift auf rotbraunem Metall mit, das
-- Eingabefeld einen goldenen Rahmen, der Kontrollkasten einen dritten Stil.
-- Auf einer dunkelblauen Flaeche standen damit drei fremde Handschriften
-- nebeneinander, jede in ihrer eigenen Aufloesung skaliert.
--
-- Seit 1.1.0 baut dieses Fenster ALLE seine Bausteine selbst, auf der Palette
-- und der Pixelrechnung aus UI\Stil.lua. Der Gewinn ist doppelt: ein
-- einheitliches Bild, und Raender, die auf einen echten Bildschirmpunkt
-- fallen statt ueber zwei zu verschmieren (die lange Begruendung steht im
-- Kopf von UI\Stil.lua).
--
-- Der Preis sind rund 200 Zeilen Bausteine. Dafuer gibt es keinen Tag mehr,
-- an dem eine Vorlage verschwindet und der Editor beim Oeffnen einen Fehler
-- wirft - und keinen, an dem Blizzard seine Knopffarbe aendert.
-- ===========================================================================
local addonName, TCD = ...

TCD.Editor = {}
local E = TCD.Editor
local L = TCD.L
local S = TCD.Speicher
local St = TCD.Stil
local F = St.FARBE
local M = St.MASS

local fenster           -- der Hauptrahmen
local gewaehlt = 1      -- welcher Knopf gerade bearbeitet wird
local versatz  = 0      -- erste sichtbare Zeile der Liste
local felder   = {}     -- die Eingabefelder des Formulars
local zeilen   = {}     -- die Zeilen der Knopfliste
local schalter = {}     -- die Bedienelemente des Leisten-Reiters
local reiterAktiv = "BUTTONS"

local ZEILEN_SICHTBAR = 11
local ZEILEN_HOEHE    = M.zeile
local LISTE_BREITE    = 236
local FORM_X          = 276
local FORM_BREITE     = 356

-- ===========================================================================
-- BAUSTEINE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Eine Beschriftung
-- ---------------------------------------------------------------------------
local function beschriftung(eltern, text, schriftObjekt)
    return St.Text(eltern, text, schriftObjekt or St.Klein)
end

-- ---------------------------------------------------------------------------
-- Ein Knopf
-- ---------------------------------------------------------------------------
-- Drei Zustaende, alle ueber die Palette: ruhend, unter der Maus, gedrueckt.
-- "art" waehlt den Ton - "warnung" ist fuer den einen Knopf gedacht, der
-- eigene Texte kostet (Vorgaben wiederherstellen).
--
-- Der Text sitzt in einem Font-OBJEKT und nicht ueber SetTextColor: So bleibt
-- er weiss, egal was der Rahmen darunter gerade tut.
local function knopf(eltern, text, breite, beiKlick, art)
    local b = CreateFrame("Button", nil, eltern)
    b:SetSize(breite, M.knopf)

    local grund = art == "warnung" and F.akzentTief or F.flaeche
    local hell  = art == "warnung" and F.warnung or F.linieHell

    St.Karte(b, { grund = grund, rand = F.linieHell, randAlpha = 0.5 })

    b.text = St.Text(b, text, St.Klein)
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetJustifyH("CENTER")

    b.grundfarbe = grund
    b.hellfarbe  = hell

    b:SetScript("OnEnter", function(self)
        if not self:IsEnabled() then return end
        St.Faerben(self, self.hellfarbe, F.akzent, 0.85, 0.9)
    end)
    b:SetScript("OnLeave", function(self)
        St.Faerben(self, self.grundfarbe, F.linieHell, 1, 0.5)
    end)
    b:SetScript("OnMouseDown", function(self)
        if not self:IsEnabled() then return end
        self.text:SetPoint("CENTER", 0, -1)
    end)
    b:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("CENTER", 0, 0)
    end)
    b:SetScript("OnClick", beiKlick)

    return b
end

-- ---------------------------------------------------------------------------
-- Ein einzeiliges Eingabefeld
-- ---------------------------------------------------------------------------
-- Der Rand wechselt bei Fokus auf den Akzent. Das ist die einzige Rueckmeldung
-- darueber, wo die Tastatur gerade hingeht - ohne sie tippt man in das
-- falsche Feld und merkt es erst am Ergebnis.
local function eingabe(eltern, breite, hoehe)
    local box = CreateFrame("EditBox", nil, eltern)
    box:SetSize(breite, hoehe or M.feld)
    box:SetAutoFocus(false)
    box:SetFontObject(St.Normal)
    box:SetTextInsets(7, 7, 0, 0)

    St.Karte(box, { grund = F.feld, rand = F.linie })

    box:SetScript("OnEditFocusGained", function(self)
        St.Faerben(self, F.feldHell, F.akzent)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        St.Faerben(self, F.feld, F.linie)
    end)

    -- Escape gibt den Fokus frei, statt das Fenster zu schliessen. Wer
    -- mitten in einem Text steckt, will nicht bei jedem Vertipper von vorn
    -- anfangen.
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    return box
end

-- Damit ein Feld sowohl den Fokusrand zuruecksetzt als auch die Aenderung
-- uebernimmt: OnEditFocusLost gibt es nur einmal je Rahmen.
local function beiFokusVerlust(box, was)
    box:SetScript("OnEditFocusLost", function(self)
        St.Faerben(self, F.feld, F.linie)
        was(self)
    end)
end

-- ---------------------------------------------------------------------------
-- Ein Kontrollkasten
-- ---------------------------------------------------------------------------
-- Selbst gebaut, weil UICheckButtonTemplate seinen eigenen Metallrahmen
-- mitbringt. Gefuellt heisst hier wirklich gefuellt: ein Kasten in der
-- Akzentfarbe mit weissem Haken - das erkennt man auch aus dem Augenwinkel,
-- waehrend Blizzards duennes Haekchen auf dunklem Grund verschwindet.
local function kasten(eltern, text, beiAenderung)
    local k = CreateFrame("Button", nil, eltern)
    k:SetSize(18, 18)

    St.Karte(k, { grund = F.feld, rand = F.linieHell, randAlpha = 0.7 })

    k.haken = St.Scharf(k:CreateTexture(nil, "ARTWORK"))
    k.haken:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    k.haken:SetPoint("TOPLEFT", -3, 3)
    k.haken:SetPoint("BOTTOMRIGHT", 3, -3)
    k.haken:SetVertexColor(1, 1, 1)
    k.haken:Hide()

    -- Der Text traegt den Klick mit: Ein 18 Punkte grosses Kaestchen ist ein
    -- kleines Ziel, die Beschriftung daneben ein grosses.
    k.text = St.Text(k, text, St.Klein)
    k.text:SetPoint("LEFT", k, "RIGHT", M.eng, 0)
    k.text:SetWidth(300)

    local fang = CreateFrame("Button", nil, eltern)
    fang:SetPoint("TOPLEFT", k, "TOPLEFT", 0, 0)
    fang:SetPoint("BOTTOMRIGHT", k.text, "BOTTOMRIGHT", 0, 0)

    k.wert = false

    function k:SetChecked(an)
        self.wert = an and true or false
        self.haken:SetShown(self.wert)
        St.Faerben(self, self.wert and F.akzentTief or F.feld,
                         self.wert and F.akzent or F.linieHell,
                         1, self.wert and 1 or 0.7)
    end

    function k:GetChecked() return self.wert end

    local function umschalten()
        k:SetChecked(not k.wert)
        beiAenderung(k.wert)
    end

    k:SetScript("OnClick", umschalten)
    fang:SetScript("OnClick", umschalten)

    fang:SetScript("OnEnter", function()
        if not k.wert then St.Faerben(k, F.feldHell, F.akzent, 1, 0.8) end
    end)
    fang:SetScript("OnLeave", function()
        if not k.wert then St.Faerben(k, F.feld, F.linieHell, 1, 0.7) end
    end)

    return k
end

-- ---------------------------------------------------------------------------
-- Ein Zahlenfeld mit zwei Schrittknoepfen
-- ---------------------------------------------------------------------------
-- Ersetzt den Schieberegler. Zwei Vorteile ausser der Patchfestigkeit: Man
-- kann einen Wert genau eintippen statt ihn zu treffen, und man sieht ihn
-- immer als Zahl - bei einem Regler muss man dafuer den Griff anfassen.
--
-- Das Mausrad geht ebenfalls: ueber dem Feld drehen aendert den Wert. Das ist
-- die schnellste Art, Knopfgroesse oder Deckkraft zu suchen, weil man dabei
-- auf die Leiste sehen kann statt auf das Feld.
local function zahlenfeld(eltern, text, min, max, schritt, holen, setzen)
    local halter = CreateFrame("Frame", nil, eltern)
    halter:SetSize(232, M.feld)

    local titel = beschriftung(halter, text, St.Leise)
    titel:SetPoint("LEFT", 0, 0)
    titel:SetWidth(130)
    titel:SetJustifyH("LEFT")

    local box = eingabe(halter, 52, 22)
    box:SetPoint("LEFT", halter, "LEFT", 134, 0)
    box:SetNumeric(false)   -- Kommazahlen (Deckkraft, Skalierung) sollen gehen
    box:SetJustifyH("CENTER")
    box:SetTextInsets(2, 2, 0, 0)
    box:SetFontObject(St.Wert)

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
    beiFokusVerlust(box, function(self) uebernehmen(tonumber(self:GetText())) end)

    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(_, richtung)
        uebernehmen(holen() + richtung * schritt)
    end)

    local runter = knopf(halter, "-", 22, function() uebernehmen(holen() - schritt) end)
    runter:SetPoint("LEFT", box, "RIGHT", M.winzig, 0)
    runter:SetHeight(22)

    local hoch = knopf(halter, "+", 22, function() uebernehmen(holen() + schritt) end)
    hoch:SetPoint("LEFT", runter, "RIGHT", 2, 0)
    hoch:SetHeight(22)

    halter.Auffrischen = anzeigen
    return halter
end

-- ===========================================================================
-- Eine eigene Auswahlliste
-- ===========================================================================
-- Ersatz fuer UIDropDownMenu. Der Knopf zeigt den aktuellen Wert; ein Klick
-- klappt die Liste darunter auf.
--
-- ---------------------------------------------------------------------------
-- WARUM DIE AUFGEKLAPPTE LISTE 1.1.0 NEU GEBAUT WURDE
-- ---------------------------------------------------------------------------
-- In 1.0 war sie im Spiel schlecht zu lesen, und die Ursache war NICHT die
-- Farbe - der Grund stand schon auf 0.98 Deckkraft. Es waren zwei andere
-- Dinge, die sich zu demselben Eindruck addiert haben:
--
--   1. Die Liste lag in derselben Ebene (DIALOG) wie das Fenster. Innerhalb
--      einer Ebene entscheidet der Rahmen-LEVEL, und den bekam sie vom
--      Formular vererbt - also einen NIEDRIGEREN als die Eingabefelder, ueber
--      die sie sich legt. WoW hat die Felder folglich UEBER die Liste
--      gezeichnet. Was wie ein durchsichtiger Hintergrund aussah, waren in
--      Wahrheit fremde Widgets, die durch sie hindurchstachen.
--
--   2. Das Backdrop darunter war halbdurchsichtig, und der Editor selbst ist
--      es auch. Zwei mal "fast undurchsichtig" uebereinander lassen den
--      Spielhintergrund immer noch durch.
--
-- Beides ist jetzt anders: eine eigene, HOEHERE Ebene (FULLSCREEN_DIALOG) mit
-- SetToplevel, ein voellig undurchsichtiger Grund, ein Schlagschatten, damit
-- man sieht, dass die Liste DAVOR liegt, und Zeilen, die hoch genug sind, um
-- die Zielmarkierungs-Symbole in voller Groesse zu zeigen.
--
-- eintraege: Liste von { wert = ..., text = "..." }
local AUSWAHL_ZEILE   = 24
local AUSWAHL_SICHTBAR = 12

-- Es darf immer nur EINE Liste offen sein. Ohne diese Merkstelle bleibt beim
-- Wechsel von "Kanal" zu "Markierung" die erste stehen und verdeckt die zweite.
local offeneListe

local function alleZuklappen()
    if offeneListe then
        offeneListe:Hide()
        offeneListe = nil
    end
end

local function auswahl(eltern, breite, eintraege, holen, setzen)
    local halter = CreateFrame("Frame", nil, eltern)
    halter:SetSize(breite, M.feld)

    -- -----------------------------------------------------------------
    -- Das Anzeigefeld
    -- -----------------------------------------------------------------
    -- Sieht aus wie ein Eingabefeld daneben, weil es dasselbe IST: ein Feld,
    -- das einen Wert haelt. Nur der Pfeil sagt, dass man ihn nicht tippt,
    -- sondern waehlt.
    local anzeige = CreateFrame("Button", nil, halter)
    anzeige:SetAllPoints()
    St.Karte(anzeige, { grund = F.feld, rand = F.linie })

    anzeige.text = St.Text(anzeige, nil, St.Normal)
    anzeige.text:SetPoint("LEFT", 7, 0)
    anzeige.text:SetPoint("RIGHT", -24, 0)
    anzeige.text:SetJustifyH("LEFT")
    anzeige.text:SetWordWrap(false)

    -- Der Pfeil ist selbst gezeichnet: drei uebereinanderliegende Striche,
    -- die nach unten schmaler werden. Blizzards Pfeiltexturen sind je nach
    -- Herkunft blau, gold oder grau eingefaerbt und haben alle einen Rahmen
    -- mitgebracht, der auf dieser Flaeche fremd aussah.
    local pfeil = CreateFrame("Frame", nil, anzeige)
    pfeil:SetSize(10, 6)
    pfeil:SetPoint("RIGHT", -8, 0)

    pfeil.striche = {}
    for i = 1, 3 do
        local t = St.Scharf(pfeil:CreateTexture(nil, "OVERLAY"))
        t:SetColorTexture(St.Ent(F.textLeise))
        t:SetPoint("TOP", pfeil, "TOP", 0, -(i - 1) * 2)
        t:SetSize(10 - (i - 1) * 3, 2)
        pfeil.striche[i] = t
    end

    local function pfeilFaerben(farbe)
        for _, t in ipairs(pfeil.striche) do
            t:SetColorTexture(St.Ent(farbe))
        end
    end

    -- -----------------------------------------------------------------
    -- Die aufgeklappte Liste
    -- -----------------------------------------------------------------
    local sichtbar = math.min(#eintraege, AUSWAHL_SICHTBAR)

    local liste = CreateFrame("Frame", nil, halter)
    liste:SetWidth(breite)
    liste:SetHeight(sichtbar * AUSWAHL_ZEILE + 2)

    -- Der ganze Grund, warum die Liste in 1.0 durchsichtig WIRKTE: eine
    -- eigene, hoehere Ebene. Damit ist sie ueber jedem Feld des Formulars,
    -- unabhaengig davon, in welcher Reihenfolge die Rahmen entstanden sind.
    liste:SetFrameStrata("FULLSCREEN_DIALOG")
    liste:SetToplevel(true)
    liste:EnableMouse(true)
    liste:Hide()

    -- Voellig undurchsichtig. Eine Auswahlliste ist kein Fenster, durch das
    -- man etwas sehen soll - sie liegt fuer zwei Sekunden da und geht wieder.
    St.Karte(liste, { grund = F.kopf, grundAlpha = 1, rand = F.linieHell, randAlpha = 1 })
    St.Schatten(liste, 5)

    local listenVersatz = 0

    local function text_zu(wert)
        for _, e in ipairs(eintraege) do
            if e.wert == wert then return e.text end
        end
        return tostring(wert)
    end

    local zeilenRahmen = {}
    local anzeigen

    local function listeAuffrischen()
        local maxVersatz = math.max(0, #eintraege - sichtbar)
        if listenVersatz > maxVersatz then listenVersatz = maxVersatz end
        if listenVersatz < 0 then listenVersatz = 0 end

        local jetzt = holen()

        for i = 1, sichtbar do
            local z = zeilenRahmen[i]
            local e = eintraege[i + listenVersatz]

            if e then
                z.wert = e.wert
                z.text:SetText(e.text)

                -- Der aktive Eintrag wird hervorgehoben. Ohne das muss man
                -- beim Aufklappen erst suchen, was gerade eingestellt ist.
                if e.wert == jetzt then
                    z.grund:SetColorTexture(St.Ent(F.akzent, 0.85))
                    z.text:SetFontObject(St.Normal)
                    z.marke:Show()
                else
                    z.grund:SetColorTexture(0, 0, 0, 0)
                    z.text:SetFontObject(St.Normal)
                    z.marke:Hide()
                end

                z:Show()
            else
                z:Hide()
            end
        end
    end

    for i = 1, sichtbar do
        local z = CreateFrame("Button", nil, liste)
        z:SetSize(breite - 2, AUSWAHL_ZEILE)
        z:SetPoint("TOPLEFT", 1, -((i - 1) * AUSWAHL_ZEILE) - 1)

        z.grund = St.Scharf(z:CreateTexture(nil, "BACKGROUND"))
        z.grund:SetAllPoints()

        z.hell = St.Scharf(z:CreateTexture(nil, "HIGHLIGHT"))
        z.hell:SetAllPoints()
        z.hell:SetColorTexture(1, 1, 1, 0.14)

        -- Ein schmaler Balken links am aktiven Eintrag. Die Flaechenfarbe
        -- allein traegt nicht, wenn die Zeile ein helles Symbol enthaelt.
        z.marke = St.Scharf(z:CreateTexture(nil, "ARTWORK"))
        z.marke:SetPoint("TOPLEFT", 0, 0)
        z.marke:SetPoint("BOTTOMLEFT", 0, 0)
        z.marke:SetWidth(3)
        z.marke:SetColorTexture(St.Ent(F.weiss, 0.9))
        z.marke:Hide()

        z.text = St.Text(z, nil, St.Normal)
        z.text:SetPoint("LEFT", 9, 0)
        z.text:SetPoint("RIGHT", -6, 0)
        z.text:SetJustifyH("LEFT")
        z.text:SetWordWrap(false)

        z:SetScript("OnClick", function(self)
            setzen(self.wert)
            anzeigen()
            alleZuklappen()
        end)

        zeilenRahmen[i] = z
    end

    -- Mausrad, falls ein Client mehr Eintraege meldet als Platz ist. Bei den
    -- neun Zielmarkierungen greift das nie - bei einer Ping-Liste, die
    -- Blizzard eines Tages erweitert, schon.
    if #eintraege > sichtbar then
        liste:EnableMouseWheel(true)
        liste:SetScript("OnMouseWheel", function(_, richtung)
            listenVersatz = listenVersatz - richtung
            listeAuffrischen()
        end)
    end

    anzeigen = function()
        anzeige.text:SetText(text_zu(holen()))
        listeAuffrischen()
    end

    local function zuklappen()
        if offeneListe == liste then offeneListe = nil end
        liste:Hide()
        pfeilFaerben(F.textLeise)
        St.Faerben(anzeige, F.feld, F.linie)
    end

    anzeige:SetScript("OnEnter", function(self)
        St.Faerben(self, F.feldHell, F.linieHell)
        pfeilFaerben(F.text)
    end)
    anzeige:SetScript("OnLeave", function(self)
        if liste:IsShown() then return end
        St.Faerben(self, F.feld, F.linie)
        pfeilFaerben(F.textLeise)
    end)

    -- -----------------------------------------------------------------
    -- Aufklappen - nach unten, wenn Platz ist, sonst nach oben
    -- -----------------------------------------------------------------
    -- Die Markierungsliste hat neun Eintraege. Weiter unten im Formular
    -- reicht der Platz darunter nicht mehr, und die Liste haengt halb unter
    -- dem Bildschirmrand - man waehlt dann blind. Deshalb wird bei jedem
    -- Aufklappen neu entschieden, in welche Richtung sie sich oeffnet.
    --
    -- Die Entscheidung faellt erst beim Klick und nicht beim Bauen: Das
    -- Fenster laesst sich verschieben, und was am unteren Bildschirmrand
    -- keinen Platz hat, hat ihn in der Bildschirmmitte sehr wohl.
    anzeige:SetScript("OnClick", function(self)
        if liste:IsShown() then alleZuklappen() return end

        alleZuklappen()
        listenVersatz = 0
        listeAuffrischen()

        liste:ClearAllPoints()

        local unten = self:GetBottom()
        if unten and (unten - liste:GetHeight() - 3) < 0 then
            liste:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 3)
        else
            liste:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
        end

        liste:Show()
        offeneListe = liste

        St.Faerben(self, F.feldHell, F.akzent)
        pfeilFaerben(F.akzent)
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
        -- sucht man sonst "Kreuz" statt es zu sehen. 16 statt 14 Punkte, weil
        -- die Zeile seit 1.1.0 hoch genug dafuer ist.
        liste[#liste + 1] = {
            wert = i,
            text = format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:16|t %s", i, L["MARK_" .. i]),
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

            local symbol = eintrag.symbol or "Interface\\Icons\\INV_Misc_QuestionMark"
            zeile.symbol:SetTexture(symbol)

            -- Denselben Zuschnitt wie die Leiste. Vorher stand hier ein fest
            -- verdrahtetes 0.08..0.92, das auch die Zielmarkierungen
            -- beschnitten hat - in der Liste sahen sie damit anders aus als
            -- auf dem Knopf, den sie darstellen.
            if TCD.Knopf.BrauchtZuschnitt(symbol) then
                zeile.symbol:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            else
                zeile.symbol:SetTexCoord(0, 1, 0, 1)
            end

            zeile.nummer:SetText(tostring(index))
            zeile.text:SetText(eintrag.beschriftung ~= "" and eintrag.beschriftung or L.CFG_NEW_LABEL)

            if index == gewaehlt then
                zeile.grund:SetColorTexture(St.Ent(F.akzent, 0.30))
                zeile.marke:Show()
                zeile.text:SetFontObject(St.Normal)
            else
                zeile.grund:SetColorTexture(0, 0, 0, 0)
                zeile.marke:Hide()
                zeile.text:SetFontObject(St.Leise)
            end

            zeile:Show()
        else
            zeile:Hide()
        end
    end

    fenster.leerHinweis:SetShown(anzahl == 0)

    -- Der Zaehler ueber der Liste. Bei elf sichtbaren Zeilen und mehr
    -- Knoepfen ist sonst nicht zu sehen, dass da noch etwas kommt.
    fenster.listenZahl:SetText(anzahl > ZEILEN_SICHTBAR
        and format("%d-%d / %d", versatz + 1, math.min(anzahl, versatz + ZEILEN_SICHTBAR), anzahl)
        or tostring(anzahl))
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
        fenster.formTitel:Hide()
        fenster.vorschauKarte:Hide()
        return
    end

    for _, feld in pairs(felder) do feld:Show() end
    fenster.formTitel:Show()
    fenster.vorschauKarte:Show()

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
    alleZuklappen()

    fenster.bereichKnoepfe:SetShown(welcher == "BUTTONS")
    fenster.bereichLayout:SetShown(welcher == "LAYOUT")

    -- Der aktive Reiter traegt einen Akzentstrich UNTER sich, nicht eine
    -- gefuellte Flaeche. Das ist der Unterschied zwischen einem Reiter und
    -- einem Knopf, und man erkennt ihn ohne hinzusehen.
    local function reiterFaerben(reiter, aktiv)
        reiter.strich:SetShown(aktiv)
        reiter.text:SetFontObject(aktiv and St.Kopf or St.Leise)
    end

    reiterFaerben(fenster.reiterKnoepfe, welcher == "BUTTONS")
    reiterFaerben(fenster.reiterLayout, welcher == "LAYOUT")

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

    fenster = CreateFrame("Frame", "TacticalCalloutDockEditor", UIParent)
    fenster:SetSize(680, 524)
    fenster:SetPoint("CENTER")
    fenster:SetFrameStrata("DIALOG")
    fenster:SetMovable(true)
    fenster:EnableMouse(true)
    fenster:SetClampedToScreen(true)

    -- Fast undurchsichtig. Ein Editor ist kein Overlay: Wer hier Texte tippt,
    -- soll den Text sehen und nicht die Wand dahinter. Die verbleibenden vier
    -- Prozent halten nur den Eindruck aufrecht, dass ueber dem Spiel gearbeitet
    -- wird und nicht in einem eigenen Programm.
    St.Karte(fenster, { grund = F.grund, grundAlpha = 0.96, rand = F.linieHell, randAlpha = 0.8 })
    St.Schatten(fenster, 6, 0.08)

    -- Escape schliesst das Fenster. UISpecialFrames verlangt den GLOBALEN
    -- Namen des Rahmens - ein lokaler Verweis reicht nicht.
    tinsert(UISpecialFrames, "TacticalCalloutDockEditor")

    -- Ein Klick irgendwo im Fenster klappt eine offene Auswahlliste zu. Ohne
    -- das bleibt sie stehen, bis man sie noch einmal trifft.
    fenster:SetScript("OnMouseDown", alleZuklappen)

    -- ---------------------------------------------------------------------
    -- Die Kopfzeile
    -- ---------------------------------------------------------------------
    -- Ein eigener Streifen, kein blosser Text auf dem Grund. Er traegt das
    -- Ziehen, den Titel, das aktive Profil und das Schliessen - vier Dinge,
    -- die alle zum Fenster gehoeren und nicht zum Inhalt.
    local kopf = CreateFrame("Frame", nil, fenster)
    kopf:SetPoint("TOPLEFT", 0, 0)
    kopf:SetPoint("TOPRIGHT", 0, 0)
    kopf:SetHeight(M.kopf)
    kopf:EnableMouse(true)
    kopf:RegisterForDrag("LeftButton")
    kopf:SetScript("OnDragStart", function() fenster:StartMoving() end)
    kopf:SetScript("OnDragStop", function() fenster:StopMovingOrSizing() end)
    kopf:SetScript("OnMouseDown", alleZuklappen)

    St.Flaeche(kopf, F.kopf, 1)

    -- Der Akzentbalken links. Das einzige Stueck Farbe im Kopf - es macht aus
    -- einem grauen Streifen eine Kopfzeile, und es kostet drei Zeilen.
    local balken = St.Scharf(kopf:CreateTexture(nil, "ARTWORK"))
    balken:SetPoint("TOPLEFT", 0, 0)
    balken:SetPoint("BOTTOMLEFT", 0, 0)
    balken:SetWidth(3)
    balken:SetColorTexture(St.Ent(F.akzent))

    local kopfLinie = St.Trennlinie(kopf, F.linieHell, 0.6)
    kopfLinie:SetPoint("BOTTOMLEFT", 0, 0)
    kopfLinie:SetPoint("BOTTOMRIGHT", 0, 0)

    local titel = beschriftung(kopf, L.ADDON_NAME, St.Titel)
    titel:SetPoint("LEFT", M.rand, 1)

    local untertitel = beschriftung(kopf, L.CFG_SUBTITLE, St.Aus)
    untertitel:SetPoint("LEFT", titel, "RIGHT", M.eng, 0)

    -- Das aktive Profil. Es steht hier und nicht nur an der Leiste, damit man
    -- beim Bearbeiten sieht, wessen Knoepfe man gerade vor sich hat.
    fenster.profil = beschriftung(kopf, "", St.Klein)
    fenster.profil:SetJustifyH("RIGHT")

    -- Das Schliessen-Kreuz.
    --
    -- UI-StopButton und nicht UIPanelCloseButton: Blizzards Schliessknopf
    -- bringt einen goldenen Ring mit, der auf dieser Flaeche wie ein
    -- Fremdkoerper sass. UI-StopButton ist das nackte Kreuz, das WoW selbst
    -- in seinen Chateinstellungen benutzt - eine Textur, die es seit der
    -- ersten Fassung des Spiels gibt und die sich einfaerben laesst.
    local zu = CreateFrame("Button", nil, kopf)
    zu:SetSize(26, 26)
    zu:SetPoint("RIGHT", -M.eng, 0)

    zu.kreuz = St.Scharf(zu:CreateTexture(nil, "OVERLAY"))
    zu.kreuz:SetTexture("Interface\\Buttons\\UI-StopButton")
    zu.kreuz:SetPoint("CENTER")
    zu.kreuz:SetSize(12, 12)
    zu.kreuz:SetVertexColor(St.Ent(F.textLeise))

    -- Ein Rahmen, der nur unter der Maus erscheint. Ohne ihn ist die
    -- Trefferflaeche unsichtbar, und man klickt zweimal daneben.
    St.Karte(zu, { grund = F.kopf, grundAlpha = 0, rand = F.linie, randAlpha = 0 })

    zu:SetScript("OnEnter", function(self)
        self.kreuz:SetVertexColor(St.Ent(F.weiss))
        St.Faerben(self, F.warnung, F.warnung, 0.85, 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L.CFG_CLOSE, 1, 1, 1)
        GameTooltip:Show()
    end)
    zu:SetScript("OnLeave", function(self)
        self.kreuz:SetVertexColor(St.Ent(F.textLeise))
        St.Faerben(self, F.kopf, F.linie, 0, 0)
        GameTooltip:Hide()
    end)
    zu:SetScript("OnClick", function() E:Schliessen() end)

    fenster.profil:SetPoint("RIGHT", zu, "LEFT", -M.luft, 0)

    -- ---------------------------------------------------------------------
    -- Die Reiter
    -- ---------------------------------------------------------------------
    local function reiterBauen(text, x, welcher)
        local r = CreateFrame("Button", nil, fenster)
        r:SetSize(104, M.reiter)
        r:SetPoint("TOPLEFT", x, -M.kopf)

        r.text = St.Text(r, text, St.Leise)
        r.text:SetPoint("CENTER")
        r.text:SetJustifyH("CENTER")

        r.hell = St.Scharf(r:CreateTexture(nil, "HIGHLIGHT"))
        r.hell:SetAllPoints()
        r.hell:SetColorTexture(1, 1, 1, 0.05)

        -- Der Akzentstrich des aktiven Reiters. Zwei Punkte hoch, damit er
        -- auch auf einem 4K-Monitor als Strich und nicht als Haar ankommt.
        r.strich = St.Scharf(r:CreateTexture(nil, "ARTWORK"))
        r.strich:SetPoint("BOTTOMLEFT", 0, 0)
        r.strich:SetPoint("BOTTOMRIGHT", 0, 0)
        r.strich:SetColorTexture(St.Ent(F.akzent))
        r.strich:Hide()

        local function strichHoehe() r.strich:SetHeight(St.Pixel(r) * 2) end
        strichHoehe()
        St.NachSkalierung(strichHoehe)

        r:SetScript("OnClick", function() reiterZeigen(welcher) end)
        return r
    end

    fenster.reiterKnoepfe = reiterBauen(L.CFG_TAB_BUTTONS, M.rand, "BUTTONS")
    fenster.reiterLayout  = reiterBauen(L.CFG_TAB_LAYOUT, M.rand + 104, "LAYOUT")

    local reiterLinie = St.Trennlinie(fenster, F.linie, 1)
    reiterLinie:SetPoint("TOPLEFT", 0, -(M.kopf + M.reiter))
    reiterLinie:SetPoint("TOPRIGHT", 0, -(M.kopf + M.reiter))

    local OBEN = -(M.kopf + M.reiter + M.luft)

    -- =====================================================================
    -- Bereich "Knoepfe"
    -- =====================================================================
    local B = CreateFrame("Frame", nil, fenster)
    B:SetPoint("TOPLEFT", 0, OBEN)
    B:SetPoint("BOTTOMRIGHT", 0, 0)
    fenster.bereichKnoepfe = B

    local listenTitel = beschriftung(B, L.CFG_LIST, St.Kopf)
    listenTitel:SetPoint("TOPLEFT", M.rand, 0)

    fenster.listenZahl = beschriftung(B, "", St.Aus)
    fenster.listenZahl:SetPoint("TOPRIGHT", B, "TOPLEFT", M.rand + LISTE_BREITE, 0)
    fenster.listenZahl:SetJustifyH("RIGHT")

    -- Der Listenrahmen. Mausrad statt Scrollrahmen (siehe Kopf der Datei).
    local listenRahmen = CreateFrame("Frame", nil, B)
    listenRahmen:SetPoint("TOPLEFT", M.rand, -(M.luft + M.winzig))
    listenRahmen:SetSize(LISTE_BREITE, ZEILEN_SICHTBAR * ZEILEN_HOEHE + 4)
    St.Karte(listenRahmen, { grund = F.feld, grundAlpha = 0.55, rand = F.linie })

    listenRahmen:EnableMouseWheel(true)
    listenRahmen:SetScript("OnMouseWheel", function(_, richtung)
        versatz = versatz - richtung
        listeAuffrischen()
    end)

    fenster.leerHinweis = beschriftung(listenRahmen, L.CFG_EMPTY, St.Aus)
    fenster.leerHinweis:SetPoint("TOPLEFT", M.eng, -M.eng)
    fenster.leerHinweis:SetWidth(LISTE_BREITE - 2 * M.eng)
    fenster.leerHinweis:SetJustifyH("LEFT")

    for i = 1, ZEILEN_SICHTBAR do
        local zeile = CreateFrame("Button", nil, listenRahmen)
        zeile:SetSize(LISTE_BREITE - 4, ZEILEN_HOEHE)
        zeile:SetPoint("TOPLEFT", 2, -((i - 1) * ZEILEN_HOEHE) - 2)

        zeile.grund = St.Scharf(zeile:CreateTexture(nil, "BACKGROUND"))
        zeile.grund:SetAllPoints()

        zeile.hell = St.Scharf(zeile:CreateTexture(nil, "HIGHLIGHT"))
        zeile.hell:SetAllPoints()
        zeile.hell:SetColorTexture(1, 1, 1, 0.08)

        zeile.marke = St.Scharf(zeile:CreateTexture(nil, "ARTWORK"))
        zeile.marke:SetPoint("TOPLEFT", 0, 0)
        zeile.marke:SetPoint("BOTTOMLEFT", 0, 0)
        zeile.marke:SetWidth(3)
        zeile.marke:SetColorTexture(St.Ent(F.akzent))
        zeile.marke:Hide()

        -- Die laufende Nummer in eigener Spalte statt als "1. " vor dem Text.
        -- So stehen alle Beschriftungen untereinander auf derselben Kante,
        -- und ab dem zehnten Knopf rutscht die Spalte nicht.
        zeile.nummer = St.Text(zeile, nil, St.Aus)
        zeile.nummer:SetPoint("LEFT", M.eng, 0)
        zeile.nummer:SetWidth(16)
        zeile.nummer:SetJustifyH("RIGHT")

        zeile.symbol = St.Scharf(zeile:CreateTexture(nil, "ARTWORK"))
        zeile.symbol:SetSize(18, 18)
        zeile.symbol:SetPoint("LEFT", zeile.nummer, "RIGHT", M.eng, 0)

        zeile.text = St.Text(zeile, nil, St.Leise)
        zeile.text:SetPoint("LEFT", zeile.symbol, "RIGHT", M.eng, 0)
        zeile.text:SetPoint("RIGHT", -M.eng, 0)
        zeile.text:SetJustifyH("LEFT")
        zeile.text:SetWordWrap(false)

        zeile:SetScript("OnClick", function(self)
            gewaehlt = self.index
            alleZuklappen()
            E:Auffrischen()
        end)

        zeilen[i] = zeile
    end

    -- ---------------------------------------------------------------------
    -- Die Knoepfe unter der Liste
    -- ---------------------------------------------------------------------
    -- Zwei Reihen zu zwei Knoepfen. Erst standen alle vier nebeneinander; im
    -- Spiel war "Runter" halb abgeschnitten, und breiter durfte die Reihe
    -- nicht werden, weil sie unter die Liste passen muss. Deutsche
    -- Beschriftungen sind laenger als englische - eine Reihe, die auf
    -- Englisch gerade noch passt, passt auf Deutsch nicht mehr.
    local KNOPF_BREITE = (LISTE_BREITE - M.eng) / 2

    local hinzu = knopf(B, L.CFG_ADD, KNOPF_BREITE, function()
        gewaehlt = S.KnopfHinzufuegen()
        -- Zum neuen Knopf springen, sonst legt man ihn blind am Ende an.
        versatz = math.max(0, gewaehlt - ZEILEN_SICHTBAR)
        TCD.Dock.Aufbauen()
        E:Auffrischen()
    end)
    hinzu:SetPoint("TOPLEFT", listenRahmen, "BOTTOMLEFT", 0, -M.eng)

    local weg = knopf(B, L.CFG_DELETE, KNOPF_BREITE, function()
        if S.KnopfLoeschen(gewaehlt) then
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    weg:SetPoint("LEFT", hinzu, "RIGHT", M.eng, 0)

    local hoch = knopf(B, L.CFG_UP, KNOPF_BREITE, function()
        local neu = S.KnopfVerschieben(gewaehlt, -1)
        if neu then
            gewaehlt = neu
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    hoch:SetPoint("TOPLEFT", hinzu, "BOTTOMLEFT", 0, -M.winzig)

    local runter = knopf(B, L.CFG_DOWN, KNOPF_BREITE, function()
        local neu = S.KnopfVerschieben(gewaehlt, 1)
        if neu then
            gewaehlt = neu
            TCD.Dock.Aufbauen()
            E:Auffrischen()
        end
    end)
    runter:SetPoint("LEFT", hoch, "RIGHT", M.eng, 0)

    -- ---------------------------------------------------------------------
    -- Die senkrechte Trennung zwischen Liste und Formular
    -- ---------------------------------------------------------------------
    local trenner = St.Scharf(B:CreateTexture(nil, "ARTWORK"))
    trenner:SetPoint("TOPLEFT", M.rand + LISTE_BREITE + M.luft + M.eng, 2)
    trenner:SetPoint("BOTTOMLEFT", M.rand + LISTE_BREITE + M.luft + M.eng, M.rand)
    trenner:SetColorTexture(St.Ent(F.linie))

    local function trennerBreite() trenner:SetWidth(St.Pixel(B)) end
    trennerBreite()
    St.NachSkalierung(trennerBreite)

    -- ---------------------------------------------------------------------
    -- Das Formular
    -- ---------------------------------------------------------------------
    fenster.formTitel = beschriftung(B, L.CFG_FORM, St.Kopf)
    fenster.formTitel:SetPoint("TOPLEFT", FORM_X, 0)

    local y = -(M.luft + M.winzig)

    -- Eine Beschriftung mit Erklaerung darueber. FontStrings nehmen keine
    -- Maus-Ereignisse an - deshalb liegt ein unsichtbarer Rahmen darauf, der
    -- den Tooltip traegt. Das "?" dahinter ist der Hinweis, dass es
    -- ueberhaupt etwas zu lesen gibt; ohne ihn findet den Tooltip niemand.
    local function reihe(text, tipp, hoehe)
        local fs = beschriftung(B, text, St.Leise)
        fs:SetPoint("TOPLEFT", FORM_X, y)

        if tipp then
            local marke = beschriftung(B, "?", St.Akzent)
            marke:SetPoint("LEFT", fs, "RIGHT", M.winzig + 1, 0)

            local fang = CreateFrame("Frame", nil, B)
            fang:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 3)
            fang:SetPoint("BOTTOMRIGHT", marke, "BOTTOMRIGHT", 3, -3)
            fang:EnableMouse(true)
            fang:SetScript("OnEnter", function(self)
                marke:SetFontObject(St.Normal)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(text, 1, 1, 1)
                GameTooltip:AddLine(tipp, 0.7, 0.75, 0.8, true)
                GameTooltip:Show()
            end)
            fang:SetScript("OnLeave", function()
                marke:SetFontObject(St.Akzent)
                GameTooltip:Hide()
            end)
        end

        y = y - 17
        local merk = y
        y = y - (hoehe or (M.feld + M.luft))
        return merk
    end

    local yBeschriftung = reihe(L.CFG_LABEL, L.CFG_LABEL_TIP)
    felder.beschriftung = eingabe(B, FORM_BREITE)
    felder.beschriftung:SetPoint("TOPLEFT", FORM_X, yBeschriftung)
    beiFokusVerlust(felder.beschriftung, function(self)
        aendern("beschriftung", self:GetText())
    end)

    local yText = reihe(L.CFG_MESSAGE, L.CFG_MESSAGE_TIP)
    felder.text = eingabe(B, FORM_BREITE)
    felder.text:SetPoint("TOPLEFT", FORM_X, yText)
    beiFokusVerlust(felder.text, function(self)
        aendern("text", self:GetText())
    end)

    local ySymbol = reihe(L.CFG_ICON, L.CFG_ICON_TIP)
    felder.symbol = eingabe(B, FORM_BREITE - 32)
    felder.symbol:SetPoint("TOPLEFT", FORM_X, ySymbol)
    beiFokusVerlust(felder.symbol, function(self)
        aendern("symbol", self:GetText())
    end)

    -- Die Vorschau neben dem Symbolfeld. Ein Pfad, den es nicht gibt, liefert
    -- ein leeres Bild - das sieht man hier sofort, statt es an der Leiste zu
    -- suchen.
    local vorschau = CreateFrame("Frame", nil, B)
    vorschau:SetSize(M.feld, M.feld)
    vorschau:SetPoint("LEFT", felder.symbol, "RIGHT", M.eng, 0)
    St.Karte(vorschau, { grund = F.feld, rand = F.linie })

    fenster.vorschauKarte = vorschau
    fenster.symbolVorschau = St.Scharf(vorschau:CreateTexture(nil, "ARTWORK"))
    fenster.symbolVorschau:SetPoint("TOPLEFT", 2, -2)
    fenster.symbolVorschau:SetPoint("BOTTOMRIGHT", -2, 2)

    local yKanal = reihe(L.CFG_CHANNEL, L.CH_AUTO_DESC)
    felder.kanal = auswahl(B, 200, kanalEintraege(),
        function() local k = aktuell() return k and k.kanal or "AUTO" end,
        function(wert) aendern("kanal", wert) end)
    felder.kanal:SetPoint("TOPLEFT", FORM_X, yKanal)

    local yMarke = reihe(L.CFG_MARKER, L.CFG_MARKER_TIP)
    felder.marke = auswahl(B, 200, markeEintraege(),
        function() local k = aktuell() return k and k.marke or 0 end,
        function(wert) aendern("marke", wert) end)
    felder.marke:SetPoint("TOPLEFT", FORM_X, yMarke)

    local yPing = reihe(L.CFG_PING, L.CFG_PING_TIP)
    felder.ping = auswahl(B, 200, pingEintraege(),
        function() local k = aktuell() return k and k.ping or false end,
        function(wert) aendern("ping", wert or nil) end)
    felder.ping:SetPoint("TOPLEFT", FORM_X, yPing)

    -- Der Platzhalter-Spickzettel. Er steht unten und klein: Man braucht ihn
    -- beim ersten Mal und danach nie wieder.
    local hinweis = beschriftung(B, L.CFG_PLACEHOLDERS, St.Aus)
    hinweis:SetPoint("TOPLEFT", FORM_X, y - M.eng)
    hinweis:SetWidth(FORM_BREITE)
    hinweis:SetJustifyH("LEFT")

    -- =====================================================================
    -- Bereich "Leiste"
    -- =====================================================================
    local Y = CreateFrame("Frame", nil, fenster)
    Y:SetPoint("TOPLEFT", 0, OBEN)
    Y:SetPoint("BOTTOMRIGHT", 0, 0)
    Y:Hide()
    fenster.bereichLayout = Y

    local anordnungTitel = beschriftung(Y, L.CFG_GROUP_LAYOUT, St.Kopf)
    anordnungTitel:SetPoint("TOPLEFT", M.rand, 0)

    local zy = -(M.luft + M.winzig)

    local function setzeZahlenfeld(feld)
        feld:SetPoint("TOPLEFT", M.rand, zy)
        zy = zy - (M.feld + M.eng)
    end

    local ausTitel = beschriftung(Y, L.CFG_LAYOUT_DIR, St.Leise)
    ausTitel:SetPoint("TOPLEFT", M.rand, zy - 5)
    ausTitel:SetWidth(130)
    ausTitel:SetJustifyH("LEFT")

    schalter.ausrichtung = auswahl(Y, 200, {
        { wert = "horizontal", text = L.CFG_HORIZONTAL },
        { wert = "vertikal",   text = L.CFG_VERTICAL },
    }, function() return S.Dock().ausrichtung end,
       function(wert) S.Dock().ausrichtung = wert TCD.Dock.Aufbauen() end)
    schalter.ausrichtung:SetPoint("TOPLEFT", M.rand + 134, zy)
    zy = zy - (M.feld + M.eng)

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

    zy = zy - M.eng

    local verhaltenTitel = beschriftung(Y, L.CFG_GROUP_BEHAVIOUR, St.Kopf)
    verhaltenTitel:SetPoint("TOPLEFT", M.rand, zy)
    zy = zy - (M.luft + M.eng)

    schalter.drosselung = zahlenfeld(Y, L.CFG_THROTTLE, 0, 10, 0.5,
        function() return S.db.drosselung end,
        function(w) S.db.drosselung = w end)
    setzeZahlenfeld(schalter.drosselung)

    zy = zy - M.winzig

    schalter.beschriftungen = kasten(Y, L.CFG_SHOW_LABELS, function(an)
        S.Dock().beschriftungen = an
        TCD.Dock.Aufbauen()
    end)
    schalter.beschriftungen:SetPoint("TOPLEFT", M.rand, zy)
    zy = zy - (M.knopf + M.winzig)

    schalter.gesperrt = kasten(Y, L.CFG_LOCKED, function(an)
        S.Dock().gesperrt = an
    end)
    schalter.gesperrt:SetPoint("TOPLEFT", M.rand, zy)
    zy = zy - (M.knopf + M.winzig)

    schalter.nurGruppe = kasten(Y, L.CFG_HIDE_SOLO, function(an)
        S.Dock().nurGruppe = an
        TCD.Dock.SichtbarkeitPruefen()
    end)
    schalter.nurGruppe:SetPoint("TOPLEFT", M.rand, zy)
    zy = zy - (M.knopf + M.luft)

    -- Der Weg zurueck zu den mitgelieferten Ansagen. Bewusst hier unten und
    -- nicht neben "Loeschen": Ein Fehlgriff kostet die eigenen Texte. Und
    -- bewusst im Warnton - er ist der einzige Knopf im Fenster, der etwas
    -- wegnimmt.
    local zurueck = knopf(Y, L.CFG_DEFAULTS, 268, function()
        if S.ProfilZuruecksetzen() then
            gewaehlt, versatz = 1, 0
            TCD.Dock.Aufbauen()
            E:Auffrischen()
            TCD.Sagen(format(L.MSG_RESET_PROFILE, S.AktivesProfil()))
        end
    end, "warnung")
    zurueck:SetPoint("TOPLEFT", M.rand, zy)

    -- ---------------------------------------------------------------------
    -- Die Erklaerungen in der rechten Spalte
    -- ---------------------------------------------------------------------
    -- Sie haengen am jeweiligen Feld, NICHT an einem festen Y-Wert. Vorher
    -- stand der Umbruch-Hinweis neben "Deckkraft" - er war stehen geblieben,
    -- als ein Feld darueber dazukam, und erklaerte damit die falsche Zeile.
    -- Ein Hinweis am falschen Ort ist schlimmer als keiner.
    local ERKL_X = M.eng

    local umbruchHinweis = beschriftung(Y, L.CFG_WRAP_TIP, St.Aus)
    umbruchHinweis:SetPoint("TOPLEFT", schalter.umbruch, "TOPRIGHT", ERKL_X, -3)
    umbruchHinweis:SetWidth(FORM_BREITE)
    umbruchHinweis:SetJustifyH("LEFT")

    -- Die Wiederholungssperre braucht ihre Erklaerung sichtbar, nicht im
    -- Tooltip: Eine Sperre, die man nicht versteht, stellt man auf 0.
    local drossHinweis = beschriftung(Y, L.CFG_THROTTLE_TIP, St.Aus)
    drossHinweis:SetPoint("TOPLEFT", schalter.drosselung, "TOPRIGHT", ERKL_X, -3)
    drossHinweis:SetWidth(FORM_BREITE)
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
    fenster.profil:SetText(format("%s  |cff3c98e5%s|r", L.CFG_PROFILE, anzeige and L[anzeige] or name))

    if reiterAktiv == "BUTTONS" then
        listeAuffrischen()
        formularAuffrischen()

        local eintrag = aktuell()
        fenster.symbolVorschau:SetShown(eintrag ~= nil)
        if eintrag then
            local symbol = eintrag.symbol or "Interface\\Icons\\INV_Misc_QuestionMark"
            fenster.symbolVorschau:SetTexture(symbol)
            if TCD.Knopf.BrauchtZuschnitt(symbol) then
                fenster.symbolVorschau:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            else
                fenster.symbolVorschau:SetTexCoord(0, 1, 0, 1)
            end
        end
    else
        layoutAuffrischen()
    end
end

-- index: welcher Knopf gleich bearbeitet werden soll (Shift-Klick auf der
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
    alleZuklappen()
    if fenster then fenster:Hide() end
end

function E:Umschalten()
    if fenster and fenster:IsShown() then
        E:Schliessen()
    else
        E:Oeffnen()
    end
end
