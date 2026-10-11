import numpy as np, cv2, math, random, sys, json
sys.path.insert(0,'.')
from proj import project
from fx import *
import knife
name=sys.argv[1]; cfgj=json.loads(open(sys.argv[2]).read()) if sys.argv[2].endswith('.json') else json.loads(sys.argv[2])
rnd=random.Random(cfgj.get('seed',7))
CAM=cfgj['cam']
P=lambda X: np.array(X,float) if len(X)==2 else project(X,CAM['ro'],CAM['ta'],CAM['fov'],CAM['roll'])[0]
col=cv2.imread(f'{name}_col.png'); aux=cv2.imread(f'{name}_aux.png'); H,W=col.shape[:2]
yy,xx=np.mgrid[0:H,0:W].astype(np.float32)

# ---- painted-in-before-painting: dust clouds / steam puffs (so the knife strokes paint over them)
f=to_f(col); extra=np.zeros((H,W),np.float32)
for d in cfgj.get('dust',[]):
    c=P(d['at']); s=d.get('s',1.); tint=np.array(d.get('col',[.62,.78,.9]),np.float32)  # BGR
    m=np.zeros((H,W),np.float32)
    for k in range(d.get('n',9)):
        cx=c[0]+rnd.gauss(0,d.get('sx',70)*s); cy=c[1]+rnd.gauss(d.get('dy',-10),d.get('sy',22)*s); r=rnd.uniform(30,80)*s
        m=np.maximum(m,np.exp(-(((xx-cx)/r)**2+((yy-cy)/(r*.68))**2))*rnd.uniform(.5,.95))
    m=cv2.GaussianBlur(m,(0,0),5)*d.get('a',.55)
    if d.get('front',True)==False:   # only over the background (behind objects)
        m*=(aux[...,0]<16).astype(np.float32)
    f=f*(1-m[...,None])+tint[None,None,:]*m[...,None]; extra=np.maximum(extra,m)
col2=to_u8(np.clip(f,0,1)); aux2=aux.copy(); aux2[...,2]=np.maximum(aux2[...,2],(extra*110).astype(np.uint8))
detail=aux2[...,2].astype(np.float32)/255.

cfg=dict(sat=1.22,con=1.08,radii=(7,4,1),jit=.035,bg_angles=tuple(cfgj.get('bg_angles',[-.45])),
 layers=[(64,0,.45,.5,.9,(1.8,3.6)),(40,0,.45,.45,.9,(1.6,3.2)),(26,0,.6,.4,.9,(1.4,3.)),(13,.25,1.,.45,.85,(1.3,2.8)),(6,.6,1.,.5,.8,(1.2,2.5)),(3,.92,1.,.4,.5,(1.,2.))])
c,base=knife.paint(col2,aux2,rnd,cfg)
c=knife.edge_accents(c,aux2,rnd,.35,2)
bf=base.astype(np.float32)
green=(bf[...,1]>bf[...,2]*1.08)&(bf[...,1]>bf[...,0]*1.05)
gm=(aux2[...,0]<16)&(aux2[...,1]<cfgj.get('blade_depth',20))&(yy>H*cfgj.get('blade_y',.62))&green&(extra<.15)
c=knife.blades(c,(base.astype(np.float32)*.9).astype(np.uint8),gm,cfgj.get('blades',12000),rnd,light=None,hmin=8,hmax=cfgj.get('blade_h',110),wmax=11)
c=knife.speckle(c,base,detail,2500,rnd,.5,1.3,.8,alpha=.4,lmin=.6)
c=knife.protect(c,col2,aux2)
c=knife.finish(c,detail,.9)
c=knife.grade(c,1.1,1.06,-.02)
f=to_f(c)

# ---- light FX after painting
for s in cfgj.get('slam',[]):     # red warning circle on the ground (boss slam)
    cen=np.array(s['at'],float); R=s['r']; pts=[]
    for i in range(97):
        a=i/96*2*math.pi; pts.append(P(cen+np.array([math.cos(a)*R,0,math.sin(a)*R])))
    pts=np.array(pts,np.float32)
    fillm=np.zeros((H,W),np.float32); cv2.fillPoly(fillm,[np.round(pts*4).astype(np.int32)],1.,cv2.LINE_AA,shift=2)
    ring=np.zeros((H,W),np.float32); cv2.polylines(ring,[np.round(pts*4).astype(np.int32)],True,1.,int(s.get('w',10)),cv2.LINE_AA,shift=2)
    vis=(aux[...,0]<16).astype(np.float32) if s.get('ground_only',True) else 1.
    fillm=cv2.GaussianBlur(fillm,(0,0),3)*vis; ring=cv2.GaussianBlur(ring,(0,0),2.5)*vis
    red=np.array([.12,.12,1.],np.float32)
    f=f*(1-fillm[...,None]*s.get('fill',.35))+red*fillm[...,None]*s.get('fill',.35)*.9
    f=screen_add(f,ring[...,None]*np.array([.35,.45,1.],np.float32))
    f=screen_add(f,cv2.GaussianBlur(ring,(0,0),14)[...,None]*np.array([.1,.15,1.],np.float32)*.9)
for g in cfgj.get('glows',[]):
    p=P(g['at']); f=glow(f,p,g['r'],g['col'],g['k'],g.get('pow',1.6))
for b in cfgj.get('bursts',[]):
    p=P(b['at']); colr=np.array(b.get('col',[.35,.82,1.]),np.float32)
    r=rays((H,W),p,b.get('n',18),b.get('l0',200),b.get('l1',800),b.get('w0',5),b.get('w1',18),rnd,rot=.2)*b.get('k',.4)
    if b.get('behind',False): r*=(aux[...,1]>200).astype(np.float32)*.85+.15
    f=screen_add(f,r[...,None]*colr)
    f=glow(f,p,b.get('core_r',40),tuple(colr*.5+.5),b.get('core',.8),2); f=glow(f,p,b.get('halo_r',170),tuple(colr*.6),b.get('halo',.3),1.6)
    sp=sparks((H,W),p,b.get('sparks',60),b.get('s0',40),b.get('s1',500),rnd,8,40); f=screen_add(f,sp[...,None]*colr)
for st in cfgj.get('streaks',[]):  # brushy motion streaks
    for k in range(st.get('n',6)):
        a=np.array(st['from'],np.float32)+np.array([rnd.gauss(0,st.get('jx',30)),rnd.gauss(0,st.get('jy',60))],np.float32)
        L=rnd.uniform(*st.get('len',[160,320])); dv=np.array(st['dir'],np.float32); dv/=np.linalg.norm(dv)
        pts=[a+dv*L*t+np.array([0,math.sin(t*3)*4]) for t in np.linspace(0,1,24)]
        m=ribbon((H,W),pts,rnd.uniform(4,9),1,rnd,blur=1.2)*st.get('k',.55)
        f=screen_add(f,m[...,None]*np.array(st.get('col',[1,1,1]),np.float32))
mc=tuple(cfgj.get('motecol',[.45,.9,1.]))
for i in range(cfgj.get('motes',30)):
    x=rnd.uniform(0,W); y=rnd.uniform(H*.1,H*.8); r0=rnd.uniform(2,5)
    f=glow(f,(x,y),r0*2.5,mc,rnd.uniform(.2,.5),2)
for sp in cfgj.get('sparkles',[]):  # 4-point twinkles
    c0=P(sp['at'])
    for i in range(sp.get('n',8)):
        a=rnd.uniform(0,2*math.pi); rr=rnd.uniform(sp.get('r0',60),sp.get('r1',260)); x=c0[0]+math.cos(a)*rr; y=c0[1]+math.sin(a)*rr*.9
        s=rnd.uniform(10,26)*sp.get('size',1.)
        m=np.zeros((H,W),np.float32)
        for (dx,dy) in [(1,0),(0,1)]:
            cv2.line(m,(int((x-dx*s)*4),int((y-dy*s)*4)),(int((x+dx*s)*4),int((y+dy*s)*4)),1.,2,cv2.LINE_AA,shift=2)
        m=cv2.GaussianBlur(m,(0,0),1.)
        f=screen_add(f,m[...,None]*np.array(sp.get('col',[.6,.95,1.]),np.float32))
        f=glow(f,(x,y),s*.5,tuple(sp.get('col',[.6,.95,1.])),.6,2)

from PIL import Image, ImageDraw, ImageFont
def text_layer(txt, size, sw, font):
    fnt=ImageFont.truetype(font,size)
    bb=fnt.getbbox(txt, stroke_width=sw); pad=sw*3
    w,h=bb[2]-bb[0]+pad*2, bb[3]-bb[1]+pad*2
    def mk(stroke):
        im=Image.new('L',(w,h),0); d=ImageDraw.Draw(im)
        d.text((pad-bb[0],pad-bb[1]),txt,font=fnt,fill=255,stroke_width=stroke,stroke_fill=255); return im
    return mk(0), mk(sw)
def put_text(f, t):
    fm,sm=text_layer(t['txt'],t['size'],t.get('sw',14),t.get('font','fonts/LuckiestGuy.ttf'))
    fm=fm.rotate(t.get('rot',0),resample=Image.BICUBIC,expand=True); sm=sm.rotate(t.get('rot',0),resample=Image.BICUBIC,expand=True)
    fa=np.array(fm).astype(np.float32)/255.; sa=np.array(sm).astype(np.float32)/255.
    h,w=fa.shape; x0=int(t['at'][0]-w/2); y0=int(t['at'][1]-h/2)
    H,W=f.shape[:2]; xs0,ys0=max(0,x0),max(0,y0); xs1,ys1=min(W,x0+w),min(H,y0+h)
    fa=fa[ys0-y0:ys1-y0, xs0-x0:xs1-x0]; sa=sa[ys0-y0:ys1-y0, xs0-x0:xs1-x0]
    reg=f[ys0:ys1,xs0:xs1]
    sh=cv2.GaussianBlur(sa,(0,0),6)*.55; dy=int(t.get('shadow',10))
    shd=np.zeros_like(sa); shd[dy:,dy//2:]=sh[:-dy or None,:sh.shape[1]-dy//2 or None] if dy>0 else sh
    reg=reg*(1-shd[...,None])
    sc=np.array(t.get('stroke',[.25,.1,.08]),np.float32); reg=reg*(1-sa[...,None])+sc*sa[...,None]
    yy=np.linspace(0,1,fa.shape[0])[:,None,None]
    top=np.array(t.get('top',[1,1,1]),np.float32); bot=np.array(t.get('bottom',[1,.9,.75]),np.float32)
    grad=top*(1-yy)+bot*yy
    reg=reg*(1-fa[...,None])+grad*fa[...,None]
    # small glossy highlight streak in the upper part of the letters
    hl=fa*(yy[...,0]<.32)*(yy[...,0]>.1)*.35; reg=reg*(1-hl[...,None])+hl[...,None]
    f[ys0:ys1,xs0:xs1]=reg
    return f
def petals(f, pp, rnd):
    H,W=f.shape[:2]
    for i in range(pp.get('n',60)):
        x=rnd.uniform(*pp.get('x',[0,W])); y=rnd.uniform(*pp.get('y',[0,H*.8])); s=rnd.uniform(*pp.get('s',[5,13]))
        big=rnd.random()<pp.get('near',.12)
        if big: s*=2.6
        m=np.zeros((H,W),np.float32)
        cv2.ellipse(m,(int(x*4),int(y*4)),(int(s*4),int(s*.55*4)),rnd.uniform(0,180),0,360,1.,-1,cv2.LINE_AA,shift=2)
        m=cv2.GaussianBlur(m,(0,0),3.5 if big else .8)
        c=np.array(pp.get('col',[.82,.7,1.]),np.float32)*rnd.uniform(.9,1.08)
        f=f*(1-m[...,None]*.92)+c*m[...,None]*.92
    return f

def flames(f, fl, rnd, aux):
    H,W=f.shape[:2]; cx,cy=fl['at']; rx,ry=fl['rx'],fl['ry']
    outer=np.zeros((H,W),np.float32); inner=np.zeros((H,W),np.float32)
    yy0=np.mgrid[0:H,0:W][0].astype(np.float32)
    n=fl.get('n',16)
    for i in range(n):
        a=math.radians(fl.get('a0',190))+(math.radians(fl.get('a1',350))-math.radians(fl.get('a0',190)))*(i+rnd.uniform(.1,.9))/n
        bx=cx+math.cos(a)*rx; by=cy+math.sin(a)*ry
        up=-math.sin(a); L=rnd.uniform(*fl.get('len',[90,200]))*(.55+.7*up)
        lean=math.cos(a)*fl.get('spread',.6)
        w=rnd.uniform(*fl.get('w',[50,80]))*(.7+.5*up)
        tip=(bx+lean*L+rnd.gauss(0,14), by-L)
        sw=rnd.choice([-1,1])*rnd.uniform(10,26)
        c1=(bx+lean*L*.1+sw, by-L*.33); c2=(bx+lean*L*.6-sw, by-L*.7)
        cl=bezier((bx,by),c1,c2,tip,30)
        T=np.gradient(cl,axis=0); T/=np.linalg.norm(T,axis=1,keepdims=True)+1e-9; N=np.stack([-T[:,1],T[:,0]],1)
        t=np.linspace(0,1,30)[:,None]
        prof=np.sin(np.clip(t*1.15+.12,0,1)*math.pi)*(1-t)**.6
        for layer,scale,val in ((outer,1.,rnd.uniform(.6,.9)),(inner,.45,rnd.uniform(.7,1.))):
            ww=w*.5*scale*prof
            poly=np.concatenate([cl+N*ww, (cl-N*ww)[::-1]],0)
            tmp=np.zeros_like(layer); cv2.fillPoly(tmp,[np.round(poly*4).astype(np.int32)],val,cv2.LINE_AA,shift=2)
            fade=np.clip((yy0-(by-L))/max(L,1)*1.4,0,1)**.7
            np.maximum(layer,tmp*fade,out=layer)
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    egg=((((xx-cx)/(rx*.98))**2+((yy-cy)/(ry*.98))**2)<1.).astype(np.float32)
    eggm=cv2.GaussianBlur(egg,(0,0),3)*fl.get('occlude',.9)
    outer=cv2.GaussianBlur(outer,(0,0),2.5)*(1-eggm); inner=cv2.GaussianBlur(inner,(0,0),2.5)*(1-eggm)
    co=np.array(fl.get('outer',[1.,.25,.75]),np.float32); ci=np.array(fl.get('inner',[1.,.8,1.]),np.float32)
    f=screen_add(f,cv2.GaussianBlur(outer,(0,0),22)[...,None]*co*fl.get('glow',.8))
    f=f*(1-outer[...,None]*.85)+co*outer[...,None]*.85
    f=screen_add(f,inner[...,None]*ci*.9)
    return f
for fl in cfgj.get('flames',[]): f=flames(f,fl,rnd,aux)
for pp in cfgj.get('petals',[]): f=petals(f,pp,rnd)
for t in cfgj.get('texts',[]): f=put_text(f,t)
out=to_u8(np.clip(f,0,1))
cv2.imwrite(f'{name}_final.png',out)
for k in cfgj.get('print',[]): print(k,P(k))
