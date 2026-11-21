"""Genera assets/fonts/DBFlowArrow.ttf: un font con il solo glifo «←» (U+2190).

Roboto, il font di Android, non ha le frecce: Android ripiega su Noto Sans
Symbols, dove «←» è molto piccola, e nei blocchi dell'assegnazione quasi non si
vede. Questo font, usato come ripiego (fontFamilyFallback in lib/render/theme.dart),
dà una freccia della stessa altezza e dello stesso spessore del segno meno di
Roboto. Il disegno è originale (un poligono), quindi nessuna licenza di terzi.
Su iOS e macOS il font di sistema ha già la freccia e questo non viene usato.

    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install fonttools
    /tmp/venv/bin/python tool/fonts/make_arrow_font.py
"""

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM = 2048
ADVANCE = 1900
AXIS = 660  # all'incirca il centro del segno «=» di Roboto (399..975)
STROKE = 150  # spessore del segno meno di Roboto (152)
LEFT, RIGHT = 140, ADVANCE - 140
HEAD_LENGTH = 560
HEAD_HALF = 340


def arrow():
    """Un unico contorno, in senso orario: punta piena e asta."""
    pen = TTGlyphPen(None)
    head = LEFT + HEAD_LENGTH
    half = STROKE // 2
    pen.moveTo((LEFT, AXIS))
    for p in [
        (head, AXIS + HEAD_HALF),
        (head, AXIS + half),
        (RIGHT, AXIS + half),
        (RIGHT, AXIS - half),
        (head, AXIS - half),
        (head, AXIS - HEAD_HALF),
    ]:
        pen.lineTo(p)
    pen.closePath()
    return pen.glyph()


def empty():
    return TTGlyphPen(None).glyph()


fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder([".notdef", "arrowleft"])
fb.setupCharacterMap({0x2190: "arrowleft"})
fb.setupGlyf({".notdef": empty(), "arrowleft": arrow()})
fb.setupHorizontalMetrics({".notdef": (ADVANCE, 0), "arrowleft": (ADVANCE, LEFT)})
fb.setupHorizontalHeader(ascent=1900, descent=-500)
fb.setupNameTable({"familyName": "DBFlowArrow", "styleName": "Regular"})
fb.setupOS2(sTypoAscender=1900, sTypoDescender=-500, usWinAscent=1900, usWinDescent=500)
fb.setupPost()
fb.save("assets/fonts/DBFlowArrow.ttf")
print("assets/fonts/DBFlowArrow.ttf")
