import numpy as np, cv2, math, random
from kuwa import kuwahara
from painter import orient_field, lum

def ss(a,b,x): t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)

def make_base(col, detail, radii=(11,6,2)):
    d0=detail
    kb=kuwahara(col,radii[0],q=6).astype(np.float32); km=kuwahara(col,radii[1],q=6).astype(np.float32); kf=kuwahara(col,radii[2],q=4).astype(np.float32)
    d=cv2.GaussianBlur(detail,(0,0),6)[...,None]
    wf=ss(.7,.88,d); wm=ss(.18,.42,d)*(1-wf); wb=1-wf-wm
    return np.clip(kb*wb+km*wm+kf*wf,0,255).astype(np.uint8)

def stroke_layer(canvas, src, ids, detail, R, dmin, dmax, density, maxLen, minLen, alpha, rnd, jit=.025, bg_angle=-.6, width=1.0, respect=True):
    H,W=canvas.shape[:2]
    srcf=src.astype(np.float32)/255.
    blur=cv2.GaussianBlur(srcf,(0,0),max(R*.35,.7))
    theta,coh,mag=orient_field(blur,max(R*1.1,2))
    layer=canvas.copy(); mask=np.zeros((H,W),np.uint8)
    step=max(int(R*.9),1); n=0
    pts_all=[]
    for gy in range(0,H,step):
        for gx in range(0,W,step):
            y=min(H-1,gy+rnd.randrange(step)); x=min(W-1,gx+rnd.randrange(step))
            d=detail[y,x]
            if d<dmin or d>dmax: continue
            if rnd.random()>density: continue
            pts_all.append((y,x))
    rnd.shuffle(pts_all)
    for (y,x) in pts_all:
        c=blur[y,x].copy(); oid=ids[y,x]
        pts=[(float(x),float(y))]; ld=None; fx,fy=float(x),float(y)
        L=int(minLen+rnd.random()*(maxLen-minLen))
        for i in range(L):
            iy,ix=int(fy),int(fx)
            if mag[iy,ix]<.015 or coh[iy,ix]<.2: a=bg_angle+(rnd.random()-.5)*.6
            else: a=theta[iy,ix]
            dv=np.array([math.cos(a),math.sin(a)])
            if ld is not None:
                if dv@ld<0: dv=-dv
                dv=.55*dv+.45*ld; dv/=np.linalg.norm(dv)+1e-9
            nx,ny=fx+R*.8*dv[0],fy+R*.8*dv[1]
            if not(0<=nx<W-1 and 0<=ny<H-1): break
            if respect and ids[int(ny),int(nx)]!=oid: break
            if i>=minLen and np.sum((blur[int(ny),int(nx)]-c)**2)>.012: break
            fx,fy=nx,ny; pts.append((fx,fy)); ld=dv
        draw_bristles(layer,mask,pts,c,R*width,rnd,jit)
        n+=1
    m=(mask.astype(np.float32)/255.*alpha)[...,None]
    out=canvas.astype(np.float32)*(1-m)+layer.astype(np.float32)*m
    print(f'  R={R}: {n} strokes',flush=True)
    return np.clip(out,0,255).astype(np.uint8)

def draw_bristles(layer,mask,pts,c,R,rnd,jit):
    P=np.array(pts,np.float32)
    if len(P)==1:
        a=rnd.random()*6.28; P=np.vstack([P-[math.cos(a)*R*.4,math.sin(a)*R*.4],P+[math.cos(a)*R*.4,math.sin(a)*R*.4]]).astype(np.float32)
    T=np.gradient(P,axis=0); T/=np.linalg.norm(T,axis=1,keepdims=True)+1e-9
    N=np.stack([-T[:,1],T[:,0]],1)
    nb=int(np.clip(R/1.8,2,12))
    base=c*(1+rnd.gauss(0,jit))
    taper=(0.65+0.35*np.sin(np.linspace(0.15,np.pi-0.15,len(P))))[:,None]
    for b in range(nb):
        off=((b+.5)/nb-.5)*2*R+rnd.uniform(-.3,.3)*R/nb
        Q=P+N*off*taper
        n=len(Q); s,e=0,n
        if n>2:
            s=int(rnd.random()**2.5*n*.4); e=n-int(rnd.random()**2.5*n*.4)
            if e-s<2: s,e=0,n
        Q=Q[s:e]
        col=np.clip(base*(1+rnd.gauss(0,jit*.8))*255,0,255)
        bw=max(1,int(round(2*R/nb*rnd.uniform(1.15,1.6))))
        q=[np.round(Q*4).astype(np.int32)]
        cv2.polylines(layer,q,False,tuple(float(v) for v in col),bw,cv2.LINE_AA,shift=2)
        cv2.polylines(mask,q,False,255,bw,cv2.LINE_AA,shift=2)

def scratches(img, src, detail, n, rnd, lmin=.86, amt=.32, minlen=20, maxlen=90, mask=None):
    H,W=img.shape[:2]; f=src.astype(np.float32)/255.
    L=lum(f); theta,coh,mag=orient_field(cv2.GaussianBlur(f,(0,0),3),7)
    over=img.copy(); cond=(L>lmin)&(detail>.15)
    if mask is not None: cond&=mask
    ys,xs=np.where(cond)
    if len(ys)==0: return img
    for _ in range(n):
        i=rnd.randrange(len(ys)); y,x=ys[i],xs[i]; a=theta[y,x]+rnd.gauss(0,.12); ln=rnd.uniform(minlen,maxlen)
        p0=np.array([x-math.cos(a)*ln/2,y-math.sin(a)*ln/2]); p1=np.array([x+math.cos(a)*ln/2,y+math.sin(a)*ln/2])
        col=np.clip(f[y,x]*1.1+.13,0,1)*255
        cv2.line(over,tuple((p0*4).astype(int)),tuple((p1*4).astype(int)),tuple(float(v) for v in col),1,cv2.LINE_AA,shift=2)
    return cv2.addWeighted(img,1-amt,over,amt,0)

def grade(img, sat=1.15, warm=.06, cool=.07, vig=.35, contrast=1.08):
    f=img.astype(np.float32)/255.
    g=lum(f)[...,None]; f=g+(f-g)*sat
    f=(f-.5)*contrast+.5
    L=lum(np.clip(f,0,1))[...,None]
    f=f+np.array([-.4,-.1,.5])*cool*(1-L)**2+np.array([-.3,.15,.45])*0  # BGR: shadows to blue/purple
    f=f+np.array([-.5,.1,.6])*warm*L**2                                   # highlights warm
    H,W=f.shape[:2]; yy,xx=np.mgrid[0:H,0:W]; r=np.sqrt(((xx-W/2)/(W/2))**2+((yy-H/2)/(H/2))**2)
    f*=(1-vig*np.clip(r-.55,0,None)**1.6)[...,None]
    return np.clip(f*255,0,255).astype(np.uint8)

def canvas_texture(img, seed=3, amt=.06):
    H,W=img.shape[:2]; rs=np.random.RandomState(seed)
    n=rs.rand(H,W).astype(np.float32)
    n=cv2.GaussianBlur(n,(0,0),.7)
    fib=cv2.GaussianBlur(rs.rand(H,W).astype(np.float32),(0,0),sigmaX=6,sigmaY=.6)
    t=(n-.5)*1.0+(fib-.5)*2.0
    f=img.astype(np.float32)*(1+amt*t[...,None])
    return np.clip(f,0,255).astype(np.uint8)

def paint_all(col, aux, rnd, cfg):
    detail=aux[...,2].astype(np.float32)/255.
    ids=(aux[...,0]//16).astype(np.int32)*4+(aux[...,1]>200).astype(np.int32)
    base=make_base(col,detail,cfg.get('radii',(11,6,2)))
    c=base.copy()
    for (R,dmin,dmax,dens,maxL,minL,alpha,resp) in cfg['layers']:
        c=stroke_layer(c,base,ids,detail,R,dmin,dmax,dens,maxL,minL,alpha,rnd,jit=cfg.get('jit',.025),bg_angle=cfg.get('bg_angle',-.6),respect=resp)
    c=scratches(c,base,detail,cfg.get('scratch',1800),rnd,mask=(detail<.8)&(aux[...,0]<80))
    # crisp digital-painting finish: unsharp mask, stronger on detailed areas
    bl=cv2.GaussianBlur(c,(0,0),2.2).astype(np.float32); cf=c.astype(np.float32)
    k=(0.35+0.9*cv2.GaussianBlur(detail,(0,0),4))[...,None]
    c=np.clip(cf+(cf-bl)*k,0,255).astype(np.uint8)
    return c, base

def grass(img, src, mask, n, rnd, light=None, light_r=300, light_col=(80,190,255), hmin=8, hmax=46, lean=-.15):
    H,W=img.shape[:2]; ys,xs=np.where(mask)
    if len(ys)==0: return img
    f=src.astype(np.float32)
    order=list(range(n))
    pts=[]
    for _ in range(n):
        i=rnd.randrange(len(ys)); pts.append((ys[i],xs[i]))
    pts.sort()                       # paint back to front
    for (y,x) in pts:
        t=(y/H)**1.6; L=hmin+(hmax-hmin)*t*rnd.uniform(.6,1.3)
        bend=rnd.uniform(-.5,.5)+lean
        p0=np.array([x,y],np.float32); p1=p0+np.array([bend*L*.3,-L*.5]); p2=p0+np.array([bend*L,-L])
        tt=np.linspace(0,1,6)[:,None]; Q=(1-tt)**2*p0+2*(1-tt)*tt*p1+tt**2*p2
        c=f[y,x]*rnd.uniform(.75,1.35)
        if light is not None:
            d=math.hypot(x-light[0],(y-light[1])*1.8); k=max(0,1-d/light_r)**1.5
            c=c*(1-k*.6)+np.array(light_col,np.float32)*k*rnd.uniform(.7,1.1)
        w=max(1,int(1+2.2*t*rnd.random()))
        cv2.polylines(img,[np.round(Q*4).astype(np.int32)],False,tuple(float(v) for v in np.clip(c,0,255)),w,cv2.LINE_AA,shift=2)
    return img
