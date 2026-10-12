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

def ridged(th, rnd, k0, k1, n, amp=1.):
    v=np.zeros_like(th)
    for i in range(n):
        k=rnd.randint(k0,k1); ph=rnd.uniform(0,6.283); a=rnd.uniform(.5,1.)/(1+i*.35)
        v+=a*(1-np.abs(np.sin(k*th*.5+ph)))**2.2
    return v/max(1e-6,v.max())*amp
def flame_bg(col, aux, bg, rnd):
    H,W=col.shape[:2]; f=col.astype(np.float32)/255.
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    m=(aux[...,1]>=bg.get('far',250)).astype(np.float32)
    if bg.get('ground_too'): m=np.maximum(m,((aux[...,0]<16)&(yy<H*bg.get('ground_y',.7))).astype(np.float32))
    top=np.array(bg.get('sky_top',[1.,.55,.16]),np.float32); bot=np.array(bg.get('sky_bot',[1.,.92,.74]),np.float32)
    t=np.clip(yy/H,0,1)[...,None]; sky=top*(1-t)+bot*t
    c=bg['at']; R=bg.get('r',900.)
    dx=xx-c[0]; dy=(yy-c[1])*bg.get('squash',1.); r=np.sqrt(dx*dx+dy*dy)/R; th=np.arctan2(dy,dx)+r*bg.get('twist',.35)
    out=sky.copy()
    layers=bg.get('layers',[[1.0,.38,[.85,.12,.45]],[.72,.3,[.75,.25,1.]],[.45,.22,[.55,.75,1.]],[.22,.12,[.85,.97,1.]]])
    def tongues(n,s0,s1):
        F=np.zeros_like(th)
        for j in range(n):
            phi=rnd.uniform(-math.pi,math.pi); sg=rnd.uniform(s0,s1); h=rnd.uniform(.4,1.)
            d=(th-phi+math.pi)%(2*math.pi)-math.pi
            F=np.maximum(F,h*np.clip(1-np.abs(d)/sg,0,1)**1.5)
        return F
    for i,(rad,amp,cl) in enumerate(layers):
        lick=rad*(1-amp)+rad*amp*(tongues(bg.get('tongues',24),.1,.32)*.85+.15*ridged(th,rnd,8,30,4))
        a=np.clip((lick-r)/(.035+.02*i),0,1)
        a=cv2.GaussianBlur(a,(0,0),1.5)
        out=out*(1-a[...,None])+np.array(cl,np.float32)*a[...,None]
    # white speed lines converging on the burst centre
    sl=np.zeros((H,W),np.float32); sp=bg.get('speed',{})
    for i in range(sp.get('n',70)):
        a=rnd.uniform(0,6.283); r0=rnd.uniform(*sp.get('r0',[.55,1.0]))*R; L=3000.; w=rnd.uniform(*sp.get('w',[2.,9.]))
        d=np.array([math.cos(a),math.sin(a)]); nrm=np.array([-d[1],d[0]]); p0=np.array(c)+d*r0; p1=np.array(c)+d*(r0+L)
        poly=np.array([p0,p1+nrm*w*6,p1-nrm*w*6],np.float32)
        cv2.fillPoly(sl,[np.round(poly*4).astype(np.int32)],float(rnd.uniform(.45,.95)),cv2.LINE_AA,shift=2)
    sl=cv2.GaussianBlur(sl,(0,0),1.)*sp.get('k',.8)
    out=out*(1-sl[...,None])+sl[...,None]
    f=f*(1-m[...,None])+out*m[...,None]
    return (np.clip(f,0,1)*255).astype(np.uint8)
if cfgj.get('bg'): col2=flame_bg(col2,aux,cfgj['bg'],rnd)

def clean_render(col, aux, cj):
    """glossy 'home page' look: punchy color, bloom, crisp dark outline around near characters"""
    f=col.astype(np.float32)/255.
    L=(f[...,0]*.114+f[...,1]*.587+f[...,2]*.299)[...,None]
    f=L+(f-L)*cj.get('sat',1.25); f=np.clip((f-.5)*cj.get('con',1.08)+.5,0,1)
    f=f*.6+(f*f*(3-2*f))*.4
    hi=np.clip(f-.72,0,1); f=1-(1-f)*(1-cv2.GaussianBlur(hi,(0,0),14)*cj.get('bloom',.55))
    g=aux[...,0].astype(np.int32)//16; d=aux[...,1].astype(np.float32)
    fg=(g>0)&(d<cj.get('outline_depth',60))
    e=np.zeros(g.shape,bool)
    for dy,dx in [(0,1),(1,0),(1,1),(1,-1)]:
        gs=np.roll(np.roll(g,dy,0),dx,1); ds=np.roll(np.roll(d,dy,0),dx,1); fs=np.roll(np.roll(fg,dy,0),dx,1)
        e|=((g!=gs)|(np.abs(d-ds)>cj.get('depth_jump',6)))&(fg|fs)
    e[:2,:]=False; e[-2:,:]=False; e[:,:2]=False; e[:,-2:]=False
    w=cj.get('outline',3)
    m=cv2.dilate(e.astype(np.uint8),cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(w,w))).astype(np.float32)
    m=cv2.GaussianBlur(m,(0,0),.7)*cj.get('outline_a',.85)
    oc=np.array(cj.get('outline_col',[.1,.06,.08]),np.float32)
    f=f*(1-m[...,None])+oc*m[...,None]
    bl=cv2.GaussianBlur(f,(0,0),1.2); f=np.clip(f+(f-bl)*.6,0,1)
    return (f*255).astype(np.uint8)
if cfgj.get('clean'):
    c=clean_render(col2,aux2,cfgj)
else:
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
f=to_f(c)

# ---- light FX after painting
for rg in cfgj.get('rings',[]):   # shockwave rings
    m=np.zeros((H,W),np.float32)
    cv2.ellipse(m,(int(rg['at'][0]*4),int(rg['at'][1]*4)),(int(rg['rx']*4),int(rg['ry']*4)),rg.get('rot',0),rg.get('a0',0),rg.get('a1',360),1.,int(rg.get('w',10)),cv2.LINE_AA,shift=2)
    cr=np.array(rg.get('col',[.85,.95,1.]),np.float32)
    f=screen_add(f,cv2.GaussianBlur(m,(0,0),rg.get('soft',3))[...,None]*cr*rg.get('k',.9))
    f=screen_add(f,cv2.GaussianBlur(m,(0,0),22)[...,None]*cr*rg.get('k',.9)*.6)
for ac in cfgj.get('arcs',[]):    # swoosh / motion-blur arcs
    for i in range(ac.get('n',4)):
        m=np.zeros((H,W),np.float32); rr=ac['r']*(1-.09*i); a0=ac['a0']+i*ac.get('da',6); a1=ac['a1']-i*ac.get('db',4)
        pts=[(ac['c'][0]+math.cos(math.radians(a))*rr, ac['c'][1]+math.sin(math.radians(a))*rr*ac.get('sy',1.)) for a in np.linspace(a0,a1,60)]
        pts=np.array(pts,np.float32); n=len(pts)
        T=np.gradient(pts,axis=0); T/=np.linalg.norm(T,axis=1,keepdims=True)+1e-9; N=np.stack([-T[:,1],T[:,0]],1)
        wv=ac.get('w',26)*(1-.18*i)*np.sin(np.linspace(0,1,n)**.7*np.pi)[:,None]
        poly=np.concatenate([pts+N*wv*.5,(pts-N*wv*.5)[::-1]],0)
        cv2.fillPoly(m,[np.round(poly*4).astype(np.int32)],1.,cv2.LINE_AA,shift=2)
        fade=np.zeros((H,W),np.float32)
        m=cv2.GaussianBlur(m,(0,0),2.)*ac.get('k',.6)*(1-.15*i)
        f=screen_add(f,m[...,None]*np.array(ac.get('col',[1,.95,.85]),np.float32))
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
    ex=int(t.get('extrude',0))
    if ex>0:   # chunky 3D base: stroke mask pushed down
        ext=np.zeros_like(sa)
        for k in range(1,ex+1): ext[k:,:]=np.maximum(ext[k:,:],sa[:-k,:])
        sa_full=np.maximum(sa,ext)
    else: sa_full=sa
    sh=cv2.GaussianBlur(sa_full,(0,0),6)*.55; dy=int(t.get('shadow',10))
    shd=np.zeros_like(sa); shd[dy:,dy//2:]=sh[:-dy or None,:sh.shape[1]-dy//2 or None] if dy>0 else sh
    reg=reg*(1-shd[...,None])
    sc=np.array(t.get('stroke',[.25,.1,.08]),np.float32)
    if ex>0: reg=reg*(1-sa_full[...,None])+sc*.55*sa_full[...,None]
    reg=reg*(1-sa[...,None])+sc*sa[...,None]
    if ex>0:   # lift the face of the letters up off the extrusion
        pass
    yy=np.linspace(0,1,fa.shape[0])[:,None,None]
    top=np.array(t.get('top',[1,1,1]),np.float32); bot=np.array(t.get('bottom',[1,.9,.75]),np.float32)
    grad=top*(1-yy)+bot*yy
    if t.get('rainbow'):
        xx_=np.linspace(0,1,fa.shape[1])[None,:]
        hue=((xx_*.83+t.get('hue0',0.))%1.*179).astype(np.uint8); hue=np.repeat(hue,fa.shape[0],0)
        rbw=cv2.cvtColor(np.dstack([hue,np.full_like(hue,215),np.full_like(hue,255)]),cv2.COLOR_HSV2BGR).astype(np.float32)/255.
        grad=rbw*(1.08-.3*yy)
    if t.get('bevel',0):
        fb=cv2.GaussianBlur(fa,(0,0),t.get('bevel_r',3.)); gy_,gx_=np.gradient(fb)
        grad=np.clip(grad+(-(gy_*.8+gx_*.6))[...,None]*t['bevel'],0,1)
    reg=reg*(1-fa[...,None])+np.clip(grad,0,1)*fa[...,None]
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
for st in cfgj.get('stars',[]):   # cartoon impact star
    c=np.array(st['at'],np.float32); n=st.get('n',8); pts=[]
    for i in range(2*n):
        a=math.radians(st.get('rot',0))+i*math.pi/n; rr=(st['r'] if i%2==0 else st['r']*st.get('inner',.38))*(1+(rnd.uniform(-.25,.25) if i%2==0 else 0))
        pts.append(c+rr*np.array([math.cos(a),math.sin(a)]))
    m=np.zeros((H,W),np.float32); cv2.fillPoly(m,[np.round(np.array(pts)*4).astype(np.int32)],1.,cv2.LINE_AA,shift=2)
    f=screen_add(f,cv2.GaussianBlur(m,(0,0),st.get('r',100)*.25)[...,None]*np.array(st.get('glow',[.4,.8,1.]),np.float32))
    m=cv2.GaussianBlur(m,(0,0),1.)
    f=f*(1-m[...,None])+np.array(st.get('col',[1,1,1]),np.float32)*m[...,None]
for fl in cfgj.get('flames',[]): f=flames(f,fl,rnd,aux)
sil=cfgj.get('sil')
if sil:
    gv=int(round(sil.get('grp',6)/8*255)); sm=(np.abs(aux[...,0].astype(np.int32)-gv)<9).astype(np.uint8)
    ys,xs=np.nonzero(sm); cy,cx=ys.mean(),xs.mean()
    k=lambda r: cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2*r+1,2*r+1))
    blocked=np.zeros_like(sm)
    for gb in sil.get('block',[3]): blocked|=(np.abs(aux[...,0].astype(np.int32)-int(round(gb/8*255)))<9).astype(np.uint8)
    ring=(cv2.dilate(sm,k(sil.get('outline',6)))-sm).astype(np.float32)*(1-blocked)
    ring=cv2.GaussianBlur(ring,(0,0),1.)
    hue=((np.arctan2(yy-cy,xx-cx)/(2*np.pi)+.5)*179).astype(np.uint8)
    rb=cv2.cvtColor(np.dstack([hue,np.full_like(hue,230),np.full_like(hue,255)]),cv2.COLOR_HSV2BGR).astype(np.float32)/255.
    aura=cv2.GaussianBlur(cv2.dilate(sm,k(sil.get('aura',30))).astype(np.float32),(0,0),sil.get('aura',30)*.6)*(1-sm)
    aa=np.clip(aura*sil.get('aura_k',1.)*(1-.85*blocked),0,1)[...,None]; f=f*(1-aa)+rb*aa
    rb2=cv2.GaussianBlur(cv2.dilate(sm,k(sil.get('outline',6)+8)).astype(np.float32),(0,0),5)*(1-sm)*(1-blocked)
    f=screen_add(f,rb2[...,None]*rb*.9)
    f=f*(1-ring[...,None])+ring[...,None]
    smf=cv2.GaussianBlur(sm.astype(np.float32),(0,0),.8)[...,None]*sil.get('black',.85)
    f=f*(1-smf)+np.array([.03,.02,.04],np.float32)*smf
for pp in cfgj.get('petals',[]): f=petals(f,pp,rnd)
for t in cfgj.get('texts',[]): f=put_text(f,t)
out=to_u8(np.clip(f,0,1))
cv2.imwrite(f'{name}_final.png',out)
for k in cfgj.get('print',[]): print(k,P(k))
