import numpy as np, cv2, math, random, sys
from proj import project, norm
from fx import *
import paint2
rnd=random.Random(11)
CAM=dict(ro=(2.6,1.15,6.0),ta=(2.05,2.75,0.8),fov=1.22,roll=-.12)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
def rotX(a):c,s=math.cos(a),math.sin(a);return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def rotY(a):c,s=math.cos(a),math.sin(a);return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def rotZ(a):c,s=math.cos(a),math.sin(a);return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def eulD(d):d=np.radians(d);return rotY(d[1])@rotX(d[0])@rotZ(d[2])
def axrot(v,ax,a):ax=norm(ax);return v*math.cos(a)+np.cross(ax,v)*math.sin(a)+ax*(ax@v)*(1-math.cos(a))
eggC=np.array([3.85,1.32,1.75]); yaw=math.degrees(math.atan2(eggC[0],eggC[2]))
tO=np.array([0,3.,0]); tR=eulD([18,yaw-8,-4]); grip=tO+tR@[0.05,.05,1.75]
IMP=np.array([3.26,2.2,2.29]); pkB=IMP+np.array([0,1.4,0.])
for _ in range(4):
    y=norm(pkB-grip); x=norm(np.cross(y,np.cross(y,[0,1,0]))); pkB=IMP-x*1.39+y*.67
col=cv2.imread('A_col.png'); aux=cv2.imread('A_aux.png')
f=to_f(col); H,W=f.shape[:2]
bgmask=((aux[...,0]<16)&(aux[...,1]>60)).astype(np.float32)   # sky/far
ip=P(IMP); print('impact',ip)
# --- wind ribbons behind the hero (ex.1 style white swooshes), only on background
wind=np.zeros((H,W),np.float32)
for (a,b,c2,d,w0,w1) in [((-40,430),(250,260),(560,170),(980,150),18,95),((-50,640),(200,540),(420,470),(700,440),12,60),((1500,60),(1680,110),(1830,230),(1990,300),45,16)]:
    wind=np.maximum(wind,ribbon((H,W),bezier(a,b,c2,d),w0,w1,rnd))
wind=cv2.GaussianBlur(wind,(0,0),1.2)*cv2.GaussianBlur(bgmask,(0,0),3)
f=f*(1-wind[...,None]*.8)+np.array([1.,.98,.96])*wind[...,None]*.8
# --- swing swoosh: arc traced by the pick head
dirv=pkB-grip; ax=np.cross(dirv,[0,1,0]); L=np.linalg.norm(dirv)
inner=[];outer=[]
for k in range(40):
    a=-math.radians(28+95*(1-k/39))
    v=axrot(dirv,ax,a)/L
    inner.append(P(grip+v*L*.85)); outer.append(P(grip+v*L*1.4))
sw=band((H,W),inner,outer,0.0,.45,blur=6)
streak=np.zeros((H,W),np.float32)
for j in range(9):
    t=.9+j*.055; pts=[P(grip+axrot(dirv,ax,-math.radians(26+95*(1-k/39)))/L*L*t) for k in range(40)][int(rnd.random()*15):]
    cv2.polylines(streak,[np.round(np.array(pts)*4).astype(np.int32)],False,1.0,rnd.choice([2,3,5]),cv2.LINE_AA,shift=2)
charm=cv2.GaussianBlur(((aux[...,0]>16)&(aux[...,0]<112)).astype(np.float32),(0,0),2)
sw=np.clip(sw*.6+cv2.GaussianBlur(streak,(0,0),1.2)*sw*1.5,0,1)*(1-charm)
f=f*(1-sw[...,None]*.6)+np.array([1.,.97,.85])*sw[...,None]*.7   # BGR: slightly cyan-white
# small cash coins? keep focus. comic shake lines near face
f=np.clip(f,0,1)
fxcol=to_u8(f)
# detail map: fx regions get mid detail so they paint as loose strokes
aux2=aux.copy()
fxm=np.clip(np.maximum(wind,sw)*255,0,255).astype(np.uint8)
aux2[...,2]=np.maximum(aux2[...,2],(fxm*.35).astype(np.uint8))
aux2[...,0]=np.where(sw>.2,200,aux2[...,0]); aux2[...,0]=np.where((wind>.3)&(sw<.2),180,aux2[...,0])
cv2.imwrite('A_fx.png',fxcol); cv2.imwrite('A_auxfx.png',aux2)
cfg=dict(radii=(8,4,1),jit=.02,bg_angle=-.45,scratch=500,
 layers=[(24,0,.45,.9,16,5,.6,True),(12,0,.45,.6,12,3,.5,True),(6,.3,.88,.55,8,2,.5,True),(2,.88,1.,.4,4,1,.3,True)])
out,base=paint2.paint_all(fxcol,aux2,rnd,cfg)
out=paint2.grade(out,sat=1.12,warm=.05,cool=.08,vig=.4,contrast=1.06)
f=to_f(out)
# --- impact flash
r=rays((H,W),ip,16,160,480,5,13,rnd,rot=.1)*.55
r2=rays((H,W),ip,11,120,300,3,7,rnd,rot=.35)*.8
f=screen_add(f,np.stack([r*.55,r*.88,r],-1),1.0)
f=screen_add(f,np.stack([r2*.85,r2,r2],-1),1.0)
f=glow(f,ip,26,(0.75,0.95,1.0),.85,2)
f=glow(f,ip,85,(0.02,0.45,1.0),.3,1.7)
f=glow(f,ip,300,(0.0,0.12,0.35),.12,1.5)

sp=sparks((H,W),ip,55,50,330,rnd,8,40)
f=screen_add(f,np.stack([sp*.6,sp*.95,sp],-1))
out=to_u8(np.clip(f,0,1))
out=paint2.canvas_texture(out)
cv2.imwrite('A_painted.png',out); cv2.imwrite('A_base.png',base)
from compose import place_logo
fin=place_logo(out,'logo.png',400,190,700,rot=0)
fin=paint2.canvas_texture(fin,seed=9,amt=.03)
cv2.imwrite('A_final.png',fin)
