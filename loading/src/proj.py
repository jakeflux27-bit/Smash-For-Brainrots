import numpy as np
def norm(v): v=np.asarray(v,float); return v/np.linalg.norm(v)
def project(P, ro, ta, fov, roll, W=1920, H=1080):
    ro=np.array(ro,float); ww=norm(np.array(ta)-ro); uu=norm(np.cross(ww,[0,1,0])); vv=np.cross(uu,ww)
    d=np.array(P,float)-ro; x,y,z=d@uu,d@vv,d@ww
    rx,ry=x*fov/z,y*fov/z
    c,s=np.cos(-roll),np.sin(-roll); ux,uy=c*rx-s*ry, s*rx+c*ry
    fx=(ux*H+W)/2; fy=(uy*H+H)/2
    return np.array([fx, H-fy]), z
