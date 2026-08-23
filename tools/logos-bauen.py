#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Baut die Plattform-Logos fuer CurseForge aus dem Zeichen des Projekts.

Das Zeichen ist dasselbe wie in docs/logo.svg: eine Sprechblase ueber einer
Leiste aus drei Knoepfen, von denen einer gedrueckt ist. Hier wird es mit
Pillow gerendert, weil in dieser Umgebung kein SVG-Rasterer liegt.

Zwei Fassungen:
  klassisch - 1:1 das Zeichen der Projektseite. Gut ab etwa 128 Pixel.
  kompakt   - dickere Formen, groessere Abstaende. Fuer 64 Pixel, wo die
              feinen Teile der klassischen Fassung zulaufen.
  winzig    - nur die Sprechblase, ohne Leiste. Fuer 32 Pixel und darunter.

Aufruf:  python3 tools/logos-bauen.py
Ausgabe: docs/curseforge/
"""

import os
from PIL import Image, ImageDraw

# Supersampling: erst gross zeichnen, dann herunterrechnen. Das ersetzt das
# Kantenglaetten, das Pillow beim Zeichnen selbst nicht kann.
SS = 16
BOX = 64  # Koordinatensystem wie im SVG

DUNKEL = (13, 22, 32, 255)      # #0d1620
HELL = (58, 209, 255, 255)      # #3ad1ff
TIEF = (27, 143, 196, 255)      # #1b8fc4
GRAU = (37, 56, 74, 255)        # #25384a

ZIEL = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "..", "docs", "curseforge")


def s(wert):
    """Rechnet eine Koordinate des 64er-Rasters in Bildpunkte um."""
    return wert * SS


def verlauf(groesse, oben, unten, y0, y1):
    """Senkrechter Farbverlauf, begrenzt auf den Bereich y0..y1."""
    bild = Image.new("RGBA", (groesse, groesse))
    zeichner = ImageDraw.Draw(bild)
    hoehe = max(1, y1 - y0)
    for y in range(groesse):
        t = min(1.0, max(0.0, (y - y0) / hoehe))
        farbe = tuple(int(oben[i] + (unten[i] - oben[i]) * t) for i in range(4))
        zeichner.line([(0, y), (groesse, y)], fill=farbe)
    return bild


def mit_verlauf(ziel, form_zeichnen, y0, y1):
    """Malt eine Form mit Farbverlauf: Form als Maske, Verlauf als Farbe."""
    maske = Image.new("L", ziel.size, 0)
    form_zeichnen(ImageDraw.Draw(maske), 255)
    farbe = verlauf(ziel.size[0], HELL, TIEF, s(y0), s(y1))
    ziel.paste(farbe, (0, 0), maske)


def sprechblase(zeichner, kasten, radius, schwanz, fuellung):
    """Sprechblase = abgerundeter Kasten plus dreieckiger Schwanz."""
    x0, y0, x1, y1 = kasten
    zeichner.rounded_rectangle([s(x0), s(y0), s(x1), s(y1)],
                               radius=s(radius), fill=fuellung)
    zeichner.polygon([(s(p[0]), s(p[1])) for p in schwanz], fill=fuellung)


def zeichne(fassung):
    """Zeichnet eine Fassung in voller Aufloesung und gibt das Bild zurueck."""
    gross = BOX * SS
    bild = Image.new("RGBA", (gross, gross), (0, 0, 0, 0))
    zeichner = ImageDraw.Draw(bild)

    if fassung == "klassisch":
        rand, ecke = 2, 12
        blase = (14, 12, 55, 36)
        blasen_radius = 5
        schwanz = [(32, 34), (20, 42), (20, 34)]
        punkte = [(23, 24), (32, 24), (41, 24)]
        punkt_radius = 3
        knopf_y, knopf_h, knopf_r = 47, 11, 3
        knoepfe = [(12, 12), (26.5, 12), (41, 12)]
        aktiv = 1
    elif fassung == "winzig":
        rand, ecke = 1, 11
        blase = (5, 9, 59, 41)
        blasen_radius = 7
        schwanz = [(34, 39), (18, 54), (18, 39)]
        punkte = [(18, 25), (32, 25), (46, 25)]
        punkt_radius = 5
        knopf_y, knopf_h, knopf_r = 0, 0, 0
        knoepfe = []
        aktiv = -1
    else:  # kompakt
        rand, ecke = 1, 11
        blase = (9, 8, 55, 35)
        blasen_radius = 6
        schwanz = [(30, 33), (16, 44), (16, 33)]
        punkte = [(20, 21.5), (32, 21.5), (44, 21.5)]
        punkt_radius = 4
        knopf_y, knopf_h, knopf_r = 45, 13, 4
        knoepfe = [(9, 13), (25.5, 13), (42, 13)]
        aktiv = 1

    # Grundflaeche
    zeichner.rounded_rectangle([s(rand), s(rand), s(BOX - rand), s(BOX - rand)],
                               radius=s(ecke), fill=DUNKEL)

    # Sprechblase mit Verlauf
    mit_verlauf(bild,
                lambda z, f: sprechblase(z, blase, blasen_radius, schwanz, f),
                blase[1], schwanz[1][1])

    # Die drei Punkte: die Ansage
    for cx, cy in punkte:
        zeichner.ellipse([s(cx - punkt_radius), s(cy - punkt_radius),
                          s(cx + punkt_radius), s(cy + punkt_radius)],
                         fill=DUNKEL)

    # Die Leiste: drei Knoepfe, der mittlere gedrueckt
    for i, (kx, kw) in enumerate(knoepfe):
        zeichner.rounded_rectangle(
            [s(kx), s(knopf_y), s(kx + kw), s(knopf_y + knopf_h)],
            radius=s(knopf_r), fill=(HELL if i == aktiv else GRAU))

    return bild


def speichern(bild, pfad, groesse):
    """Rechnet auf die Zielgroesse herunter und speichert verlustfrei."""
    klein = bild.resize((groesse, groesse), Image.LANCZOS)
    klein.save(pfad, "PNG", optimize=True)
    return os.path.getsize(pfad)


def main():
    os.makedirs(ZIEL, exist_ok=True)
    plan = [
        ("klassisch", [400, 256, 128]),
        ("kompakt", [400, 128, 64]),
        ("winzig", [400, 64, 32]),
    ]
    for fassung, groessen in plan:
        bild = zeichne(fassung)
        for groesse in groessen:
            name = "logo-%s-%d.png" % (fassung, groesse)
            bytes_ = speichern(bild, os.path.join(ZIEL, name), groesse)
            print("%-28s %5d Byte" % (name, bytes_))


if __name__ == "__main__":
    main()
