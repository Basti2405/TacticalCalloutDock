-- Locales/enUS.lua - English base language (and the fallback for every other)
--
-- luacheck: max_line_length 400
--
-- Ein Satz gehoert in EINE Zeile. Umbrueche mit ".." mitten im Text machen das
-- Uebersetzen fehleranfaellig: Man sieht nicht mehr auf einen Blick, was am
-- Ende dasteht, und ein vergessenes Leerzeichen an der Nahtstelle faellt erst
-- im Spiel auf.
-- ===========================================================================
-- WIE DIE SPRACHDATEIEN ARBEITEN
-- ---------------------------------------------------------------------------
-- Diese Datei laedt als ERSTE und legt TCD.L an. Sie muss VOLLSTAENDIG sein:
-- jeder Schluessel, den das Addon irgendwo benutzt, steht hier mit seinem
-- englischen Text. Alle anderen Sprachdateien ueberschreiben danach nur
-- einzelne Schluessel.
--
-- Fehlt ein Schluessel trotzdem, liefert die Metatabelle den Schluesselnamen
-- selbst zurueck - im Spiel steht dann z. B. "CFG_LABEL" auf dem Knopf. Das
-- ist haesslich, aber sichtbar; ein nil waere ein Absturz mitten im Aufbau
-- des Fensters. Tests\logik-test.lua prueft ausserdem, dass keine
-- Sprachdatei Schluessel setzt, die es hier nicht gibt (Tippfehler faengt man
-- so ab).
--
-- BESONDERHEIT DIESES ADDONS: Die Schluessel mit dem Praefix  SAY_  sind
-- keine Oberflaechentexte, sondern die VORGABE-ANSAGEN. Sie gehen in den
-- Gruppenchat. Was hier steht, liest die Gruppe - deshalb kurz, sachlich und
-- ohne Ausrufezeichenketten. Beim ersten Start werden sie einmal in die
-- gespeicherten Einstellungen kopiert; danach gehoeren sie dem Spieler und
-- werden nicht mehr aus der Sprachdatei nachgezogen (sonst wuerde eine
-- Aenderung im Editor beim naechsten Login verschwinden).
--
-- FORMATPLATZHALTER: Die Reihenfolge der %s / %d in einem Text ist in ALLEN
-- Sprachen dieselbe. Lua 5.1 kennt kein "%1$s", man kann sie also nicht
-- umstellen - wer uebersetzt, muss den Satzbau darum herum bauen.
-- ===========================================================================
local addonName, TCD = ...

TCD.L = setmetatable({}, {
    __index = function(_, schluessel) return schluessel end,
})

local L = TCD.L

-- ---------------------------------------------------------------------------
-- Grundlegendes
-- ---------------------------------------------------------------------------
L.ADDON_NAME = "Tactical Callout Dock"

-- ---------------------------------------------------------------------------
-- Meldungen im Chatfenster
-- ---------------------------------------------------------------------------
L.MSG_LOADED           = "loaded. %s for the dock, %s for the editor."
L.MSG_THROTTLED        = "Slow down - that callout went out less than %.1f seconds ago."
L.MSG_NO_MARK_RIGHT    = "You need to be group leader or assistant to place raid markers."
L.MSG_NO_TARGET_MARK   = "No target to mark."
L.MSG_PING_MISSING     = "This client does not offer the ping API - the ping was skipped."
L.MSG_PING_BLOCKED     = "The game refused the ping (pings are disabled or not available here)."
L.MSG_EMPTY_MESSAGE    = "This button has no message text - nothing was sent."
L.MSG_DOCK_LOCKED      = "Dock locked."
L.MSG_DOCK_UNLOCKED    = "Dock unlocked - drag it with the left mouse button."
L.MSG_DOCK_SHOWN       = "Dock shown."
L.MSG_DOCK_HIDDEN      = "Dock hidden."
L.MSG_PROFILE_SWITCHED = "Profile: %s"
L.MSG_PROFILE_UNKNOWN  = "No profile named '%s'. Available: %s"
L.MSG_RESET_DONE       = "Position reset and dock unlocked."
L.MSG_RESET_PROFILE    = "Profile '%s' reset to the built-in callouts."
L.MSG_NOT_IN_GROUP     = "Not in a group - the callout went to /say."

-- ---------------------------------------------------------------------------
-- Slash-Hilfe
-- ---------------------------------------------------------------------------
L.HELP_TITLE   = "Commands:"
L.HELP_TOGGLE  = "show or hide the dock"
L.HELP_CONFIG  = "open the editor"
L.HELP_LOCK    = "lock or unlock the dock for dragging"
L.HELP_ROLE    = "switch profile (tank / healer / dps or a custom name)"
L.HELP_RESET   = "move the dock back to the centre of the screen"
L.HELP_DEFAULTS = "restore the built-in callouts of the current profile"
L.HELP_MINIMAP = "show or hide the minimap button"
L.HELP_DOCTOR  = "self-check - start here when something does not work"
L.HELP_HELP    = "this list"

-- ---------------------------------------------------------------------------
-- Rollen und Profile
-- ---------------------------------------------------------------------------
L.ROLE_TANK    = "Tank"
L.ROLE_HEALER  = "Healer"
L.ROLE_DAMAGER = "Damage"

-- ---------------------------------------------------------------------------
-- Kanaele
-- ---------------------------------------------------------------------------
-- AUTO ist die Vorgabe und der Grund, warum das Addon ueberhaupt eine
-- Kanalwahl hat: dieselbe Taste soll im Schluesselstein in den
-- Instanzchat gehen, im Schlachtzug in den Raidchat und allein
-- stehend niemanden anschreien.
L.CH_AUTO          = "Automatic"
L.CH_AUTO_DESC     = "Instance chat, raid, party or say - whichever fits right now."
L.CH_SAY           = "Say"
L.CH_YELL          = "Yell"
L.CH_PARTY         = "Party"
L.CH_RAID          = "Raid"
L.CH_RAID_WARNING  = "Raid warning"
L.CH_INSTANCE_CHAT = "Instance"
L.CH_EMOTE         = "Emote"

-- ---------------------------------------------------------------------------
-- Zielmarkierungen
-- ---------------------------------------------------------------------------
L.MARK_NONE  = "No marker"
L.MARK_1     = "Star"
L.MARK_2     = "Circle"
L.MARK_3     = "Diamond"
L.MARK_4     = "Triangle"
L.MARK_5     = "Moon"
L.MARK_6     = "Square"
L.MARK_7     = "Cross"
L.MARK_8     = "Skull"

-- ---------------------------------------------------------------------------
-- Pings
-- ---------------------------------------------------------------------------
L.PING_NONE     = "No ping"
L.PING_ATTACK   = "Attack"
L.PING_WARNING  = "Warning"
L.PING_ONMYWAY  = "On my way"
L.PING_ASSIST   = "Assist"

-- ---------------------------------------------------------------------------
-- Der Editor
-- ---------------------------------------------------------------------------
L.CFG_TITLE        = "Tactical Callout Dock - Editor"

-- Steht klein hinter dem Namen in der Kopfzeile des Editors. Es sagt, was
-- dieses Fenster IST - "Editor" allein liest sich wie ein Texteditor.
L.CFG_SUBTITLE     = "Callout editor"

-- Ueberschriften der drei Bereiche. Sie ordnen ein Fenster, in dem sonst
-- zwanzig Felder gleichberechtigt untereinander stehen.
L.CFG_FORM             = "Selected callout"
L.CFG_GROUP_LAYOUT     = "Arrangement"
L.CFG_GROUP_BEHAVIOUR  = "Behaviour"

L.CFG_TAB_BUTTONS  = "Buttons"
L.CFG_TAB_LAYOUT   = "Dock"
L.CFG_PROFILE      = "Profile"
L.CFG_LIST         = "Buttons in this profile"
L.CFG_ADD          = "Add"
L.CFG_DELETE       = "Delete"
L.CFG_UP           = "Up"
L.CFG_DOWN         = "Down"
L.CFG_CLOSE        = "Close"
L.CFG_DEFAULTS     = "Restore built-in callouts"
L.CFG_NEW_LABEL    = "New"
L.CFG_NEW_MESSAGE  = "Type your callout here"
L.CFG_EMPTY        = "No buttons yet. 'Add' creates one."

L.CFG_LABEL        = "Label"
L.CFG_LABEL_TIP    = "Short text under the icon. Two or three characters read best at small sizes."
L.CFG_MESSAGE      = "Chat message"
L.CFG_MESSAGE_TIP  = "What goes into the chat. Leave empty for a button that only marks or pings."
L.CFG_CHANNEL      = "Channel"
L.CFG_ICON         = "Icon"
L.CFG_ICON_TIP     = "A texture path such as Interface\\Icons\\Ability_Kick, or a numeric file ID."
L.CFG_MARKER       = "Raid marker"
L.CFG_MARKER_TIP   = "Placed on your current target. Needs lead or assist inside a group."
L.CFG_PING         = "Ping"
L.CFG_PING_TIP     = "Uses the in-game ping wheel. Only fires on a real mouse click, never on its own."
L.CFG_PLACEHOLDERS = "Placeholders: %t target, %f focus, %m mouseover, %p yourself"

L.CFG_LAYOUT_DIR   = "Direction"
L.CFG_HORIZONTAL   = "Horizontal"
L.CFG_VERTICAL     = "Vertical"
L.CFG_SIZE         = "Button size"
L.CFG_PADDING      = "Spacing"
L.CFG_OPACITY      = "Opacity"
L.CFG_WRAP         = "Buttons per row"
L.CFG_WRAP_TIP     = "0 keeps everything in a single row or column."
L.CFG_SHOW_LABELS  = "Show labels"
L.CFG_LOCKED       = "Lock position"
L.CFG_SCALE        = "Scale"
L.CFG_THROTTLE     = "Repeat protection (seconds)"
L.CFG_THROTTLE_TIP = "Blocks the same button from firing twice in quick succession. Protects you from the server's own chat throttle."
L.CFG_HIDE_SOLO    = "Hide the dock when not in a group"

-- ---------------------------------------------------------------------------
-- Tooltips am Dock
-- ---------------------------------------------------------------------------
L.TIP_CLICK      = "Left click: send"
L.TIP_SHIFT      = "Shift-click: edit this button"
L.TIP_DRAG       = "Drag with the left mouse button to move the dock."
L.TIP_MINIMAP    = "Left click: dock on/off"
L.TIP_MINIMAP2   = "Right click: editor"
L.TIP_SENDS_TO   = "Goes to: %s"
L.TIP_WILL_MARK  = "Marks your target: %s"
L.TIP_WILL_PING  = "Ping: %s"

-- ---------------------------------------------------------------------------
-- Ersatztexte fuer Platzhalter ohne Ziel
-- ---------------------------------------------------------------------------
-- Wichtig, dass hier etwas Lesbares steht: Ein leerer Platzhalter macht aus
-- "Focus %t" die Zeile "Focus " - und die Gruppe raetselt, was gemeint war.
L.SUB_NO_TARGET    = "no target"
L.SUB_NO_FOCUS     = "no focus"
L.SUB_NO_MOUSEOVER = "no mouseover"

-- ---------------------------------------------------------------------------
-- Selbstdiagnose  /tcd doctor
-- ---------------------------------------------------------------------------
L.DOC_TITLE      = "Self-check"
L.DOC_VERSION    = "Version %s, interface %s, client %s"
L.DOC_LOCALE     = "Client language: %s"
L.DOC_SCREEN     = "Screen: %s x %s - one screen pixel is %.3f interface units"
L.DOC_API_OK     = "|cff59d98cok|r   %s  (%s)"
L.DOC_API_FAIL   = "|cffe74c3cMISSING|r  %s"
L.DOC_API_OPT    = "|cfff1c40fabsent|r  %s  (optional - %s)"
L.DOC_PING_NOTE  = "pings are simply skipped"
L.DOC_GROUP      = "Group: %s"
L.DOC_GROUP_NONE = "solo"
L.DOC_GROUP_PARTY = "party"
L.DOC_GROUP_RAID  = "raid"
L.DOC_GROUP_INSTANCE = "instance group"
L.DOC_MARK_RIGHT = "May place markers: %s"
L.DOC_YES        = "yes"
L.DOC_NO         = "no"
L.DOC_PROFILE    = "Active profile: %s (%d buttons)"
L.DOC_CHANNEL    = "A callout on 'Automatic' would go to: %s"
L.DOC_SUMMARY_OK = "Everything the dock needs is there."
L.DOC_SUMMARY_BAD = "%d required function(s) missing - the dock cannot work like this. Please report the lines above."

-- ===========================================================================
-- DIE VORGABE-ANSAGEN
-- ---------------------------------------------------------------------------
-- Das hier liest die Gruppe, nicht der Besitzer des Addons. Deshalb:
--   * kurz genug, um im Kampf ueberflogen zu werden,
--   * sachlich - eine Ansage ist eine Information, kein Vorwurf,
--   * kein "!!!", keine Grossbuchstabenketten. Wer im Schluesselstein
--     angebruellt wird, spielt nicht besser.
--
-- Die LBL_-Schluessel sind die Beschriftung UNTER dem Symbol. Zwei bis fuenf
-- Zeichen - alles Laengere wird bei 32 Pixel Knopfgroesse unleserlich.
-- ===========================================================================

-- Tank ----------------------------------------------------------------------
L.LBL_T_LOS       = "LoS"
L.SAY_T_LOS       = "Pulling around the corner - line of sight, stay behind me"
L.LBL_T_PATROL    = "Pat"
L.SAY_T_PATROL    = "Wait for the patrol"
L.LBL_T_SKIP      = "Skip"
L.SAY_T_SKIP      = "Skipping this pack - shroud now"
L.LBL_T_GATHER    = "Wait"
L.SAY_T_GATHER    = "Still gathering - do not pull yet"
L.LBL_T_BIGPULL   = "Big"
L.SAY_T_BIGPULL   = "Big pull incoming - cooldowns please"
L.LBL_T_SKULL     = "Skull"
L.SAY_T_SKULL     = "Focus skull %t"
L.LBL_T_KITE      = "Kite"
L.SAY_T_KITE      = "Kiting this one - do not taunt"
L.LBL_T_EXTERNAL  = "Help"
L.SAY_T_EXTERNAL  = "I am low - external cooldown please"

-- Heiler --------------------------------------------------------------------
L.LBL_H_MANA      = "Mana"
L.SAY_H_MANA      = "Need mana - short break please"
L.LBL_H_DRINK     = "Drink"
L.SAY_H_DRINK     = "Drinking, give me a moment"
L.LBL_H_DEFS      = "Defs"
L.SAY_H_DEFS      = "Defensives now - heavy damage incoming"
L.LBL_H_DISPEL    = "Disp"
L.SAY_H_DISPEL    = "Dispelling - spread out"
L.LBL_H_REZ       = "Rez"
L.SAY_H_REZ       = "I am down - combat res please"
L.LBL_H_PATROL    = "Pat"
L.SAY_H_PATROL    = "Wait for the patrol"
L.LBL_H_STOP      = "Stop"
L.SAY_H_STOP      = "Do not pull yet"
L.LBL_H_LUST      = "Lust"
L.SAY_H_LUST      = "Bloodlust on this pull"

-- Schaden -------------------------------------------------------------------
L.LBL_D_KICK      = "Kick"
L.SAY_D_KICK      = "Interrupts ready - I kick first"
L.LBL_D_SKULL     = "Skull"
L.SAY_D_SKULL     = "Focus skull %t"
L.LBL_D_CROSS     = "Cross"
L.SAY_D_CROSS     = "Cross is the second target"
L.LBL_D_CC        = "CC"
L.SAY_D_CC        = "Crowd control on moon - do not break it"
L.LBL_D_CDS       = "CDs"
L.SAY_D_CDS       = "My cooldowns are up - go"
L.LBL_D_OMW       = "OMW"
L.SAY_D_OMW       = "On my way"
L.LBL_D_ADDS      = "Adds"
L.SAY_D_ADDS      = "Adds incoming on my side"
L.LBL_D_HOLD      = "Hold"
L.SAY_D_HOLD      = "My cooldowns are down - hold a moment"
