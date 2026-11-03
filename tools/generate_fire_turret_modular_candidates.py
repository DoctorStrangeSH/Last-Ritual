#!/usr/bin/env python3
"""Generate review-only modular Fire Turret Pixel Art assets."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import tempfile
from pathlib import Path
from typing import Iterable
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/fire"
DIRECTIONS = (
    (0.0, -1.0), (0.7071, -0.7071), (1.0, 0.0), (0.7071, 0.7071),
    (0.0, 1.0), (-0.7071, 0.7071), (-1.0, 0.0), (-0.7071, -0.7071),
)
DIRECTION_ORDER = ["north", "north_east", "east", "south_east",
                   "south", "south_west", "west", "north_west"]
P = {
    "outline": (19, 20, 27, 255), "shadow": (18, 17, 22, 255),
    "stone_dark": (38, 43, 52, 255), "stone": (58, 66, 76, 255),
    "stone_mid": (82, 91, 99, 255), "stone_light": (123, 130, 130, 255),
    "iron_dark": (37, 33, 36, 255), "iron": (76, 65, 62, 255),
    "iron_light": (123, 103, 87, 255), "bronze_dark": (80, 43, 30, 255),
    "bronze": (147, 75, 43, 255), "bronze_light": (199, 119, 55, 255),
    "ember_dark": (112, 35, 22, 255), "ember": (205, 61, 25, 255),
    "flame": (255, 112, 42, 255), "gold": (255, 177, 64, 255),
    "fire_white": (255, 230, 155, 255), "ash": (99, 81, 72, 255),
    "transparent": (0, 0, 0, 0),
}


def c(name: str, alpha: int | None = None):
    value = P[name]
    return value if alpha is None else (*value[:3], max(0, min(255, alpha)))


def q(value: float) -> int:
    return int(math.floor(value + 0.5))


def poly(draw: ImageDraw.ImageDraw, points: Iterable[tuple[float, float]], fill, outline=None, width=2):
    pts = [(q(x), q(y)) for x, y in points]
    draw.polygon(pts, fill=fill)
    if outline is not None:
        draw.line(pts + [pts[0]], fill=outline, width=width)


def line(draw: ImageDraw.ImageDraw, a, b, fill, width=1):
    draw.line((q(a[0]), q(a[1]), q(b[0]), q(b[1])), fill=fill, width=width)


def diamond(draw: ImageDraw.ImageDraw, x, y, rx, ry, fill, outline=None):
    poly(draw, [(x,y-ry),(x+rx,y),(x,y+ry),(x-rx,y)], fill, outline, 1)


def op(origin, direction, along: float, across: float):
    dx, dy = direction
    return (origin[0] + dx*along - dy*across,
            origin[1] + dy*along + dx*across)


def base_layer(level: int) -> Image.Image:
    if level not in (1, 2, 3):
        raise ValueError("Fire Turret base level must be 1, 2 or 3")
    image = Image.new("RGBA", (128, 128), c("transparent"))
    d = ImageDraw.Draw(image)
    d.ellipse((17, 107, 111, 124), fill=c("shadow"))
    poly(d,[(64,83),(92,88),(111,102),(109,114),(91,123),(37,123),(19,114),(17,102),(36,88)],c("outline"))
    poly(d,[(64,87),(90,92),(104,103),(91,117),(37,117),(24,103),(38,92)],c("stone"))
    poly(d,[(64,89),(86,94),(97,103),(86,111),(42,111),(31,103),(42,94)],c("stone_mid"))
    poly(d,[(64,90),(82,95),(90,102),(80,107),(48,107),(38,102),(46,95)],c("stone_light"))
    line(d,(25,105),(40,116),c("stone_dark"),3)
    line(d,(40,116),(88,116),c("stone_dark"),3)
    line(d,(88,116),(103,105),c("stone_dark"),3)
    line(d,(35,111),(93,111),c("bronze"),2)
    for x in (29,99):
        diamond(d,x,105,4,6,c("iron_dark"),c("bronze"))
        d.point((x,103),fill=c("gold"))

    # Static furnace body: an open fire chamber, never rotated with the weapon.
    poly(d,[(43,77),(49,64),(57,58),(71,58),(79,64),(85,77),(82,103),(46,103)],c("outline"))
    poly(d,[(47,77),(53,66),(59,62),(69,62),(75,66),(81,77),(78,99),(50,99)],c("iron"))
    poly(d,[(51,76),(56,68),(64,65),(72,68),(77,76),(74,94),(54,94)],c("iron_dark"))
    poly(d,[(55,79),(59,71),(64,69),(69,71),(73,79),(70,91),(58,91)],c("ember_dark"))
    poly(d,[(58,82),(61,75),(64,73),(68,77),(67,88),(61,89)],c("flame"))
    poly(d,[(62,82),(64,77),(66,82),(65,86),(62,87)],c("fire_white"))
    line(d,(48,82),(53,94),c("iron_light"),2)
    line(d,(80,82),(75,94),c("iron_light"),2)
    for x in (48,80):
        diamond(d,x,87,3,5,c("bronze"),c("outline"))
        d.point((x,86),fill=c("gold"))
    line(d,(52,97),(76,97),c("bronze_light"),2)
    for x in (57,64,71):
        d.point((x,100),fill=c("gold"))
    for x in (42,86):
        poly(d,[(x-4,103),(x-3,93),(x,89),(x+3,93),(x+4,103)],c("outline"))
        poly(d,[(x-2,101),(x-2,94),(x,92),(x+2,94),(x+2,101)],c("bronze"))
        line(d,(x,94),(x,100),c("gold"),1)
    for x,y in ((34,107),(94,107),(49,90),(79,90)):
        d.point((x,y),fill=c("fire_white"))

    if level >= 2:
        for side in (-1,1):
            x=64+side*39
            poly(d,[(x-7,108),(x-6,94),(x,86),(x+6,94),(x+7,108)],c("outline"))
            poly(d,[(x-4,105),(x-4,95),(x,90),(x+4,95),(x+4,105)],c("bronze_dark"))
            line(d,(x,93),(x,103),c("gold"),2)
        poly(d,[(39,81),(47,73),(81,73),(89,81),(83,91),(45,91)],c("outline"))
        poly(d,[(44,81),(50,77),(78,77),(84,81),(78,86),(50,86)],c("iron_light"))
        line(d,(50,82),(78,82),c("gold"),2)
        for x in (51,77):
            diamond(d,x,81,2,3,c("fire_white"))
        line(d,(39,96),(45,105),c("bronze_light"),2)
        line(d,(89,96),(83,105),c("bronze_light"),2)

    if level >= 3:
        poly(d,[(54,67),(56,55),(61,49),(67,49),(72,55),(74,67),(69,76),(59,76)],c("outline"))
        poly(d,[(58,66),(60,56),(64,52),(68,56),(70,66),(66,72),(62,72)],c("bronze"))
        poly(d,[(61,65),(63,57),(65,56),(67,63),(65,69),(62,69)],c("flame"))
        d.point((64,58),fill=c("fire_white"))
        for side in (-1,1):
            x=64+side*45
            poly(d,[(x-6,105),(x-5,89),(x,79),(x+5,89),(x+6,105)],c("outline"))
            poly(d,[(x-3,101),(x-3,89),(x,83),(x+3,89),(x+3,101)],c("iron"))
            line(d,(x,86),(x,99),c("bronze_light"),2)
            d.point((x,84),fill=c("gold"))
        for x in (48,80):
            diamond(d,x,75,4,7,c("bronze"),c("outline"))
            d.point((x,73),fill=c("fire_white"))
        line(d,(44,77),(51,70),c("gold"),2)
        line(d,(77,70),(84,77),c("gold"),2)
        for x in (37,91):
            d.point((x,99),fill=c("flame"))
    return image


def draw_fire_orb(draw: ImageDraw.ImageDraw, origin, direction, along: float, across: float, size: float, heavy=False):
    poly(draw,[op(origin,direction,along-size*.85,across-size*.45),
               op(origin,direction,along-size*.35,across-size*.9),
               op(origin,direction,along+size*.45,across-size*.65),
               op(origin,direction,along+size*.95,across),
               op(origin,direction,along+size*.2,across+size*.8),
               op(origin,direction,along-size*.6,across+size*.55)],c("outline"))
    poly(draw,[op(origin,direction,along-size*.65,across-size*.3),
               op(origin,direction,along-size*.2,across-size*.65),
               op(origin,direction,along+size*.5,across-size*.35),
               op(origin,direction,along+size*.7,across),
               op(origin,direction,along+size*.05,across+size*.55),
               op(origin,direction,along-size*.45,across+size*.35)],c("ember") if heavy else c("flame"))
    poly(draw,[op(origin,direction,along-size*.25,across-size*.2),
               op(origin,direction,along+size*.2,across-size*.25),
               op(origin,direction,along+size*.25,across+size*.2),
               op(origin,direction,along-size*.15,across+size*.25)],c("fire_white"))
    line(draw,op(origin,direction,along-size*1.15,across),
         op(origin,direction,along-size*1.9,across),c("gold"),2)


def weapon_frame(branch: str, direction_index: int) -> Image.Image:
    if branch not in ("base","inferno","sparks") or direction_index not in range(8):
        raise ValueError("Invalid Fire Turret branch or direction")
    image=Image.new("RGBA",(128,128),c("transparent"))
    d=ImageDraw.Draw(image)
    origin=(64.0,90.0)
    direction=(DIRECTIONS[direction_index][0]*0.76,DIRECTIONS[direction_index][1]*0.76)
    poly(d,[op(origin,direction,-12,-15),op(origin,direction,8,-18),
            op(origin,direction,17,-9),op(origin,direction,17,9),
            op(origin,direction,8,18),op(origin,direction,-12,15)],c("outline"))
    poly(d,[op(origin,direction,-10,-12),op(origin,direction,7,-14),
            op(origin,direction,13,-7),op(origin,direction,13,7),
            op(origin,direction,7,14),op(origin,direction,-10,12)],c("iron"))
    line(d,op(origin,direction,-7,-8),op(origin,direction,7,-9),c("iron_light"),2)
    line(d,op(origin,direction,-7,8),op(origin,direction,7,9),c("bronze"),2)
    diamond(d,*op(origin,direction,0,0),5,7,c("bronze"),c("outline"))
    center=op(origin,direction,0,0)
    d.point((q(center[0]),q(center[1]-1)),fill=c("gold"))

    poly(d,[op(origin,direction,5,-9),op(origin,direction,27,-7),
            op(origin,direction,34,-5),op(origin,direction,34,5),
            op(origin,direction,27,7),op(origin,direction,5,9)],c("outline"))
    poly(d,[op(origin,direction,7,-6),op(origin,direction,26,-5),
            op(origin,direction,31,-3),op(origin,direction,31,3),
            op(origin,direction,26,5),op(origin,direction,7,6)],c("bronze_dark"))
    line(d,op(origin,direction,9,-3),op(origin,direction,27,-2),c("bronze_light"),2)
    line(d,op(origin,direction,9,3),op(origin,direction,27,2),c("iron_light"),1)
    for along in (11,24):
        for across in (-6,6):
            diamond(d,*op(origin,direction,along,across),2,3,c("gold"),c("outline"))

    if branch=="base":
        poly(d,[op(origin,direction,31,-7),op(origin,direction,39,-5),
                op(origin,direction,41,0),op(origin,direction,39,5),
                op(origin,direction,31,7)],c("outline"))
        draw_fire_orb(d,origin,direction,43,0,4,False)
    elif branch=="inferno":
        poly(d,[op(origin,direction,29,-10),op(origin,direction,39,-9),
                op(origin,direction,44,-6),op(origin,direction,44,6),
                op(origin,direction,39,9),op(origin,direction,29,10)],c("outline"))
        poly(d,[op(origin,direction,32,-7),op(origin,direction,39,-6),
                op(origin,direction,41,0),op(origin,direction,39,6),
                op(origin,direction,32,7)],c("iron_light"))
        line(d,op(origin,direction,33,-5),op(origin,direction,40,-4),c("gold"),2)
        for across in (-5,5):
            diamond(d,*op(origin,direction,24,across),3,4,c("gold"),c("outline"))
        draw_fire_orb(d,origin,direction,42,0,5.5,True)
    else:
        for across in (-8,0,8):
            poly(d,[op(origin,direction,28,across-3),op(origin,direction,38,across-2),
                    op(origin,direction,40,across),op(origin,direction,38,across+2),
                    op(origin,direction,28,across+3)],c("outline"))
            draw_fire_orb(d,origin,direction,43,across,2.5,False)
        for across in (-13,13):
            line(d,op(origin,direction,16,across),op(origin,direction,25,across),c("bronze_light"),2)

    poly(d,[op(origin,direction,-8,-7),op(origin,direction,-15,0),
            op(origin,direction,-8,7),op(origin,direction,0,0)],c("outline"))
    poly(d,[op(origin,direction,-8,-4),op(origin,direction,-11,0),
            op(origin,direction,-8,4),op(origin,direction,-2,0)],c("ember"))
    d.point((q(origin[0]),q(origin[1]-8)),fill=c("fire_white"))
    return image


def projectile_frame(branch: str, frame: int) -> Image.Image:
    image=Image.new("RGBA",(32,32),c("transparent"))
    d=ImageDraw.Draw(image)
    progress=frame/7.0
    cx=7+frame*2.1
    cy=16+(1 if frame%2 else 0)
    alpha=245-frame*16
    line(d,(max(1,q(cx-9-progress)),q(cy+1)),(q(cx-3),q(cy+1)),c("gold",alpha),2)
    if branch=="base":
        draw_fire_orb(d,(cx,cy),(1.0,0.0),0,0,3.4,False)
    elif branch=="inferno":
        draw_fire_orb(d,(cx,cy),(1.0,0.0),0,0,5.2,True)
    else:
        for across in (-4,0,4):
            draw_fire_orb(d,(cx,cy),(1.0,0.0),0,across,1.8,False)
    d.point((q(cx+3),q(cy-4-progress)),fill=c("fire_white",alpha))
    return image


def impact_frame(branch: str, frame: int) -> Image.Image:
    image=Image.new("RGBA",(64,64),c("transparent"))
    d=ImageDraw.Draw(image)
    progress=frame/7.0
    cx=cy=32
    radius=4+frame*3
    alpha=max(45,245-frame*26)
    d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=c("gold",alpha),width=2)
    count={"base":6,"inferno":10,"sparks":8}[branch]
    for index in range(count):
        angle=math.tau*index/count+progress*.22
        distance=radius+2+(index%2)*2
        x=cx+math.cos(angle)*distance
        y=cy+math.sin(angle)*distance
        draw_fire_orb(d,(x,y),(math.cos(angle),math.sin(angle)),0,0,
                      2+frame//3+(2 if branch=="inferno" else 0),branch=="inferno")
    if branch=="sparks":
        for offset in (-7,0,7):
            diamond(d,cx+offset,cy,2,5,c("flame",alpha))
    diamond(d,cx,cy,max(2,7-frame//2),max(2,8-frame//2),c("ember",alpha),c("outline",alpha))
    d.point((cx,cy-2),fill=c("fire_white",alpha))
    for index in range(4):
        x=5+((frame*11+index*13)%54)
        y=5+((frame*7+index*17)%54)
        d.point((x,y),fill=c("gold",max(35,alpha-50)))
    return image


def strip(frames: list[Image.Image]) -> Image.Image:
    if not frames:
        raise ValueError("Cannot create an empty atlas")
    width,height=frames[0].size
    atlas=Image.new("RGBA",(width*len(frames),height),c("transparent"))
    for index,frame in enumerate(frames):
        if frame.size!=(width,height):
            raise ValueError("Atlas frames must share dimensions")
        atlas.alpha_composite(frame,(index*width,0))
    return atlas


def manifest_data() -> dict:
    branches=("base","inferno","sparks")
    return {
        "schema_version":1,"id":"fire","display_name":"Огненная турель",
        "status":"review_candidate","runtime_enabled":False,
        "camera":"top_down_3_quarter",
        "canvas":{"width":128,"height":128,"pivot":[64,90],"ground_anchor":[64,118]},
        "direction_order":DIRECTION_ORDER,
        "specialization_branches":{"siege":"inferno","swarm":"sparks"},
        "specialization_labels":{"siege":"ИНФЕРНО: ПЛАМЯ","swarm":"ИСКРЫ: 3 ЦЕЛИ"},
        "base":{"levels":{str(n):f"candidate/base/level_{n}.png" for n in (1,2,3)},"frame_size":[128,128],"anchor":"ground_anchor"},
        "weapon":{branch:{"path":f"candidate/weapon/{branch}/weapon_8way.png","frame_size":[128,128],"frame_count":8,"direction_order":DIRECTION_ORDER,"pivot":[64,90],"forward_direction":"north"} for branch in branches},
        "projectiles":{branch:{"path":f"candidate/vfx/{branch}_projectile_8f.png","frame_size":[32,32],"frame_count":8,"fps":24,"loop":True,"forward_axis":"+X"} for branch in branches},
        "impacts":{branch:{"path":f"candidate/vfx/{branch}_impact_8f.png","frame_size":[64,64],"frame_count":8,"fps":24,"loop":False} for branch in branches},
        "source":{"editable_project":"tools/generate_fire_turret_modular_candidates.py","provenance":"candidate/SOURCE.md","editable_project_status":"procedural_source_is_tools/generate_fire_turret_modular_candidates.py"},
        "notes":[
            "Review-only Pixel Art candidate; owner approval is required before production use.",
            "runtime_enabled is false; original Foozle fire assets and live gameplay are unchanged.",
            "siege maps to inferno (heavy flame cannon and explosive impact); swarm maps to sparks (three-target spark volley).",
            "All eight weapon poses are individually rasterized from directional geometry and share one pivot.",
            "The reproducible editable source is tools/generate_fire_turret_modular_candidates.py; no Aseprite project is claimed.",
            "Gameplay ID remains fire. Do not migrate saves, change combat values or replace legacy source PNGs in this art-only candidate."
        ],
    }


def generate_assets(output_root: Path) -> list[Path]:
    candidate=output_root/"candidate"
    for folder in ("base","weapon","vfx"):
        (candidate/folder).mkdir(parents=True,exist_ok=True)
    written=[]
    for level in (1,2,3):
        path=candidate/"base"/f"level_{level}.png"
        base_layer(level).save(path,optimize=False)
        written.append(path)
    for branch in ("base","inferno","sparks"):
        weapon_dir=candidate/"weapon"/branch
        weapon_dir.mkdir(parents=True,exist_ok=True)
        weapon_path=weapon_dir/"weapon_8way.png"
        strip([weapon_frame(branch,index) for index in range(8)]).save(weapon_path,optimize=False)
        written.append(weapon_path)
        projectile=candidate/"vfx"/f"{branch}_projectile_8f.png"
        impact=candidate/"vfx"/f"{branch}_impact_8f.png"
        strip([projectile_frame(branch,index) for index in range(8)]).save(projectile,optimize=False)
        strip([impact_frame(branch,index) for index in range(8)]).save(impact,optimize=False)
        written.extend((projectile,impact))
    manifest=output_root/"manifest.json"
    manifest.write_text(json.dumps(manifest_data(),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    written.append(manifest)
    source=candidate/"SOURCE.md"
    source.write_text(
        "# Огненная турель — исходники модульного Pixel Art\n\n"
        "Статус: **review candidate**, не production. Владелец ещё не утверждал этот набор.\n\n"
        "Редактируемый воспроизводимый источник: tools/generate_fire_turret_modular_candidates.py. "
        "Он создаёт три основания 128×128, три восьминаправленных оружейных атласа и шесть VFX strips "
        "с прозрачным RGBA фоном.\n\n"
        "Ветки: base (одиночный огненный заряд), inferno (тяжёлое пламя, siege), "
        "sparks (залп трёх искр, swarm). Runtime mapping: siege → inferno, swarm → sparks. "
        "Pivot оружия (64,90), ground anchor основания (64,118), направления N, NE, E, SE, S, SW, W, NW.\n\n"
        "Кандидатные ресурсы не загружаются игровым рендерером: runtime_enabled=false. "
        "Существующие Foozle PNG не изменены. Aseprite-файл не создан и не заявляется.\n",
        encoding="utf-8")
    written.append(source)
    return written


def verify_assets() -> None:
    with tempfile.TemporaryDirectory(prefix="fire-turret-candidate-") as temp:
        root=Path(temp)
        generated=generate_assets(root)
        for path in generated:
            relative=path.relative_to(root)
            committed=ART/relative
            if not committed.is_file():
                raise SystemExit(f"Missing committed Fire Turret candidate: {committed}")
            if hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256(committed.read_bytes()).digest():
                raise SystemExit(f"Non-reproducible Fire Turret candidate: {committed}")
        expected={path.relative_to(root) for path in generated}
        actual={
            path.relative_to(ART) for path in ART.rglob("*")
            if path.is_file() and (path.parts[len(ART.parts)]=="candidate" or path.name=="manifest.json")
            and path.suffix.lower() in {".png",".json",".md"} and "review" not in path.parts
        }
        if actual!=expected:
            raise SystemExit(f"Candidate file set differs: extra={sorted(map(str,actual-expected))}, missing={sorted(map(str,expected-actual))}")
    print("Fire Turret modular source is reproducible.")


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write",action="store_true")
    mode.add_argument("--verify",action="store_true")
    args=parser.parse_args()
    if args.write:
        print(f"Wrote {len(generate_assets(ART))} reproducible Fire Turret candidate files.")
    else:
        verify_assets()


if __name__=="__main__":
    main()
