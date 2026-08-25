-- UI/Stil.lua - Farben, Schriften und pixelgenaue Rahmen
--
-- ===========================================================================
-- WAS "HOHE AUFLOESUNG" IN WOW UEBERHAUPT BEDEUTET
-- ---------------------------------------------------------------------------
-- WoW zeichnet die Oberflaeche nicht in Bildschirmpunkten, sondern auf einer
-- gedachten Flaeche von 768 Einheiten Hoehe. Auf einem 1440p-Monitor stehen
-- also 1440 echte Punkte fuer 768 Einheiten bereit. Ein Rand, der im
-- Quelltext "1" breit ist, landet damit auf 1,875 Punkten - und weil es
-- keinen dreiviertel Punkt gibt, verschmiert die Kante ueber zwei Reihen.
--
-- Genau das ist der Grund, warum selbst gebaute Oberflaechen weich und
-- billig aussehen, obwohl der Monitor scharf ist. Es ist keine Frage von
-- Texturen in hoeherer Aufloesung: Blizzards Symbole haben 64x64 Punkte, mehr
-- gibt es nicht. Beeinflussen kann man allein, wie sauber die vorhandenen
-- Punkte auf dem Bildschirm landen.
--
-- Diese Datei rechnet den Weg deshalb zurueck. EIN echter Bildschirmpunkt ist
--
--     768 / physische Bildschirmhoehe / effektive Skalierung des Rahmens
--
-- Einheiten breit. Ein Rand mit dieser Breite trifft genau eine Punktreihe -
-- und sieht aus wie ein Strich, nicht wie ein Schleier. Dieselbe Rechnung
-- benutzen ElvUI und WeakAuras fuer ihre Raender.
--
-- Dazu kommen zwei Dinge, die ohne die Rechnung nichts bringen:
--
--   1. Blizzard rundet Texturkanten auf ganze Punkte. Bei einem Rand, der
--      duenner als ein Punkt gerechnet ist, verschiebt diese Rundung ihn
--      wieder. St.Scharf() schaltet sie ab - denselben Griff macht
--      UI\Knopf.lua schon lange fuer die Symbole.
--
--   2. Aufloesung und Skalierung aendern sich zur LAUFZEIT: Fenstermodus,
--      zweiter Monitor, der Regler in den Spieleinstellungen. Wer die
--      Randbreite einmal beim Bauen rechnet, hat danach wieder weiche
--      Kanten. Darum merkt sich diese Datei jeden Umriss und rechnet ihn bei
--      UI_SCALE_CHANGED und DISPLAY_SIZE_CHANGED neu.
--
-- ---------------------------------------------------------------------------
-- WARUM NICHT BACKDROPTEMPLATE
-- ---------------------------------------------------------------------------
-- SetBackdrop() kann genau das NICHT: sein "edgeSize" geht durch dieselbe
-- Rundung, und die Kante liegt zusaetzlich halb ausserhalb des Rahmens. Vier
-- eigene Texturen sind ein Dutzend Zeilen mehr und dafuer punktgenau. Das
-- Backdrop bleibt nur dort, wo es schon war und nichts kostet.
-- ===========================================================================
local addonName, TCD = ...

TCD.Stil = {}
local St = TCD.Stil

-- Die Grundflaeche, auf die WoW jede Oberflaeche rechnet.
local BASIS = 768

-- ===========================================================================
-- DIE PALETTE
-- ===========================================================================
-- Kuehles Blaugrau in fuenf Stufen, dazu genau EINE Akzentfarbe. Das ist
-- Absicht: Blizzards eigene Fenster sind braun-gold und arbeiten mit
-- Verzierung; wer das nachbaut, verliert. Eine flache, dunkle Flaeche mit
-- einem einzigen kraeftigen Blau wirkt daneben ruhig - und die Symbole der
-- Knoepfe, die ja der eigentliche Inhalt sind, bleiben das Bunteste im Bild.
--
-- Die Werte sind nach Helligkeit sortiert. Wer eine neue Flaeche braucht,
-- nimmt die naechste Stufe und erfindet keine sechste.
St.FARBE = {
    -- Flaechen, von dunkel nach hell
    grund      = { 0.043, 0.051, 0.067 },   -- Fenstergrund
    kopf       = { 0.075, 0.090, 0.118 },   -- Kopfzeile, Reiterleiste
    feld       = { 0.098, 0.118, 0.153 },   -- Eingabefeld, Liste, Karte
    feldHell   = { 0.141, 0.173, 0.224 },   -- dasselbe unter der Maus
    flaeche    = { 0.180, 0.216, 0.275 },   -- Knopf

    -- Linien
    linie      = { 0.180, 0.216, 0.275 },
    linieHell  = { 0.310, 0.380, 0.470 },

    -- Der Akzent. Sparsam: aktiver Reiter, gewaehlte Zeile, Fokus.
    akzent     = { 0.235, 0.596, 0.898 },
    akzentTief = { 0.106, 0.278, 0.435 },

    -- Schrift
    text       = { 0.925, 0.941, 0.961 },
    textLeise  = { 0.588, 0.635, 0.698 },
    textAus    = { 0.400, 0.431, 0.478 },

    -- Der einzige warme Ton im Haus - fuer das, was Daten kostet.
    warnung    = { 0.902, 0.494, 0.333 },

    schwarz    = { 0, 0, 0 },
    weiss      = { 1, 1, 1 },
}

-- Eine Palettenfarbe in ihre vier Zahlen aufloesen.
function St.Ent(farbe, alpha)
    farbe = farbe or St.FARBE.weiss
    return farbe[1], farbe[2], farbe[3], alpha == nil and 1 or alpha
end

-- ===========================================================================
-- DER BILDSCHIRM
-- ===========================================================================
local physHoehe

local function bildschirmHoehe()
    if physHoehe then return physHoehe end

    -- GetPhysicalScreenSize liefert die ECHTE Aufloesung, nicht die
    -- hochgerechnete. Genau darauf kommt es an: bei aktiviertem
    -- Renderskalierung-Regler weichen die beiden voneinander ab.
    if type(GetPhysicalScreenSize) == "function" then
        local _, hoehe = GetPhysicalScreenSize()
        if type(hoehe) == "number" and hoehe > 0 then
            physHoehe = hoehe
            return hoehe
        end
    end

    -- Ein Client, der die Funktion nicht kennt, rechnet ohnehin 1:1.
    physHoehe = BASIS
    return BASIS
end

-- ---------------------------------------------------------------------------
-- Wie breit ist EIN Bildschirmpunkt, in Einheiten dieses Rahmens?
-- ---------------------------------------------------------------------------
-- Ohne Rahmen wird UIParent gefragt. Mit Rahmen ist es genauer: Die Leiste
-- laesst sich skalieren, und in einem auf 0,8 gestellten Rahmen ist ein
-- Bildschirmpunkt eben 1,25 Einheiten breit.
function St.Pixel(rahmen)
    local skala

    if rahmen and rahmen.GetEffectiveScale then
        skala = rahmen:GetEffectiveScale()
    elseif UIParent then
        skala = UIParent:GetEffectiveScale()
    end

    if type(skala) ~= "number" or skala <= 0 then skala = 1 end

    return (BASIS / bildschirmHoehe()) / skala
end

-- ---------------------------------------------------------------------------
-- Die Kantenrundung fuer eine Textur abschalten
-- ---------------------------------------------------------------------------
function St.Scharf(textur)
    if textur and textur.SetSnapToPixelGrid then
        textur:SetSnapToPixelGrid(false)
        textur:SetTexelSnappingBias(0)
    end
    return textur
end

-- ===========================================================================
-- NACHRECHNEN, WENN SICH DER BILDSCHIRM AENDERT
-- ===========================================================================
-- Alles, was von St.Pixel() abhaengt, traegt sich hier ein. Sonst bleibt die
-- Berechnung auf dem Stand des ersten Oeffnens stehen.
local nachrechner = {}

function St.NachSkalierung(fn)
    nachrechner[#nachrechner + 1] = fn
    return fn
end

function St.Nachrechnen()
    physHoehe = nil
    for _, fn in ipairs(nachrechner) do fn() end
end

local wache = CreateFrame("Frame")
wache:RegisterEvent("UI_SCALE_CHANGED")
wache:RegisterEvent("DISPLAY_SIZE_CHANGED")
wache:SetScript("OnEvent", St.Nachrechnen)

-- ===========================================================================
-- BAUSTEINE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Eine gefuellte Flaeche
-- ---------------------------------------------------------------------------
function St.Flaeche(rahmen, farbe, alpha, ebene)
    local t = St.Scharf(rahmen:CreateTexture(nil, ebene or "BACKGROUND"))
    t:SetAllPoints()
    t:SetColorTexture(St.Ent(farbe or St.FARBE.feld, alpha))
    return t
end

-- ---------------------------------------------------------------------------
-- Ein punktgenauer Umriss aus vier Strichen
-- ---------------------------------------------------------------------------
-- staerke ist in BILDSCHIRMPUNKTEN gemeint, nicht in Einheiten: 1 heisst
-- "ein Punkt", auf jedem Monitor.
--
-- Ober- und Unterkante laufen ueber die volle Breite, die Seiten sitzen
-- dazwischen. So gibt es an den Ecken keine doppelte Deckung, die man bei
-- halbdurchsichtigen Raendern als vier dunkle Punkte sieht.
function St.Umriss(rahmen, farbe, alpha, staerke)
    local u = { rahmen = rahmen, staerke = staerke or 1 }

    for _, seite in ipairs({ "oben", "unten", "links", "rechts" }) do
        u[seite] = St.Scharf(rahmen:CreateTexture(nil, "BORDER"))
    end

    function u:Ankern()
        local p = St.Pixel(self.rahmen) * self.staerke

        self.oben:ClearAllPoints()
        self.oben:SetPoint("TOPLEFT")
        self.oben:SetPoint("TOPRIGHT")
        self.oben:SetHeight(p)

        self.unten:ClearAllPoints()
        self.unten:SetPoint("BOTTOMLEFT")
        self.unten:SetPoint("BOTTOMRIGHT")
        self.unten:SetHeight(p)

        self.links:ClearAllPoints()
        self.links:SetPoint("TOPLEFT", 0, -p)
        self.links:SetPoint("BOTTOMLEFT", 0, p)
        self.links:SetWidth(p)

        self.rechts:ClearAllPoints()
        self.rechts:SetPoint("TOPRIGHT", 0, -p)
        self.rechts:SetPoint("BOTTOMRIGHT", 0, p)
        self.rechts:SetWidth(p)
    end

    function u:Faerben(neu, neuAlpha)
        local r, g, b, a = St.Ent(neu or St.FARBE.linie, neuAlpha)
        self.oben:SetColorTexture(r, g, b, a)
        self.unten:SetColorTexture(r, g, b, a)
        self.links:SetColorTexture(r, g, b, a)
        self.rechts:SetColorTexture(r, g, b, a)
    end

    function u:Zeigen(an)
        for _, seite in ipairs({ "oben", "unten", "links", "rechts" }) do
            self[seite]:SetShown(an and true or false)
        end
    end

    u:Faerben(farbe, alpha)
    u:Ankern()
    St.NachSkalierung(function() u:Ankern() end)

    return u
end

-- ---------------------------------------------------------------------------
-- Flaeche und Umriss in einem Griff
-- ---------------------------------------------------------------------------
-- Haengt beides als rahmen.stilFlaeche / rahmen.stilUmriss an, damit ein
-- OnEnter spaeter umfaerben kann, ohne die Rueckgabewerte durchzuschleifen.
function St.Karte(rahmen, opts)
    opts = opts or {}

    rahmen.stilFlaeche = St.Flaeche(rahmen, opts.grund or St.FARBE.feld, opts.grundAlpha)
    rahmen.stilUmriss  = St.Umriss(rahmen, opts.rand or St.FARBE.linie, opts.randAlpha, opts.staerke)

    return rahmen.stilFlaeche, rahmen.stilUmriss
end

-- Die Flaeche eines mit St.Karte gebauten Rahmens umfaerben.
function St.Faerben(rahmen, grund, rand, grundAlpha, randAlpha)
    if rahmen.stilFlaeche and grund then
        rahmen.stilFlaeche:SetColorTexture(St.Ent(grund, grundAlpha))
    end
    if rahmen.stilUmriss and rand then
        rahmen.stilUmriss:Faerben(rand, randAlpha)
    end
end

-- ---------------------------------------------------------------------------
-- Ein Schlagschatten
-- ---------------------------------------------------------------------------
-- Fuer alles, was ueber anderem Inhalt liegt - vor allem die aufklappende
-- Auswahlliste. Ohne Schatten klebt sie flach auf dem Formular und man sieht
-- nicht, dass sie DAVOR liegt.
--
-- Gebaut aus mehreren schwarzen Rechtecken mit kleinem Alpha, jedes ein Stueck
-- groesser als das darunter. Wo sie sich ueberlappen, addiert sich das Alpha -
-- daraus entsteht der weiche Verlauf von selbst, ohne eine Verlaufstextur, die
-- Blizzard eines Tages umbenennt. Die Rechtecke liegen in der Ebene
-- BACKGROUND mit negativer Unterebene, also hinter allem anderen im Rahmen.
function St.Schatten(rahmen, ringe, deckung)
    ringe = ringe or 5

    local s = { rahmen = rahmen, ringe = {} }

    for i = 1, ringe do
        local t = St.Scharf(rahmen:CreateTexture(nil, "BACKGROUND", nil, -i))
        t:SetColorTexture(0, 0, 0, deckung or 0.11)
        s.ringe[i] = t
    end

    function s:Ankern()
        local p = St.Pixel(self.rahmen)
        for i, t in ipairs(self.ringe) do
            local aus = p * i * 2
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", self.rahmen, "TOPLEFT", -aus, aus)
            t:SetPoint("BOTTOMRIGHT", self.rahmen, "BOTTOMRIGHT", aus, -aus)
        end
    end

    s:Ankern()
    St.NachSkalierung(function() s:Ankern() end)

    return s
end

-- ---------------------------------------------------------------------------
-- Eine waagerechte Trennlinie
-- ---------------------------------------------------------------------------
function St.Trennlinie(eltern, farbe, alpha)
    local t = St.Scharf(eltern:CreateTexture(nil, "ARTWORK"))
    t:SetColorTexture(St.Ent(farbe or St.FARBE.linie, alpha))

    local function ankern() t:SetHeight(St.Pixel(eltern)) end
    ankern()
    St.NachSkalierung(ankern)

    return t
end

-- ===========================================================================
-- SCHRIFTEN
-- ===========================================================================
-- Als Schriftobjekte und nicht als SetFont je Beschriftung. Zwei Gruende:
-- Blizzard setzt die Farbe eines Knopftextes bei Hover und Klick selbst
-- zurueck und ueberschreibt dabei jedes SetTextColor - ein Font-OBJEKT
-- gewinnt dagegen. Und eine Farbe, die an dreissig Stellen einzeln steht,
-- ist beim naechsten Mal an achtundzwanzig Stellen geaendert.
--
-- ZUR SCHRIFTWAHL: Ueberschriften laufen in FRIZQT, der Hausschrift des
-- Spiels - das haelt das Fenster im Bild von WoW. Alles Kleine und alle
-- Zahlen laufen in ARIALN. Die ist schmaler (deutsche Beschriftungen passen
-- eher in einen Knopf) und bei 10 bis 12 Punkt sichtbar schaerfer, weil ihre
-- Striche senkrecht stehen und damit auf ganze Punktreihen fallen. FRIZQT
-- verschmiert dort ihre Rundungen.
local FRIZ  = "Fonts\\FRIZQT__.TTF"
local ENG   = "Fonts\\ARIALN.TTF"

local function schrift(name, pfad, groesse, farbe, umriss)
    local f = CreateFont(name)
    f:SetFont(pfad, groesse, umriss or "")
    f:SetTextColor(St.Ent(farbe))

    -- Ein Punkt Schatten. Nicht Zierde: Diese Beschriftungen liegen auch auf
    -- Symbolen und auf der Spielwelt, und dort traegt allein der Schatten den
    -- Kontrast. Der Versatz ist ganzzahlig, damit er nicht selbst verschmiert.
    f:SetShadowColor(0, 0, 0, 0.85)
    f:SetShadowOffset(1, -1)

    return f
end

St.Titel   = schrift("TCDStilTitel",   FRIZ, 15, St.FARBE.text)
St.Kopf    = schrift("TCDStilKopf",    FRIZ, 12, St.FARBE.text)
St.Normal  = schrift("TCDStilNormal",  ENG,  12, St.FARBE.text)
St.Klein   = schrift("TCDStilKlein",   ENG,  11, St.FARBE.text)
St.Leise   = schrift("TCDStilLeise",   ENG,  11, St.FARBE.textLeise)
St.Aus     = schrift("TCDStilAus",     ENG,  11, St.FARBE.textAus)
St.Akzent  = schrift("TCDStilAkzent",  ENG,  11, St.FARBE.akzent)
St.Wert    = schrift("TCDStilWert",    ENG,  12, St.FARBE.text)

-- ---------------------------------------------------------------------------
-- Eine Beschriftung anlegen
-- ---------------------------------------------------------------------------
function St.Text(eltern, text, schriftObjekt, ebene)
    local fs = eltern:CreateFontString(nil, ebene or "OVERLAY")
    fs:SetFontObject(schriftObjekt or St.Klein)
    fs:SetJustifyH("LEFT")
    if text then fs:SetText(text) end
    return fs
end

-- ===========================================================================
-- MASSE
-- ===========================================================================
-- Ein Raster statt gewuerfelter Zahlen. Der Editor hatte vorher Abstaende von
-- 4, 6, 14, 16 und 30 Einheiten - nebeneinander sah das aus, als waere jede
-- Zeile einzeln hingeschoben worden, und genau das war es auch. Alles hier
-- ist ein Vielfaches von 4; wer einen neuen Abstand braucht, nimmt den
-- naechsten aus dieser Liste.
St.MASS = {
    rand    = 16,   -- Fenster zum Inhalt
    luft    = 12,   -- zwischen Gruppen
    eng     = 8,    -- zwischen verwandten Dingen
    winzig  = 4,    -- Beschriftung zu ihrem Feld

    zeile   = 26,   -- Hoehe einer Listenzeile
    feld    = 24,   -- Hoehe eines Eingabefeldes
    knopf   = 24,   -- Hoehe eines Knopfes
    kopf    = 40,   -- Hoehe der Kopfzeile
    reiter  = 28,   -- Hoehe eines Reiters
}
