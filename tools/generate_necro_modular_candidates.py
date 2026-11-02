#!/usr/bin/env python3
"""Rebuild the six ORIGINAL Soul Altar candidate PNGs with a pixel grid.

This is the editable reproducible source for the rough candidate, NOT approved
Soul Altar production artwork. Pillow is required; --verify never changes files.
"""
from __future__ import annotations
import argparse
import math
from pathlib import Path
from PIL import Image

ROOT = Path("assets/spire/towers/necro/candidate")
PALETTE = [
 (0,0,0,0),(21,17,37,255),(41,33,55,255),(65,54,76,255),
 (94,77,98,255),(138,109,95,255),(188,149,92,255),(244,200,125,255),
 (42,17,64,255),(89,24,113,255),(151,43,183,255),(212,93,248,255),
 (255,184,251,255),(92,76,140,255),(215,205,211,255),(249,241,255,255),
]
DIRECTIONS=((0,-1),(.707,-.707),(1,0),(.707,.707),(0,1),(-.707,.707),(-1,0),(-.707,-.707))
def canvas(w=128,h=128):
 return Image.new("P",(w,h),0)
def point(im,x,y,c):
 x=math.floor(x+0.5); y=math.floor(y+0.5)
 if 0<=x<im.width and 0<=y<im.height: im.putpixel((x,y),c)
def box(im,x0,y0,x1,y1,c):
 for y in range(int(y0),int(y1)+1):
  for x in range(int(x0),int(x1)+1): point(im,x,y,c)
def oval(im,cx,cy,rx,ry,c):
 for y in range(-int(ry),int(ry)+1):
  for x in range(-int(rx),int(rx)+1):
   if x*x*ry*ry+y*y*rx*rx<=rx*rx*ry*ry: point(im,cx+x,cy+y,c)
def line(im,x0,y0,x1,y1,thick,c):
 n=max(abs(x1-x0),abs(y1-y0))*2+1
 for i in range(math.floor(n)+1):
  x=x0+(x1-x0)*i/n; y=y0+(y1-y0)*i/n
  x=math.floor(x+0.5);y=math.floor(y+0.5)
  box(im,x-thick,y-thick,x+thick,y+thick,c)
def skull(im,x,y,s=1):
 oval(im,x,y,5*s,5*s,1);oval(im,x,y-1*s,4*s,4*s,14)
 box(im,x-2*s,y+2*s,x+2*s,y+4*s,14)
 box(im,x-3*s,y-2*s,x-1*s,y,1);box(im,x+1*s,y-2*s,x+3*s,y,1)
 box(im,x-1*s,y+2*s,x+1*s,y+3*s,1);point(im,x,y-1*s,11)
def gothic_base_detail(im,level):
 # Deliberate handmade-pixel forms on the stationary stone foundation.
 # Shared geometry is mirrored, while taller spires unlock at later levels.
 for side in (-1,1):
  cx=64+side*(35+level*2)
  box(im,cx-5,80,cx+5,90,1)
  box(im,cx-4,80,cx+4,87,3)
  box(im,cx-4,80,cx-3,87,6)
  box(im,cx+3,80,cx+4,87,6)
  line(im,cx-4,79,cx,75,1,1)
  line(im,cx,75,cx+4,79,1,1)
  line(im,cx,77,cx,81,0,7)
  oval(im,cx,83,2,3,9)
  point(im,cx,82,12)
 for k in range(-2,3):
  x=64+k*12
  point(im,x,108,7)
  line(im,x-3,110,x+3,110,0,1)
 for dx in (-11,11):
  box(im,64+dx-2,95,64+dx+2,97,1)
  point(im,64+dx,96,11)
 if level>=2:
  for side in (-1,1):
   x=64+side*21
   box(im,x-3,76,x+3,85,1)
   box(im,x-2,78,x+2,84,8)
   line(im,x-3,75,x,69,1,6)
   line(im,x,69,x+3,75,1,7)
   point(im,x,76,12)
 if level>=3:
  for side in (-1,1):
   x=64+side*27
   line(im,x,78,x+side*5,65,2,1)
   line(im,x,77,x+side*5,66,0,7)
  box(im,57,84,71,87,1)
  box(im,58,85,70,86,6)
  for x in (59,64,69): point(im,x,85,12)
def base(level):
 im=canvas()
 oval(im,64,106,43+level*3,16+level,1)
 oval(im,64,104,40+level*3,14+level,4)
 oval(im,64,101,36+level*3,12+level,2)
 oval(im,64,97,33+level*2,10+level,3)
 oval(im,64,94,30+level*2,8,1)
 oval(im,64,93,27+level*2,7,5)
 oval(im,64,91,24+level*2,6,2)
 for k in range(5):
  xx=32+k*15;box(im,xx,104,xx+6,111,2);box(im,xx+1,105,xx+5,107,4)
  line(im,xx+1,107,xx+5,107,0,6)
 for j in (-1,1):
  xx=64+j*(31+level*2)
  box(im,xx-5,91,xx+5,105,1);box(im,xx-4,89,xx+4,101,3)
  box(im,xx-4,89,xx-2,100,6);box(im,xx+2,89,xx+4,100,5);point(im,xx,95,11)
 skull(im,64,102)
 line(im,32,99,49,92,0,6);line(im,79,92,96,99,0,6)
 for i in range(level):
  x=64+(i-(level-1)/2)*14
  oval(im,x,88,4,3,9);point(im,x,87,12)
 if level>1:
  box(im,43,84,46,91,6);box(im,82,84,85,91,6)
  oval(im,44,83,3,4,10);oval(im,84,83,3,4,10)
 if level>2:
  for dx in (-22,22):
   line(im,64+dx,84,64+dx*1.17,75,2,1)
   line(im,64+dx,82,64+dx*1.17,76,0,7)
 gothic_base_detail(im,level)
 return im
def reaper_detail(im,dx,dy,x,y):
 # Directional blade ribs, chained skull pommel and purple soul-fire.
 sx,sy=-dy,dx
 tx,ty=x+dx*13,y+dy*13
 for k in range(-3,4):
  px,py=tx+sx*k*3,ty+sy*k*3
  point(im,px+dx*2,py+dy*2,11 if k%2 else 12)
 line(im,tx-sx*15,ty-sy*15,tx+sx*11,ty+sy*11,0,7)
 for k in (0,1,2,3):
  cx=64-dx*k*4+sx*4
  cy=70-dy*k*4+sy*4
  oval(im,cx,cy,2,2,1)
  point(im,cx,cy,6)
 line(im,64-sx*5,72-sy*5,64+sx*5,72+sy*5,1,6)
 oval(im,64,69,5,4,9)
 point(im,62,68,12)
 point(im,66,68,12)
 for k in (1,2,3):
  point(im,tx+dx*k+sx*5,ty+dy*k+sy*5,12)
def weapon(branch):
 atlas=canvas(1024,128)
 for idx,(dx,dy) in enumerate(DIRECTIONS):
  im=canvas()
  box(im,57,74,71,88,1);box(im,60,76,68,85,5);box(im,62,78,66,83,7)
  x,y=64+dx*30,65+dy*27
  line(im,64,70,x,y,6,1);line(im,64,70,x,y,4,3);line(im,64,70,x,y,2,6)
  if branch=="base":
   oval(im,x,y,10,11,1);oval(im,x,y,8,9,8);oval(im,x,y-1,6,7,10)
   oval(im,x,y-2,4,5,11);point(im,x,y-4,12)
   skull(im,64,70);line(im,x-4,y+5,x+4,y+5,0,7)
  elif branch=="reaper":
   line(im,64,70,x+dx*5,y+dy*5,2,7)
   tip=(x+dx*13,y+dy*13);sx,sy=-dy,dx
   line(im,tip[0]-sx*13,tip[1]-sy*13,tip[0]+sx*10,tip[1]+sy*10,3,1)
   line(im,tip[0]-sx*12,tip[1]-sy*12,tip[0]+sx*9,tip[1]+sy*9,2,10)
   line(im,tip[0]-sx*8,tip[1]-sy*8,tip[0]+sx*4,tip[1]+sy*4,0,12)
   oval(im,64,66,11,12,1);oval(im,64,64,8,9,8);skull(im,64,67)
   reaper_detail(im,dx,dy,x,y)
  else:
   sx,sy=-dy,dx
   for q in (-1,0,1):
    ex=x+sx*q*11+dx*(5 if q==0 else 0)
    ey=y+sy*q*11+dy*(5 if q==0 else 0)
    line(im,64+sx*q*3,72+sy*q*3,ex,ey,2,5)
    oval(im,ex,ey,6,7,1);oval(im,ex,ey,4,5,10)
    point(im,ex-2,ey-1,12);point(im,ex+2,ey-1,12);point(im,ex,ey+2,1)
   skull(im,64,70)
  atlas.paste(im,(idx*128,0))
 return atlas
def rgba(im):
 out=Image.new("RGBA",im.size)
 out.putdata([PALETTE[index] for index in im.getdata()])
 return out
def assets():
 for level in (1,2,3): yield ROOT/f"base/level_{level}.png",rgba(base(level))
 for branch in ("base","reaper","legion"):
  yield ROOT/f"weapon/{branch}/weapon_8way.png",rgba(weapon(branch))
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("--verify",action="store_true",help="compare pixel-by-pixel, never overwrite files")
 p.add_argument("--output",type=Path,default=ROOT,help="destination candidate directory")
 args=p.parse_args(); failed=[]
 for path,generated in assets():
  target=args.output/path.relative_to(ROOT)
  if args.verify:
   if not target.is_file():
    failed.append(f"missing: {target}");continue
   with Image.open(target) as source:
    if source.convert("RGBA").tobytes()!=generated.tobytes():
     failed.append(f"pixel mismatch: {target}")
   continue
  target.parent.mkdir(parents=True,exist_ok=True)
  generated.save(target)
  print(f"generated: {target}")
 if failed: raise SystemExit("\n".join(failed))
 if args.verify: print("PASS: all six candidate atlases match the reproducible pixel source")
if __name__=="__main__": main()
