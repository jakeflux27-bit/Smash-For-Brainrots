#define PI 3.14159265
mat3 rotX(float a){float c=cos(a),s=sin(a);return mat3(1,0,0, 0,c,s, 0,-s,c);}
mat3 rotY(float a){float c=cos(a),s=sin(a);return mat3(c,0,-s, 0,1,0, s,0,c);}
mat3 rotZ(float a){float c=cos(a),s=sin(a);return mat3(c,s,0, -s,c,0, 0,0,1);}
mat3 eul(vec3 a){return rotY(a.y)*rotX(a.x)*rotZ(a.z);} // degrees->radians done by caller
mat3 eulD(vec3 d){return eul(d*PI/180.);}
// world -> local : local = transpose(R)*(p-o)
vec3 loc(vec3 p, vec3 o, mat3 R){return transpose(R)*(p-o);}
float sdBox(vec3 p, vec3 b, float r){vec3 q=abs(p)-b+r;return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;}
float sdSphere(vec3 p,float r){return length(p)-r;}
float sdCapsule(vec3 p, vec3 a, vec3 b, float r){vec3 pa=p-a,ba=b-a;float h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.);return length(pa-ba*h)-r;}
float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2){
  vec3 ba=b-a; float l2=dot(ba,ba); float rr=r1-r2; float a2=l2-rr*rr; float il2=1./l2;
  vec3 pa=p-a; float y=dot(pa,ba); float z=y-l2; vec3 xv=pa*l2-ba*y; float x2=dot(xv,xv);
  float y2=y*y*l2; float z2=z*z*l2; float k=sign(rr)*rr*rr*x2;
  if(sign(z)*a2*z2>k) return sqrt(x2+z2)*il2-r2;
  if(sign(y)*a2*y2<k) return sqrt(x2+y2)*il2-r1;
  return (sqrt(x2*a2*il2)+y*rr)*il2-r1;}
float sdEllipsoid(vec3 p, vec3 r){float k0=length(p/r);float k1=length(p/(r*r));return k0*(k0-1.)/k1;}
float sdCyl(vec3 p, float h, float r, float rr){vec2 d=abs(vec2(length(p.xz),p.y))-vec2(r-rr,h-rr);return min(max(d.x,d.y),0.)+length(max(d,0.))-rr;}
float smin(float a,float b,float k){float h=clamp(.5+.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}
vec2 U(vec2 a, vec2 b){return a.x<b.x?a:b;}
// noise
float h31(vec3 p){p=fract(p*.3183099+.1);p*=17.;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}
float h21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float vnoise(vec3 x){vec3 i=floor(x),f=fract(x);f=f*f*(3.-2.*f);
 return mix(mix(mix(h31(i),h31(i+vec3(1,0,0)),f.x),mix(h31(i+vec3(0,1,0)),h31(i+vec3(1,1,0)),f.x),f.y),
            mix(mix(h31(i+vec3(0,0,1)),h31(i+vec3(1,0,1)),f.x),mix(h31(i+vec3(0,1,1)),h31(i+vec3(1,1,1)),f.x),f.y),f.z);}
float fbm(vec3 p){float a=.5,s=0.;for(int i=0;i<5;i++){s+=a*vnoise(p);p*=2.03;a*=.5;}return s;}
float vnoise2(vec2 x){vec2 i=floor(x),f=fract(x);f=f*f*(3.-2.*f);return mix(mix(h21(i),h21(i+vec2(1,0)),f.x),mix(h21(i+vec2(0,1)),h21(i+vec2(1,1)),f.x),f.y);}
float fbm2(vec2 p){float a=.5,s=0.;for(int i=0;i<5;i++){s+=a*vnoise2(p);p*=2.03;a*=.5;}return s;}
// voronoi edge distance (for cracks)
float voroEdge(vec3 x){vec3 p=floor(x),f=fract(x);vec3 mr;float md=8.;
 for(int k=-1;k<=1;k++)for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec3 b=vec3(i,j,k);vec3 r=b+vec3(h31(p+b),h31(p+b+17.),h31(p+b+31.))-f;float d=dot(r,r);if(d<md){md=d;mr=r;}}
 md=8.;for(int k=-1;k<=1;k++)for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec3 b=vec3(i,j,k);vec3 r=b+vec3(h31(p+b),h31(p+b+17.),h31(p+b+31.))-f;if(dot(mr-r,mr-r)>1e-5)md=min(md,dot(.5*(mr+r),normalize(r-mr)));}
 return md;}
// 2D shape helpers for painted faces (uv space)
float sd2Seg(vec2 p, vec2 a, vec2 b){vec2 pa=p-a,ba=b-a;float h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.);return length(pa-ba*h);}
float sd2Ell(vec2 p, vec2 c, vec2 r){return (length((p-c)/r)-1.)*min(r.x,r.y);}
float sd2Box(vec2 p, vec2 c, vec2 b, float r){vec2 d=abs(p-c)-b+r;return length(max(d,0.))+min(max(d.x,d.y),0.)-r;}
float fill(float d, float aa){return 1.-smoothstep(-aa,aa,d);}
vec3 C(vec3 s){return pow(s,vec3(2.2));}
vec3 HX(int h){return C(vec3(float((h>>16)&255),float((h>>8)&255),float(h&255))/255.);}
// box spanning a->b (b = far end), cross half-size hw, extends 'ext' past a
mat3 frameAB(vec3 a, vec3 b, vec3 ref){vec3 y=normalize(b-a); vec3 x=normalize(cross(y,ref)); vec3 z=cross(x,y); return mat3(x,y,z);}
float limbBox(vec3 p, vec3 a, vec3 b, vec3 ref, vec2 hw, float ext, float r){
  mat3 R=frameAB(a,b,ref); float L=length(b-a); vec3 c=a+(b-a)*.5 - normalize(b-a)*ext*.5;
  vec3 q=transpose(R)*(p-c); return sdBox(q, vec3(hw.x,(L+ext)*.5,hw.y), r);}
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}
float RIMK=1.;
