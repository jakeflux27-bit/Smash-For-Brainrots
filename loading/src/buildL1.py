import numpy as np, cv2, math, random, sys
sys.path.insert(0,'.')
from proj import project
from fx import *
import knife
rnd=random.Random(41)
CAM=dict(ro=(-7.6,3.6,-6.0),ta=(-8.5,4.6,24.),fov=1.22,roll=-.03)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread('L1_col.png'); aux=cv2.imread('L1_aux.png'); H,W=col.shape[:2]
detail=aux[...,2].astype(np.float32)/255.
sunp=P(np.array([-.55,.15,1.])/np.linalg.norm([-.55,.15,1.])*1000+np.array(CAM['ro']))
print('sun',sunp)
cfg=dict(sat=1.22,con=1.08,radii=(7,4,1),jit=.035,bg_angles=(-.32,),
 layers=[(64,0,.45,.5,.9,(1.8,3.6)),(40,0,.45,.45,.9,(1.6,3.2)),(26,0,.6,.4,.9,(1.4,3.)),(13,.25,1.,.45,.85,(1.3,2.8)),(6,.6,1.,.5,.8,(1.2,2.5)),(3,.9,1.,.45,.5,(1.,2.))])
c,base=knife.paint(col,aux,rnd,cfg)
yy,xx=np.mgrid[0:H,0:W]
gm=(aux[...,0]<16)&(aux[...,1]<9)&(yy>H*.6)
c=knife.edge_accents(c,aux,rnd,.35,2)
c=knife.blades(c,(base.astype(np.float32)*.85).astype(np.uint8),gm,14000,rnd,light=None,hmin=6,hmax=95,wmax=10)
c=knife.speckle(c,base,detail,2500,rnd,.5,1.3,.8,alpha=.4,lmin=.6)
c=knife.finish(c,detail,.9)
c=knife.grade(c,1.12,1.06,-.02)
f=to_f(c)
# sun bloom + god rays + floating light motes
r=rays((H,W),sunp,22,500,1500,18,60,rnd,rot=.2)*.16*np.clip((sunp[1]+120-np.mgrid[0:H,0:W][0])/300,0,1)
f=screen_add(f,np.stack([r*.45,r*.8,r],-1))
f=glow(f,sunp+np.array([60,-40]),40,(.85,.97,1.),.5,2); f=glow(f,sunp,240,(.3,.65,1.),.22,1.5); f=glow(f,sunp,900,(.12,.3,.55),.12,1.3)
for i in range(26):
    a=rnd.uniform(0,6.28); d=rnd.uniform(80,700); x=sunp[0]+math.cos(a)*d*1.4; y=sunp[1]+math.sin(a)*d*.6; r0=rnd.uniform(1.5,3.5)
    f=glow(f,(x,y),r0*2.5,(.55,.95,1.),rnd.uniform(.2,.5),2)
out=to_u8(np.clip(f,0,1))
out=knife_grade=out
cv2.imwrite('L1_final.png',out)
