-- UI/Minimap.lua - der Knopf an der Minikarte
--
-- ===========================================================================
-- WARUM VON HAND UND NICHT MIT LibDBIcon
-- ---------------------------------------------------------------------------
-- LibDBIcon ist gut und weit verbreitet - aber sie bringt LibStub,
-- CallbackHandler und LibDataBroker mit. Das sind drei Bibliotheken und rund
-- 900 Zeilen fremder Quelltext fuer EINEN runden Knopf.
--
-- Fuer ein Addon, das ausdruecklich schlank sein soll, ist das der falsche
-- Handel. Was hier steht, sind 130 Zeilen, die genau eines koennen: einen
-- Knopf am Rand der Minikarte halten, den man im Kreis ziehen kann.
--
-- Der Preis: Wer eine Broker-Leiste wie Titan Panel oder ChocolateBar
-- benutzt, findet dieses Addon dort nicht. Dafuer gibt es  /tcd  - und wer
-- den Knopf gar nicht will, blendet ihn mit  /tcd minimap  aus.
-- ===========================================================================
local addonName, TCD = ...

TCD.Minimap = {}
local M = TCD.Minimap
local L = TCD.L

local knopf

-- Der Abstand vom Mittelpunkt der Minikarte. 80 ist der Wert, den auch
-- LibDBIcon benutzt - damit sitzt der Knopf auf derselben Kreisbahn wie die
-- Knoepfe anderer Addons und reiht sich sauber ein.
local RADIUS = 80

-- ---------------------------------------------------------------------------
-- Den Knopf auf seinen Winkel setzen
-- ---------------------------------------------------------------------------
local function positionieren()
    if not knopf then return end

    local winkel = math.rad(TCD.Speicher.db.minimap.winkel)
    knopf:SetPoint(
        "CENTER", Minimap, "CENTER",
        math.cos(winkel) * RADIUS,
        math.sin(winkel) * RADIUS
    )
end

-- ---------------------------------------------------------------------------
-- Ziehen
-- ---------------------------------------------------------------------------
-- Waehrend die Maus gedrueckt ist, wird der Winkel aus der Cursorposition
-- gegenueber dem Mittelpunkt der Minikarte gerechnet. Der Cursor liefert
-- Bildschirmkoordinaten, die Karte ihre eigene Skalierung - deshalb wird
-- durch UIParent:GetEffectiveScale() geteilt, sonst wandert der Knopf bei
-- einer skalierten Oberflaeche neben den Zeiger.
local function beimZiehen()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local skala = UIParent:GetEffectiveScale()

    cx, cy = cx / skala, cy / skala

    local winkel = math.deg(math.atan2(cy - my, cx - mx))
    if winkel < 0 then winkel = winkel + 360 end

    TCD.Speicher.db.minimap.winkel = winkel
    positionieren()
end

-- ---------------------------------------------------------------------------
-- Erzeugen
-- ---------------------------------------------------------------------------
function M.Erzeugen()
    if knopf then return knopf end

    knopf = CreateFrame("Button", "TacticalCalloutDockMinimapButton", Minimap)
    knopf:SetSize(31, 31)
    knopf:SetFrameStrata("MEDIUM")
    knopf:SetFrameLevel(8)
    knopf:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    knopf:RegisterForDrag("LeftButton")
    knopf:SetMovable(true)

    -- Das Symbol. Kleiner als der Knopf und rund zugeschnitten, damit es
    -- unter den Ring passt.
    local symbol = knopf:CreateTexture(nil, "BACKGROUND")
    symbol:SetSize(20, 20)
    symbol:SetPoint("CENTER", -1, 1)
    symbol:SetTexture("Interface\\Icons\\Ability_Warrior_RallyingCry")
    symbol:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    knopf.symbol = symbol

    -- Der Ring drumherum. Genau die Textur, die auch Blizzards eigene
    -- Minikarten-Knoepfe benutzen - so faellt er nicht aus der Reihe.
    local ring = knopf:CreateTexture(nil, "OVERLAY")
    ring:SetSize(53, 53)
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetPoint("TOPLEFT")

    knopf:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    knopf:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", beimZiehen)
    end)
    knopf:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    knopf:SetScript("OnClick", function(_, taste)
        if taste == "RightButton" then
            TCD.Editor:Umschalten()
        else
            local an = TCD.Dock.Umschalten()
            TCD.Sagen(an and L.MSG_DOCK_SHOWN or L.MSG_DOCK_HIDDEN)
        end
    end)

    knopf:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L.ADDON_NAME, 1, 1, 1)

        -- Welches Profil gerade aktiv ist, ist die Angabe, die man von aussen
        -- am haeufigsten braucht: Ob die Leiste die Tank- oder die
        -- Heilerknoepfe zeigt, sieht man den Symbolen nicht sofort an.
        local name = TCD.Speicher.AktivesProfil()
        local anzeige = TCD.Vorgaben.ROLLENNAME[name]
        GameTooltip:AddLine(format("%s: %s", L.CFG_PROFILE, anzeige and L[anzeige] or name), 0.4, 0.75, 1)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.TIP_MINIMAP, 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L.TIP_MINIMAP2, 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    knopf:SetScript("OnLeave", function() GameTooltip:Hide() end)

    positionieren()
    return knopf
end

-- ---------------------------------------------------------------------------
-- Ein- und ausblenden
-- ---------------------------------------------------------------------------
function M.SichtbarkeitPruefen()
    if not knopf then return end
    knopf:SetShown(not TCD.Speicher.db.minimap.versteckt)
end

function M.Umschalten()
    local m = TCD.Speicher.db.minimap
    m.versteckt = not m.versteckt
    M.SichtbarkeitPruefen()
    return not m.versteckt
end
