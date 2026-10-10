import numpy as np, cv2, math, random, sys
sys.path.insert(0,'.')
from proj import project
from fx import *
import knife
rnd=random.Random(52)
CAM=dict(ro=(1.8,1.0,12.),ta=(-.1,6.4,0.),fov=2.15,roll=.05)
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread('L2_col.png'); aux=cv2.imread('L2_aux.png'); H,W=col.shape[:2]
detail=aux[...,2].astype(np.float32)/255.
op=P((0,4.35,1.6)); print('opening',op)
cfg=dict(sat=1.22,con=1.08,radii=(7,4,1),jit=.035,bg_angles=(-.5,),
 layers=[(64,0,.45,.5,.9,(1.8,3.6)),(40,0,.45,.45,.9,(1.6,3.2)),(26,0,.6,.4,.9,(1.4,3.)),(13,.25,1.,.45,.85,(1.3,2.8)),(6,.6,1.,.5,.8,(1.2,2.5)),(3,.92,1.,.4,.5,(1.,2.))])
c,base=knife.paint(col,aux,rnd,cfg)
c=knife.edge_accents(c,aux,rnd,.35,2)
c=knife.speckle(c,base,detail,2500,rnd,.5,1.3,.8,alpha=.4,lmin=.6)
c=knife.finish(c,detail,.9)
c=knife.grade(c,1.12,1.06,-.02)
f=to_f(c)
# burst of light out of the shell opening + flying sparks + speed lines behind Tung
yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
r=rays((H,W),op,20,300,1300,10,40,rnd,rot=.1)*.28*np.clip((op[1]-60-yy)/250,0,1)
f=screen_add(f,np.stack([r*.35,r*.8,r],-1))
f=glow(f,op-np.array([0,40]),45,(.6,.9,1.),.45,2); f=glow(f,op-np.array([0,40]),200,(.1,.5,1.),.18,1.6)
sp=sparks((H,W),op-np.array([0,60]),45,80,520,rnd,6,22); f=screen_add(f,np.stack([sp*.3,sp*.8,sp],-1)*.8)
for i in range(30):
    a=rnd.uniform(0,6.28); d=rnd.uniform(120,620); x=op[0]+math.cos(a)*d*1.3; y=op[1]+math.sin(a)*d*.7-120; r0=rnd.uniform(2,5)
    f=glow(f,(x,y),r0*2.5,(.45,.9,1.),rnd.uniform(.25,.6),2)
out=to_u8(np.clip(f,0,1))
cv2.imwrite('L2_final.png',out)
