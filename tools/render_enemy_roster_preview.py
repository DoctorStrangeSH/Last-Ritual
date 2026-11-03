#!/usr/bin/env python3
"""Render enemy roster review sheets from the candidate sprite atlases."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/"assets/enemies/candidate"
ROLES=("runner","brute","captain","healer","ranged","boss")
DIRECTIONS=("N","NE","E","SE","S","SW","W","NW")
SIZE={"runner":48,"brute":48,"captain":48,"healer":48,"ranged":48,"boss":96}
MARGIN=20
HEADER=48
LABEL=24
TILE=96
ROW_GAP=16
COL_GAP=12
BG="#17191f"
TEXT="#f1dfc6"
ACCENT="#d6a46c"


def frame(role:str,direction:int,frame:int)->Image.Image:
    size=SIZE[role]
    path=ART/role/"walk_8way_4f.png"
    with Image.open(path) as source:
        atlas=source.convert("RGBA")
    if atlas.size!=(size*4,size*8):
        raise ValueError(f"Invalid {role} atlas size: {atlas.size}")
    return atlas.crop((frame*size,direction*size,(frame+1)*size,(direction+1)*size))


def draw_tile(board:Image.Image,draw:ImageDraw.ImageDraw,sprite:Image.Image,x:int,y:int,label:str,scale:int)->None:
    target=TILE if sprite.width==96 else 48*scale
    preview=sprite.resize((target,target),Image.Resampling.NEAREST)
    px=x+(TILE-target)//2
    py=y+(TILE-target)//2
    board.paste(preview.convert("RGB"),(px,py),preview.getchannel("A"))
    draw.rectangle((x,y,x+TILE-1,y+TILE-1),outline="#775943",width=2)
    draw.text((x+5,y+4),label,fill=TEXT)


def render_overview(output:Path,scale:int=2)->None:
    width=MARGIN*2+8*TILE+7*COL_GAP
    height=HEADER+len(ROLES)*(LABEL+TILE+ROW_GAP)+MARGIN
    board=Image.new("RGB",(width,height),BG)
    draw=ImageDraw.Draw(board)
    draw.text((MARGIN,12),"LAST RITUAL / ENEMY ROSTER / 8 DIRECTIONS / WALK FRAME 1",fill=TEXT)
    draw.text((MARGIN,30),f"NORMAL ENEMIES AT {scale}X; THE RITUAL GUARDIAN REMAINS NATIVE 96PX",fill=ACCENT)
    for row,role in enumerate(ROLES):
        top=HEADER+row*(LABEL+TILE+ROW_GAP)
        draw.text((MARGIN,top+4),role.upper(),fill=ACCENT)
        for col,direction in enumerate(DIRECTIONS):
            x=MARGIN+col*(TILE+COL_GAP)
            y=top+LABEL
            draw_tile(board,draw,frame(role,col,0),x,y,direction,scale)
    output.parent.mkdir(parents=True,exist_ok=True)
    board.save(output)
    print(f"Created {output} ({width}x{height})")


def render_walk_cycles(output:Path,scale:int=2)->None:
    width=MARGIN*2+4*TILE+3*COL_GAP
    height=HEADER+len(ROLES)*(LABEL+TILE+ROW_GAP)+MARGIN
    board=Image.new("RGB",(width,height),BG)
    draw=ImageDraw.Draw(board)
    draw.text((MARGIN,12),"LAST RITUAL / ENEMY ROSTER / NORTH WALK CYCLES",fill=TEXT)
    draw.text((MARGIN,30),f"FOUR DISTINCT FRAMES PER ROLE / LOOP AT 8 FPS / NORMAL {scale}X",fill=ACCENT)
    for row,role in enumerate(ROLES):
        top=HEADER+row*(LABEL+TILE+ROW_GAP)
        draw.text((MARGIN,top+4),role.upper(),fill=ACCENT)
        for col in range(4):
            x=MARGIN+col*(TILE+COL_GAP)
            y=top+LABEL
            draw_tile(board,draw,frame(role,0,col),x,y,f"FRAME {col+1}",scale)
    output.parent.mkdir(parents=True,exist_ok=True)
    board.save(output)
    print(f"Created {output} ({width}x{height})")


def main()->None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--overview",type=Path,default=ROOT/"build/enemy_roster_8way_2x.png")
    parser.add_argument("--walk-cycles",type=Path,default=ROOT/"build/enemy_walk_cycles_2x.png")
    parser.add_argument("--only",choices=("overview","walk-cycles","both"),default="both")
    parser.add_argument("--scale",type=int,choices=(1,2),default=2)
    args=parser.parse_args()
    if args.only in ("overview","both"):
        render_overview(args.overview,args.scale)
    if args.only in ("walk-cycles","both"):
        render_walk_cycles(args.walk_cycles,args.scale)


if __name__=="__main__":
    main()
