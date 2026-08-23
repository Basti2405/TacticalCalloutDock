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

    -- Umschalt-Klick oeffnet den Editor bei genau diesem Knopf. Das ist der
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
    rahmen.symbol:SetPoint("TOPLEFT", 2, -2)
    rahmen.symbol:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Die Ecken der Blizzard-Symbole abschneiden. Ohne das wirkt jedes Icon
    -- wie aufgeklebt; mit dem Zuschnitt sitzt es im Knopf.
    rahmen.symbol:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    rahmen.rand = rahmen:CreateTexture(nil, "BACKGROUND")
    rahmen.rand:SetAllPoints()
    rahmen.rand:SetColorTexture(0, 0, 0, 0.6)

    local hell = rahmen:CreateTexture(nil, "HIGHLIGHT")
    hell:SetAllPoints(rahmen.symbol)
    hell:SetColorTexture(1, 1, 1, 0.25)

    rahmen:SetPushedTextOffset(0, 0)

    -- Die Beschriftung liegt UEBER dem Symbol am unteren Rand, nicht
    -- darunter: So bleibt der Knopf quadratisch und die Leiste behaelt ihre
    -- Hoehe, egal ob Beschriftungen an oder aus sind.
    rahmen.text = rahmen:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rahmen.text:SetPoint("BOTTOMLEFT", 1, 2)
    rahmen.text:SetPoint("BOTTOMRIGHT", -1, 2)
    rahmen.text:SetJustifyH("CENTER")
    rahmen.text:SetWordWrap(false)

    -- Ein schmaler dunkler Streifen hinter der Beschriftung. Ohne ihn ist
    -- weisser Text auf einem hellen Symbol nicht zu lesen.
    rahmen.textGrund = rahmen:CreateTexture(nil, "BORDER")
    rahmen.textGrund:SetPoint("TOPLEFT", rahmen.text, "TOPLEFT", -1, 1)
    rahmen.textGrund:SetPoint("BOTTOMRIGHT", rahmen.text, "BOTTOMRIGHT", 1, -1)
    rahmen.textGrund:SetColorTexture(0, 0, 0, 0.7)

    rahmen:SetScript("OnClick", beiKlick)
    rahmen:SetScript("OnEnter", tooltipZeigen)
    rahmen:SetScript("OnLeave", function() GameTooltip:Hide() end)

    vorrat[index] = rahmen
    return rahmen
end

-- ---------------------------------------------------------------------------
-- Einen Rahmen mit Daten bestuecken
-- ---------------------------------------------------------------------------
function K.Bestuecken(rahmen, knopf, index, groesse, beschriftungen)
    rahmen.daten = knopf
    rahmen.index = index

    rahmen:SetSize(groesse, groesse)
    rahmen.symbol:SetTexture(knopf.symbol or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Unter etwa 28 Pixeln ist eine Beschriftung nicht mehr lesbar, sie
    -- verdeckt dann nur das Symbol. Also wird sie dort ausgeblendet, auch
    -- wenn die Einstellung sie verlangt.
    local zeigen = beschriftungen and groesse >= 28 and knopf.beschriftung ~= ""

    if zeigen then
        rahmen.text:SetText(knopf.beschriftung)
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
