import numpy as np, cv2
def kuwahara(img, r, q=8, sectors=8):
    """Generalized Kuwahara (Papari et al.) – painterly flat planes with crisp edges."""
    f=img.astype(np.float32)/255.; H,W=f.shape[:2]
    size=2*r+1; yy,xx=np.mgrid[-r:r+1,-r:r+1].astype(np.float32)
    ang=np.arctan2(yy,xx); rad=np.sqrt(xx**2+yy**2)
    g=np.exp(-(rad**2)/(2*(r*.5)**2))*(rad<=r)
    num=np.zeros_like(f); den=np.zeros((H,W,1),np.float32)
    f2=f*f
    for k in range(sectors):
        a0=-np.pi+k*2*np.pi/sectors; mid=a0+np.pi/sectors
        dd=np.angle(np.exp(1j*(ang-mid)))
        wk=np.exp(-(dd**2)/(2*(np.pi/sectors*.75)**2))*g
        wk[r,r]=g[r,r]/sectors
        wk/=wk.sum()
        m=cv2.filter2D(f,-1,wk,borderType=cv2.BORDER_REFLECT)
        s=cv2.filter2D(f2,-1,wk,borderType=cv2.BORDER_REFLECT)-m*m
        sig=np.sqrt(np.clip(s,0,None)).sum(-1,keepdims=True)
        w=1./(1.+(sig*255.)**q*1e-12) if False else 1./(1e-4+sig**q)
        num+=m*w; den+=w
    out=num/den
    return np.clip(out*255,0,255).astype(np.uint8)
