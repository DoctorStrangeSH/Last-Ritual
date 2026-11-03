#!/usr/bin/env python3
"""Generate a review-only 8-way Pixel Art roster for Last Ritual enemies."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import tempfile
from pathlib import Path
from typing import Iterable
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/"assets/enemies"
DIRECTIONS=((0.0,-1.0),(0.7071,-0.7071),(1.0,0.0),(0.7071,0.7071),
            (0.0,1.0),(-0.7071,0.7071),(-1.0,0.0),(-0.7071,-0.7071))
DIRECTION_ORDER=["north","north_east","east","south_east","south","south_west","west","north_west"]
ROLES=("runner","brute","captain","healer","ranged","boss")
PALETTES={
 "runner":{"outline":"#201b25","shadow":"#30252b","cloth":"#8d3940","cloth_light":"#c45a4d","leather":"#59313a","metal":"#8c817b","metal_light":"#d5c3a2","skin":"#bd8d76","eye":"#ffd17c","accent":"#e6a35d"},
 "brute":{"outline":"#1c202a","shadow":"#28303a","cloth":"#46546b","cloth_light":"#7486a1","metal":"#7c8792","metal_light":"#c5cbd0","skin":"#8d8b91","eye":"#f1bc7c","accent":"#c6a36b"},
 "captain":{"outline":"#211a24","shadow":"#32232b","cloth":"#65313b","cloth_light":"#a64b4b","metal":"#94734b","metal_light":"#e1bd7c","skin":"#b58a70","eye":"#ffdc91","accent":"#e7c16e"},
 "healer":{"outline":"#1a2529","shadow":"#24383a","cloth":"#315e59","cloth_light":"#568b79","metal":"#8d8a72","metal_light":"#d7c99a","skin":"#b79b83","eye":"#b5f4c9","accent":"#65e5a2"},
 "ranged":{"outline":"#211d2a","shadow":"#30283b","cloth":"#514366","cloth_light":"#8170a0","metal":"#928b9d","metal_light":"#d7c9c0","skin":"#b68e83","eye":"#e5d3ff","accent":"#c49bdb"},
 "boss":{"outline":"#1b1724","shadow":"#2a2033","cloth":"#553044","cloth_light":"#8c4566","metal":"#6f6179","metal_light":"#c4a4ba","skin":"#a76d7d","eye":"#ffb6d3","accent":"#ed6c9d","core":"#ff8eb7"},
}
TRANSPARENT=(0,0,0,0)


def rgb(hex_color:str,alpha:int=255):
    h=hex_color.lstrip("#")
    return (int(h[0:2],16),int(h[2:4],16),int(h[4:6],16),alpha)


def round_px(value:float)->int:
    return int(math.floor(value+0.5))


class Painter:
    def __init__(self,draw:ImageDraw.ImageDraw,origin:tuple[float,float],direction:tuple[float,float],scale:float):
        self.draw=draw
        self.origin=origin
        self.direction=direction
        self.scale=scale
        self.perp=(-direction[1],direction[0])

    def point(self,along:float,across:float)->tuple[int,int]:
        s=self.scale
        return (round_px(self.origin[0]+(self.direction[0]*along+self.perp[0]*across)*s),
                round_px(self.origin[1]+(self.direction[1]*along+self.perp[1]*across)*s))

    def polygon(self,points:Iterable[tuple[float,float]],fill,outline=None,width:int=1):
        pts=[self.point(a,b) for a,b in points]
        self.draw.polygon(pts,fill=fill)
        if outline is not None:
            self.draw.line(pts+[pts[0]],fill=outline,width=max(1,round_px(width*self.scale)),joint="curve")

    def line(self,a,b,fill,width:int=1):
        self.draw.line((*self.point(*a),*self.point(*b)),fill=fill,width=max(1,round_px(width*self.scale)))

    def circle(self,along:float,across:float,radius:float,fill,outline=None,width:int=1):
        pts=[]
        for i in range(16):
            angle=math.tau*i/16
            pts.append(self.point(along+math.cos(angle)*radius,across+math.sin(angle)*radius))
        self.draw.polygon(pts,fill=fill)
        if outline is not None:
            self.draw.line(pts+[pts[0]],fill=outline,width=max(1,width*self.scale),joint="curve")

    def diamond(self,along:float,across:float,rx:float,ry:float,fill,outline=None):
        self.polygon([(along-ry,across),(along,across+rx),(along+ry,across),(along,across-rx)],fill,outline,1)


def palette(role:str)->dict[str,tuple[int,int,int,int]]:
    return {key:rgb(value) for key,value in PALETTES[role].items()}


def draw_limb(p:Painter,role:str,pal,step:float,bob:float):
    # Feet and legs: frame offset makes a readable four-frame walk loop.
    if role=="boss":
        leg_w=5
        for side in (-1,1):
            a=-13+step*side*1.25
            x=side*8
            p.polygon([(a-4,x-5),(a+3,x-5),(a+5,x+5),(a-4,x+6)],pal["outline"])
            p.polygon([(a-3,x-4),(a+2,x-4),(a+3,x+4),(a-3,x+4)],pal["metal"])
            p.line((a-2,x+3),(a+2,x+3),pal["metal_light"],1)
    else:
        for side in (-1,1):
            a=-11+step*side*.55
            x=side*(3 if role in ("runner","healer","ranged") else 5)
            p.polygon([(a-4,x-2),(a+3,x-2),(a+5,x+3),(a-4,x+4)],pal["outline"])
            p.polygon([(a-3,x-1),(a+2,x-1),(a+3,x+2),(a-3,x+3)],pal["cloth"])
            p.line((a-2,x+2),(a+2,x+2),pal["metal_light"],1)


def draw_runner(p:Painter,pal,step:float,bob:float):
    p.polygon([(-10,-5),(-17,-9),(-18,-3),(-15,4),(-9,5)],pal["outline"])
    p.polygon([(-10,-4),(-16,-7),(-15,0),(-11,3)],pal["cloth"])
    p.polygon([(-8,-7),(4,-8),(9,-3),(7,7),(-5,8),(-10,2)],pal["outline"])
    p.polygon([(-7,-6),(3,-7),(7,-2),(5,5),(-4,6),(-8,1)],pal["cloth"])
    p.line((-4,-5),(3,-5),pal["cloth_light"],2)
    p.polygon([(5,-5),(10,-6),(14,-3),(14,4),(9,7),(4,3)],pal["outline"])
    p.polygon([(7,-4),(10,-5),(12,-2),(12,3),(9,5),(6,2)],pal["skin"])
    p.polygon([(8,-5),(12,-5),(15,-1),(12,1),(7,0)],pal["leather"])
    p.circle(10,-2,1.0,pal["eye"])
    p.circle(10,2,1.0,pal["eye"])
    # Twin short blades make the fast melee silhouette unmistakable.
    for side in (-1,1):
        p.line((1,side*8),(5+step*.25,side*13),pal["outline"],3)
        p.line((4+step*.25,side*12),(10,side*17),pal["metal_light"],2)
        p.diamond(10,side*17,1.5,3,pal["metal_light"])


def draw_brute(p:Painter,pal,step:float,bob:float):
    p.polygon([(-12,-10),(2,-13),(9,-8),(12,0),(8,11),(-9,11),(-14,2)],pal["outline"])
    p.polygon([(-10,-8),(1,-11),(7,-6),(9,1),(6,8),(-7,8),(-11,2)],pal["cloth"])
    p.polygon([(-8,-9),(0,-11),(5,-7),(2,-2),(-8,-3)],pal["cloth_light"])
    for side in (-1,1):
        p.polygon([(-5,side*9),(1,side*12),(5,side*10),(4,side*6),(-2,side*6)],pal["outline"])
        p.polygon([(-4,side*9),(1,side*11),(3,side*9),(2,side*7),(-2,side*7)],pal["metal"])
        p.line((-3,side*8),(2,side*8),pal["metal_light"],1)
    p.polygon([(6,-6),(12,-7),(15,-3),(15,4),(11,8),(6,4)],pal["outline"])
    p.polygon([(8,-5),(12,-5),(13,-2),(12,4),(8,3)],pal["metal"])
    p.line((9,-4),(12,-3),pal["metal_light"],2)
    p.circle(12,-2,1.1,pal["eye"])
    p.polygon([(-4,-12),(1,-16),(7,-12),(5,-7),(-2,-7)],pal["outline"])
    p.polygon([(-2,-11),(1,-14),(5,-11),(4,-8),(-1,-8)],pal["metal"])
    p.line((0,-11),(4,-10),pal["metal_light"],1)


def draw_captain(p:Painter,pal,step:float,bob:float):
    p.polygon([(-13,-7),(-6,-12),(4,-10),(10,-3),(7,9),(-10,9),(-14,1)],pal["outline"])
    p.polygon([(-11,-6),(-5,-10),(3,-8),(7,-2),(5,7),(-8,7),(-11,1)],pal["cloth"])
    p.polygon([(-8,-8),(-3,-10),(2,-7),(-2,0),(-8,1)],pal["cloth_light"])
    p.polygon([(5,-6),(11,-7),(15,-2),(14,5),(9,8),(4,3)],pal["outline"])
    p.polygon([(7,-5),(11,-5),(13,-1),(11,4),(7,3)],pal["skin"])
    p.polygon([(6,-8),(9,-14),(12,-9),(15,-13),(16,-5),(10,-3)],pal["outline"])
    p.polygon([(8,-8),(10,-12),(12,-8),(14,-11),(14,-6),(9,-5)],pal["metal_light"])
    p.circle(11,-2,1.0,pal["eye"])
    # Command pennant/spear is carried to the rear-side, away from the face.
    p.line((-3,-12),(-9,-19),pal["outline"],3)
    p.line((-4,-13),(-9,-19),pal["metal_light"],1)
    p.polygon([(-10,-19),(-4,-18),(-8,-14)],pal["accent"])
    p.diamond(-9,-18,2,3,pal["metal_light"])


def draw_healer(p:Painter,pal,step:float,bob:float):
    p.polygon([(-13,-8),(-7,-12),(5,-10),(10,-2),(8,9),(-10,9),(-14,2)],pal["outline"])
    p.polygon([(-11,-7),(-6,-10),(4,-8),(8,-1),(6,7),(-8,7),(-11,1)],pal["cloth"])
    p.polygon([(-9,-5),(-5,-9),(0,-8),(-3,4),(-9,4)],pal["cloth_light"])
    p.polygon([(5,-7),(11,-7),(14,-2),(13,5),(8,8),(4,2)],pal["outline"])
    p.polygon([(7,-5),(11,-5),(12,-1),(10,4),(7,2)],pal["skin"])
    p.polygon([(5,-8),(7,-14),(13,-13),(15,-6),(10,-4)],pal["outline"])
    p.polygon([(7,-8),(8,-12),(12,-11),(13,-7),(9,-6)],pal["cloth_light"])
    p.circle(10,-1,1.0,pal["eye"])
    # Staff with a bright healing crystal.
    p.line((-2,1),(-5,14),pal["outline"],3)
    p.line((-3,1),(-6,13),pal["metal_light"],1)
    p.circle(-7,14,3.0,pal["accent"],pal["outline"])
    p.circle(-7,14,1.2,pal["metal_light"])
    p.line((-2,-1),(2,-1),pal["metal_light"],2)
    p.line((0,-4),(0,2),pal["metal_light"],2)


def draw_ranged(p:Painter,pal,step:float,bob:float):
    p.polygon([(-13,-7),(-7,-12),(4,-10),(9,-2),(7,9),(-10,8),(-14,1)],pal["outline"])
    p.polygon([(-11,-6),(-6,-10),(3,-8),(7,-1),(5,7),(-8,6),(-11,1)],pal["cloth"])
    p.polygon([(-8,-7),(-4,-10),(0,-8),(-3,2),(-9,3)],pal["cloth_light"])
    p.polygon([(5,-7),(11,-7),(14,-2),(13,5),(8,8),(4,2)],pal["outline"])
    p.polygon([(7,-5),(11,-5),(12,-1),(10,4),(7,2)],pal["skin"])
    p.polygon([(5,-9),(7,-15),(13,-13),(15,-6),(10,-4)],pal["outline"])
    p.polygon([(7,-8),(8,-13),(12,-11),(13,-7),(9,-6)],pal["cloth_light"])
    p.circle(10,-1,1.0,pal["eye"])
    # Bow is a curved polygonal arc on the leading side; quiver rides behind.
    p.polygon([(-10,10),(-13,7),(-15,1),(-14,-6),(-11,-10),(-9,-8),(-12,0),(-10,7)],pal["outline"])
    p.line((-12,-7),(-12,8),pal["metal_light"],1)
    p.line((-10,-10),(-16,-13),pal["outline"],2)
    for offset in (-3,0,3):
        p.line((-11,-11+offset),(-15,-14+offset),pal["accent"],1)


def draw_boss(p:Painter,pal,step:float,bob:float,frame:int):
    # A wider four-position mantle sweep remains visible behind the silhouette at 1x.
    cape_sway=(-5.0,-1.0,5.0,1.0)[frame]
    p.polygon([(-13,-7),(-20,-17+cape_sway),(-18,-1+cape_sway),(-12,6)],pal["outline"])
    p.polygon([(-13,-6),(-18,-15+cape_sway),(-16,-2+cape_sway),(-12,4)],pal["cloth_light"])
    p.polygon([(-24,-14),(-17,-25),(-6,-28),(12,-23),(23,-12),(22,13),(12,27),(-15,25),(-25,10)],pal["outline"])
    p.polygon([(-21,-13),(-15,-22),(-5,-24),(10,-20),(19,-10),(18,11),(10,22),(-13,21),(-22,8)],pal["cloth"])
    p.polygon([(-17,-17),(-9,-23),(1,-21),(-2,-7),(-15,-4)],pal["cloth_light"])
    # Massive iron shoulder plates and spiked silhouette.
    for side in (-1,1):
        p.polygon([(-10,side*19),(1,side*28),(13,side*20),(10,side*11),(-3,side*12)],pal["outline"])
        p.polygon([(-7,side*18),(1,side*25),(10,side*18),(8,side*13),(-2,side*14)],pal["metal"])
        p.polygon([(4,side*22),(12,side*24),(17,side*32),(8,side*29)],pal["metal_light"])
    # Crowned skull face and ritual core.
    p.polygon([(12,-12),(22,-17),(27,-7),(25,7),(16,14),(7,7),(7,-5)],pal["outline"])
    p.polygon([(14,-10),(21,-13),(24,-5),(22,6),(16,10),(10,5),(10,-4)],pal["skin"])
    p.polygon([(11,-12),(13,-26),(18,-17),(23,-29),(25,-13),(20,-9)],pal["outline"])
    p.polygon([(13,-14),(14,-22),(18,-15),(22,-25),(23,-14),(19,-11)],pal["metal_light"])
    p.circle(18,-4,2.2,pal["eye"])
    p.circle(18,4,2.2,pal["eye"])
    p.polygon([(-7,-2),(2,-9),(11,-4),(13,8),(5,16),(-7,12)],pal["outline"])
    p.polygon([(-5,-1),(2,-6),(8,-2),(10,7),(4,12),(-5,9)],pal["core"])
    # The ritual core breathes through four distinct shapes, preventing a false
    # four-frame walk cycle where the boss collapses to only three unique poses.
    core_offsets=((0,-1),(1,0),(0,1),(-1,0))
    core_x,core_y=core_offsets[frame]
    p.diamond(3+core_x,3+core_y,3,5+frame,pal["metal_light"])
    p.circle(3+core_x,3+core_y,1.0+frame*.35,pal["core"])
    p.line((-4,17),(8,17),pal["metal_light"],2)
    p.line((-12,-18),(-18,-29),pal["outline"],4)
    p.line((-11,-18),(-18,-28),pal["metal_light"],2)


def draw_character(role:str,direction_index:int,frame:int)->Image.Image:
    is_boss=role=="boss"
    size=96 if is_boss else 48
    # Fractional coordinate scaling is snapped to the pixel grid by Painter.point.
    # It keeps the 96px boss atlas comfortably inside all eight facing cells.
    scale=1.4 if is_boss else 1.0
    origin=(48.0,48.0) if is_boss else (24.0,26.0)
    direction=DIRECTIONS[direction_index]
    image=Image.new("RGBA",(size,size),TRANSPARENT)
    d=ImageDraw.Draw(image)
    pal=palette(role)
    step=(-2.0,0.0,2.0,0.0)[frame]
    bob=(0.0,0.8,0.0,-0.8)[frame]
    ground_y=72 if is_boss else 41
    d.ellipse((size*.18,ground_y-3*scale,size*.82,ground_y+3*scale),fill=rgb("#17151b",105))
    p=Painter(d,(origin[0],origin[1]+bob*scale),direction,scale)

    draw_limb(p,role,pal,step,bob)
    if role=="runner":
        draw_runner(p,pal,step,bob)
    elif role=="brute":
        draw_brute(p,pal,step,bob)
    elif role=="captain":
        draw_captain(p,pal,step,bob)
    elif role=="healer":
        draw_healer(p,pal,step,bob)
    elif role=="ranged":
        draw_ranged(p,pal,step,bob)
    elif role=="boss":
        draw_boss(p,pal,step,bob,frame)

    # Small facing glint is authored per direction; no full-sprite rotation is used.
    if role=="boss":
        p.line((18,-7),(22,-7),pal["metal_light"],2)
    else:
        p.line((10,-4),(13,-4),pal["metal_light"],1)
    return image


def atlas_for_role(role:str)->Image.Image:
    size=96 if role=="boss" else 48
    atlas=Image.new("RGBA",(size*4,size*8),TRANSPARENT)
    for direction in range(8):
        for frame in range(4):
            atlas.alpha_composite(draw_character(role,direction,frame),(frame*size,direction*size))
    return atlas


def manifest_data()->dict:
    entries={}
    for role in ROLES:
        size=96 if role=="boss" else 48
        entries[role]={
            "path":f"candidate/{role}/walk_8way_4f.png",
            "frame_size":[size,size],"columns":4,"rows":8,"frame_count":32,
            "fps":8,"loop":True,"animation":"walk",
            "direction_order":DIRECTION_ORDER,
            "pivot":[size//2,72 if role=="boss" else 41],
        }
    return {
        "schema_version":1,"id":"enemy_roster","display_name":"Враги осады и Страж ритуала",
        "status":"review_candidate","runtime_enabled":False,
        "direction_order":DIRECTION_ORDER,
        "role_mapping":{
            "td":{"runner":"runner","brute":"brute","captain":"captain","healer":"healer","boss":"boss"},
            "night":{"regular":"runner","flanker":"runner","ranged":"ranged","champion":"brute","boss":"boss"},
        },
        "enemies":entries,
        "source":{"editable_project":"tools/generate_enemy_roster_pixel_art.py",
                  "provenance":"candidate/SOURCE.md",
                  "editable_project_status":"procedural_source_is_tools/generate_enemy_roster_pixel_art.py"},
        "notes":[
            "Review-only enemy Pixel Art candidate. The current game still uses its existing vector enemy renderer.",
            "runtime_enabled is false; this PR does not change enemy stats, hitboxes, movement, attacks, waves or saves.",
            "Each role has 8 hand-authored facing poses and a 4-frame walk loop; frames are stored as 4 columns x 8 direction rows.",
            "Night roles regular/flanker share runner art; champion uses brute art. A later gameplay-art pass may split these visual identities.",
            "The procedural Python generator is the editable reproducible source; no Aseprite project is claimed."
        ],
    }


def generate_assets(output_root:Path)->list[Path]:
    candidate=output_root/"candidate"
    written=[]
    for role in ROLES:
        folder=candidate/role
        folder.mkdir(parents=True,exist_ok=True)
        path=folder/"walk_8way_4f.png"
        atlas_for_role(role).save(path,optimize=False)
        written.append(path)
    manifest=output_root/"manifest.json"
    manifest.write_text(json.dumps(manifest_data(),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    written.append(manifest)
    source=candidate/"SOURCE.md"
    source.write_text(
        "# Враги осады — модульный Pixel Art кандидат\n\n"
        "Статус: **review candidate**, не production. Владелец ещё не принимал набор для runtime.\n\n"
        "Роли: runner, brute, captain, healer, ranged и boss. Для каждого подготовлены 8 направлений × 4 кадра ходьбы. "
        "Обычные враги используют кадр 48×48; Страж ритуала — 96×96. Атласы: 4 колонки (кадры) × 8 строк (N, NE, E, SE, S, SW, W, NW).\n\n"
        "Воспроизводимый источник: tools/generate_enemy_roster_pixel_art.py. "
        "Оригинальный векторный рендер игры не меняется; manifest runtime_enabled=false. "
        "Aseprite-файл не создан и не заявляется.\n",
        encoding="utf-8")
    written.append(source)
    return written


def verify_assets()->None:
    with tempfile.TemporaryDirectory(prefix="enemy-roster-candidate-") as temp:
        root=Path(temp)
        generated=generate_assets(root)
        for path in generated:
            relative=path.relative_to(root)
            committed=ART/relative
            if not committed.is_file():
                raise SystemExit(f"Missing enemy roster candidate: {committed}")
            if hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256(committed.read_bytes()).digest():
                raise SystemExit(f"Non-reproducible enemy roster candidate: {committed}")
        expected={path.relative_to(root) for path in generated}
        actual={
            path.relative_to(ART) for path in ART.rglob("*")
            if path.is_file() and (path.parts[len(ART.parts)]=="candidate" or path.name=="manifest.json")
            and path.suffix.lower() in {".png",".json",".md"} and "review" not in path.parts
        }
        if actual!=expected:
            raise SystemExit(f"Enemy candidate inventory differs: extra={sorted(map(str,actual-expected))}, missing={sorted(map(str,expected-actual))}")
    print("Enemy roster Pixel Art source is reproducible.")


def main()->None:
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write",action="store_true")
    mode.add_argument("--verify",action="store_true")
    args=parser.parse_args()
    if args.write:
        print(f"Wrote {len(generate_assets(ART))} enemy roster candidate files.")
    else:
        verify_assets()


if __name__=="__main__":
    main()
