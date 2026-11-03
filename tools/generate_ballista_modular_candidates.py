#!/usr/bin/env python3
"""Generate review-only modular Bone Ballista Pixel Art assets."""
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
ART = ROOT / "assets/spire/towers/ballista"
CANDIDATE = ART / "candidate"
DIRECTIONS = (
    (0.0, -1.0), (0.7071, -0.7071), (1.0, 0.0), (0.7071, 0.7071),
    (0.0, 1.0), (-0.7071, 0.7071), (-1.0, 0.0), (-0.7071, -0.7071),
)
DIRECTION_ORDER = ["north", "north_east", "east", "south_east",
                   "south", "south_west", "west", "north_west"]
P = {
    "outline": (18, 22, 30, 255), "shadow": (20, 24, 31, 255),
    "stone_dark": (36, 47, 57, 255), "stone": (57, 70, 78, 255),
    "stone_mid": (83, 97, 101, 255), "stone_light": (124, 133, 126, 255),
    "wood_dark": (56, 32, 27, 255), "wood": (101, 57, 38, 255),
    "wood_mid": (145, 84, 48, 255), "wood_light": (190, 126, 69, 255),
    "bronze_dark": (78, 49, 34, 255), "bronze": (151, 105, 59, 255),
    "gold": (205, 163, 94, 255), "gold_light": (238, 205, 139, 255),
    "bone_dark": (104, 78, 56, 255), "bone": (190, 163, 122, 255),
    "bone_light": (224, 204, 165, 255), "bone_white": (246, 233, 204, 255),
    "bolt_dark": (70, 43, 31, 255), "bolt": (157, 112, 70, 255),
    "spark": (255, 219, 151, 255), "transparent": (0, 0, 0, 0),
}


def color(name: str, alpha: int | None = None):
    c = P[name]
    return c if alpha is None else (*c[:3], max(0, min(255, alpha)))


def q(v: float) -> int:
    return int(math.floor(v + 0.5))


def poly(d: ImageDraw.ImageDraw, points: Iterable[tuple[float, float]], fill, outline=None, width=2):
    pts = [(q(x), q(y)) for x, y in points]
    d.polygon(pts, fill=fill)
    if outline is not None:
        d.line(pts + [pts[0]], fill=outline, width=width)


def ln(d: ImageDraw.ImageDraw, a, b, fill, width=1):
    d.line((q(a[0]), q(a[1]), q(b[0]), q(b[1])), fill=fill, width=width)


def diamond(d: ImageDraw.ImageDraw, x, y, rx, ry, fill, outline=None):
    poly(d, [(x, y-ry), (x+rx, y), (x, y+ry), (x-rx, y)], fill, outline, 1)


def op(origin, direction, along: float, across: float):
    dx, dy = direction
    return (origin[0] + dx*along - dy*across,
            origin[1] + dy*along + dx*across)


def base_layer(level: int) -> Image.Image:
    if level not in (1, 2, 3):
        raise ValueError("Ballista base level must be 1, 2 or 3")
    im = Image.new("RGBA", (128, 128), color("transparent"))
    d = ImageDraw.Draw(im)
    d.ellipse((17, 106, 111, 124), fill=color("shadow"))
    poly(d, [(64,82),(94,89),(112,103),(109,115),(91,123),(37,123),(19,115),(16,103),(34,89)], color("outline"))
    poly(d, [(64,86),(91,92),(105,104),(91,117),(37,117),(23,104),(37,92)], color("stone"))
    poly(d, [(64,88),(88,94),(98,104),(87,112),(41,112),(30,104),(40,94)], color("stone_mid"))
    poly(d, [(64,89),(84,95),(91,103),(80,108),(48,108),(37,103),(44,95)], color("stone_light"))
    ln(d,(25,106),(39,116),color("stone_dark"),3)
    ln(d,(39,116),(89,116),color("stone_dark"),3)
    ln(d,(89,116),(103,106),color("stone_dark"),3)
    ln(d,(36,111),(92,111),color("bronze"),2)
    poly(d,[(46,78),(82,78),(91,91),(84,105),(44,105),(37,91)],color("outline"))
    poly(d,[(50,81),(78,81),(85,92),(78,100),(50,100),(43,92)],color("wood"))
    poly(d,[(53,82),(75,82),(80,90),(48,90)],color("wood_light"))
    poly(d,[(48,93),(80,93),(75,102),(53,102)],color("wood_dark"))
    ln(d,(49,94),(79,94),color("bronze"),2)
    ln(d,(53,98),(75,98),color("gold"),1)
    for x in (44,84):
        diamond(d,x,96,3,5,color("bronze"),color("outline"))
        d.point((x,95),fill=color("gold_light"))
    for x in (35,93):
        diamond(d,x,108,3,4,color("bone_dark"))
        d.point((x,107),fill=color("bone_light"))
    for side in (-1, 1):
        x = 64 + side*19
        poly(d,[(x-4,91),(x-2,85),(x+2,83),(x+4,91),(x+1,98),(x-3,98)],color("bone_dark"),color("outline"),1)
        ln(d,(x,86),(x,95),color("bone_light"),2)
        d.point((x,85),fill=color("bone_white"))
    if level >= 2:
        for side in (-1, 1):
            x = 64 + side*39
            poly(d,[(x-7,108),(x-6,96),(x,89),(x+6,96),(x+7,108)],color("outline"))
            poly(d,[(x-4,105),(x-4,97),(x,92),(x+4,97),(x+4,105)],color("bronze"))
            ln(d,(x,94),(x,103),color("gold_light"),1)
        poly(d,[(40,84),(48,76),(80,76),(88,84),(82,92),(46,92)],color("outline"))
        poly(d,[(45,84),(51,79),(77,79),(83,84),(77,88),(51,88)],color("wood_mid"))
        ln(d,(51,85),(77,85),color("gold"),2)
        for x in (48,80):
            d.point((x,82),fill=color("gold_light"))
    if level >= 3:
        poly(d,[(56,83),(59,70),(64,64),(69,70),(72,83),(68,91),(60,91)],color("outline"))
        poly(d,[(59,82),(61,72),(64,68),(67,72),(69,82),(66,87),(62,87)],color("bone"))
        ln(d,(64,70),(64,84),color("bone_white"),2)
        d.point((64,69),fill=color("gold_light"))
        for side in (-1,1):
            x=64+side*46
            poly(d,[(x-5,108),(x-4,94),(x,86),(x+4,94),(x+5,108)],color("outline"))
            poly(d,[(x-2,104),(x-2,95),(x,90),(x+2,95),(x+2,104)],color("bone_dark"))
            ln(d,(x,92),(x,102),color("bone_light"),2)
        for x in (48,80):
            diamond(d,x,75,4,7,color("bronze"),color("outline"))
            d.point((x,73),fill=color("gold_light"))
        ln(d,(43,78),(51,72),color("gold"),2)
        ln(d,(77,72),(85,78),color("gold"),2)
    for x,y in ((27,103),(101,103),(42,91),(86,91)):
        d.point((x,y),fill=color("bone_white"))
    return im


def draw_bolt(d: ImageDraw.ImageDraw, origin, direction, along: float, across: float, length: float, thickness: float, heavy: bool=False):
    tip = op(origin,direction,along+length*.58,across)
    tail = op(origin,direction,along-length*.42,across)
    a = op(origin,direction,along+length*.10,across+thickness)
    b = op(origin,direction,along+length*.10,across-thickness)
    poly(d,[tip,a,tail,b],color("outline"))
    poly(d,[tip,a,tail],color("bone") if heavy else color("bolt"))
    poly(d,[op(origin,direction,along+length*.42,across),op(origin,direction,along+length*.06,across+thickness*.45),op(origin,direction,along-length*.22,across)],color("bone_white") if heavy else color("wood_light"))
    for side in (-1,1):
        a=op(origin,direction,along-length*.35,across)
        b=op(origin,direction,along-length*.52,across+side*thickness*1.6)
        c=op(origin,direction,along-length*.28,across+side*thickness*.25)
        poly(d,[a,b,c],color("bone_dark"))
        ln(d,b,c,color("bone_light"),1)
    if heavy:
        ln(d,op(origin,direction,along+length*.20,across),op(origin,direction,along+length*.46,across),color("gold_light"),1)


def weapon_frame(branch: str, direction_index: int) -> Image.Image:
    if branch not in ("base","siege_bolt","bone_volley") or direction_index not in range(8):
        raise ValueError("Invalid Ballista branch or direction")
    im=Image.new("RGBA",(128,128),color("transparent"))
    d=ImageDraw.Draw(im)
    origin=(64.0,90.0)
    direction=DIRECTIONS[direction_index]
    ln(d,op(origin,direction,0,0),op(origin,direction,31,0),color("outline"),10)
    ln(d,op(origin,direction,1,0),op(origin,direction,29,0),color("wood_dark"),7)
    ln(d,op(origin,direction,4,-1),op(origin,direction,25,-1),color("wood_light"),2)
    ln(d,op(origin,direction,4,1),op(origin,direction,25,1),color("bronze"),1)
    limb_points=[op(origin,direction,15,-27),op(origin,direction,12,-24),op(origin,direction,9,-15),op(origin,direction,10,-7),op(origin,direction,14,0),op(origin,direction,10,7),op(origin,direction,9,15),op(origin,direction,12,24),op(origin,direction,15,27)]
    poly(d,limb_points,color("outline"))
    inner=[op(origin,direction,15,-24),op(origin,direction,12,-21),op(origin,direction,12,-14),op(origin,direction,13,-7),op(origin,direction,16,0),op(origin,direction,13,7),op(origin,direction,12,14),op(origin,direction,12,21),op(origin,direction,15,24)]
    poly(d,inner,color("wood_mid"))
    ln(d,op(origin,direction,13,-20),op(origin,direction,14,-3),color("wood_light"),2)
    ln(d,op(origin,direction,14,3),op(origin,direction,13,20),color("gold"),2)
    ln(d,op(origin,direction,15,-25),op(origin,direction,15,25),color("bone_light"),1)
    ln(d,op(origin,direction,15,-25),op(origin,direction,15,25),color("bone_white"),1)
    ln(d,op(origin,direction,12,-4),op(origin,direction,18,4),color("outline"),3)
    ln(d,op(origin,direction,12,4),op(origin,direction,18,-4),color("bronze"),2)
    diamond(d,*op(origin,direction,15,0),5,7,color("gold"),color("outline"))
    center=op(origin,direction,15,0)
    d.point((q(center[0]),q(center[1]-1)),fill=color("gold_light"))
    if branch=="base":
        draw_bolt(d,origin,direction,37,0,24,4,False)
    elif branch=="siege_bolt":
        draw_bolt(d,origin,direction,39,0,34,7,True)
        for side in (-1,1):
            ln(d,op(origin,direction,29,side*3),op(origin,direction,37,side*4),color("gold_light"),1)
    else:
        for across in (-8,0,8):
            draw_bolt(d,origin,direction,34,across,21,3,False)
    poly(d,[op(origin,direction,-4,-6),op(origin,direction,-9,0),op(origin,direction,-4,6),op(origin,direction,1,0)],color("outline"))
    poly(d,[op(origin,direction,-4,-4),op(origin,direction,-7,0),op(origin,direction,-4,4),op(origin,direction,0,0)],color("bone"))
    return im


def projectile_frame(branch: str, frame: int) -> Image.Image:
    im=Image.new("RGBA",(32,32),color("transparent"))
    d=ImageDraw.Draw(im)
    progress=frame/7.0
    cx=7+frame*2.0
    cy=16+(1 if frame%2 else 0)
    alpha=240-frame*14
    ln(d,(max(1,q(cx-10)),q(cy+1)),(q(cx-3),q(cy+1)),color("gold",alpha),2)
    if branch=="base":
        draw_bolt(d,(cx,cy),(1.0,0.0),0,0,14,2,False)
    elif branch=="siege_bolt":
        draw_bolt(d,(cx,cy),(1.0,0.0),0,0,18,3,True)
    else:
        for across in (-4,0,4):
            draw_bolt(d,(cx,cy),(1.0,0.0),0,across,10,1.5,False)
    d.point((q(cx+4),q(cy-3-progress)),fill=color("bone_white",alpha))
    return im


def impact_frame(branch: str, frame: int) -> Image.Image:
    im=Image.new("RGBA",(64,64),color("transparent"))
    d=ImageDraw.Draw(im)
    progress=frame/7.0
    cx=cy=32
    radius=4+frame*3
    alpha=max(48,245-frame*25)
    d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=color("gold",alpha),width=2)
    count={"base":6,"siege_bolt":8,"bone_volley":10}[branch]
    for index in range(count):
        angle=math.tau*index/count+progress*.18
        distance=radius+2+(index%2)*2
        x=cx+math.cos(angle)*distance
        y=cy+math.sin(angle)*distance
        direction=(math.cos(angle),math.sin(angle))
        shard_len=3+frame//3+(1 if branch=="siege_bolt" else 0)
        draw_bolt(d,(x,y),direction,0,0,shard_len*2,1.5,branch=="siege_bolt")
    if branch=="bone_volley":
        for offset in (-6,0,6):
            diamond(d,cx+offset,cy,2,5,color("bone_light",alpha))
    diamond(d,cx,cy,max(2,7-frame//2),max(2,8-frame//2),color("bone",alpha),color("outline",alpha))
    d.point((cx,cy-2),fill=color("bone_white",alpha))
    for index in range(3):
        x=7+((frame*9+index*15)%50)
        y=6+((frame*5+index*19)%52)
        d.point((x,y),fill=color("spark",max(40,alpha-45)))
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
    branches=("base","siege_bolt","bone_volley")
    return {
        "schema_version":1,"id":"ballista","display_name":"Костяная баллиста",
        "status":"review_candidate","runtime_enabled":False,
        "camera":"top_down_3_quarter",
        "canvas":{"width":128,"height":128,"pivot":[64,90],"ground_anchor":[64,118]},
        "direction_order":DIRECTION_ORDER,
        "specialization_branches":{"siege":"siege_bolt","swarm":"bone_volley"},
        "specialization_labels":{"siege":"БАЛЛИСТА: +2 УРОН","swarm":"РОЙ: СКОРОСТЬ"},
        "base":{"levels":{str(n):f"candidate/base/level_{n}.png" for n in (1,2,3)},"frame_size":[128,128],"anchor":"ground_anchor"},
        "weapon":{branch:{"path":f"candidate/weapon/{branch}/weapon_8way.png","frame_size":[128,128],"frame_count":8,"direction_order":DIRECTION_ORDER,"pivot":[64,90],"forward_direction":"north"} for branch in branches},
        "projectiles":{branch:{"path":f"candidate/vfx/{branch}_projectile_8f.png","frame_size":[32,32],"frame_count":8,"fps":24,"loop":True,"forward_axis":"+X"} for branch in branches},
        "impacts":{branch:{"path":f"candidate/vfx/{branch}_impact_8f.png","frame_size":[64,64],"frame_count":8,"fps":24,"loop":False} for branch in branches},
        "source":{"editable_project":"tools/generate_ballista_modular_candidates.py","provenance":"candidate/SOURCE.md","editable_project_status":"procedural_source_is_tools/generate_ballista_modular_candidates.py"},
        "notes":[
            "Review-only Pixel Art candidate; owner approval is required before production use.",
            "runtime_enabled is false; legacy Foozle art and live gameplay are unchanged.",
            "siege maps to siege_bolt (heavy single-target bone bolt); swarm maps to bone_volley (three-bolt volley).",
            "All eight weapon poses are independently rasterized from directional geometry and share one pivot.",
            "The reproducible editable source is tools/generate_ballista_modular_candidates.py; no Aseprite project is claimed.",
            "Gameplay ID remains bone; the asset folder ID is ballista. Do not migrate saves or rename gameplay IDs in this art-only PR."
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
    for branch in ("base","siege_bolt","bone_volley"):
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
        "# Костяная баллиста — исходники модульного Pixel Art\n\n"
        "Статус: **review candidate**, не production. Владелец ещё не утверждал этот набор.\n\n"
        "Редактируемый воспроизводимый источник: tools/generate_ballista_modular_candidates.py. "
        "Он создаёт три основания 128×128, три восьминаправленных оружейных атласа и шесть VFX strips "
        "с прозрачным RGBA фоном.\n\n"
        "Оружейные ветви: base, siege_bolt (тяжёлый осадный болт), bone_volley (три быстрых болта). "
        "Runtime mapping: siege → siege_bolt, swarm → bone_volley. Pivot оружия (64,90), "
        "ground anchor основания (64,118), направления N, NE, E, SE, S, SW, W, NW.\n\n"
        "Кандидатные ресурсы не загружаются игровым рендерером: runtime_enabled=false. "
        "Существующие Foozle PNG не изменены. Aseprite-файл не создан и не заявляется.\n",
        encoding="utf-8")
    written.append(source_path)
    return written


def verify_assets() -> None:
    with tempfile.TemporaryDirectory(prefix="ballista-candidate-") as temp:
        temp_root=Path(temp)
        generated=generate_assets(temp_root)
        for generated_path in generated:
            relative=generated_path.relative_to(temp_root)
            committed=ART/relative
            if not committed.is_file():
                raise SystemExit(f"Missing committed Ballista candidate: {committed}")
            if hashlib.sha256(generated_path.read_bytes()).digest()!=hashlib.sha256(committed.read_bytes()).digest():
                raise SystemExit(f"Non-reproducible Ballista candidate: {committed}")
        expected={p.relative_to(temp_root) for p in generated}
        actual={
            p.relative_to(ART) for p in ART.rglob("*")
            if p.is_file() and (p.parts[len(ART.parts)]=="candidate" or p.name=="manifest.json")
            and p.suffix.lower() in {".png",".json",".md"}
        }
        if actual!=expected:
            raise SystemExit(f"Candidate file set differs: extra={sorted(map(str,actual-expected))}, missing={sorted(map(str,expected-actual))}")
    print("Bone Ballista modular source is reproducible.")


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write",action="store_true")
    mode.add_argument("--verify",action="store_true")
    args=parser.parse_args()
    if args.write:
        print(f"Wrote {len(generate_assets(ART))} reproducible Ballista candidate files.")
    else:
        verify_assets()


if __name__=="__main__":
    main()
