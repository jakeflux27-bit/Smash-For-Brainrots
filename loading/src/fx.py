import numpy as np, cv2, math, random
def to_f(img): return img.astype(np.float32)/255.
def to_u8(f): return np.clip(f*255,0,255).astype(np.uint8)
def glow(f, c, r, col, k=1.0, power=2.0):
    H,W=f.shape[:2]; yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    d=np.sqrt((xx-c[0])**2+(yy-c[1])**2)/r
    g=np.exp(-d**power)*k
    f+=g[...,None]*np.array(col,np.float32)[None,None,:]
    return f
def screen_add(f, layer, alpha=1.0):  # screen blend
    return 1-(1-f)*(1-np.clip(layer*alpha,0,1))
def rays(shape, c, n, lmin, lmax, wmin, wmax, rnd, rot=0):
    H,W=shape[:2]; m=np.zeros((H,W),np.float32)
    for i in range(n):
        a=rot+i*2*math.pi/n+rnd.uniform(-.12,.12); L=rnd.uniform(lmin,lmax); w=rnd.uniform(wmin,wmax)
        p0=np.array(c); p1=p0+L*np.array([math.cos(a),math.sin(a)]); nrm=np.array([-math.sin(a),math.cos(a)])
        poly=np.array([p0+nrm*w,p0-nrm*w,p1],np.float32)
        tmp=np.zeros_like(m); cv2.fillPoly(tmp,[np.round(poly*4).astype(np.int32)],1.0,cv2.LINE_AA,shift=2)
        # fade along length
        yy,xx=np.mgrid[0:H,0:W]; 
        m=np.maximum(m,tmp)
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32); d=np.sqrt((xx-c[0])**2+(yy-c[1])**2)
    m*=np.clip(1-d/lmax,0,1)**1.2
    return cv2.GaussianBlur(m,(0,0),2)
def band(shape, inner, outer, a0=0.0, a1=1.0, blur=3):
    """polygon band between two polylines; alpha ramps a0->a1 along it"""
    H,W=shape[:2]; m=np.zeros((H,W),np.float32); n=len(inner)
    for i in range(n-1):
        t=(i+.5)/(n-1); a=a0+(a1-a0)*t
        poly=np.array([inner[i],inner[i+1],outer[i+1],outer[i]],np.float32)
        cv2.fillPoly(m,[np.round(poly*4).astype(np.int32)],float(a),cv2.LINE_AA,shift=2)
    return cv2.GaussianBlur(m,(0,0),blur)
def ribbon(shape, pts, w0, w1, rnd, rag=.35, blur=1.5):
    """brushy ribbon along a polyline, width w0->w1, ragged edges"""
    H,W=shape[:2]; m=np.zeros((H,W),np.float32)
    P=np.array(pts,np.float32); T=np.gradient(P,axis=0); T/=np.linalg.norm(T,axis=1,keepdims=True)+1e-9; N=np.stack([-T[:,1],T[:,0]],1)
    n=len(P)
    for k in range(int(max(w0,w1)/2.2)+3):   # many thin streaks = brush bristles
        o=rnd.uniform(-1,1); s=int(rnd.random()**2*n*.3); e=n-int(rnd.random()**2*n*.45)
        if e-s<3: continue
        ws=np.linspace(w0,w1,n)[s:e]; Q=P[s:e]+N[s:e]*(o*ws/2)[:,None]
        th=max(1,int(rnd.uniform(1.5,4.5)))
        cv2.polylines(m,[np.round(Q*4).astype(np.int32)],False,float(rnd.uniform(.6,1)),th,cv2.LINE_AA,shift=2)
    # solid core
    for i in range(n-1):
        wa=(w0+(w1-w0)*i/(n-1))*.5*(1-rag*rnd.random()); wb=(w0+(w1-w0)*(i+1)/(n-1))*.5*(1-rag*rnd.random())
        poly=np.array([P[i]+N[i]*wa,P[i+1]+N[i+1]*wb,P[i+1]-N[i+1]*wb,P[i]-N[i]*wa],np.float32)
        cv2.fillPoly(m,[np.round(poly*4).astype(np.int32)],.85,cv2.LINE_AA,shift=2)
    return cv2.GaussianBlur(m,(0,0),blur)
def bezier(p0,p1,p2,p3,n=60):
    t=np.linspace(0,1,n)[:,None]; p0,p1,p2,p3=map(lambda v:np.array(v,np.float32),(p0,p1,p2,p3))
    return (1-t)**3*p0+3*(1-t)**2*t*p1+3*(1-t)*t**2*p2+t**3*p3
def sparks(shape, c, n, rmin, rmax, rnd, lmin=10, lmax=40):
    H,W=shape[:2]; m=np.zeros((H,W),np.float32)
    for i in range(n):
        a=rnd.uniform(0,2*math.pi); r=rnd.uniform(rmin,rmax); L=rnd.uniform(lmin,lmax)
        p=np.array(c)+r*np.array([math.cos(a),math.sin(a)]); q=p+L*np.array([math.cos(a),math.sin(a)])
        cv2.line(m,tuple((p*4).astype(int)),tuple((q*4).astype(int)),float(rnd.uniform(.6,1)),int(rnd.choice([1,2,2,3])),cv2.LINE_AA,shift=2)
    return cv2.GaussianBlur(m,(0,0),.8)
def lightning(shape, start, ang, length, rnd, seg=14, jag=.45, branch=.35, depth=0):
    """returns list of polylines (branching random-walk bolt)"""
    H,W=shape[:2]; lines=[]; p=np.array(start,np.float32); pts=[p.copy()]; a=ang; step=length/seg
    for i in range(seg):
        a+=rnd.gauss(0,jag); p=p+step*np.array([math.cos(a),math.sin(a)]); pts.append(p.copy())
        if depth<2 and rnd.random()<branch*(1-i/seg):
            lines+=lightning(shape,p,a+rnd.choice([-1,1])*rnd.uniform(.4,.9),length*rnd.uniform(.25,.5),rnd,seg//2,jag,branch*.6,depth+1)
    lines.append((np.array(pts),depth))
    return lines
def draw_bolts(f, lines, core=(1,1,1), glowc=(1,.85,.4), w=3):
    H,W=f.shape[:2]; c=np.zeros((H,W),np.float32); g=np.zeros((H,W),np.float32)
    for pts,dep in lines:
        q=[np.round(pts*4).astype(np.int32)]; ww=max(1,w-dep)
        cv2.polylines(c,q,False,1.0,ww,cv2.LINE_AA,shift=2); cv2.polylines(g,q,False,1.0,ww*4,cv2.LINE_AA,shift=2)
    g=cv2.GaussianBlur(g,(0,0),9)*.8+cv2.GaussianBlur(g,(0,0),30)*.5
    f=screen_add(f,g[...,None]*np.array(glowc,np.float32)[None,None,:])
    f=screen_add(f,c[...,None]*np.array(core,np.float32)[None,None,:])
    return f
