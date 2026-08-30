#!/usr/bin/env python3
"""
color_match.py — CIEDE2000-based nearest-theme matcher for Bibata Material cursor themes.
Perceptually uniform color distance in CIELAB space.
"""

import sys
import json
import math
import os
from typing import Dict, Tuple


def hex_to_rgb(hex_color: str) -> Tuple[float, float, float]:
    h = hex_color.lstrip("#").strip()
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) != 6:
        raise ValueError(f"Invalid hex color: {hex_color!r}")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return r / 255.0, g / 255.0, b / 255.0


def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb_to_xyz(r: float, g: float, b: float) -> Tuple[float, float, float]:
    r, g, b = _srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b)
    # sRGB D65 matrix
    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
    return x * 100.0, y * 100.0, z * 100.0


# D65 reference white
_XN, _YN, _ZN = 95.0489, 100.0, 108.8840


def _f(t: float) -> float:
    delta = 6.0 / 29.0
    if t > delta ** 3:
        return t ** (1.0 / 3.0)
    return t / (3 * delta ** 2) + 4.0 / 29.0


def xyz_to_lab(x: float, y: float, z: float) -> Tuple[float, float, float]:
    fx, fy, fz = _f(x / _XN), _f(y / _YN), _f(z / _ZN)
    L = 116 * fy - 16
    a = 500 * (fx - fy)
    b = 200 * (fy - fz)
    return L, a, b


def hex_to_lab(hex_color: str) -> Tuple[float, float, float]:
    return xyz_to_lab(*rgb_to_xyz(*hex_to_rgb(hex_color)))


def ciede2000(lab1: Tuple[float, float, float],
              lab2: Tuple[float, float, float],
              kL: float = 2.5, kC: float = 1.0, kH: float = 1.0) -> float:
    """
    Standard CIEDE2000 Delta-E with adjustable lightness weighting (kL=2.5 to
    prioritize hue and chroma matching over strict lightness differences, matching Material You palettes).
    """
    L1, a1, b1 = lab1
    L2, a2, b2 = lab2

    C1 = math.hypot(a1, b1)
    C2 = math.hypot(a2, b2)
    C_bar = (C1 + C2) / 2.0

    G = 0.5 * (1 - math.sqrt((C_bar ** 7) / (C_bar ** 7 + 25 ** 7)))
    a1p = a1 * (1 + G)
    a2p = a2 * (1 + G)

    C1p = math.hypot(a1p, b1)
    C2p = math.hypot(a2p, b2)

    def hue_angle(ap, b):
        if ap == 0 and b == 0:
            return 0.0
        h = math.degrees(math.atan2(b, ap))
        return h + 360 if h < 0 else h

    h1p = hue_angle(a1p, b1)
    h2p = hue_angle(a2p, b2)

    dLp = L2 - L1
    dCp = C2p - C1p

    if C1p * C2p == 0:
        dhp = 0.0
    else:
        diff = h2p - h1p
        if diff > 180:
            diff -= 360
        elif diff < -180:
            diff += 360
        dhp = diff
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp) / 2.0)

    L_bar = (L1 + L2) / 2.0
    C_barp = (C1p + C2p) / 2.0

    if C1p * C2p == 0:
        h_barp = h1p + h2p
    else:
        s = h1p + h2p
        diff = abs(h1p - h2p)
        if diff <= 180:
            h_barp = s / 2.0
        elif s < 360:
            h_barp = (s + 360) / 2.0
        else:
            h_barp = (s - 360) / 2.0

    T = (1
         - 0.17 * math.cos(math.radians(h_barp - 30))
         + 0.24 * math.cos(math.radians(2 * h_barp))
         + 0.32 * math.cos(math.radians(3 * h_barp + 6))
         - 0.20 * math.cos(math.radians(4 * h_barp - 63)))

    d_theta = 30 * math.exp(-(((h_barp - 275) / 25) ** 2))
    RC = 2 * math.sqrt((C_barp ** 7) / (C_barp ** 7 + 25 ** 7))
    SL = 1 + (0.015 * (L_bar - 50) ** 2) / math.sqrt(20 + (L_bar - 50) ** 2)
    SC = 1 + 0.045 * C_barp
    SH = 1 + 0.015 * C_barp * T
    RT = -math.sin(math.radians(2 * d_theta)) * RC

    dE = math.sqrt(
        (dLp / (kL * SL)) ** 2 +
        (dCp / (kC * SC)) ** 2 +
        (dHp / (kH * SH)) ** 2 +
        RT * (dCp / (kC * SC)) * (dHp / (kH * SH))
    )
    return dE


def find_closest_theme(
    target_hex: str,
    themes: Dict[str, Dict[str, str]],
    primary_weight: float = 0.85,
    body_weight: float = 0.15,
) -> Tuple[str, float]:
    target_lab = hex_to_lab(target_hex)
    total_w = primary_weight + body_weight

    best_name = None
    best_score = math.inf

    for name, cols in themes.items():
        primary_de = ciede2000(target_lab, hex_to_lab(cols["primary"]))
        score = (primary_de * primary_weight) / total_w
        if "body" in cols and body_weight > 0:
            body_de = ciede2000(target_lab, hex_to_lab(cols["body"]))
            score += (body_de * body_weight) / total_w

        if score < best_score:
            best_score = score
            best_name = name

    return best_name or "Lilac", best_score


def main():
    if len(sys.argv) < 2:
        print("Usage: color_match.py <target_hex> [themes.json]", file=sys.stderr)
        sys.exit(1)

    target_hex = sys.argv[1].strip()

    if len(sys.argv) >= 3:
        themes_path = sys.argv[2]
    else:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        themes_path = os.path.join(script_dir, "themes.json")

    if not os.path.exists(themes_path):
        print(f"Error: themes.json not found at {themes_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(themes_path, "r") as f:
            themes = json.load(f)
        best_name, score = find_closest_theme(target_hex, themes)
        # Print theme name to stdout for clean shell capture
        print(best_name)
        print(f"[color_match] matched '{best_name}' (dE2000={score:.3f}) for color {target_hex}", file=sys.stderr)
    except Exception as e:
        print(f"Error matching color: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
