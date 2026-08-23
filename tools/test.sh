#!/usr/bin/env bash
#
# tools/test.sh - Syntaxpruefung und Logiktests, ohne WoW zu starten
#
# WoW laeuft auf Lua 5.1. Die meisten Systeme bringen 5.4 mit, und die beiden
# unterscheiden sich genug, dass ein Test unter 5.4 wenig aussagt. Darum holt
# und baut dieses Skript einmalig Lua 5.1 nach .werkzeuge/ - danach laeuft es
# ohne Netz.
#
#   ./tools/test.sh            alles pruefen
#   ./tools/test.sh --syntax   nur Syntax
#
# Rueckgabe: 0 wenn alles bestanden, sonst 1.

set -euo pipefail

ADDON="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WERKZEUGE="$ADDON/.werkzeuge"
LUA_VERSION="5.1.5"
LUA_DIR="$WERKZEUGE/lua-$LUA_VERSION"
LUA="$LUA_DIR/src/lua"
LUAC="$LUA_DIR/src/luac"
TOC="$ADDON/TacticalCalloutDock.toc"

rot()   { printf '\033[31m%s\033[0m\n' "$*"; }
gruen() { printf '\033[32m%s\033[0m\n' "$*"; }
info()  { printf '\033[36m%s\033[0m\n' "$*"; }

# Unsere eigenen Lua-Dateien. Libs/ gehoert uns nicht - dort wird weder
# Syntax geprueft noch die .toc abgeglichen.
unsere_dateien() {
  find "$ADDON" -name '*.lua' \
    -not -path '*/.werkzeuge/*' \
    -not -path '*/Libs/*' \
    -not -path '*/.release/*' | sort
}

# ---------------------------------------------------------------------------
# Lua 5.1 bereitstellen
# ---------------------------------------------------------------------------
if [ ! -x "$LUA" ]; then
  info "Lua $LUA_VERSION wird einmalig gebaut (nach .werkzeuge/) ..."
  mkdir -p "$WERKZEUGE"

  if ! command -v make >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
    rot "Es fehlen make und/oder ein C-Compiler. Unter Ubuntu/Debian:"
    rot "  sudo apt-get install build-essential libreadline-dev"
    exit 1
  fi

  ARCHIV="$WERKZEUGE/lua-$LUA_VERSION.tar.gz"
  if [ ! -f "$ARCHIV" ]; then
    curl -sSL --fail "https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz" -o "$ARCHIV"
  fi

  tar xzf "$ARCHIV" -C "$WERKZEUGE"
  # "posix" statt "linux": braucht kein libreadline und reicht zum Testen.
  make -C "$LUA_DIR" posix >/dev/null 2>&1

  [ -x "$LUA" ] || { rot "Bau von Lua fehlgeschlagen."; exit 1; }
  gruen "Lua $LUA_VERSION steht bereit."
fi

# ---------------------------------------------------------------------------
# 1. Syntax aller eigenen Lua-Dateien
# ---------------------------------------------------------------------------
info ""
info "=== Syntaxpruefung ==="

ANZAHL=0
FEHLER=0
while IFS= read -r datei; do
  ANZAHL=$((ANZAHL + 1))
  if ! "$LUAC" -p "$datei" 2>&1; then
    FEHLER=$((FEHLER + 1))
  fi
done < <(unsere_dateien)

if [ "$FEHLER" -gt 0 ]; then
  rot "$FEHLER von $ANZAHL Dateien haben Syntaxfehler."
  exit 1
fi
gruen "$ANZAHL Lua-Dateien syntaktisch sauber."

if [ "${1:-}" = "--syntax" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Ladeprobe der .toc
# ---------------------------------------------------------------------------
# Findet den Fall, dass eine Datei in der .toc steht, aber nicht existiert
# (oder umgekehrt). WoW meldet so etwas beim Start nur als stummes Nichtladen.
info ""
info "=== Ladeliste der .toc ==="

TOC_FEHLER=0

while IFS= read -r zeile; do
  zeile="${zeile%$'\r'}"
  case "$zeile" in
    ''|'#'*) continue ;;
  esac
  pfad="$ADDON/${zeile//\\//}"
  if [ ! -f "$pfad" ]; then
    # Dieses Addon bringt keine Fremdbibliotheken mit - jede Zeile der
    # Ladeliste muss also wirklich als Datei dastehen.
    rot "  in der .toc gelistet, aber nicht vorhanden: $zeile"
    TOC_FEHLER=$((TOC_FEHLER + 1))
  fi
done < "$TOC"

# Und die Gegenrichtung: Lua-Dateien, die niemand laedt (Tests ausgenommen).
while IFS= read -r datei; do
  rel="${datei#"$ADDON"/}"
  case "$rel" in
    Tests/*) continue ;;
  esac
  winpfad="${rel////\\}"
  if ! grep -qiF "$winpfad" "$TOC"; then
    rot "  vorhanden, aber in der .toc nicht gelistet: $rel"
    TOC_FEHLER=$((TOC_FEHLER + 1))
  fi
done < <(unsere_dateien)

if [ "$TOC_FEHLER" -gt 0 ]; then
  rot "$TOC_FEHLER Unstimmigkeit(en) zwischen .toc und Dateien."
  exit 1
fi
gruen "Ladeliste und Dateien stimmen ueberein."

# ---------------------------------------------------------------------------
# 3. Logiktests
# ---------------------------------------------------------------------------
info ""
info "=== Logiktests ==="

if TCDPFAD="$ADDON" "$LUA" "$ADDON/Tests/logik-test.lua"; then
  gruen ""
  gruen "Alles bestanden."
  exit 0
else
  rot ""
  rot "Es sind Tests fehlgeschlagen."
  exit 1
fi
