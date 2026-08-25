-- UI/Knopf.lua - ein einzelner Knopf der Leiste
--
-- ===========================================================================
-- WARUM DIE KNOEPFE WIEDERVERWENDET WERDEN
-- ---------------------------------------------------------------------------
-- Die Leiste wird bei jeder Aenderung neu aufgebaut: anderes Profil, andere
-- Groesse, ein Knopf mehr. Wuerde dabei jedes Mal CreateFrame() laufen,
-- haette man nach einer Stunde Herumprobieren hunderte toter Rahmen im
-- Speicher - Rahmen lassen sich in WoW nicht loeschen, nur verstecken.
--
-- Darum ein Vorrat: K.Holen() liefert einen vorhandenen Rahmen, wenn es
-- einen gibt, und legt nur bei Bedarf einen neuen an. Der Neuaufbau der
-- Leiste besteht dann aus Umbeschriften und Verschieben - beides ist auch im
-- Kampf erlaubt und kostet nichts.
--
-- ---------------------------------------------------------------------------
-- KEINE GESCHUETZTE VORLAGE
-- ---------------------------------------------------------------------------
-- Das hier ist ein ganz normaler Button, kein SecureActionButtonTemplate.
-- Das ist moeglich, weil kein Knopf eine Faehigkeit wirkt: Chatnachricht,
-- Zielmarkierung und Ping sind ungeschuetzt. Und es ist noetig, weil ein
-- geschuetzter Knopf im Kampf weder umbenannt noch verschoben werden darf -
-- die frei anordenbare Leiste waere damit im Kampf eingefroren.
-- ===========================================================================
local addonName, TCD = ...

TCD.Knopf = {}
local K = TCD.Knopf
local L = TCD.L
local St = TCD.Stil
local F = St.FARBE

-- Der Vorrat. Index -> Rahmen. Waechst nur, nie schrumpfen.
local vorrat = {}

-- ---------------------------------------------------------------------------
-- Tooltip
-- ---------------------------------------------------------------------------
-- Zeigt, was der Klick tun WIRD - mit bereits eingesetzten Platzhaltern.
-- Das ist der eigentliche Nutzen: Man sieht vor dem Druecken, welcher Name
-- in der Zeile stehen wird und in welchem Kanal sie landet.
local function tooltipZeigen(rahmen)
    local knopf = rahmen.daten
    if not knopf then return end

    GameTooltip:SetOwner(rahmen, "ANCHOR_RIGHT")

    local titel = knopf.beschriftung
    if titel == nil or titel == "" then titel = L.CFG_NEW_LABEL end
    GameTooltip:AddLine(titel, 1, 1, 1)

    -- Der Nachrichtentext, wie er gleich abgeschickt wuerde.
    if knopf.text and knopf.text ~= "" then
        local vorschau = TCD.Ziele.PlatzhalterFuellen(knopf.text)
        GameTooltip:AddLine(vorschau, 0.85, 0.85, 0.85, true)

        local kanal = TCD.Ziele.KanalBestimmen(knopf.kanal)
        local name = TCD.Ziele.KANALNAME[kanal]
        GameTooltip:AddLine(format(L.TIP_SENDS_TO, name and L[name] or kanal), 0.4, 0.75, 1)
    end

    if knopf.marke and knopf.marke > 0 then
        GameTooltip:AddLine(format(L.TIP_WILL_MARK, L["MARK_" .. knopf.marke]), 0.4, 0.75, 1)
    end

    if knopf.ping then
        GameTooltip:AddLine(format(L.TIP_WILL_PING, L["PING_" .. knopf.ping]), 0.4, 0.75, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TIP_CLICK, 0.5, 0.5, 0.5)
    GameTooltip:AddLine(L.TIP_SHIFT, 0.5, 0.5, 0.5)

    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- Der Klick
-- ---------------------------------------------------------------------------
-- Hier - und nur hier - beginnt eine Ansage. Der Aufruf steht im
-- Hardware-Ereignis; das ist die Bedingung fuer C_Ping und der Grund, warum
-- Logik\Ausloesen.lua keinen einzigen Timer kennt.
local function beiKlick(rahmen, taste)
    local knopf = rahmen.daten
    if not knopf then return end

    -- Shift-Klick oeffnet den Editor bei genau diesem Knopf. Das ist der
    -- kuerzeste Weg von "der Text stimmt nicht mehr" zu "geaendert".
    if IsShiftKeyDown() then
        TCD.Editor:Oeffnen(rahmen.index)
        return
    end

    if taste == "RightButton" then
        TCD.Editor:Oeffnen(rahmen.index)
        return
    end

    local _, hinweise = TCD.Ausloesen.Knopf(knopf)

    for _, h in ipairs(hinweise) do
        TCD.Sagen(format(L[h.schluessel], unpack(h.args)))
    end
end

-- ---------------------------------------------------------------------------
-- Einen Rahmen aus dem Vorrat holen
-- ---------------------------------------------------------------------------
function K.Holen(eltern, index)
    local rahmen = vorrat[index]
    if rahmen then
        rahmen:SetParent(eltern)
        return rahmen
    end

    rahmen = CreateFrame("Button", "TacticalCalloutDockButton" .. index, eltern)
    rahmen:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Das Symbol. Ein Stueck vom Rand eingerueckt, damit der Rahmen darunter
    -- sichtbar bleibt - sonst sieht die Leiste aus wie eine Bilderreihe.
    rahmen.symbol = rahmen:CreateTexture(nil, "ARTWORK")
    rahmen.einzug = 2
    rahmen.symbol:SetPoint("TOPLEFT", 2, -2)
    rahmen.symbol:SetPoint("BOTTOMRIGHT", -2, 2)

    -- -----------------------------------------------------------------
    -- Schaerfe
    -- -----------------------------------------------------------------
    -- WoW rundet Texturkanten normalerweise auf ganze Bildschirmpixel. Bei
    -- einer Knopfgroesse, die nicht zufaellig aufgeht - und das ist bei frei
    -- einstellbarer Groesse und Skalierung der Normalfall - verschiebt diese
    -- Rundung die Kanten um Bruchteile eines Pixels. Das Ergebnis ist ein
    -- weichgezeichnetes Symbol.
    --
    -- Diese beiden Zeilen schalten die Rundung ab. Blizzards Symbole sind
    -- 64x64 Bildpunkte gross; mehr Aufloesung gibt es nicht, auch nicht ueber
    -- einen Atlas. Was man beeinflussen kann, ist allein, wie sauber diese
    -- 64 Punkte auf den Bildschirm kommen - und da liegt der sichtbare
    -- Unterschied. Dasselbe macht BigWigs fuer seine Leisten.
    if rahmen.symbol.SetSnapToPixelGrid then
        rahmen.symbol:SetSnapToPixelGrid(false)
        rahmen.symbol:SetTexelSnappingBias(0)
    end

    -- ---------------------------------------------------------------
    -- Der Rahmen um das Symbol
    -- ---------------------------------------------------------------
    -- Zwei Teile: eine dunkle Flaeche, die unter dem eingerueckten Symbol
    -- hervorschaut, und darauf ein Umriss von genau EINEM Bildschirmpunkt.
    --
    -- Bis 1.0 gab es nur die Flaeche. Der Knopf hatte damit einen 2 Punkte
    -- breiten, weichen dunklen Saum - das ist der Grund, warum eine Reihe
    -- solcher Knoepfe aussieht wie aufgeklebte Bilder und nicht wie eine
    -- Leiste. Ein harter Strich aussen macht daraus ein Element mit Kante.
    rahmen.rand = St.Scharf(rahmen:CreateTexture(nil, "BACKGROUND"))
    rahmen.rand:SetAllPoints()
    rahmen.rand:SetColorTexture(St.Ent(F.grund, 0.85))

    rahmen.umriss = St.Umriss(rahmen, F.linieHell, 0.55)

    local hell = St.Scharf(rahmen:CreateTexture(nil, "HIGHLIGHT"))
    hell:SetAllPoints(rahmen.symbol)
    hell:SetColorTexture(1, 1, 1, 0.22)

    rahmen:SetPushedTextOffset(0, 0)

    -- Unter der Maus wandert der Umriss auf den Akzent. Das ist die Antwort
    -- auf die Frage "ist das ueberhaupt ein Knopf?", und sie kommt, bevor der
    -- Tooltip aufgeht.
    rahmen:SetScript("OnMouseDown", function(self)
        self.symbol:SetPoint("TOPLEFT", self.einzug, -(self.einzug + 1))
        self.symbol:SetPoint("BOTTOMRIGHT", -self.einzug, -self.einzug + 1)
    end)
    rahmen:SetScript("OnMouseUp", function(self)
        self.symbol:SetPoint("TOPLEFT", self.einzug, -self.einzug)
        self.symbol:SetPoint("BOTTOMRIGHT", -self.einzug, self.einzug)
    end)

    -- Die Beschriftung liegt UEBER dem Symbol am unteren Rand, nicht
    -- darunter: So bleibt der Knopf quadratisch und die Leiste behaelt ihre
    -- Hoehe, egal ob Beschriftungen an oder aus sind.
    -- Weiss und in der schmalen Hausschrift, nicht im gelben
    -- GameFontNormalSmall: Die Beschriftung liegt auf einem farbigen Symbol,
    -- und Gelb auf Orange ist im Kampf nicht zu lesen. Die schmale Schrift
    -- bringt bei gleicher Hoehe rund ein Fuenftel mehr Zeichen in dieselbe
    -- Breite - genau das, was deutsche Beschriftungen auf einem 34 Punkte
    -- breiten Knopf brauchen.
    rahmen.text = St.Text(rahmen, nil, St.Klein)
    rahmen.text:SetPoint("BOTTOMLEFT", 1, 2)
    rahmen.text:SetPoint("BOTTOMRIGHT", -1, 2)
    rahmen.text:SetJustifyH("CENTER")
    rahmen.text:SetWordWrap(false)

    -- Ein schmaler dunkler Streifen hinter der Beschriftung. Ohne ihn ist
    -- weisser Text auf einem hellen Symbol nicht zu lesen.
    rahmen.textGrund = St.Scharf(rahmen:CreateTexture(nil, "BORDER"))
    rahmen.textGrund:SetPoint("TOPLEFT", rahmen.text, "TOPLEFT", -1, 1)
    rahmen.textGrund:SetPoint("BOTTOMRIGHT", rahmen.text, "BOTTOMRIGHT", 1, -1)
    rahmen.textGrund:SetColorTexture(0, 0, 0, 0.78)

    rahmen:SetScript("OnClick", beiKlick)

    rahmen:SetScript("OnEnter", function(self)
        self.umriss:Faerben(F.akzent, 0.95)
        tooltipZeigen(self)
    end)
    rahmen:SetScript("OnLeave", function(self)
        self.umriss:Faerben(F.linieHell, 0.55)
        GameTooltip:Hide()
    end)

    vorrat[index] = rahmen
    return rahmen
end

-- ---------------------------------------------------------------------------
-- Braucht dieses Symbol den Randbeschnitt?
-- ---------------------------------------------------------------------------
-- Faehigkeitssymbole unter  Interface\Icons\  haben einen dunklen Rahmen
-- eingebrannt. Den schneidet man weg, sonst wirkt das Bild aufgeklebt.
--
-- Zielmarkierungen haben diesen Rand NICHT. Wer sie trotzdem beschneidet,
-- benutzt von 64 Bildpunkten nur 54 und zieht die wieder auf. Genau das laesst
-- den Totenschaedel grob aussehen - und es faellt kaum auf, weil man den
-- Zuschnitt einmal fuer alle Symbole setzt und nie wieder hinsieht.
--
-- Datei-IDs (Zahlen) gelten als Faehigkeitssymbol: Was Spieler in den Editor
-- eintragen, stammt praktisch immer von wowhead und ist eins.
function K.BrauchtZuschnitt(symbol)
    if type(symbol) == "number" then return true end
    if type(symbol) ~= "string" then return false end
    return symbol:lower():find("interface\\icons\\", 1, true) ~= nil
end

-- ---------------------------------------------------------------------------
-- Die Beschriftung so gross wie moeglich, aber nie breiter als der Knopf
-- ---------------------------------------------------------------------------
-- Ohne das schneidet WoW zu lang geratene Beschriftungen mit "..." ab - im
-- Spiel stand dort "Trin..." statt "Trinken" und "Sch.." statt "Schaedel".
-- Deutsche Woerter sind laenger als englische, und die Knopfgroesse ist frei
-- einstellbar; eine feste Schriftgroesse kann das nicht auffangen.
--
-- Also von oben herunter probieren, bis es passt. Die Grenzen sind seit
-- 1.1.0 11 bis 8 Punkt statt 10 bis 7: Die schmale Hausschrift traegt bei
-- kleinen Groessen weiter als FRIZQT, weil ihre Striche senkrecht stehen und
-- damit auf ganze Punktreihen fallen. Was bei 8 Punkt noch nicht passt, darf
-- abgeschnitten werden - lesbar waere es ohnehin nicht mehr.
local function beschriftungEinpassen(fs, text, breite)
    local pfad, _, flaggen = fs:GetFont()
    fs:SetText(text)

    local groesse = 11
    fs:SetFont(pfad, groesse, flaggen)

    while groesse > 8 and fs:GetStringWidth() > breite do
        groesse = groesse - 1
        fs:SetFont(pfad, groesse, flaggen)
    end
end

-- ---------------------------------------------------------------------------
-- Einen Rahmen mit Daten bestuecken
-- ---------------------------------------------------------------------------
function K.Bestuecken(rahmen, knopf, index, groesse, beschriftungen)
    rahmen.daten = knopf
    rahmen.index = index

    rahmen:SetSize(groesse, groesse)

    -- Der Einzug haelt den Rahmen sichtbar. Bei kleinen Knoepfen kostet er
    -- zu viel Bild: 2 Punkte von 18 sind ein Fuenftel der Kante, und das
    -- Symbol wird unerkennbar. Ab 28 Punkten Breite - dieselbe Schwelle, ab
    -- der auch die Beschriftung erscheint - sind es 2, darunter 1.
    rahmen.einzug = groesse >= 28 and 2 or 1
    rahmen.symbol:SetPoint("TOPLEFT", rahmen.einzug, -rahmen.einzug)
    rahmen.symbol:SetPoint("BOTTOMRIGHT", -rahmen.einzug, rahmen.einzug)

    local symbol = knopf.symbol or "Interface\\Icons\\INV_Misc_QuestionMark"
    rahmen.symbol:SetTexture(symbol)

    if K.BrauchtZuschnitt(symbol) then
        rahmen.symbol:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        rahmen.symbol:SetTexCoord(0, 1, 0, 1)
    end

    -- Unter etwa 28 Pixeln ist eine Beschriftung nicht mehr lesbar, sie
    -- verdeckt dann nur das Symbol. Also wird sie dort ausgeblendet, auch
    -- wenn die Einstellung sie verlangt.
    local zeigen = beschriftungen and groesse >= 28 and knopf.beschriftung ~= ""

    if zeigen then
        -- Zwei Bildpunkte Luft, damit die Kontur nicht am Rand klebt.
        beschriftungEinpassen(rahmen.text, knopf.beschriftung, groesse - 4)
        rahmen.text:Show()
        rahmen.textGrund:Show()
    else
        rahmen.text:Hide()
        rahmen.textGrund:Hide()
    end

    rahmen:Show()
end

-- Alle Rahmen ab einem Index verstecken - fuer den Fall, dass das neue
-- Profil weniger Knoepfe hat als das alte.
function K.RestVerstecken(ab)
    local i = ab
    while vorrat[i] do
        vorrat[i]:Hide()
        vorrat[i].daten = nil
        i = i + 1
    end
end
