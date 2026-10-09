import numpy as np, cv2, math, random
from proj import project
from fx import *
import paint2
from compose import place_logo
rnd=random.Random(31)
CAM=dict(ro=(.5,1.2,7.6),ta=(-.4,5.3,0.),fov=1.02,roll=.07)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread('C_col.png'); aux=cv2.imread('C_aux.png'); H,W=col.shape[:2]
f=to_f(col); yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
cp=P((-.2,5.7,.6)); print('clash',cp)
# --- dust clouds kicked up at the feet + low haze (painted)
dust=np.zeros((H,W),np.float32)
for (X,s) in [((-4.4,.3,.6),1.0),((-2.8,.2,1.4),.8),((2.6,.2,2.6),.9),((.2,.1,2.),1.1),((-6.,.2,-.5),.7)]:
    c=P(X)
    for k in range(9):
        cx=c[0]+rnd.gauss(0,80*s); cy=c[1]+rnd.gauss(-10,25*s); r=rnd.uniform(35,85)*s
        dust=np.maximum(dust,np.exp(-(((xx-cx)/r)**2+((yy-cy)/(r*.65))**2))*rnd.uniform(.5,.9))
dust=cv2.GaussianBlur(dust,(0,0),6)
f=f*(1-dust[...,None]*.45)+np.array([.55,.72,.95])[None,None,:]*dust[...,None]*.45
fxcol=to_u8(np.clip(f,0,1)); aux2=aux.copy(); aux2[...,2]=np.maximum(aux2[...,2],(dust*90).astype(np.uint8))
cfg=dict(radii=(9,4,1),jit=.022,bg_angle=-.3,scratch=700,
 layers=[(26,0,.4,.9,16,5,.55,True),(13,0,.4,.6,12,3,.5,True),(6,.3,.9,.55,8,2,.5,True),(2,.9,1.,.4,4,1,.3,True)])
out,base=paint2.paint_all(fxcol,aux2,rnd,cfg)
out=paint2.grade(out,sat=1.12,warm=.06,cool=.08,vig=.45,contrast=1.08)
f=to_f(out)
# --- clash FX: lightning, shockwave, glow, sparks
lines=[]
def ang():
    a=rnd.uniform(math.radians(35),math.radians(145)); return -a if rnd.random()<.55 else a
for k in range(6):
    lines+=lightning((H,W),cp,ang(),rnd.uniform(220,480),rnd,seg=14,jag=.38,branch=.4)
f=draw_bolts(f,lines,core=(.85,1,1),glowc=(.15,.7,1.),w=3)
lines2=[]
for k in range(3):
    lines2+=lightning((H,W),cp,ang(),rnd.uniform(160,320),rnd,seg=10,jag=.5,branch=.3)
f=draw_bolts(f,lines2,core=(.9,1,1),glowc=(.2,.8,1.),w=3)
ring=np.zeros((H,W),np.float32); cv2.ellipse(ring,(int(cp[0]*4),int(cp[1]*4)),(int(230*4),int(80*4)),-12,0,360,1.0,4,cv2.LINE_AA,shift=2)
ring=cv2.GaussianBlur(ring,(0,0),3)*.55; f=screen_add(f,ring[...,None]*np.array([1.,.95,.8]))
f=glow(f,cp,30,(0.85,0.97,1.0),1.0,2); f=glow(f,cp,105,(0.2,0.6,1.0),.35,1.6); f=glow(f,cp,420,(0.1,0.25,0.5),.12,1.4)
sp=sparks((H,W),cp,60,40,360,rnd,8,45); f=screen_add(f,np.stack([sp*.5,sp*.9,sp],-1))
out=paint2.canvas_texture(to_u8(np.clip(f,0,1)),seed=6,amt=.05)
cv2.imwrite('C_painted.png',out)
fin=place_logo(out,'logo.png',395,165,640)
cv2.imwrite('C_final.png',paint2.canvas_texture(fin,seed=12,amt=.03))
