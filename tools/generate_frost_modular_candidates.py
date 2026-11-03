#!/usr/bin/env python3
"""Generate review-only modular Frost Obelisk Pixel Art assets.

This procedural Pillow source is editable and reproducible. Generated art is
candidate-only; owner approval and a separate runtime PR are required.
"""
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
ART = ROOT / "assets/spire/towers/frost"
DIRECTIONS = (
    (0.0, -1.0), (0.7071, -0.7071), (1.0, 0.0), (0.7071, 0.7071),
    (0.0, 1.0), (-0.7071, 0.7071), (-1.0, 0.0), (-0.7071, -0.7071),
)
DIRECTION_ORDER = ["north", "north_east", "east", "south_east",
                   "south", "south_west", "west", "north_west"]
P = {
    "outline": (9, 22, 39, 255), "shadow": (13, 29, 47, 255),
    "stone_dark": (22, 47, 69, 255), "stone": (35, 75, 101, 255),
    "stone_mid": (53, 105, 135, 255), "stone_light": (87, 148, 171, 255),
    "ice_dark": (20, 91, 129, 255), "ice": (42, 166, 204, 255),
    "ice_mid": (82, 204, 229, 255), "ice_light": (154, 237, 249, 255),
    "ice_white": (231, 253, 255, 255), "rune": (55, 209, 231, 255),
    "gold": (191, 157, 94, 255), "gold_light": (242, 211, 145, 255),
    "transparent": (0, 0, 0, 0),
}


def color(name: str, alpha: int | None = None) -> tuple[int, int, int, int]:
    c = P[name]
    return c if alpha is None else (*c[:3], max(0, min(255, alpha)))


def q(v: float) -> int:
    return int(math.floor(v + 0.5))


def poly(d: ImageDraw.ImageDraw, points: Iterable[tuple[float, float]],
         fill: tuple[int, int, int, int], outline=None, width: int = 2) -> None:
    pts = [(q(x), q(y)) for x, y in points]
    d.polygon(pts, fill=fill)
    if outline is not None:
        d.line(pts + [pts[0]], fill=outline, width=width)


def ln(d: ImageDraw.ImageDraw, a, b, fill, width: int = 1) -> None:
    d.line((q(a[0]), q(a[1]), q(b[0]), q(b[1])), fill=fill, width=width)


def diamond(d: ImageDraw.ImageDraw, x: float, y: float, rx: int, ry: int, fill, outline=None) -> None:
    poly(d, [(x, y-ry), (x+rx, y), (x, y+ry), (x-rx, y)], fill, outline, 1)


def base_layer(level: int) -> Image.Image:
    if level not in (1, 2, 3):
        raise ValueError("Frost base level must be 1, 2 or 3")
    im = Image.new("RGBA", (128, 128), color("transparent"))
    d = ImageDraw.Draw(im)
    d.ellipse((20, 105, 108, 123), fill=color("shadow"))
    poly(d, [(64,87),(93,93),(111,105),(108,113),(91,120),(37,120),(20,113),(17,105),(35,93)], color("outline"))
    poly(d, [(64,91),(91,96),(105,106),(91,115),(37,115),(23,106),(37,96)], color("stone"))
    poly(d, [(64,93),(88,98),(98,105),(88,110),(40,110),(30,105),(40,98)], color("stone_mid"))
    poly(d, [(64,94),(86,99),(92,104),(80,108),(48,108),(36,104),(42,99)], color("stone_light"))
    ln(d,(25,107),(39,115),color("stone_dark"),3)
    ln(d,(39,115),(89,115),color("stone_dark"),3)
    ln(d,(89,115),(103,107),color("stone_dark"),3)
    ln(d,(38,111),(90,111),color("ice_mid"),1)
    for x in (35,48,64,80,93):
        diamond(d,x,108,2,3,color("ice_dark"))
        d.point((x,107),fill=color("ice_white"))

    poly(d,[(48,82),(80,82),(88,94),(81,105),(47,105),(40,94)],color("outline"))
    poly(d,[(51,84),(77,84),(83,94),(77,101),(51,101),(45,94)],color("stone_mid"))
    poly(d,[(54,84),(74,84),(79,92),(49,92)],color("stone_light"))
    ln(d,(49,93),(79,93),color("ice_light"),1)
    poly(d,[(54,96),(74,96),(70,103),(58,103)],color("stone_dark"))
    ln(d,(58,99),(70,99),color("rune"),1)
    for side in (-1,1):
        x=64+side*29
        poly(d,[(x-5,96),(x,93),(x+5,96),(x,103)],color("outline"))
        diamond(d,x,98,3,4,color("ice"))
        d.point((x,97),fill=color("ice_white"))
        ln(d,(x-2,105),(x+2,105),color("gold"),1)

    if level >= 2:
        for side in (-1,1):
            x=64+side*39
            poly(d,[(x-7,101),(x-5,89),(x,84),(x+5,89),(x+7,101)],color("outline"))
            poly(d,[(x-4,98),(x-3,90),(x,87),(x+3,90),(x+4,98)],color("ice_dark"))
            ln(d,(x,90),(x,98),color("ice_light"),2)
            d.point((x,88),fill=color("ice_white"))
            ln(d,(x-4,102),(x+4,102),color("gold"),1)
        poly(d,[(43,88),(50,78),(78,78),(85,88),(78,95),(50,95)],color("outline"))
        poly(d,[(48,87),(53,81),(75,81),(80,87),(74,91),(54,91)],color("stone_light"))
        ln(d,(54,89),(74,89),color("ice_mid"),2)

    if level >= 3:
        for side in (-1,1):
            x=64+side*45
            poly(d,[(x-6,100),(x-5,87),(x,78),(x+5,87),(x+6,100)],color("outline"))
            poly(d,[(x-3,96),(x-3,87),(x,81),(x+3,87),(x+3,96)],color("ice"))
            ln(d,(x,83),(x,95),color("ice_white"),1)
            d.point((x+side,88),fill=color("ice_light"))
        for side in (-1,1):
            x=64+side*17
            diamond(d,x,82,5,9,color("ice_dark"),color("outline"))
            ln(d,(x,76),(x,85),color("ice_light"),2)
            d.point((x,75),fill=color("ice_white"))
        ln(d,(47,77),(55,72),color("gold"),1)
        ln(d,(73,72),(81,77),color("gold"),1)
        for x in (52,76):
            d.point((x,73),fill=color("gold_light"))
    for x,y in ((29,101),(99,101),(43,92),(85,92)):
        d.point((x,y),fill=color("ice_white"))
    return im


def op(origin, direction, along: float, across: float):
    dx,dy=direction
    return (origin[0]+dx*along-dy*across, origin[1]+dy*along+dx*across)


def crystal(d, origin, direction, along: float, across: float,
            length: float, width: float, fill, inner) -> None:
    tip=op(origin,direction,along+length*.58,across)
    a=op(origin,direction,along,across+width)
    rear=op(origin,direction,along-length*.42,across)
    b=op(origin,direction,along,across-width)
    poly(d,[tip,a,rear,b],fill,color("outline"),2)
    it=op(origin,direction,along+length*.42,across)
    ia=op(origin,direction,along,across+width*.48)
    ib=op(origin,direction,along-length*.28,across)
    poly(d,[it,ia,ib],inner)
    glint=op(origin,direction,along+length*.22,across-width*.16)
    d.point((q(glint[0]),q(glint[1])),fill=color("ice_white"))


def weapon_frame(branch: str, direction_index: int) -> Image.Image:
    if branch not in ("base","frost_lance","blizzard") or direction_index not in range(8):
        raise ValueError("Invalid Frost weapon branch or direction")
    im=Image.new("RGBA",(128,128),color("transparent"))
    d=ImageDraw.Draw(im)
    origin=(64.0,90.0)
    direction=DIRECTIONS[direction_index]
    for side in (-1,1):
        a=op(origin,direction,-7,side*7)
        b=op(origin,direction,-15,side*10)
        c=op(origin,direction,-11,side*3)
        poly(d,[a,b,c],color("outline"))
        ln(d,b,c,color("ice_mid"),1)
    start=op(origin,direction,-9,0)
    end=op(origin,direction,22,0)
    ln(d,start,end,color("outline"),8)
    ln(d,start,end,color("stone_mid"),5)
    ln(d,op(origin,direction,-5,-1),op(origin,direction,18,-1),color("ice_light"),2)

    if branch=="base":
        crystal(d,origin,direction,29,0,25,7,color("ice_dark"),color("ice_mid"))
    elif branch=="frost_lance":
        crystal(d,origin,direction,31,0,34,11,color("ice_dark"),color("ice_light"))
        for side in (-1,1):
            crystal(d,origin,direction,17,side*9,15,4,color("ice"),color("ice_white"))
        ln(d,op(origin,direction,7,-7),op(origin,direction,7,7),color("gold_light"),2)
    else:
        crystal(d,origin,direction,26,0,20,5,color("ice_dark"),color("ice_light"))
        for side in (-1,1):
            crystal(d,origin,direction,23,side*10,15,4,color("ice"),color("ice_white"))
            crystal(d,origin,direction,34,side*15,10,3,color("ice_mid"),color("ice_white"))

    d.ellipse((55,81,73,99),fill=color("outline"))
    d.ellipse((58,84,70,96),fill=color("stone_mid"))
    d.ellipse((60,86,68,94),fill=color("ice_dark"))
    d.point((63,87),fill=color("ice_white"))
    tick=op(origin,direction,-1,-11)
    d.point((q(tick[0]),q(tick[1])),fill=color("gold_light"))
    return im


def projectile_frame(branch: str, frame: int) -> Image.Image:
    im=Image.new("RGBA",(32,32),color("transparent"))
    d=ImageDraw.Draw(im)
    progress=frame/7.0
    cx=8+frame*1.8
    cy=16+(1 if frame%2 else -1)
    alpha=220-frame*12
    ln(d,(max(1,cx-10),cy+1),(cx-3,cy+1),color("ice_mid",alpha),2)
    d.point((q(cx-7),q(cy-2)),fill=color("ice_white",alpha//2))
    if branch=="base":
        crystal(d,(cx,cy),(1.0,0.0),0,0,13,4,color("ice_dark",alpha),color("ice_white",alpha))
    elif branch=="frost_lance":
        crystal(d,(cx,cy),(1.0,0.0),0,0,17,6,color("ice_dark",alpha),color("ice_light",alpha))
        d.point((q(cx-1),q(cy+6)),fill=color("ice_white",alpha))
    else:
        for offset in (-5,0,5):
            crystal(d,(cx,cy),(1.0,0.0),0,offset,9,2,color("ice",alpha),color("ice_white",alpha))
    d.point((q(cx+2),q(cy-2-progress)),fill=color("ice_white",alpha))
    return im


def impact_frame(branch: str, frame: int) -> Image.Image:
    im=Image.new("RGBA",(64,64),color("transparent"))
    d=ImageDraw.Draw(im)
    progress=frame/7.0
    cx=cy=32
    radius=4+frame*3
    alpha=max(50,245-frame*25)
    d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=color("ice_mid",alpha),width=2)
    d.ellipse((cx-max(1,radius-3),cy-max(1,radius-3),
               cx+max(1,radius-3),cy+max(1,radius-3)),
              outline=color("ice_dark",alpha//2),width=1)
    count={"base":6,"frost_lance":8,"blizzard":12}[branch]
    for index in range(count):
        angle=(math.tau*index/count)+(progress*.22)
        distance=radius+2+(index%2)*2
        x=cx+math.cos(angle)*distance
        y=cy+math.sin(angle)*distance
        direction=(math.cos(angle),math.sin(angle))
        size=3+frame//3+(1 if branch=="frost_lance" else 0)
        crystal(d,(x,y),direction,0,0,size*2,size,color("ice_dark",alpha),color("ice_white",alpha))
    center_size=max(2,7-frame//2)
    diamond(d,cx,cy,center_size,center_size+2,color("ice",alpha),color("outline",alpha))
    d.point((cx,cy-2),fill=color("ice_white",alpha))
    for index in range(3):
        x=8+((frame*7+index*17)%48)
        y=7+((frame*5+index*11)%50)
        d.point((x,y),fill=color("ice_light",max(40,alpha-50)))
    return im


def strip(frames: list[Image.Image]) -> Image.Image:
    if not frames:
        raise ValueError("Cannot create an empty atlas")
    w,h=frames[0].size
    result=Image.new("RGBA",(w*len(frames),h),color("transparent"))
    for index,frame in enumerate(frames):
        if frame.size!=(w,h):
            raise ValueError("Atlas frames must share a common size")
        result.alpha_composite(frame,(index*w,0))
    return result


def manifest_data() -> dict:
    branches=("base","frost_lance","blizzard")
    weapon={}
    projectiles={}
    impacts={}
    for branch in branches:
        weapon[branch]={
            "path":f"candidate/weapon/{branch}/weapon_8way.png",
            "frame_size":[128,128],"frame_count":8,
            "direction_order":DIRECTION_ORDER,"pivot":[64,90],
            "forward_direction":"north",
        }
        projectiles[branch]={
            "path":f"candidate/vfx/{branch}_projectile_8f.png",
            "frame_size":[32,32],"frame_count":8,"fps":24,
            "loop":True,"forward_axis":"+X",
        }
        impacts[branch]={
            "path":f"candidate/vfx/{branch}_impact_8f.png",
            "frame_size":[64,64],"frame_count":8,"fps":24,"loop":False,
        }
    return {
        "schema_version":1,"id":"frost","display_name":"Ледяной обелиск",
        "status":"review_candidate","runtime_enabled":False,
        "camera":"top_down_3_quarter",
        "canvas":{"width":128,"height":128,"pivot":[64,90],"ground_anchor":[64,118]},
        "direction_order":DIRECTION_ORDER,
        "specialization_branches":{"siege":"frost_lance","swarm":"blizzard"},
        "specialization_labels":{"siege":"МОРОЗ: СИЛЬНЕЕ","swarm":"МЕТЕЛЬ: БЫСТРЕЕ"},
        "base":{"levels":{str(n):f"candidate/base/level_{n}.png" for n in (1,2,3)},
                "frame_size":[128,128],"anchor":"ground_anchor"},
        "weapon":weapon,"projectiles":projectiles,"impacts":impacts,
        "source":{"editable_project":"source/layers/README.md",
                  "provenance":"candidate/SOURCE.md",
                  "editable_project_status":"procedural_source_is_tools/generate_frost_modular_candidates.py"},
        "notes":[
            "Review-only Pixel Art candidate; owner approval is required before production use.",
            "runtime_enabled is false; live Frost renderer and all combat values are unchanged.",
            "siege maps to frost_lance (heavy single-target crystal); swarm maps to blizzard (multi-shard fan).",
            "All eight weapon poses are individually rasterized from directional geometry, not copied or rotated from one finished sprite.",
            "The reproducible editable source is tools/generate_frost_modular_candidates.py; no Aseprite project is claimed.",
            "Existing Spark placeholder art and current Frost experimental art remain untouched pending approval and a separate runtime PR.",
        ],
    }


def generate_assets(output_root: Path) -> list[Path]:
    candidate=output_root/"candidate"
    (candidate/"base").mkdir(parents=True,exist_ok=True)
    (candidate/"weapon").mkdir(parents=True,exist_ok=True)
    (candidate/"vfx").mkdir(parents=True,exist_ok=True)
    written=[]
    for level in (1,2,3):
        path=candidate/"base"/f"level_{level}.png"
        base_layer(level).save(path,optimize=False)
        written.append(path)
    for branch in ("base","frost_lance","blizzard"):
        folder=candidate/"weapon"/branch
        folder.mkdir(parents=True,exist_ok=True)
        weapon_path=folder/"weapon_8way.png"
        strip([weapon_frame(branch,i) for i in range(8)]).save(weapon_path,optimize=False)
        written.append(weapon_path)
        projectile_path=candidate/"vfx"/f"{branch}_projectile_8f.png"
        impact_path=candidate/"vfx"/f"{branch}_impact_8f.png"
        strip([projectile_frame(branch,i) for i in range(8)]).save(projectile_path,optimize=False)
        strip([impact_frame(branch,i) for i in range(8)]).save(impact_path,optimize=False)
        written.extend((projectile_path,impact_path))
    manifest_path=output_root/"manifest.json"
    manifest_path.write_text(json.dumps(manifest_data(),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    written.append(manifest_path)
    source_path=candidate/"SOURCE.md"
    source_path.write_text(
        "# Ледяной обелиск — исходники модульного Pixel Art\n\n"
        "Статус: **review candidate**, не production. Владелец ещё не утверждал этот набор.\n\n"
        "Редактируемый источник: tools/generate_frost_modular_candidates.py. Он процедурно рисует "
        "каждый пиксель, сохраняет прозрачный RGBA PNG и воспроизводит 3 основания, 3 восьминаправленных "
        "оружейных атласа и 6 VFX strips.\n\n"
        "Пивот оружия: (64, 90); опорная точка основания: (64, 118). Порядок направлений: "
        "N, NE, E, SE, S, SW, W, NW. Специализация siege — «Мороз» (тяжёлое копьё), "
        "swarm — «Метель» (веер осколков).\n\n"
        "Aseprite-файл не создан и не заявляется. Для изменения геометрии редактируйте Python-генератор. "
        "Кандидатные ресурсы не загружаются игровым рендерером: runtime_enabled=false.\n",
        encoding="utf-8")
    written.append(source_path)
    return written


def verify_assets() -> None:
    with tempfile.TemporaryDirectory(prefix="frost-obelisk-") as temp:
        temp_root=Path(temp)
        generated=generate_assets(temp_root)
        for generated_path in generated:
            relative=generated_path.relative_to(temp_root)
            committed=ART/relative
            if not committed.is_file():
                raise SystemExit(f"Missing committed Frost candidate: {committed}")
            if hashlib.sha256(generated_path.read_bytes()).digest()!=hashlib.sha256(committed.read_bytes()).digest():
                raise SystemExit(f"Non-reproducible Frost candidate: {committed}")
        expected={p.relative_to(temp_root) for p in generated}
        actual={
            p.relative_to(ART) for p in ART.rglob("*")
            if p.is_file() and (
                p.parts[len(ART.parts)]=="candidate" or p.name=="manifest.json"
            ) and p.suffix.lower() in {".png",".json",".md"} and "review" not in p.parts
        }
        if actual!=expected:
            raise SystemExit(f"Candidate file set differs: extra={sorted(map(str,actual-expected))}, missing={sorted(map(str,expected-actual))}")
    print("Frost Obelisk modular source is reproducible.")


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write",action="store_true",help="Generate review-only candidate assets")
    mode.add_argument("--verify",action="store_true",help="Regenerate in temp folder and compare SHA-256")
    args=parser.parse_args()
    if args.write:
        print(f"Wrote {len(generate_assets(ART))} reproducible Frost candidate files.")
    else:
        verify_assets()


if __name__=="__main__":
    main()
