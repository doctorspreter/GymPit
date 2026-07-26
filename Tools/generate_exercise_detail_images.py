#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
DETAIL_IMAGES = ROOT / "GymPit" / "ExerciseDetailImages"
SHEET = Path("/private/tmp/gympit_exercise_detail_sheet.png")

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


def asset_name(slug: str) -> str:
    return f"exercise_{slug.replace('-', '_')}"


def make_sheet() -> None:
    cell = 210
    cols = 8
    rows = math.ceil(len(SLUGS) / cols)
    sheet = Image.new("RGB", (cols * cell, rows * cell), (248, 250, 252))
    draw = ImageDraw.Draw(sheet)

    for index, slug in enumerate(SLUGS):
        path = DETAIL_IMAGES / f"{asset_name(slug)}.png"
        image = Image.open(path).convert("RGB")
        image.thumbnail((180, 180), Image.Resampling.LANCZOS)
        x = (index % cols) * cell + (cell - image.width) // 2
        y = (index // cols) * cell + 4
        sheet.paste(image, (x, y))
        draw.text(
            ((index % cols) * cell + 8, (index // cols) * cell + 186),
            slug.replace("-", " ")[:24],
            fill=(20, 24, 28),
        )

    sheet.save(SHEET)
    print(SHEET)


if __name__ == "__main__":
    make_sheet()
