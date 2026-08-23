#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Baut das Auslieferungs-ZIP - dasselbe, was der Spieler bekommt.

Ersatz fuer den BigWigs-Packager fuer den Fall, dass kein  zip  auf dem
Rechner liegt. Das Ergebnis ist inhaltlich gleich, solange das Addon keine
Packager-Platzhalter (@project-version@ und Verwandte) benutzt - und das tut
es nicht, siehe den Kopf der .toc.

Zwei Regeln bestimmen, was hineinkommt:
  1. Nur versionierte Dateien (git ls-files). Damit bleiben .idea,
     .release und jede unfertige Arbeitsdatei draussen, ohne Extrawurst.
  2. Die  ignore-Liste aus .pkgmeta . Sie ist die eine Wahrheit darueber,
     was nur im Repository Sinn ergibt: Werkzeuge, Tests, CI, Projektseite.

Fuer ein echtes Release ist weiterhin der Tag zustaendig - dann baut der
Packager in der GitHub-Action. Dieses Skript ist zum Nachsehen und zum
Weitergeben von Hand.

Aufruf:  python3 tools/paket-bauen.py
"""

import os
import re
import subprocess
import sys
import zipfile

WURZEL = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TOC = "TacticalCalloutDock.toc"


def lies_pkgmeta():
    """Holt package-as und die ignore-Liste aus .pkgmeta."""
    name, ignoriert, in_ignore = None, [], False
    with open(os.path.join(WURZEL, ".pkgmeta"), encoding="utf-8") as datei:
        for zeile in datei:
            zeile = zeile.rstrip("\n")
            if zeile.startswith("package-as:"):
                name = zeile.split(":", 1)[1].strip()
            elif zeile.startswith("ignore:"):
                in_ignore = True
            elif in_ignore:
                treffer = re.match(r"^\s+-\s+(\S+)", zeile)
                if treffer:
                    ignoriert.append(treffer.group(1).rstrip("/"))
                elif zeile and not zeile.startswith((" ", "#", "\t")):
                    in_ignore = False  # naechster Abschnitt der Datei
    return name, ignoriert


def lies_version():
    with open(os.path.join(WURZEL, TOC), encoding="utf-8") as datei:
        for zeile in datei:
            if zeile.startswith("## Version:"):
                return zeile.split(":", 1)[1].strip()
    return None


def main():
    name, ignoriert = lies_pkgmeta()
    version = lies_version()
    if not name or not version:
        sys.exit("package-as oder Version nicht gefunden.")

    dateien = subprocess.run(["git", "-C", WURZEL, "ls-files"],
                             capture_output=True, text=True,
                             check=True).stdout.splitlines()

    drin, draussen = [], []
    for pfad in dateien:
        teile = pfad.split("/")
        if any(teile[0] == muster or pfad == muster for muster in ignoriert):
            draussen.append(pfad)
        else:
            drin.append(pfad)

    ziel_ordner = os.path.join(WURZEL, ".release")
    os.makedirs(ziel_ordner, exist_ok=True)
    ziel = os.path.join(ziel_ordner, "%s-%s.zip" % (name, version))

    with zipfile.ZipFile(ziel, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as paket:
        for pfad in sorted(drin):
            paket.write(os.path.join(WURZEL, pfad), "%s/%s" % (name, pfad))

    print("Paket:      %s" % os.path.relpath(ziel, WURZEL))
    print("Version:    %s" % version)
    print("Ordner:     %s/  (so heisst er im AddOns-Verzeichnis)" % name)
    print("Enthalten:  %d Dateien" % len(drin))
    print("Groesse:    %.1f KB" % (os.path.getsize(ziel) / 1024.0))
    print()
    print("Draussen geblieben (%d):" % len(draussen))
    for pfad in sorted(draussen):
        print("  %s" % pfad)


if __name__ == "__main__":
    main()
