import numpy as np, cv2
def place_logo(img, logo_path, cx, cy, width, rot=0, shadow=.55):
    lg=cv2.imread(logo_path, cv2.IMREAD_UNCHANGED)
    ys,xs=np.where(lg[...,3]>8); lg=lg[ys.min():ys.max()+1, xs.min():xs.max()+1]
    s=width/lg.shape[1]; lg=cv2.resize(lg,None,fx=s,fy=s,interpolation=cv2.INTER_AREA)
    if rot:
        h,w=lg.shape[:2]; M=cv2.getRotationMatrix2D((w/2,h/2),rot,1); lg=cv2.warpAffine(lg,M,(w,h),flags=cv2.INTER_LINEAR,borderValue=(0,0,0,0))
    h,w=lg.shape[:2]; x0,y0=int(cx-w/2),int(cy-h/2)
    out=img.astype(np.float32)
    a=lg[...,3].astype(np.float32)/255.
    # soft drop shadow
    sh=np.zeros(img.shape[:2],np.float32); sx,sy=x0+10,y0+16
    sh[max(sy,0):sy+h, max(sx,0):sx+w]=a[max(-sy,0):, max(-sx,0):][:sh.shape[0]-max(sy,0), :sh.shape[1]-max(sx,0)]
    sh=cv2.GaussianBlur(sh,(0,0),12)*shadow
    out*=(1-sh[...,None])
    H,W=img.shape[:2]
    ya,yb=max(y0,0),min(y0+h,H); xa,xb=max(x0,0),min(x0+w,W)
    A=a[ya-y0:yb-y0, xa-x0:xb-x0][...,None]; Cc=lg[ya-y0:yb-y0, xa-x0:xb-x0,:3].astype(np.float32)
    out[ya:yb,xa:xb]=out[ya:yb,xa:xb]*(1-A)+Cc*A
    return np.clip(out,0,255).astype(np.uint8)
