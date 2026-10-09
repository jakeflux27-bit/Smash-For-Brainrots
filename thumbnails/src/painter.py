import numpy as np, cv2, math, random, sys, json

def lum(img): return img[...,0]*.114+img[...,1]*.587+img[...,2]*.299

def orient_field(img, sigma):
    L = lum(img)
    gx = cv2.Sobel(L, cv2.CV_32F, 1, 0, ksize=3); gy = cv2.Sobel(L, cv2.CV_32F, 0, 1, ksize=3)
    Jxx = cv2.GaussianBlur(gx*gx, (0,0), sigma); Jyy = cv2.GaussianBlur(gy*gy, (0,0), sigma); Jxy = cv2.GaussianBlur(gx*gy, (0,0), sigma)
    theta = 0.5*np.arctan2(2*Jxy, Jxx-Jyy)          # gradient direction
    tr = Jxx+Jyy; det = np.sqrt((Jxx-Jyy)**2+4*Jxy**2)
    coh = det/(tr+1e-6)
    mag = np.sqrt(tr)
    return theta + np.pi/2, coh, mag                   # stroke direction = along edges

def paint(ref, aux, cfg, seed=1):
    rnd = random.Random(seed); np.random.seed(seed)
    H, W = ref.shape[:2]
    detail = aux[...,2].astype(np.float32)/255.
    reff = ref.astype(np.float32)/255.
    # tonal underpainting: very blurred + slightly warm
    canvas = cv2.GaussianBlur(reff, (0,0), 28)
    canvas = (canvas*0.85 + np.array([0.05,0.06,0.09])*0.15)
    canvas = np.clip(canvas*255,0,255).astype(np.uint8)
    default_ang = cfg.get('bg_angle', -0.7)
    for li,(R, dmin, T, maxLen, minLen) in enumerate(cfg['layers']):
        blur = cv2.GaussianBlur(reff, (0,0), max(R*0.45,0.8))
        theta, coh, mag = orient_field(blur, max(R*1.2, 2))
        cf = canvas.astype(np.float32)/255.
        diff = np.sqrt(((cf-blur)**2).sum(-1))
        strokes = []
        step = max(int(R*cfg.get('grid',1.0)),1)
        for gy in range(0, H, step):
            for gx in range(0, W, step):
                y0,x0 = gy, gx; y1,x1 = min(gy+step,H), min(gx+step,W)
                if detail[y0:y1, x0:x1].max() < dmin: continue
                cell = diff[y0:y1, x0:x1]
                if li>0 and cell.mean() < T: continue
                k = np.argmax(cell); yy, xx = y0 + k//(x1-x0), x0 + k%(x1-x0)
                if li==0: yy, xx = y0+rnd.randrange(y1-y0), x0+rnd.randrange(x1-x0)
                strokes.append((yy,xx))
        rnd.shuffle(strokes)
        n_drawn=0
        for (y,x) in strokes:
            c = blur[y,x].copy()
            pts=[(x,y)]; ld=None; fx,fy=float(x),float(y)
            for i in range(maxLen):
                iy,ix=int(fy),int(fx)
                if i>=minLen:
                    if np.sum((blur[iy,ix]-c)**2) > np.sum((blur[iy,ix]-cf[iy,ix])**2)+1e-4: break
                if mag[iy,ix] < cfg.get('flat_mag',0.02) or coh[iy,ix]<0.15:
                    a = default_ang + (rnd.random()-.5)*0.5
                else: a = theta[iy,ix]
                d = np.array([math.cos(a), math.sin(a)])
                if ld is not None:
                    if d@ld < 0: d=-d
                    d = 0.6*d + 0.4*ld; d/=np.linalg.norm(d)+1e-9
                fx += R*d[0]; fy += R*d[1]
                if not (0<=fx<W-1 and 0<=fy<H-1): break
                pts.append((fx,fy)); ld=d
            draw_stroke(canvas, pts, c, R, rnd, cfg)
            n_drawn+=1
        print(f'layer R={R}: {n_drawn} strokes', flush=True)
    return canvas

def draw_stroke(canvas, pts, c, R, rnd, cfg):
    P = np.array(pts, np.float32)
    if len(P)==1: P = np.vstack([P, P+np.array([rnd.uniform(-1,1)*R*.5, rnd.uniform(-1,1)*R*.5])])
    # normals
    T = np.gradient(P, axis=0); T /= (np.linalg.norm(T,axis=1,keepdims=True)+1e-9)
    N = np.stack([-T[:,1], T[:,0]],1)
    nb = int(np.clip(R/2.0, 2, 11))
    width = R*cfg.get('width',1.0)
    jit = cfg.get('jitter',0.06)
    # per-stroke colour shift (hue/value wobble like real mixing)
    base = c*(1+rnd.gauss(0,jit*0.6)) + np.array([rnd.gauss(0,jit*.35) for _ in range(3)])
    for b in range(nb):
        off = (b/(nb-1)-0.5)*2*width if nb>1 else 0
        off += rnd.uniform(-0.3,0.3)*width/nb
        Q = P + N*off*(0.75+0.25*np.cos(np.linspace(-1.2,1.2,len(P)))[:,None])  # taper toward ends
        # dry-brush: random trim at ends
        n=len(Q); s=0; e=n
        if n>2:
            s = int(rnd.random()**2*n*0.35); e = n-int(rnd.random()**2*n*0.35)
            if e-s<2: s,e=0,n
        Q=Q[s:e]
        col = np.clip((base*(1+rnd.gauss(0,jit)))*255,0,255)
        bw = max(1, int(round(2*width/nb*rnd.uniform(1.1,1.7))))
        cv2.polylines(canvas, [np.round(Q*4).astype(np.int32)], False, tuple(float(v) for v in col), bw, cv2.LINE_AA, shift=2)

def scratches(canvas, ref, aux, n, rnd, lmin=0.75, amt=0.55):
    H,W=canvas.shape[:2]; reff=ref.astype(np.float32)/255.
    L=lum(reff); detail=aux[...,2]/255.
    theta,coh,mag=orient_field(cv2.GaussianBlur(reff,(0,0),3),6)
    over=canvas.copy()
    ys,xs=np.where((L>lmin)&(detail>0.2))
    if len(ys)==0: return canvas
    for _ in range(n):
        i=rnd.randrange(len(ys)); y,x=ys[i],xs[i]
        a=theta[y,x]; ln=rnd.uniform(15,70)
        p0=(x-math.cos(a)*ln/2, y-math.sin(a)*ln/2); p1=(x+math.cos(a)*ln/2, y+math.sin(a)*ln/2)
        col=np.clip(reff[y,x]*1.12+0.12,0,1)*255
        cv2.line(over,(int(p0[0]*4),int(p0[1]*4)),(int(p1[0]*4),int(p1[1]*4)),tuple(float(v) for v in col),1,cv2.LINE_AA,shift=2)
    return cv2.addWeighted(canvas,1-amt,over,amt,0)

def canvas_texture(img, seed=3, amt=0.07):
    H,W=img.shape[:2]; rs=np.random.RandomState(seed)
    n=rs.rand(H//2+1,W//2+1).astype(np.float32); n=cv2.resize(n,(W,H))
    weave=(np.sin(np.arange(W)[None,:]*1.9)+np.sin(np.arange(H)[:,None]*1.7))*0.25
    t=cv2.GaussianBlur(n,(0,0),0.8)-0.5+weave*0.3
    f=img.astype(np.float32)*(1+amt*t[...,None])
    return np.clip(f,0,255).astype(np.uint8)

if __name__=='__main__':
    ref=cv2.imread(sys.argv[1]); aux=cv2.imread(sys.argv[2]); out=sys.argv[3]
    cfg=json.loads(sys.argv[4]) if len(sys.argv)>4 else {}
    cfg.setdefault('layers',[(36,0,0,10,3),(20,0,.05,12,3),(11,.18,.06,12,2),(6,.4,.07,10,2),(3,.8,.07,8,1)])
    rnd=random.Random(7)
    c=paint(ref,aux,cfg)
    c=scratches(c,ref,aux,cfg.get('scratches',2500),rnd)
    c=canvas_texture(c)
    cv2.imwrite(out,c)
