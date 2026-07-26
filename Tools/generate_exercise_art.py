#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "GymPit" / "Assets.xcassets"
EXERCISE_IMAGES = ROOT / "GymPit" / "ExerciseImages"
SIZE = 512

INK = (28, 34, 42, 255)
MACHINE = (154, 166, 176, 255)
MACHINE_DARK = (91, 103, 116, 255)
METAL = (192, 201, 208, 255)
SKIN = (207, 145, 95, 255)
SHOE = (24, 28, 34, 255)
SHORTS = (37, 45, 54, 255)
LEGGINGS = (43, 51, 63, 255)
BAR = (46, 54, 64, 255)
WEIGHT = (40, 46, 54, 255)
MALE_SHIRT = (34, 150, 218, 255)
FEMALE_SHIRT = (35, 184, 170, 255)
ALT_SHIRT = (236, 119, 90, 255)


FEMALE = {
    "pec-deck", "machine-fly", "cable-chest-press", "seated-row", "low-row",
    "rear-delt", "cable-lateral-raise", "front-raise", "arnold-press",
    "leg-extension", "hip-thrust", "adductor", "glute-kickback",
    "standing-calf-raise", "preacher-curl", "cable-curl", "ab-crunch",
    "plank", "hanging-leg-raise", "bike", "cross-trainer",
    "walking-lunge", "dumbbell-bench-press",
}


def asset_name(slug: str) -> str:
    return f"exercise_{slug.replace('-', '_')}"


def rounded_line(draw: ImageDraw.ImageDraw, points, fill, width: int):
    draw.line(points, fill=fill, width=width, joint="curve")
    r = width / 2
    for x, y in points:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def dot(draw: ImageDraw.ImageDraw, xy, r, fill, outline=None, width=1):
    x, y = xy
    draw.ellipse((x - r, y - r, x + r, y + r), fill=fill, outline=outline, width=width)


def rr(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def outline_box(draw, box, radius=18):
    rr(draw, box, radius, (0, 0, 0, 0), MACHINE_DARK, 10)


def bench(draw, x1=118, y=330, x2=385, angle=0):
    if abs(angle) < 1:
        rounded_line(draw, [(x1, y), (x2, y)], MACHINE_DARK, 18)
        rounded_line(draw, [(x1 + 35, y), (x1 + 12, y + 78)], MACHINE_DARK, 12)
        rounded_line(draw, [(x2 - 42, y), (x2 - 12, y + 78)], MACHINE_DARK, 12)
        return
    a = math.radians(angle)
    cx, cy = (x1 + x2) / 2, y
    length = x2 - x1
    dx, dy = math.cos(a) * length / 2, math.sin(a) * length / 2
    rounded_line(draw, [(cx - dx, cy - dy), (cx + dx, cy + dy)], MACHINE_DARK, 18)
    rounded_line(draw, [(cx - dx + 42, cy - dy + 4), (cx - dx + 18, cy - dy + 76)], MACHINE_DARK, 12)


def weight_stack(draw, x=382, y=118, h=220):
    rr(draw, (x, y, x + 62, y + h), 14, MACHINE, INK, 8)
    for yy in range(y + 28, y + h - 18, 35):
        rounded_line(draw, [(x + 10, yy), (x + 52, yy)], INK, 5)


def cable_tower(draw, side="left"):
    if side == "left":
        x = 66
        rr(draw, (x, 78, x + 58, 392), 16, MACHINE, INK, 8)
        rounded_line(draw, [(x + 29, 92), (x + 29, 390)], BAR, 7)
        dot(draw, (x + 29, 108), 15, METAL, INK, 6)
        return (x + 29, 108)
    x = 388
    rr(draw, (x, 78, x + 58, 392), 16, MACHINE, INK, 8)
    rounded_line(draw, [(x + 29, 92), (x + 29, 390)], BAR, 7)
    dot(draw, (x + 29, 108), 15, METAL, INK, 6)
    return (x + 29, 108)


def barbell(draw, y=120, x1=108, x2=404):
    rounded_line(draw, [(x1, y), (x2, y)], BAR, 11)
    for x in (x1, x2):
        rounded_line(draw, [(x, y - 42), (x, y + 42)], WEIGHT, 18)
        rounded_line(draw, [(x + (14 if x == x1 else -14), y - 32), (x + (14 if x == x1 else -14), y + 32)], WEIGHT, 13)


def dumbbell(draw, x, y, angle=0, scale=1.0):
    length = 48 * scale
    dx = math.cos(angle) * length / 2
    dy = math.sin(angle) * length / 2
    p1 = (x - dx, y - dy)
    p2 = (x + dx, y + dy)
    rounded_line(draw, [p1, p2], BAR, int(7 * scale))
    for sx, sy in (p1, p2):
        rounded_line(draw, [(sx - math.sin(angle) * 12 * scale, sy + math.cos(angle) * 12 * scale),
                            (sx + math.sin(angle) * 12 * scale, sy - math.cos(angle) * 12 * scale)],
                     WEIGHT, int(13 * scale))


def kettlebell(draw, x, y, scale=1.0):
    rr(draw, (x - 24 * scale, y - 10 * scale, x + 24 * scale, y + 42 * scale), int(17 * scale), WEIGHT, INK, int(5 * scale))
    draw.arc((x - 23 * scale, y - 32 * scale, x + 23 * scale, y + 16 * scale), 190, 350, fill=INK, width=int(8 * scale))


def draw_person(draw, j, gender="male", shirt=None):
    shirt = shirt or (FEMALE_SHIRT if gender == "female" else MALE_SHIRT)
    lower = LEGGINGS if gender == "female" else SHORTS
    leg_w = 30 if gender == "female" else 32
    arm_w = 26 if gender == "female" else 28

    for side in ("l", "r"):
        hip, knee, ankle = j[f"{side}hip"], j[f"{side}knee"], j[f"{side}ankle"]
        rounded_line(draw, [hip, knee, ankle], lower, leg_w)
        if f"{side}foot" in j:
            rounded_line(draw, [ankle, j[f"{side}foot"]], SHOE, max(11, leg_w - 6))

    torso = [j["lshoulder"], j["rshoulder"], j["rhip"], j["lhip"]]
    draw.polygon(torso, fill=shirt)
    rounded_line(draw, [j["lshoulder"], j["rshoulder"]], shirt, 30)
    rounded_line(draw, [j["lhip"], j["rhip"]], lower, 24)
    rounded_line(draw, [j["lhip"], j["rhip"]], INK, 4)
    cx = int((j["lshoulder"][0] + j["rshoulder"][0]) / 2)
    cy = int((j["lshoulder"][1] + j["rshoulder"][1]) / 2)
    rounded_line(draw, [(cx - 12, cy + 6), (cx + 12, cy + 6)], (235, 246, 252, 210), 5)

    for side in ("l", "r"):
        shoulder, elbow, hand = j[f"{side}shoulder"], j[f"{side}elbow"], j[f"{side}hand"]
        rounded_line(draw, [shoulder, elbow, hand], SKIN, arm_w)
        sx, sy = shoulder
        ex, ey = elbow
        sleeve = (sx + (ex - sx) * 0.35, sy + (ey - sy) * 0.35)
        rounded_line(draw, [shoulder, sleeve], shirt, arm_w + 4)

    neck = j.get("neck")
    if neck:
        rounded_line(draw, [neck, j["head"]], SKIN, 17)
    hx, hy = j["head"]
    if gender == "female":
        hair = (61, 45, 38, 255)
        dot(draw, (hx, hy + 4), 32, hair)
        dot(draw, (hx - 22, hy + 4), 17, hair)
        rounded_line(draw, [(hx - 25, hy + 16), (hx - 42, hy + 46)], hair, 11)
    else:
        draw.pieslice((hx - 27, hy - 30, hx + 27, hy + 18), 180, 360, fill=(65, 52, 43, 255))
    dot(draw, (hx, hy), 24, SKIN, INK, 5)
    dot(draw, (hx - 7, hy - 2), 2, INK)
    dot(draw, (hx + 7, hy - 2), 2, INK)
    rounded_line(draw, [(hx - 6, hy + 11), (hx + 8, hy + 11)], INK, 3)


def pose_seated(cx=260, cy=244, gender="male", arms="press", legs="bent", lean=0):
    sh_y = cy - 55
    hip_y = cy + 48
    head = (cx + lean * 10, cy - 104)
    lsh, rsh = (cx - 30 + lean, sh_y), (cx + 30 + lean, sh_y)
    lhip, rhip = (cx - 28, hip_y), (cx + 28, hip_y)
    if arms == "press":
        lel, rel = (cx - 76, cy - 42), (cx + 80, cy - 42)
        lh, rh = (cx - 118, cy - 42), (cx + 122, cy - 42)
    elif arms == "fly":
        lel, rel = (cx - 100, cy - 58), (cx + 100, cy - 58)
        lh, rh = (cx - 132, cy - 88), (cx + 132, cy - 88)
    elif arms == "row":
        lel, rel = (cx - 64, cy - 36), (cx + 64, cy - 36)
        lh, rh = (cx - 106, cy - 58), (cx + 106, cy - 58)
    elif arms == "pulldown":
        lel, rel = (cx - 80, cy - 105), (cx + 80, cy - 105)
        lh, rh = (cx - 100, cy - 150), (cx + 100, cy - 150)
    elif arms == "overhead":
        lel, rel = (cx - 66, cy - 105), (cx + 66, cy - 105)
        lh, rh = (cx - 66, cy - 154), (cx + 66, cy - 154)
    elif arms == "curl":
        lel, rel = (cx - 70, cy - 6), (cx + 70, cy - 6)
        lh, rh = (cx - 38, cy - 72), (cx + 38, cy - 72)
    else:
        lel, rel = (cx - 74, cy - 18), (cx + 74, cy - 18)
        lh, rh = (cx - 100, cy + 8), (cx + 100, cy + 8)

    if legs == "open":
        lk, rk = (cx - 108, cy + 92), (cx + 108, cy + 92)
        la, ra = (cx - 148, cy + 144), (cx + 148, cy + 144)
    elif legs == "together":
        lk, rk = (cx - 38, cy + 112), (cx + 38, cy + 112)
        la, ra = (cx - 78, cy + 150), (cx + 78, cy + 150)
    elif legs == "straight":
        lk, rk = (cx - 70, cy + 88), (cx + 70, cy + 88)
        la, ra = (cx - 125, cy + 118), (cx + 125, cy + 118)
    else:
        lk, rk = (cx - 72, cy + 92), (cx + 72, cy + 92)
        la, ra = (cx - 98, cy + 150), (cx + 98, cy + 150)

    return {
        "head": head, "neck": (cx + lean * 8, cy - 76),
        "lshoulder": lsh, "rshoulder": rsh, "lhip": lhip, "rhip": rhip,
        "lelbow": lel, "relbow": rel, "lhand": lh, "rhand": rh,
        "lhip": lhip, "rhip": rhip, "lknee": lk, "rknee": rk,
        "lankle": la, "rankle": ra, "lfoot": (la[0] - 28, la[1] + 5), "rfoot": (ra[0] + 28, ra[1] + 5),
    }


def pose_standing(cx=256, cy=242, arms="down", legs="stance", gender="male"):
    head = (cx, cy - 132)
    lsh, rsh = (cx - 32, cy - 74), (cx + 32, cy - 74)
    lhip, rhip = (cx - 26, cy + 28), (cx + 26, cy + 28)
    if arms == "side":
        lel, rel = (cx - 95, cy - 45), (cx + 95, cy - 45)
        lh, rh = (cx - 134, cy - 40), (cx + 134, cy - 40)
    elif arms == "front":
        lel, rel = (cx - 56, cy - 58), (cx + 56, cy - 58)
        lh, rh = (cx - 80, cy - 98), (cx + 80, cy - 98)
    elif arms == "overhead":
        lel, rel = (cx - 58, cy - 128), (cx + 58, cy - 128)
        lh, rh = (cx - 64, cy - 176), (cx + 64, cy - 176)
    elif arms == "curl":
        lel, rel = (cx - 58, cy - 10), (cx + 58, cy - 10)
        lh, rh = (cx - 36, cy - 76), (cx + 36, cy - 76)
    elif arms == "rope":
        lel, rel = (cx - 56, cy - 78), (cx + 56, cy - 78)
        lh, rh = (cx - 28, cy - 116), (cx + 28, cy - 116)
    elif arms == "bar":
        lel, rel = (cx - 78, cy - 58), (cx + 78, cy - 58)
        lh, rh = (cx - 106, cy - 56), (cx + 106, cy - 56)
    else:
        lel, rel = (cx - 58, cy - 4), (cx + 58, cy - 4)
        lh, rh = (cx - 70, cy + 58), (cx + 70, cy + 58)
    if legs == "squat":
        lk, rk = (cx - 96, cy + 90), (cx + 96, cy + 90)
        la, ra = (cx - 132, cy + 144), (cx + 132, cy + 144)
    elif legs == "lunge":
        lk, rk = (cx - 110, cy + 92), (cx + 78, cy + 88)
        la, ra = (cx - 148, cy + 150), (cx + 122, cy + 150)
    else:
        lk, rk = (cx - 44, cy + 108), (cx + 44, cy + 108)
        la, ra = (cx - 68, cy + 166), (cx + 68, cy + 166)
    return {
        "head": head, "neck": (cx, cy - 100), "lshoulder": lsh, "rshoulder": rsh,
        "lhip": lhip, "rhip": rhip, "lelbow": lel, "relbow": rel, "lhand": lh, "rhand": rh,
        "lknee": lk, "rknee": rk, "lankle": la, "rankle": ra,
        "lfoot": (la[0] - 30, la[1] + 4), "rfoot": (ra[0] + 30, ra[1] + 4),
    }


def pose_lying(cx=255, cy=262, incline=False, arms="press"):
    dy = -42 if incline else 0
    return {
        "head": (cx - 128, cy - 42 + dy), "neck": (cx - 100, cy - 28 + dy),
        "lshoulder": (cx - 70, cy - 42 + dy), "rshoulder": (cx - 58, cy - 10 + dy),
        "lhip": (cx + 44, cy - 8), "rhip": (cx + 54, cy + 26),
        "lelbow": (cx - 18, cy - 104 + dy), "relbow": (cx + 18, cy - 92 + dy),
        "lhand": (cx + 25, cy - 132 + dy), "rhand": (cx + 60, cy - 118 + dy),
        "lknee": (cx + 120, cy + 38), "rknee": (cx + 136, cy + 66),
        "lankle": (cx + 176, cy + 18), "rankle": (cx + 188, cy + 52),
        "lfoot": (cx + 208, cy + 14), "rfoot": (cx + 218, cy + 50),
    }


def pose_pushup(cx=258, cy=268):
    return {
        "head": (cx - 138, cy - 38), "neck": (cx - 108, cy - 28),
        "lshoulder": (cx - 78, cy - 32), "rshoulder": (cx - 68, cy - 2),
        "lhip": (cx + 46, cy + 16), "rhip": (cx + 58, cy + 44),
        "lelbow": (cx - 88, cy + 32), "relbow": (cx - 58, cy + 46),
        "lhand": (cx - 112, cy + 82), "rhand": (cx - 42, cy + 88),
        "lknee": (cx + 132, cy + 44), "rknee": (cx + 146, cy + 72),
        "lankle": (cx + 204, cy + 55), "rankle": (cx + 214, cy + 78),
        "lfoot": (cx + 235, cy + 54), "rfoot": (cx + 244, cy + 78),
    }


def pose_plank(cx=260, cy=274):
    j = pose_pushup(cx, cy)
    j["lelbow"] = (cx - 100, cy + 44)
    j["relbow"] = (cx - 66, cy + 55)
    j["lhand"] = (cx - 132, cy + 48)
    j["rhand"] = (cx - 34, cy + 58)
    return j


def pose_bike(cx=256, cy=250):
    return {
        "head": (cx, cy - 120), "neck": (cx, cy - 88),
        "lshoulder": (cx - 34, cy - 62), "rshoulder": (cx + 34, cy - 62),
        "lhip": (cx - 34, cy + 34), "rhip": (cx + 34, cy + 34),
        "lelbow": (cx - 64, cy - 26), "relbow": (cx + 70, cy - 28),
        "lhand": (cx - 84, cy - 8), "rhand": (cx + 100, cy - 6),
        "lknee": (cx - 78, cy + 96), "rknee": (cx + 78, cy + 96),
        "lankle": (cx - 116, cy + 136), "rankle": (cx + 116, cy + 136),
        "lfoot": (cx - 142, cy + 130), "rfoot": (cx + 142, cy + 130),
    }


def pose_cross_trainer(cx=260, cy=246):
    return {
        "head": (cx, cy - 128), "neck": (cx, cy - 96),
        "lshoulder": (cx - 34, cy - 70), "rshoulder": (cx + 34, cy - 70),
        "lhip": (cx - 30, cy + 26), "rhip": (cx + 30, cy + 26),
        "lelbow": (cx - 64, cy - 78), "relbow": (cx + 66, cy - 82),
        "lhand": (cx - 82, cy - 118), "rhand": (cx + 86, cy - 124),
        "lknee": (cx - 78, cy + 98), "rknee": (cx + 72, cy + 82),
        "lankle": (cx - 120, cy + 158), "rankle": (cx + 126, cy + 136),
        "lfoot": (cx - 152, cy + 158), "rfoot": (cx + 156, cy + 138),
    }


def pose_rowing_machine(cx=258, cy=262):
    return {
        "head": (cx - 88, cy - 92), "neck": (cx - 62, cy - 68),
        "lshoulder": (cx - 32, cy - 48), "rshoulder": (cx - 20, cy - 18),
        "lhip": (cx + 54, cy + 20), "rhip": (cx + 66, cy + 48),
        "lelbow": (cx + 10, cy - 58), "relbow": (cx + 30, cy - 38),
        "lhand": (cx + 70, cy - 72), "rhand": (cx + 86, cy - 52),
        "lknee": (cx + 120, cy + 90), "rknee": (cx + 136, cy + 112),
        "lankle": (cx + 186, cy + 108), "rankle": (cx + 206, cy + 128),
        "lfoot": (cx + 220, cy + 104), "rfoot": (cx + 238, cy + 128),
    }


def draw_floor(draw):
    rounded_line(draw, [(80, 424), (432, 424)], (70, 79, 88, 120), 8)


def chair(draw, x=212, y=322, w=120, h=78):
    rr(draw, (x, y, x + w, y + 28), 12, MACHINE_DARK, INK, 5)
    rounded_line(draw, [(x + 20, y + 20), (x + 20, y + h)], MACHINE_DARK, 10)
    rounded_line(draw, [(x + w - 20, y + 20), (x + w - 20, y + h)], MACHINE_DARK, 10)
    rounded_line(draw, [(x + 8, y + h), (x + w - 8, y + h)], MACHINE_DARK, 8)


def draw_press_machine(draw, incline=False, cable=False, smith=False):
    chair(draw, 206, 322, 118, 70)
    rr(draw, (330, 142, 384, 360), 18, MACHINE, INK, 8)
    rounded_line(draw, [(360, 190), (246, 208)], MACHINE_DARK, 12)
    rounded_line(draw, [(360, 224), (246, 224)], MACHINE_DARK, 12)
    if incline:
        rounded_line(draw, [(214, 314), (178, 226)], MACHINE_DARK, 16)
    if cable:
        pulley = cable_tower(draw, "right")
        rounded_line(draw, [pulley, (332, 205), (208, 206)], BAR, 5)
    if smith:
        rounded_line(draw, [(132, 92), (132, 392)], MACHINE_DARK, 12)
        rounded_line(draw, [(394, 92), (394, 392)], MACHINE_DARK, 12)
        barbell(draw, 164, 136, 388)


def draw_fly_machine(draw, reverse=False):
    chair(draw, 196, 326, 128, 70)
    rr(draw, (210, 160, 308, 330), 20, MACHINE, INK, 8)
    rounded_line(draw, [(164, 166), (220, 226)], MACHINE_DARK, 13)
    rounded_line(draw, [(348, 166), (296, 226)], MACHINE_DARK, 13)
    if reverse:
        rr(draw, (220, 184, 294, 304), 18, METAL, INK, 6)


def draw_row_machine(draw, cable=False, high=False):
    chair(draw, 246, 340, 122, 66)
    rr(draw, (84, 134, 142, 360), 16, MACHINE, INK, 8)
    rounded_line(draw, [(126, 224), (260, 220)], BAR, 6)
    rr(draw, (172, 190, 226, 292), 14, MACHINE, INK, 7)
    if high:
        rounded_line(draw, [(126, 152), (266, 196)], BAR, 7)
    if cable:
        dot(draw, (126, 150), 14, METAL, INK, 5)
        rounded_line(draw, [(126, 150), (258, 210)], BAR, 5)


def draw_leg_machine(draw, mode):
    chair(draw, 160, 320, 150, 72)
    rr(draw, (158, 182, 238, 326), 18, MACHINE, INK, 8)
    if mode == "extension":
        rounded_line(draw, [(308, 284), (402, 276)], MACHINE_DARK, 15)
        dot(draw, (408, 276), 25, WEIGHT, INK, 5)
    elif mode == "curl":
        rounded_line(draw, [(304, 306), (382, 364)], MACHINE_DARK, 15)
        dot(draw, (388, 370), 25, WEIGHT, INK, 5)
    elif mode == "press":
        rr(draw, (338, 132, 396, 330), 14, MACHINE, INK, 8)
        rounded_line(draw, [(308, 250), (366, 202)], MACHINE_DARK, 14)
    elif mode == "abductor":
        rounded_line(draw, [(254, 314), (146, 260)], MACHINE_DARK, 17)
        rounded_line(draw, [(254, 314), (362, 260)], MACHINE_DARK, 17)
        dot(draw, (140, 258), 20, WEIGHT, INK, 5)
        dot(draw, (368, 258), 20, WEIGHT, INK, 5)
    elif mode == "adductor":
        rounded_line(draw, [(246, 310), (202, 246)], MACHINE_DARK, 17)
        rounded_line(draw, [(266, 310), (310, 246)], MACHINE_DARK, 17)
        dot(draw, (202, 246), 20, WEIGHT, INK, 5)
        dot(draw, (310, 246), 20, WEIGHT, INK, 5)


def draw_cardio(draw, mode):
    if mode == "treadmill":
        rr(draw, (92, 338, 420, 384), 18, MACHINE_DARK, INK, 7)
        rounded_line(draw, [(350, 336), (376, 190), (424, 178)], MACHINE_DARK, 12)
        rr(draw, (405, 148, 462, 190), 12, MACHINE, INK, 6)
    elif mode == "bike":
        dot(draw, (170, 340), 56, (0, 0, 0, 0), MACHINE_DARK, 13)
        dot(draw, (350, 340), 56, (0, 0, 0, 0), MACHINE_DARK, 13)
        rounded_line(draw, [(170, 340), (254, 260), (350, 340), (238, 340), (170, 340)], MACHINE_DARK, 11)
        rounded_line(draw, [(254, 260), (270, 208), (326, 206)], MACHINE_DARK, 10)
        rounded_line(draw, [(254, 260), (224, 220), (188, 220)], MACHINE_DARK, 10)
    elif mode == "air-bike":
        dot(draw, (168, 338), 58, (0, 0, 0, 0), MACHINE_DARK, 13)
        dot(draw, (352, 338), 68, (0, 0, 0, 0), MACHINE_DARK, 13)
        for a in range(0, 360, 45):
            rad = math.radians(a)
            rounded_line(draw, [(352, 338), (352 + math.cos(rad) * 58, 338 + math.sin(rad) * 58)], MACHINE_DARK, 5)
        rounded_line(draw, [(168, 338), (256, 254), (352, 338), (236, 338), (168, 338)], MACHINE_DARK, 11)
        rounded_line(draw, [(256, 254), (306, 200), (338, 208)], MACHINE_DARK, 10)
    elif mode == "cross":
        dot(draw, (184, 360), 36, (0, 0, 0, 0), MACHINE_DARK, 10)
        dot(draw, (334, 360), 36, (0, 0, 0, 0), MACHINE_DARK, 10)
        rounded_line(draw, [(112, 372), (220, 372), (318, 328), (430, 328)], MACHINE_DARK, 12)
        rounded_line(draw, [(214, 340), (244, 180)], MACHINE_DARK, 11)
        rounded_line(draw, [(314, 340), (278, 166)], MACHINE_DARK, 11)
        rounded_line(draw, [(244, 180), (190, 110)], MACHINE_DARK, 9)
        rounded_line(draw, [(278, 166), (340, 104)], MACHINE_DARK, 9)
    elif mode == "row":
        rounded_line(draw, [(98, 370), (420, 370)], MACHINE_DARK, 13)
        rr(draw, (110, 318, 186, 358), 14, MACHINE, INK, 6)
        dot(draw, (406, 340), 34, METAL, INK, 7)
        rounded_line(draw, [(186, 340), (360, 302)], BAR, 6)
    elif mode == "stairs":
        for i in range(6):
            rr(draw, (142 + i * 42, 368 - i * 30, 226 + i * 42, 394 - i * 30), 8, MACHINE_DARK, INK, 5)
        rounded_line(draw, [(350, 326), (384, 152), (426, 144)], MACHINE_DARK, 12)
    elif mode == "skierg":
        rr(draw, (230, 84, 282, 392), 18, MACHINE, INK, 8)
        dot(draw, (256, 118), 19, METAL, INK, 6)
        rounded_line(draw, [(256, 118), (176, 218), (178, 300)], BAR, 6)
        rounded_line(draw, [(256, 118), (334, 218), (334, 300)], BAR, 6)


def draw_capsule_bar(draw, x1, y1, x2, y2, label=False):
    rounded_line(draw, [(x1, y1), (x2, y2)], BAR, 12)
    dot(draw, (x1, y1), 20, WEIGHT, INK, 5)
    dot(draw, (x2, y2), 20, WEIGHT, INK, 5)


def draw_icon(slug: str, out_path: Path):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gender = "female" if slug in FEMALE else "male"
    shirt = FEMALE_SHIRT if gender == "female" else MALE_SHIRT
    if slug in {"adductor", "cable-chest-press", "walking-lunge", "dumbbell-bench-press"}:
        shirt = ALT_SHIRT

    draw_floor(draw)

    if slug in {"chest-press", "incline-press", "cable-chest-press", "smith-bench-press"}:
        draw_press_machine(draw, incline=slug == "incline-press", cable=slug == "cable-chest-press", smith=slug == "smith-bench-press")
        draw_person(draw, pose_seated(240, 250, gender, arms="press"), gender, shirt)
    elif slug in {"pec-deck", "machine-fly"}:
        draw_fly_machine(draw)
        draw_person(draw, pose_seated(256, 250, gender, arms="fly", legs="together"), gender, shirt)
    elif slug == "cable-fly":
        cable_tower(draw, "left"); cable_tower(draw, "right")
        rounded_line(draw, [(95, 108), (202, 206), (256, 222), (310, 206), (417, 108)], BAR, 5)
        draw_person(draw, pose_standing(256, 256, arms="fly" if False else "side", legs="stance"), gender, shirt)
    elif slug == "bench-press":
        bench(draw, 120, 318, 390)
        barbell(draw, 174, 132, 386)
        draw_person(draw, pose_lying(250, 286), gender, shirt)
    elif slug == "dumbbell-bench-press":
        bench(draw, 120, 318, 390)
        draw_person(draw, pose_lying(250, 286), gender, shirt)
        dumbbell(draw, 274, 150, -0.1, 1.0); dumbbell(draw, 312, 164, -0.1, 1.0)
    elif slug == "push-up":
        draw_person(draw, pose_pushup(), gender, shirt)

    elif slug == "lat-pulldown":
        rr(draw, (124, 80, 388, 118), 12, MACHINE_DARK, INK, 6)
        weight_stack(draw, 386, 132, 230)
        chair(draw, 208, 338, 112, 60)
        rounded_line(draw, [(156, 100), (212, 92), (300, 92), (356, 100)], BAR, 8)
        draw_person(draw, pose_seated(256, 264, gender, arms="pulldown"), gender, shirt)
    elif slug in {"seated-row", "seated-machine-row", "low-row", "cable-row", "t-bar-row-machine"}:
        draw_row_machine(draw, cable=slug == "cable-row", high=slug in {"low-row", "t-bar-row-machine"})
        draw_person(draw, pose_seated(280, 262, gender, arms="row", legs="straight", lean=-1), gender, shirt)
        if slug == "t-bar-row-machine":
            rounded_line(draw, [(128, 260), (302, 316)], BAR, 11)
            dot(draw, (122, 258), 26, WEIGHT, INK, 5)
    elif slug == "back-extension":
        rr(draw, (126, 292, 308, 328), 14, MACHINE_DARK, INK, 6)
        rounded_line(draw, [(186, 322), (142, 404)], MACHINE_DARK, 10)
        j = pose_pushup(260, 258)
        j["head"] = (164, 160); j["neck"] = (190, 186)
        j["lshoulder"] = (216, 208); j["rshoulder"] = (226, 238)
        j["lhip"] = (300, 292); j["rhip"] = (310, 322)
        draw_person(draw, j, gender, shirt)
    elif slug == "assisted-pullup":
        outline_box(draw, (132, 84, 380, 386))
        rounded_line(draw, [(150, 96), (362, 96)], BAR, 12)
        rr(draw, (216, 314, 296, 356), 12, MACHINE, INK, 6)
        draw_person(draw, pose_seated(256, 238, gender, arms="pulldown", legs="together"), gender, shirt)
    elif slug == "pullover-machine":
        rr(draw, (120, 138, 174, 366), 16, MACHINE, INK, 8)
        chair(draw, 220, 334, 118, 64)
        rounded_line(draw, [(148, 168), (254, 178), (310, 222)], MACHINE_DARK, 14)
        draw_person(draw, pose_seated(260, 256, gender, arms="overhead"), gender, shirt)
    elif slug == "face-pull":
        cable_tower(draw, "left")
        rounded_line(draw, [(95, 108), (212, 146), (236, 146)], BAR, 6)
        draw_person(draw, pose_standing(300, 260, arms="rope"), gender, shirt)

    elif slug in {"shoulder-press", "arnold-press"}:
        chair(draw, 204, 326, 120, 68)
        rr(draw, (156, 150, 200, 330), 14, MACHINE, INK, 7)
        rr(draw, (312, 150, 356, 330), 14, MACHINE, INK, 7)
        draw_person(draw, pose_seated(256, 262, gender, arms="overhead"), gender, shirt)
        if slug == "arnold-press":
            dumbbell(draw, 190, 110, 1.2, .8); dumbbell(draw, 322, 110, -1.2, .8)
    elif slug in {"lateral-raise", "cable-lateral-raise"}:
        if slug == "cable-lateral-raise":
            cable_tower(draw, "left")
            rounded_line(draw, [(95, 320), (178, 212)], BAR, 5)
        else:
            rr(draw, (120, 180, 168, 360), 14, MACHINE, INK, 7)
            rr(draw, (344, 180, 392, 360), 14, MACHINE, INK, 7)
        draw_person(draw, pose_standing(256, 260, arms="side"), gender, shirt)
    elif slug == "rear-delt":
        draw_fly_machine(draw, reverse=True)
        draw_person(draw, pose_seated(256, 250, gender, arms="fly", legs="together"), gender, shirt)
    elif slug == "front-raise":
        draw_person(draw, pose_standing(256, 260, arms="front"), gender, shirt)
        dumbbell(draw, 176, 160, 0.0, .8); dumbbell(draw, 336, 160, 0.0, .8)
    elif slug == "shrug-machine":
        rr(draw, (126, 250, 386, 366), 18, MACHINE, INK, 8)
        rounded_line(draw, [(166, 260), (196, 330)], MACHINE_DARK, 14)
        rounded_line(draw, [(346, 260), (316, 330)], MACHINE_DARK, 14)
        draw_person(draw, pose_standing(256, 246, arms="down"), gender, shirt)

    elif slug == "leg-press":
        draw_leg_machine(draw, "press")
        draw_person(draw, pose_seated(226, 248, gender, arms="hold", legs="straight"), gender, shirt)
    elif slug in {"leg-extension", "leg-curl"}:
        draw_leg_machine(draw, "extension" if slug == "leg-extension" else "curl")
        draw_person(draw, pose_seated(238, 250, gender, arms="hold", legs="straight"), gender, shirt)
    elif slug in {"abductor", "adductor"}:
        draw_leg_machine(draw, slug)
        draw_person(draw, pose_seated(256, 250, gender, arms="hold", legs="open" if slug == "abductor" else "together"), gender, shirt)
    elif slug == "hip-thrust":
        bench(draw, 124, 324, 312)
        rr(draw, (288, 288, 390, 326), 14, MACHINE, INK, 6)
        j = pose_lying(255, 286)
        j["lhip"] = (270, 230); j["rhip"] = (280, 260)
        j["lknee"] = (350, 300); j["rknee"] = (362, 326)
        j["lankle"] = (382, 374); j["rankle"] = (398, 384)
        draw_person(draw, j, gender, shirt)
    elif slug in {"calf-raise", "standing-calf-raise"}:
        rr(draw, (154, 136, 358, 196), 16, MACHINE, INK, 8)
        rounded_line(draw, [(178, 190), (178, 374)], MACHINE_DARK, 12)
        rounded_line(draw, [(334, 190), (334, 374)], MACHINE_DARK, 12)
        draw_person(draw, pose_standing(256, 242, arms="down"), gender, shirt)
    elif slug == "seated-calf-raise":
        chair(draw, 176, 328, 148, 66)
        rr(draw, (192, 230, 320, 272), 12, MACHINE, INK, 6)
        rounded_line(draw, [(250, 316), (386, 320)], MACHINE_DARK, 14)
        draw_person(draw, pose_seated(248, 250, gender, arms="hold", legs="straight"), gender, shirt)
    elif slug in {"hack-squat", "smith-squat", "squat"}:
        if slug == "hack-squat":
            rr(draw, (318, 104, 380, 388), 18, MACHINE, INK, 8)
            rounded_line(draw, [(184, 304), (348, 166)], MACHINE_DARK, 13)
        else:
            outline_box(draw, (120, 86, 392, 388))
            barbell(draw, 168, 134, 378)
        draw_person(draw, pose_standing(256, 258, arms="bar", legs="squat"), gender, shirt)
    elif slug == "glute-kickback":
        rr(draw, (108, 186, 180, 352), 16, MACHINE, INK, 8)
        rr(draw, (318, 280, 410, 328), 12, MACHINE, INK, 6)
        j = pose_standing(244, 260, arms="bar")
        j["rknee"] = (342, 278); j["rankle"] = (408, 248); j["rfoot"] = (434, 238)
        draw_person(draw, j, gender, shirt)

    elif slug in {"biceps-curl", "hammer-curl", "cable-curl"}:
        if slug == "cable-curl":
            cable_tower(draw, "left")
            rounded_line(draw, [(95, 330), (218, 250)], BAR, 5)
        elif slug == "biceps-curl":
            rr(draw, (128, 276, 384, 330), 16, MACHINE, INK, 7)
        draw_person(draw, pose_standing(256, 260, arms="curl"), gender, shirt)
        dumbbell(draw, 220, 184, 1.15 if slug == "hammer-curl" else .35, .75)
        dumbbell(draw, 292, 184, -1.15 if slug == "hammer-curl" else -.35, .75)
    elif slug in {"triceps-press", "overhead-triceps"}:
        cable_tower(draw, "left")
        arms = "overhead" if slug == "overhead-triceps" else "down"
        draw_person(draw, pose_standing(286, 260, arms=arms), gender, shirt)
        if slug == "triceps-press":
            rounded_line(draw, [(95, 112), (260, 230)], BAR, 5)
        else:
            rounded_line(draw, [(95, 112), (260, 100), (286, 84)], BAR, 5)
    elif slug == "dip-machine":
        rr(draw, (126, 184, 386, 350), 18, MACHINE, INK, 8)
        rounded_line(draw, [(160, 230), (226, 230)], MACHINE_DARK, 14)
        rounded_line(draw, [(352, 230), (286, 230)], MACHINE_DARK, 14)
        draw_person(draw, pose_seated(256, 248, gender, arms="hold", legs="bent"), gender, shirt)
    elif slug == "preacher-curl":
        rr(draw, (144, 270, 368, 320), 16, MACHINE, INK, 7)
        rr(draw, (188, 210, 324, 270), 16, METAL, INK, 6)
        draw_person(draw, pose_seated(256, 246, gender, arms="curl", legs="bent"), gender, shirt)
    elif slug == "skull-crusher":
        bench(draw, 120, 328, 390)
        draw_person(draw, pose_lying(250, 292), gender, shirt)
        draw_capsule_bar(draw, 248, 162, 336, 162)

    elif slug in {"ab-crunch", "crunch-press"}:
        rr(draw, (136, 156, 376, 350), 22, MACHINE, INK, 8)
        chair(draw, 192, 326, 128, 64)
        draw_person(draw, pose_seated(256, 252, gender, arms="hold", legs="bent"), gender, shirt)
        rounded_line(draw, [(172, 156), (226, 226), (286, 226), (340, 156)], MACHINE_DARK, 11)
    elif slug == "rotary-torso":
        chair(draw, 192, 328, 128, 64)
        rr(draw, (152, 180, 360, 260), 18, MACHINE, INK, 8)
        rounded_line(draw, [(176, 218), (336, 218)], MACHINE_DARK, 13)
        draw_person(draw, pose_seated(256, 252, gender, arms="bar", legs="bent"), gender, shirt)
    elif slug == "plank":
        draw_person(draw, pose_plank(), gender, shirt)
    elif slug == "cable-crunch":
        cable_tower(draw, "left")
        rounded_line(draw, [(95, 112), (220, 150), (248, 194)], BAR, 5)
        j = pose_seated(274, 272, gender, arms="overhead", legs="bent")
        j["head"] = (238, 148); j["neck"] = (254, 176)
        draw_person(draw, j, gender, shirt)
    elif slug == "hanging-leg-raise":
        outline_box(draw, (132, 84, 380, 386))
        rounded_line(draw, [(152, 96), (360, 96)], BAR, 12)
        j = pose_seated(256, 230, gender, arms="pulldown", legs="straight")
        j["lknee"] = (218, 306); j["rknee"] = (294, 306)
        j["lankle"] = (200, 356); j["rankle"] = (312, 356)
        draw_person(draw, j, gender, shirt)
    elif slug == "roman-chair":
        rr(draw, (120, 308, 350, 346), 14, MACHINE_DARK, INK, 6)
        rr(draw, (262, 214, 342, 260), 14, MACHINE, INK, 6)
        j = pose_lying(258, 270, incline=True)
        j["head"] = (176, 158)
        draw_person(draw, j, gender, shirt)
    elif slug == "pallof-press":
        cable_tower(draw, "left")
        rounded_line(draw, [(95, 224), (222, 224)], BAR, 5)
        draw_person(draw, pose_standing(300, 260, arms="press" if False else "front"), gender, shirt)

    elif slug in {"treadmill", "bike", "air-bike", "cross-trainer", "rowing", "stairmaster", "skierg"}:
        mode = {"cross-trainer": "cross", "stairmaster": "stairs", "air-bike": "air-bike"}.get(slug, slug if slug != "rowing" else "row")
        draw_cardio(draw, mode)
        if slug == "treadmill":
            draw_person(draw, pose_standing(250, 240, arms="down", legs="lunge"), gender, shirt)
        elif slug in {"bike", "air-bike"}:
            draw_person(draw, pose_bike(256, 248), gender, shirt)
        elif slug == "cross-trainer":
            draw_person(draw, pose_cross_trainer(260, 246), gender, shirt)
        elif slug == "rowing":
            draw_person(draw, pose_rowing_machine(228, 262), gender, shirt)
        elif slug == "stairmaster":
            draw_person(draw, pose_standing(250, 246, arms="bar", legs="lunge"), gender, shirt)
        elif slug == "skierg":
            draw_person(draw, pose_standing(256, 254, arms="overhead"), gender, shirt)

    elif slug in {"deadlift", "romanian-deadlift"}:
        draw_capsule_bar(draw, 142, 358, 370, 358)
        j = pose_standing(256, 250, arms="bar", legs="stance")
        j["head"] = (236, 130); j["neck"] = (250, 158)
        j["lshoulder"] = (224, 184); j["rshoulder"] = (286, 178)
        j["lhip"] = (238, 260); j["rhip"] = (296, 252)
        j["lelbow"] = (210, 260); j["relbow"] = (308, 260)
        j["lhand"] = (196, 354); j["rhand"] = (318, 354)
        draw_person(draw, j, gender, shirt)
    elif slug == "dumbbell-row":
        bench(draw, 138, 338, 360)
        j = pose_standing(256, 254, arms="down", legs="lunge")
        j["head"] = (202, 134); j["neck"] = (222, 166)
        j["lshoulder"] = (234, 194); j["rshoulder"] = (290, 206)
        j["lhip"] = (274, 278); j["rhip"] = (322, 288)
        j["lhand"] = (190, 334); j["rhand"] = (330, 220)
        draw_person(draw, j, gender, shirt)
        dumbbell(draw, 188, 352, 1.5, .9)
    elif slug == "goblet-squat":
        draw_person(draw, pose_standing(256, 258, arms="front", legs="squat"), gender, shirt)
        kettlebell(draw, 256, 194, .85)
    elif slug == "walking-lunge":
        draw_person(draw, pose_standing(256, 252, arms="down", legs="lunge"), gender, shirt)
        dumbbell(draw, 186, 322, 1.45, .8); dumbbell(draw, 326, 322, -1.45, .8)
    else:
        draw_person(draw, pose_standing(256, 250), gender, shirt)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)
    EXERCISE_IMAGES.mkdir(parents=True, exist_ok=True)
    img.save(EXERCISE_IMAGES / f"{asset_name(slug)}.png")


def ensure_contents(slug: str):
    name = asset_name(slug)
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    contents = {
        "images": [
            {"filename": f"{name}.png", "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    return folder / f"{name}.png"


def make_sheet(slugs):
    cell = 170
    cols = 8
    rows = math.ceil(len(slugs) / cols)
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (248, 250, 252, 255))
    for idx, slug in enumerate(slugs):
        img = Image.open(ASSETS / f"{asset_name(slug)}.imageset" / f"{asset_name(slug)}.png").resize((132, 132))
        x = (idx % cols) * cell + 19
        y = (idx // cols) * cell + 8
        sheet.alpha_composite(img, (x, y))
        d = ImageDraw.Draw(sheet)
        label = slug.replace("-", " ")
        d.text((idx % cols * cell + 8, y + 136), label[:22], fill=(28, 34, 42, 255))
    out = Path("/private/tmp/gympit_exercise_art_sheet.png")
    sheet.convert("RGB").save(out)
    print(out)


SLUGS = [
    "chest-press", "incline-press", "pec-deck", "cable-fly", "machine-fly",
    "cable-chest-press", "smith-bench-press", "push-up",
    "lat-pulldown", "seated-row", "seated-machine-row", "back-extension",
    "assisted-pullup", "low-row", "t-bar-row-machine", "pullover-machine",
    "cable-row", "face-pull",
    "shoulder-press", "lateral-raise", "rear-delt", "cable-lateral-raise",
    "front-raise", "shrug-machine", "arnold-press",
    "leg-press", "leg-extension", "leg-curl", "hip-thrust", "abductor",
    "adductor", "calf-raise", "hack-squat", "smith-squat", "glute-kickback",
    "seated-calf-raise", "standing-calf-raise",
    "biceps-curl", "triceps-press", "dip-machine", "preacher-curl",
    "hammer-curl", "cable-curl", "overhead-triceps", "skull-crusher",
    "ab-crunch", "crunch-press", "rotary-torso", "plank", "cable-crunch",
    "hanging-leg-raise", "roman-chair", "pallof-press",
    "treadmill", "bike", "cross-trainer", "rowing", "stairmaster", "skierg",
    "air-bike", "bench-press", "squat", "deadlift", "dumbbell-row",
    "romanian-deadlift", "goblet-squat", "walking-lunge", "dumbbell-bench-press",
]


def main():
    for slug in SLUGS:
        draw_icon(slug, ensure_contents(slug))
    make_sheet(SLUGS)


if __name__ == "__main__":
    main()
