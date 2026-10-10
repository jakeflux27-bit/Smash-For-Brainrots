import numpy as np, cv2, math, random, sys, json
sys.path.insert(0,'.')
from proj import project
from fx import *
import knife
name=sys.argv[1]; cfgj=json.loads(sys.argv[2])
rnd=random.Random(cfgj.get('seed',7))
CAM=cfgj['cam']
P=lambda X: project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread(f'{name}_col.png'); aux=cv2.imread(f'{name}_aux.png'); H,W=col.shape[:2]
detail=aux[...,2].astype(np.float32)/255.
cfg=dict(sat=1.22,con=1.08,radii=(7,4,1),jit=.035,bg_angles=(-.45,),
 layers=[(64,0,.45,.5,.9,(1.8,3.6)),(40,0,.45,.45,.9,(1.6,3.2)),(26,0,.6,.4,.9,(1.4,3.)),(13,.25,1.,.45,.85,(1.3,2.8)),(6,.6,1.,.5,.8,(1.2,2.5)),(3,.92,1.,.4,.5,(1.,2.))])
c,base=knife.paint(col,aux,rnd,cfg)
c=knife.edge_accents(c,aux,rnd,.35,2)
yy,xx=np.mgrid[0:H,0:W]
gm=(aux[...,0]<16)&(aux[...,1]<20)&(yy>H*.62)
c=knife.blades(c,(base.astype(np.float32)*.9).astype(np.uint8),gm,cfgj.get('blades',12000),rnd,light=None,hmin=8,hmax=110,wmax=11)
c=knife.speckle(c,base,detail,2500,rnd,.5,1.3,.8,alpha=.4,lmin=.6)
c=knife.protect(c,col,aux)
c=knife.finish(c,detail,.9)
c=knife.grade(c,1.1,1.06,-.02)
f=to_f(c)
for g in cfgj.get('glows',[]):
    p=P(g['at']); f=glow(f,p,g['r'],g['col'],g['k'],g.get('pow',1.6))
for b in cfgj.get('bursts',[]):
    p=P(b['at'])
    r=rays((H,W),p,b.get('n',18),b.get('l0',200),b.get('l1',800),b.get('w0',5),b.get('w1',18),rnd,rot=.2)*b.get('k',.4)
    f=screen_add(f,np.stack([r*.35,r*.82,r],-1))
    f=glow(f,p,40,(.75,.95,1.),b.get('core',.8),2); f=glow(f,p,170,(.1,.55,1.),.3,1.6)
    sp=sparks((H,W),p,b.get('sparks',60),40,500,rnd,8,40); f=screen_add(f,np.stack([sp*.35,sp*.85,sp],-1))
for i in range(cfgj.get('motes',30)):
    x=rnd.uniform(0,W); y=rnd.uniform(H*.1,H*.8); r0=rnd.uniform(2,5)
    f=glow(f,(x,y),r0*2.5,(.45,.9,1.),rnd.uniform(.2,.5),2)
out=to_u8(np.clip(f,0,1))
cv2.imwrite(f'{name}_final.png',out)
for k,v in [('impact',cfgj.get('bursts',[{}])[0].get('at')),]:
    if v: print(k,P(v))
