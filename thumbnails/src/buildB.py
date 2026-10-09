import numpy as np, cv2, math, random
from proj import project
from fx import *
import paint2
from compose import place_logo
rnd=random.Random(21)
CAM=dict(ro=(4.3,3.35,8.1),ta=(.85,2.15,0.),fov=1.38,roll=.05)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread('B_col.png'); aux=cv2.imread('B_aux.png'); H,W=col.shape[:2]
f=to_f(col)
op=P((0,2.77,0)); eggc=P((0,1.6,0)); eye=P((0,2.2*1.35+1.5*1.35,0)); ground=P((0,0,0))
print('opening',op,'eggc',eggc)
# --- light column rising out of the egg (painted, so before the paint pass)
beam=np.zeros((H,W),np.float32)
top=P((0,9,0)); 
poly=np.array([[op[0]-70,op[1]],[op[0]+70,op[1]],[top[0]+260,top[1]],[top[0]-260,top[1]]],np.float32)
cv2.fillPoly(beam,[np.round(poly*4).astype(np.int32)],1.0,cv2.LINE_AA,shift=2)
yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
beam*=np.clip((op[1]-yy)/op[1],0,1)**.25*np.clip(1-(op[1]-yy)/(op[1]+50),0,1)**1.2
beam=cv2.GaussianBlur(beam,(0,0),22)
skym=(aux[...,0]<16).astype(np.float32)*(aux[...,1]>80)
beam*=cv2.GaussianBlur(skym.astype(np.float32),(0,0),3)
f=screen_add(f,np.stack([beam*.25,beam*.65,beam*.95],-1),.55)
# glow pool on the ground around the egg
gp=np.exp(-(((xx-ground[0])/330)**2+((yy-ground[1])/120)**2))
f=f+np.stack([gp*.02,gp*.16,gp*.33],-1)*((aux[...,0]<16)[...,None])
fxcol=to_u8(np.clip(f,0,1))
aux2=aux.copy()
cfg=dict(radii=(9,4,1),jit=.025,bg_angle=-.25,scratch=400,
 layers=[(26,0,.4,.9,16,5,.55,True),(13,0,.4,.6,12,3,.5,True),(6,.35,.9,.55,8,2,.5,True),(2,.88,1.,.4,4,1,.3,True)])
out,base=paint2.paint_all(fxcol,aux2,rnd,cfg)
# --- painted grass blades, lit gold near the egg (ex.2 style)
gm=(aux[...,0]<16)&(aux[...,1]<200)&(yy>ground[1]-160)
out=paint2.grass(out,base,gm,26000,rnd,light=(ground[0],ground[1]-10),light_r=420,light_col=(60,185,255),hmin=6,hmax=60,lean=-.1)
out=paint2.grade(out,sat=1.15,warm=.04,cool=.1,vig=.55,contrast=1.08)
f=to_f(out)
# --- starburst flare at the egg opening + eyes glow + fireflies
r=rays((H,W),op,14,140,520,4,12,rnd,rot=.25)*.65
f=screen_add(f,np.stack([r*.35,r*.75,r],-1))
f=glow(f,op,40,(0.75,0.95,1.0),.9,2); f=glow(f,op,170,(0.05,0.4,1.0),.35,1.6); f=glow(f,op,520,(0.05,0.15,0.35),.12,1.4)
ex=P((0,(2.2+1.5)*1.35,0)); f=glow(f,ex,60,(0.5,0.85,1.0),.25,2)
for i in range(45):
    x=rnd.uniform(0,W); y=rnd.uniform(H*.25,H*.95); r0=rnd.uniform(2,6)
    f=glow(f,(x,y),r0*3,(0.3,0.95,1.0),rnd.uniform(.25,.7),2) if rnd.random()<.6 else f
f=np.clip(f,0,1)
out=paint2.canvas_texture(to_u8(f),seed=4,amt=.05)
cv2.imwrite('B_painted.png',out)
fin=place_logo(out,'logo.png',395,165,640)
cv2.imwrite('B_final.png',paint2.canvas_texture(fin,seed=8,amt=.03))
