import numpy as np, cv2, math, random, sys
sys.path.insert(0,'.')
from proj import project
from fx import *
import knife
rnd=random.Random(63)
CAM=dict(ro=(-1.2,1.4,13.5),ta=(-1.4,5.0,0.),fov=1.55,roll=-.08)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread('L3_col.png'); aux=cv2.imread('L3_aux.png'); H,W=col.shape[:2]
detail=aux[...,2].astype(np.float32)/255.
ip=P((-2.6,5.6,2.1)); print('impact',ip)
cfg=dict(sat=1.2,con=1.08,radii=(7,4,1),jit=.04,bg_angles=(-.35,),
 layers=[(64,0,.45,.5,.9,(1.8,3.6)),(40,0,.45,.45,.9,(1.6,3.2)),(26,0,.6,.4,.9,(1.4,3.)),(13,.25,1.,.45,.85,(1.3,2.8)),(6,.6,1.,.5,.8,(1.2,2.5)),(3,.92,1.,.4,.5,(1.,2.))])
c,base=knife.paint(col,aux,rnd,cfg)
c=knife.edge_accents(c,aux,rnd,.35,2)
yy,xx=np.mgrid[0:H,0:W]
gm=(aux[...,0]<16)&(aux[...,1]<20)&(yy>H*.62)
c=knife.blades(c,(base.astype(np.float32)*.9).astype(np.uint8),gm,9000,rnd,light=(ip[0]+120,H*.78),light_r=650,light_col=(40,170,255),hmin=6,hmax=80,wmax=9)
c=knife.speckle(c,base,detail,2500,rnd,.5,1.3,.8,alpha=.4,lmin=.6)
c=knife.finish(c,detail,.9)
c=knife.grade(c,1.1,1.06,-.02,shadow_tint=(0.08,0.0,0.02))
f=to_f(c)
# impact flash: rays + glow + sparks + shockwave ring
r=rays((H,W),ip,18,200,900,6,22,rnd,rot=.3)*.45
f=screen_add(f,np.stack([r*.35,r*.82,r],-1))
f=glow(f,ip,40,(.75,.95,1.),.9,2); f=glow(f,ip,170,(.1,.6,1.),.35,1.6); f=glow(f,ip,520,(.05,.25,.6),.15,1.4)
sp=sparks((H,W),ip,80,40,520,rnd,8,40); f=screen_add(f,np.stack([sp*.35,sp*.85,sp],-1))
ring=np.zeros((H,W),np.float32); cv2.ellipse(ring,(int(ip[0]*4),int(ip[1]*4)),(int(260*4),int(120*4)),-25,0,360,1.0,5,cv2.LINE_AA,shift=2)
ring=cv2.GaussianBlur(ring,(0,0),3)*.45; f=screen_add(f,ring[...,None]*np.array([.7,.95,1.]))
for i in range(60):
    x=rnd.uniform(0,W); y=rnd.uniform(H*.3,H*.95); r0=rnd.uniform(2,5)
    if rnd.random()<.7: f=glow(f,(x,y),r0*2.5,(.4,1.,.85),rnd.uniform(.25,.6),2)
out=to_u8(np.clip(f,0,1))
cv2.imwrite('L3_final.png',out)
