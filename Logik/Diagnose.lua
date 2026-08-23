-- Logik/Diagnose.lua - beantwortet  /tcd doctor
--
-- ===========================================================================
-- WOZU EINE SELBSTDIAGNOSE?
-- ---------------------------------------------------------------------------
-- Weil die haeufigste Fehlermeldung zu einem Addon "geht nicht" lautet - und
-- weil bei DIESEM Addon besonders viele Gruende dafuer in Frage kommen, die
-- gar nichts mit dem Addon zu tun haben:
--
--   * Die Ansage geht raus, aber niemand liest sie, weil sie im falschen
--     Kanal landet (Instanzgruppe vs. Gruppe).
--   * Die Markierung erscheint nicht, weil man in der Zufallsgruppe kein
--     Assistentenrecht hat.
--   * Der Ping bleibt stumm, weil das Ping-Rad in den Spieloptionen aus ist.
--
-- Alle drei sehen fuer den Spieler gleich aus. Diese Datei beantwortet sie in
-- einem Durchgang, damit eine Fehlermeldung mit Inhalt entstehen kann statt
-- eines Ratespiels.
-- ===========================================================================
local addonName, TCD = ...

TCD.Diagnose = {}
local D = TCD.Diagnose
local A = TCD.API

-- Die Zwecke, die im Bericht auftauchen, in sinnvoller Reihenfolge. Nicht
-- alle - nur die, deren Fehlen der Spieler auch merken wuerde.
local ZWECKE = {
    "ChatSenden",
    "MarkeSetzen",
    "PingSenden",
    "PingSystemAn",
    "KampfSperre",
    "EinheitName",
    "InGruppe",
    "InSchlachtzug",
    "IstAnfuehrer",
    "ZugewieseneRolle",
}

-- ---------------------------------------------------------------------------
-- Den Bericht als Liste von Zeilen bauen
-- ---------------------------------------------------------------------------
-- Als Liste und nicht als Ausgabe, damit die Tests den Inhalt pruefen
-- koennen, ohne ein Chatfenster zu brauchen.
function D.Zeilen()
    local L = TCD.L
    local zeilen = {}

    local function zeile(text) zeilen[#zeilen + 1] = text end

    -- ---------------------------------------------------------------------
    -- Kopf: Fassung und Umgebung
    -- ---------------------------------------------------------------------
    local version = A.Ruf("AddonMetadaten", addonName, "Version") or "?"
    local schnittstelle = A.Ruf("AddonMetadaten", addonName, "Interface") or "?"
    local _, _, _, bauNummer = A.Ruf("Bauinfo")

    zeile(L.DOC_TITLE)
    zeile(format(L.DOC_VERSION, tostring(version), tostring(schnittstelle), tostring(bauNummer or "?")))
    zeile(format(L.DOC_LOCALE, tostring(A.Ruf("Sprache") or "?")))
    zeile(" ")

    -- ---------------------------------------------------------------------
    -- Die Schnittstellen
    -- ---------------------------------------------------------------------
    for _, zweck in ipairs(ZWECKE) do
        local quelle = A.quelle[zweck]

        if quelle then
            zeile(format(L.DOC_API_OK, zweck, quelle))
        elseif A.optional[zweck] then
            -- Beim Ping steht dabei, was sein Fehlen bedeutet - das ist die
            -- Frage, die sonst als naechste kaeme.
            local folge = (zweck == "PingSenden" or zweck == "PingSystemAn")
                and L.DOC_PING_NOTE or ""
            zeile(format(L.DOC_API_OPT, zweck, folge))
        else
            zeile(format(L.DOC_API_FAIL, zweck))
        end
    end

    -- Ein Zweck, der da ist, aber beim Aufruf geworfen hat, ist ein anderer
    -- Befund als ein fehlender - und der interessantere.
    for zweck, fehler in pairs(A.fehler) do
        zeile(format("|cffe74c3c%s:|r %s", zweck, tostring(fehler)))
    end

    zeile(" ")

    -- ---------------------------------------------------------------------
    -- Die Lage: Gruppe, Rechte, Kanal
    -- ---------------------------------------------------------------------
    local lage = TCD.Ziele.Gruppenlage()
    local lageText = ({
        SOLO     = L.DOC_GROUP_NONE,
        PARTY    = L.DOC_GROUP_PARTY,
        RAID     = L.DOC_GROUP_RAID,
        INSTANCE = L.DOC_GROUP_INSTANCE,
    })[lage]

    zeile(format(L.DOC_GROUP, lageText))
    zeile(format(L.DOC_MARK_RIGHT, A.DarfMarkieren() and L.DOC_YES or L.DOC_NO))

    -- Die Frage "wo landet meine Ansage gerade?" - beantwortet fuer den Fall
    -- AUTO, den fast alle Knoepfe benutzen.
    local kanal = TCD.Ziele.KanalBestimmen("AUTO")
    zeile(format(L.DOC_CHANNEL, L[TCD.Ziele.KANALNAME[kanal] or kanal]))

    -- ---------------------------------------------------------------------
    -- Das Profil
    -- ---------------------------------------------------------------------
    local S = TCD.Speicher
    if S.db then
        local liste = S.AktiveListe() or {}
        local name = S.AktivesProfil()
        local anzeige = TCD.Vorgaben.ROLLENNAME[name]
        zeile(format(L.DOC_PROFILE, anzeige and L[anzeige] or name, #liste))
    end

    zeile(" ")

    -- ---------------------------------------------------------------------
    -- Fazit
    -- ---------------------------------------------------------------------
    local wichtig = A.FehlendeAnzahl()
    if wichtig == 0 then
        zeile("|cff59d98c" .. L.DOC_SUMMARY_OK .. "|r")
    else
        zeile("|cffe74c3c" .. format(L.DOC_SUMMARY_BAD, wichtig) .. "|r")
    end

    return zeilen
end
