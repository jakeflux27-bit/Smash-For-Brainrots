import numpy as np, cv2, math, random
from kuwa import kuwahara
from painter import orient_field, lum

def ss(a,b,x): t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)

def saturate(img, s=1.2, c=1.05):
    f=img.astype(np.float32)/255.; g=lum(f)[...,None]; f=g+(f-g)*s; f=(f-.5)*c+.5
    return np.clip(f*255,0,255).astype(np.uint8)

def base_layer(col, detail, radii=(8,4,1)):
    kb=kuwahara(col,radii[0],q=8).astype(np.float32); km=kuwahara(col,radii[1],q=8).astype(np.float32); kf=kuwahara(col,radii[2],q=6).astype(np.float32)
    d=cv2.GaussianBlur(detail,(0,0),5)[...,None]
    wf=ss(.75,.92,d); wm=ss(.2,.45,d)*(1-wf); wb=1-wf-wm
    return np.clip(kb*wb+km*wm+kf*wf,0,255).astype(np.uint8)

def knife_layer(canvas, src, ids, detail, R, dmin, dmax, density, alpha, lenr, rnd, bg_angles=(-.6,), jit=.06, ang_jit=.22, ridge=True, wmul=(.45,.95), sky=None):
    H,W=canvas.shape[:2]
    srcf=src.astype(np.float32)/255.
    blur=cv2.GaussianBlur(srcf,(0,0),max(R*.38,.7))
    theta,coh,mag=orient_field(blur,max(R*1.0,2))
    layer=canvas.copy(); mask=np.zeros((H,W),np.uint8)
    step=max(int(R*.8),1); pts=[]
    for gy in range(0,H,step):
        for gx in range(0,W,step):
            y=min(H-1,gy+rnd.randrange(step)); x=min(W-1,gx+rnd.randrange(step))
            if not (dmin<=detail[y,x]<=dmax) or rnd.random()>density: continue
            pts.append((y,x))
    rnd.shuffle(pts)
    for (y,x) in pts:
        if sky is not None and sky[y,x]:
            a=bg_angles[0]+rnd.gauss(0,.06)
            if R<20 and rnd.random()<.6: continue
        elif mag[y,x]<.02 or coh[y,x]<.25: a=rnd.choice(bg_angles)+rnd.gauss(0,ang_jit*1.4)
        else: a=theta[y,x]+rnd.gauss(0,ang_jit)
        d=np.array([math.cos(a),math.sin(a)],np.float32); n=np.array([-d[1],d[0]],np.float32)
        L=R*rnd.uniform(*lenr); w=R*rnd.uniform(*wmul)
        oid=ids[y,x]; c0=blur[y,x]
        ends=[]
        for sgn in (1,-1):
            t=0.
            while t<L/2:
                t2=t+max(R*.35,1.)
                px,py=x+sgn*d[0]*t2, y+sgn*d[1]*t2
                if not(0<=px<W-1 and 0<=py<H-1): break
                if ids[int(py),int(px)]!=oid or np.sum((blur[int(py),int(px)]-c0)**2)>.02: break
                t=t2
            ends.append(t)
        tf,tb=ends
        if tf+tb<R*.5: tf=tb=R*.25
        p0=np.array([x,y],np.float32)-d*tb; p1=np.array([x,y],np.float32)+d*tf
        # knife quad with slanted ends + slightly jagged sides
        sl=rnd.uniform(-.5,.5)*w
        k=5; side1=[]; side2=[]
        for i in range(k+1):
            t=i/k; p=p0+(p1-p0)*t
            side1.append(p+n*(w*.5+rnd.gauss(0,w*.06))+d*(sl*(1-t)))
            side2.append(p-n*(w*.5+rnd.gauss(0,w*.06))-d*(sl*t))
        poly=np.array(side1+side2[::-1],np.float32)
        jj=jit*(.45 if (sky is not None and sky[y,x]) else 1.)
        c=c0*(1+rnd.gauss(0,jj))+np.array([rnd.gauss(0,jj*.4) for _ in range(3)],np.float32)
        col=tuple(float(v) for v in np.clip(c*255,0,255))
        q=[np.round(poly*4).astype(np.int32)]
        cv2.fillPoly(layer,q,col,cv2.LINE_AA,shift=2); cv2.fillPoly(mask,q,255,cv2.LINE_AA,shift=2)
        if ridge and R>=12:
            for r_ in range(rnd.randint(0,2)):
                o=rnd.uniform(-.4,.4)*w; s=rnd.uniform(0,.3); e=rnd.uniform(.6,1.)
                a_=p0+(p1-p0)*s+n*o; b_=p0+(p1-p0)*e+n*o
                rc=tuple(float(v) for v in np.clip(c*rnd.choice([.9,.94,1.06,1.1])*255,0,255))
                cv2.line(layer,tuple((a_*4).astype(int)),tuple((b_*4).astype(int)),rc,1,cv2.LINE_AA,shift=2)
    m=(mask.astype(np.float32)/255.*alpha)[...,None]
    return np.clip(canvas.astype(np.float32)*(1-m)+layer.astype(np.float32)*m,0,255).astype(np.uint8), len(pts)

def speckle(img, src, detail, n, rnd, smin=.5, smax=2.0, bright_bias=.5, alpha=.6, lmin=0.):
    H,W=img.shape[:2]; f=src.astype(np.float32); out=img; img=img.copy(); L=lum(f/255.)
    for _ in range(n):
        x=rnd.randrange(W); y=rnd.randrange(H)
        if L[y,x]<lmin: continue
        c=f[y,x]*rnd.choice([.7,.8,1.2,1.35,1.5 if rnd.random()<bright_bias else .75])
        r=rnd.uniform(smin,smax)
        cv2.circle(img,(int(x*4),int(y*4)),max(1,int(r*4)),tuple(float(v) for v in np.clip(c,0,255)),-1,cv2.LINE_AA,shift=2)
    return cv2.addWeighted(out,1-alpha,img,alpha,0)

def blades(img, src, mask, n, rnd, light=None, light_r=500, light_col=(60,200,255), hmin=10, hmax=90, wmax=9):
    """sharp triangular grass blades, painted back to front"""
    H,W=img.shape[:2]; ys,xs=np.where(mask)
    if len(ys)==0: return img
    f=src.astype(np.float32); P=[]
    for _ in range(n):
        i=rnd.randrange(len(ys)); P.append((ys[i],xs[i]))
    P.sort()
    for (y,x) in P:
        t=(y/H)**1.8; L=hmin+(hmax-hmin)*t*rnd.uniform(.5,1.3); w=max(2,wmax*t*rnd.uniform(.5,1.2))
        lean=rnd.uniform(-.45,.45)
        tip=np.array([x+lean*L,y-L],np.float32); b0=np.array([x-w/2,y],np.float32); b1=np.array([x+w/2,y],np.float32)
        mid=(b0+tip)/2+np.array([lean*L*.15,0])
        c=f[y,x]*rnd.uniform(.7,1.4)
        if light is not None:
            dd=math.hypot(x-light[0],(y-light[1])*1.6); k=max(0,1-dd/light_r)**1.4
            c=c*(1-k*.5)+np.array(light_col,np.float32)*k*rnd.uniform(.7,1.1)
        poly=np.array([b0,mid,tip,b1],np.float32)
        cv2.fillPoly(img,[np.round(poly*4).astype(np.int32)],tuple(float(v) for v in np.clip(c,0,255)),cv2.LINE_AA,shift=2)
    return img

def finish(img, detail, sharp=.8):
    bl=cv2.GaussianBlur(img,(0,0),1.6).astype(np.float32); cf=img.astype(np.float32)
    k=(sharp*(.5+.7*cv2.GaussianBlur(detail,(0,0),4)))[...,None]
    return np.clip(cf+(cf-bl)*k,0,255).astype(np.uint8)

def paint(col, aux, rnd, cfg):
    detail=aux[...,2].astype(np.float32)/255.
    ids=(aux[...,0]//16).astype(np.int32)*4+(aux[...,1]>200).astype(np.int32)
    col=saturate(col,cfg.get('sat',1.18),cfg.get('con',1.06))
    base=base_layer(col,detail,cfg.get('radii',(8,4,1)))
    c=base.copy()
    for L in cfg['layers']:
        R,dmin,dmax,dens,alpha,lenr=L[:6]
        sky=(aux[...,1]>250)
        c,n=knife_layer(c,base,ids,detail,R,dmin,dmax,dens,alpha,lenr,rnd,bg_angles=cfg.get('bg_angles',(-.6,)),jit=cfg.get('jit',.06),sky=sky)
        print(f'  knife R={R}: {n}',flush=True)
    return c, base

def edge_accents(img, aux, rnd, strength=.55, width=2):
    """painterly dark accents along silhouettes (depth / object id breaks)"""
    d=aux[...,1].astype(np.float32); g=aux[...,0].astype(np.float32)
    e=(np.abs(cv2.Sobel(d,cv2.CV_32F,1,0,ksize=3))+np.abs(cv2.Sobel(d,cv2.CV_32F,0,1,ksize=3)))>40
    e|=(np.abs(cv2.Sobel(g,cv2.CV_32F,1,0,ksize=3))+np.abs(cv2.Sobel(g,cv2.CV_32F,0,1,ksize=3)))>20
    near=cv2.dilate(((g>16)&(g<200)).astype(np.uint8),np.ones((5,5),np.uint8))>0
    e&=near
    m=cv2.dilate(e.astype(np.uint8),np.ones((width,width),np.uint8)).astype(np.float32)
    n=cv2.resize(np.random.RandomState(5).rand(img.shape[0]//6+1,img.shape[1]//6+1).astype(np.float32),(img.shape[1],img.shape[0]))
    m=cv2.GaussianBlur(m,(0,0),1.)*(.5+.5*n)
    f=img.astype(np.float32)*(1-strength*m[...,None])
    return np.clip(f,0,255).astype(np.uint8)
def grade(img, contrast=1.12, sat=1.1, lift=-.03, shadow_tint=(0.06,0.0,-0.02)):
    f=img.astype(np.float32)/255.
    f=np.clip(f+lift,0,1); f=.5+(f-.5)*contrast
    s=f*f*(3-2*f); f=f*.5+s*.5                      # gentle S-curve
    L=lum(f)[...,None]; f=L+(f-L)*sat
    f=f+np.array(shadow_tint,np.float32)*(1-L)**2      # BGR: cool shadows
    return np.clip(f*255,0,255).astype(np.uint8)

def protect(painted, col, aux, lum_max=.32, dmin=.85, grow=2, amt=.9):
    """bring back crisp dark details (eyes, mouths, cracks) on high-detail objects after painting"""
    from kuwa import kuwahara
    colf=saturate(col,1.22,1.08)
    crisp=kuwahara(colf,2,q=6).astype(np.float32)
    L=lum(colf.astype(np.float32)/255.); d=aux[...,2].astype(np.float32)/255.
    m=((L<lum_max)&(d>dmin)).astype(np.uint8)
    m=cv2.dilate(m,np.ones((grow*2+1,grow*2+1),np.uint8)).astype(np.float32)
    m=cv2.GaussianBlur(m,(0,0),1.2)[...,None]*amt
    return np.clip(painted.astype(np.float32)*(1-m)+crisp*m,0,255).astype(np.uint8)
