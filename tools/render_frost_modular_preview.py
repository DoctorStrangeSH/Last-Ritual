#!/usr/bin/env python3
"""Render Frost Obelisk modular candidate contact sheets (review only)."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/"assets/spire/towers/frost/candidate"
BRANCHES=(("base","BASE / ОБЫЧНАЯ"),("frost_lance","FROST LANCE / МОРОЗ"),("blizzard","BLIZZARD / МЕТЕЛЬ"))
DIRECTIONS=("N","NE","E","SE","S","SW","W","NW")
FRAME=(128,128)
PIVOT=(64,90)
GROUND=(64,118)
COMPOSITE=(128,156)
GAP=12
HEADER=42
LEVEL_HEADER=28
LABEL=26


def compose(level:int,branch:str,direction:int)->Image.Image:
    with Image.open(ART/f"base/level_{level}.png") as source:
        base=source.convert("RGBA")
    with Image.open(ART/f"weapon/{branch}/weapon_8way.png") as source:
        strip=source.convert("RGBA")
    if base.size!=FRAME or strip.size!=(FRAME[0]*8,FRAME[1]):
        raise ValueError(f"Invalid Frost art dimensions for L{level}/{branch}")
    weapon=strip.crop((direction*FRAME[0],0,(direction+1)*FRAME[0],FRAME[1]))
    result=Image.new("RGBA",COMPOSITE,(0,0,0,0))
    result.alpha_composite(base,(0,0))
    result.alpha_composite(weapon,(GROUND[0]-PIVOT[0],GROUND[1]-PIVOT[1]))
    return result


def sheet_dimensions(level_count:int,scale:int)->tuple[int,int]:
    if level_count not in (1,2,3) or scale not in (1,2):
        raise ValueError("Use one to three levels and scale 1x or 2x")
    tile=FRAME[0]*scale
    tile_h=COMPOSITE[1]*scale
    row_h=LABEL+tile_h+GAP
    return GAP+8*(tile+GAP), HEADER+level_count*(LEVEL_HEADER+3*row_h+GAP)


def render_full(output:Path,all_levels:bool=True,level:int=3,scale:int=2)->None:
    levels=(1,2,3) if all_levels else (level,)
    tile=FRAME[0]*scale
    tile_h=COMPOSITE[1]*scale
    row_h=LABEL+tile_h+GAP
    width,height=sheet_dimensions(len(levels),scale)
    sheet=Image.new("RGB",(width,height),"#101b2b")
    draw=ImageDraw.Draw(sheet)
    label="ALL LEVELS" if all_levels else f"L{level}"
    draw.text((GAP,9),f"FROST OBELISK / MODULAR PIXEL ART CANDIDATE / {label} / {scale}X / 72 POSES",fill="#d9f6ff")
    for li,selected in enumerate(levels):
        top=HEADER+li*(LEVEL_HEADER+3*row_h+GAP)
        draw.text((GAP,top+5),f"BASE LEVEL {selected}",fill="#8eeaff")
        for ri,(branch,title) in enumerate(BRANCHES):
            row_top=top+LEVEL_HEADER+ri*row_h
            draw.text((GAP,row_top+4),f"{title} / 8 DIRECTIONS",fill="#b9d8ef")
            for col,direction in enumerate(DIRECTIONS):
                x=GAP+col*(tile+GAP)
                y=row_top+LABEL
                preview=compose(selected,branch,col).resize((tile,tile_h),Image.Resampling.NEAREST)
                sheet.paste(preview.convert("RGB"),(x,y),preview.getchannel("A"))
                draw.rectangle((x,y,x+tile-1,y+tile_h-1),outline="#476a86",width=2)
                draw.text((x+7,y+7),direction,fill="#f2fdff")
    output.parent.mkdir(parents=True,exist_ok=True)
    sheet.save(output)
    print(f"Created {output} ({width}x{height}; {scale}x; {len(levels)*3*8} poses)")


def render_compact(output:Path)->None:
    margin=20
    header=54
    label_h=24
    card_w=FRAME[0]+16
    card_h=COMPOSITE[1]+label_h+16
    board=Image.new("RGB",(margin*2+3*card_w,header+3*card_h+margin),"#101b2b")
    draw=ImageDraw.Draw(board)
    draw.text((margin,12),"FROST OBELISK / MODULAR PIXEL ART / 1X / NORTH",fill="#d9f6ff")
    draw.text((margin,32),"L1 - L2 - L3  x  BASE - FROST LANCE - BLIZZARD",fill="#a9cde5")
    for row,(branch,title) in enumerate(BRANCHES):
        for col,level in enumerate((1,2,3)):
            x=margin+col*card_w
            y=header+row*card_h
            preview=compose(level,branch,0)
            draw.text((x+4,y),f"{branch.upper()} / L{level}",fill="#8eeaff")
            board.paste(preview.convert("RGB"),(x,y+label_h),preview.getchannel("A"))
            draw.rectangle((x,y+label_h,x+FRAME[0]-1,y+label_h+COMPOSITE[1]-1),outline="#476a86")
    output.parent.mkdir(parents=True,exist_ok=True)
    board.save(output)
    print(f"Created {output} ({board.width}x{board.height})")


def main()->None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=ROOT/"build/frost_obelisk_modular_contact_sheet.png")
    parser.add_argument("--level",type=int,choices=(1,2,3),default=3)
    parser.add_argument("--scale",type=int,choices=(1,2),default=2)
    parser.add_argument("--all-levels",action="store_true")
    parser.add_argument("--compact",action="store_true")
    args=parser.parse_args()
    if args.compact:
        render_compact(args.output)
    else:
        render_full(args.output,args.all_levels,args.level,args.scale)


if __name__=="__main__":
    main()
