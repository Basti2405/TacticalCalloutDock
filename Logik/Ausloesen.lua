-- Logik/Ausloesen.lua - was bei einem Klick tatsaechlich passiert
--
-- ===========================================================================
-- DREI AKTIONEN, EINE REIHENFOLGE, KEIN AUTOMATISMUS
-- ---------------------------------------------------------------------------
-- Ein Knopf kann dreierlei: markieren, sagen, pingen. Die Reihenfolge ist
-- nicht beliebig:
--
--   1. MARKIEREN zuerst. Die Ansage lautet oft "Fokus Totenschaedel %t" -
--      steht der Schaedel erst nach der Nachricht auf dem Ziel, schaut die
--      Gruppe im falschen Augenblick hin.
--   2. SAGEN. Das ist der Kern; alles andere ist Beiwerk.
--   3. PINGEN zuletzt. Der wackeligste Teil (siehe Logik\Kompat.lua) darf
--      niemals die Ansage verhindern - deshalb ganz am Ende.
--
-- ---------------------------------------------------------------------------
-- ZU DEN ADDON-REGELN
-- ---------------------------------------------------------------------------
-- Dieses Addon automatisiert NICHTS. Es gibt hier
--   * keinen Timer, der etwas sendet,
--   * kein Spielereignis, an dem eine Nachricht haengt,
--   * keine Wiederholung, keine Warteschlange, kein Nachholen im Kampf.
--
-- Aus\Knopf() wird ausschliesslich aus dem OnClick eines Knopfes gerufen,
-- also im Hardware-Ereignis eines echten Mausklicks. Das ist die Bedingung,
-- an die Blizzard C_Ping knuepft, und es ist zugleich der Grund, warum das
-- Addon im Kampf ohne Einschraenkung arbeiten darf: Chatnachricht und
-- Zielmarkierung sind keine geschuetzten Funktionen.
--
-- Was es dafuer NICHT gibt: einen Knopf, der eine Faehigkeit wirkt. Sobald
-- ein Knopf eine Aktion des Charakters ausloesen soll, braucht er eine
-- geschuetzte Vorlage und darf im Kampf nicht mehr umgebaut werden - und die
-- frei anordenbare Leiste waere dahin.
-- ===========================================================================
local addonName, TCD = ...

TCD.Ausloesen = {}
local Aus = TCD.Ausloesen
local A = TCD.API
local Z = TCD.Ziele

-- ---------------------------------------------------------------------------
-- Die Wiederholungssperre
-- ---------------------------------------------------------------------------
-- Schluessel ist die Knopftabelle selbst, nicht ihr Index: Wer im Editor
-- einen Knopf nach oben schiebt, soll damit nicht seine Sperre verlieren.
--
-- Schwache Schluessel, damit ein geloeschter Knopf nicht ewig in dieser
-- Tabelle haengen bleibt.
local letzterKlick = setmetatable({}, { __mode = "k" })

-- ---------------------------------------------------------------------------
-- Hinweise, die nur EINMAL kommen sollen
-- ---------------------------------------------------------------------------
-- "Du darfst nicht markieren" ist beim ersten Mal nuetzlich und beim
-- zwanzigsten Mal nur noch Laerm - erst recht, wenn es waehrend eines Pulls
-- bei jedem Klick im Chat steht.
local schonGemeldet = {}

function Aus.HinweiseVergessen()
    wipe(schonGemeldet)
end

-- ===========================================================================
-- Der Klick
-- ===========================================================================
-- Rueckgabe: ergebnis, hinweise
--   ergebnis  was tatsaechlich geschehen ist (fuer Tests und Tooltip)
--   hinweise  Liste von { schluessel = "MSG_...", args = { ... } }
--
-- Die Trennung ist Absicht: Diese Datei gibt selbst nichts im Chatfenster
-- aus. So laesst sie sich ohne WoW pruefen, und der Aufrufer entscheidet, ob
-- ein Hinweis den Spieler gerade erreichen soll.
function Aus.Knopf(knopf, jetzt)
    local ergebnis = {}
    local hinweise = {}

    local function hinweis(schluessel, ...)
        -- Nur einmal je Sitzung und Art.
        if schonGemeldet[schluessel] then return end
        schonGemeldet[schluessel] = true
        hinweise[#hinweise + 1] = { schluessel = schluessel, args = { ... } }
    end

    if type(knopf) ~= "table" then
        return ergebnis, hinweise
    end

    local db = TCD.Speicher.db
    local sperre = db and db.drosselung or 0
    jetzt = jetzt or A.Ruf("Zeit") or 0

    -- ---------------------------------------------------------------------
    -- Wiederholungssperre
    -- ---------------------------------------------------------------------
    -- Sie greift VOR allem anderen: Auch die Markierung wird nicht neu
    -- gesetzt. Sonst haette man einen Knopf, der zwar nichts mehr sagt, aber
    -- weiter am Ziel herumschraubt.
    if sperre > 0 then
        local zuletzt = letzterKlick[knopf]
        if zuletzt and (jetzt - zuletzt) < sperre then
            ergebnis.gedrosselt = true
            -- Dieser Hinweis darf sich wiederholen: Er ist die Antwort auf
            -- eine Handlung des Spielers, nicht eine Eigenschaft der Lage.
            hinweise[#hinweise + 1] = {
                schluessel = "MSG_THROTTLED",
                args = { sperre },
            }
            return ergebnis, hinweise
        end
        letzterKlick[knopf] = jetzt
    end

    -- ---------------------------------------------------------------------
    -- 1. Markieren
    -- ---------------------------------------------------------------------
    local marke = knopf.marke or 0
    if marke > 0 then
        if not A.Vorhanden("MarkeSetzen") then
            ergebnis.marke = "MISSING"
        elseif not A.Ruf("EinheitDa", "target") then
            ergebnis.marke = "NOTARGET"
            hinweis("MSG_NO_TARGET_MARK")
        elseif not A.DarfMarkieren() then
            ergebnis.marke = "NORIGHT"
            hinweis("MSG_NO_MARK_RIGHT")
        else
            A.Ruf("MarkeSetzen", "target", marke)
            ergebnis.marke = true
        end
    end

    -- ---------------------------------------------------------------------
    -- 2. Die Ansage
    -- ---------------------------------------------------------------------
    local vorlage = knopf.text
    if type(vorlage) == "string" and vorlage ~= "" then
        local text = Z.PlatzhalterFuellen(vorlage)
        local kanal, ersetzt = Z.KanalBestimmen(knopf.kanal)

        ergebnis.kanal = kanal
        ergebnis.text  = text

        if text ~= "" then
            A.Ruf("ChatSenden", text, kanal)
            ergebnis.gesendet = true
        end

        -- Nur melden, wenn die Ansage woanders gelandet ist als gewuenscht -
        -- und auch das nur einmal.
        if ersetzt and kanal == "SAY" then
            hinweis("MSG_NOT_IN_GROUP")
        end
    elseif marke == 0 and not knopf.ping then
        -- Ein Knopf, der nichts tut, ist fast immer ein Versehen im Editor.
        hinweise[#hinweise + 1] = { schluessel = "MSG_EMPTY_MESSAGE", args = {} }
        ergebnis.leer = true
    end

    -- ---------------------------------------------------------------------
    -- 3. Der Ping
    -- ---------------------------------------------------------------------
    if knopf.ping then
        local stand = A.PingAbsetzen(knopf.ping)
        ergebnis.ping = stand

        if stand == "MISSING" then
            hinweis("MSG_PING_MISSING")
        elseif stand == "BLOCKED" then
            hinweis("MSG_PING_BLOCKED")
        end
    end

    return ergebnis, hinweise
end

-- Fuer die Tests: die Sperre gezielt leeren.
function Aus.SperrenVergessen()
    letzterKlick = setmetatable({}, { __mode = "k" })
end
