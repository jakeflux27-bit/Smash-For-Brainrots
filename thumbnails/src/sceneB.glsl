// ===== Scene B: THE HATCH (night, mystery silhouette) =====
const float FAR=90.;
const float CAM_ROLL=.05;
const vec3 KEY_DIR=normalize(vec3(-.5,.55,-.65));
const vec3 KEY_COL=vec3(.32,.42,.78);
const vec3 SKY_COL=vec3(.025,.045,.11);
const vec3 GROUND_COL=vec3(.01,.02,.02);
const vec3 RIM_DIR=normalize(vec3(-.4,.5,-.8));
const vec3 RIM_COL=vec3(.25,.45,.9);
const vec3 PL_POS=vec3(0.,2.05,0.);
const vec3 PL_COL=vec3(9.,5.2,1.6);
const float PL_FALL=.55;
const vec3 FOG_COL=vec3(.02,.05,.10);
const float FOG_START=10.; const float FOG_DENS=.05;
vec3 CAMP;
vec3 tO; mat3 tR; vec3 hO; mat3 hR; vec3 shL,shR,haL,haR,hipL,hipR,ftL,ftR; vec3 pkA,pkB; mat3 pkR;
vec3 sO; mat3 sR;  // silhouette
void setup(){
  vec3 base=vec3(5.6,0.,2.2);
  vec3 fw=normalize(vec3(-base.x,0.,-base.z)); float yaw=atan(fw.x,fw.z)*180./PI;
  tO=base+vec3(0.,3.0,0.); tR=eulD(vec3(4.,yaw-28.,2.));
  vec3 neck=tO+tR*vec3(0,1.,0); hR=eulD(vec3(-4.,yaw-8.,0.)); hO=neck+hR*vec3(0,.74,0);
  shL=tO+tR*vec3(-1.5,.62,0.); shR=tO+tR*vec3(1.5,.62,0.);
  haL=shL+tR*normalize(vec3(-.15,-1.,.1))*1.95; haR=shR+tR*normalize(vec3(.12,-1.,.18))*1.95;
  hipL=tO+tR*vec3(-.5,-1.,0.); hipR=tO+tR*vec3(.5,-1.,0.);
  ftL=hipL+tR*vec3(-.1,-1.95,.35); ftL.y=0.; ftR=hipR+tR*vec3(.15,-1.95,-.3); ftR.y=0.;
  // pickaxe hanging from right hand, head down near ground
  pkA=haR-normalize(tR*vec3(.25,-.75,-.9))*.4; pkB=haR+normalize(tR*vec3(.25,-.75,-.9))*2.4;
  pkR=frameAB(pkA,pkB,tR*vec3(0,0,1));
  sO=vec3(0.,2.2,0.); sR=eulD(vec3(0.,30.,4.));
  CAMP=vec3(4.3,3.35,8.1);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=vec3(.85,2.15,0.); fov=1.38; }
float zig(float a){ return .22*abs(fract(a*7./6.2832)-.5)*2.+.08*sin(a*23.); }
float sdEggOpen0(vec3 p){
  vec3 q=p-vec3(0.,1.35,0.); q.xz*=1.+.16*q.y;
  float e=sdEllipsoid(q,vec3(1.1,1.4,1.1));
  float shell=abs(e+.06)-.06;                       // thin shell so we can see inside
  float a=atan(p.z,p.x); float cut=p.y-(2.05+zig(a));
  return max(shell,cut);}
float sdShard0(vec3 p){ // fallen top piece on the ground
  vec3 q=transpose(eulD(vec3(110.,30.,-20.)))*(p-vec3(-2.0,.45,.9));
  vec3 r=q; r.xz*=1.+.16*(r.y+.8);
  float e=sdEllipsoid(r-vec3(0,-.85,0),vec3(1.05,1.35,1.05)); float shell=abs(e+.06)-.06;
  return max(shell,-(q.y-.15+.12*abs(fract(atan(q.z,q.x)*7./6.28)-.5)*2.)) ;}
float sdTung0(vec3 p){
  vec3 q=transpose(sR)*(p-sO);
  float d=sdRoundCone(q,vec3(0,.2,0),vec3(0,1.75,0),.5,.43);        // log body
  d=smin(d,sdCapsule(q,vec3(-.42,1.45,0),vec3(-1.0,2.2,.1),.12),.08);   // arm up
  d=smin(d,sdCapsule(q,vec3(.42,1.35,0),vec3(.95,1.75,.2),.12),.08);    // other arm
  d=min(d,sdRoundCone(q,vec3(-1.05,2.1,.1),vec3(-.55,3.5,-.1),.1,.22)); // bat
  return d;}
const float ES=1.35;
float sdEggOpen(vec3 p){return sdEggOpen0(p/ES)*ES;}
float sdShard(vec3 p){return sdShard0(p/ES)*ES;}
float sdTung(vec3 p){return sdTung0(p/ES)*ES;}
vec2 map(vec3 p){
  float g=p.y - .15*fbm(p*.35) + .0;
  vec2 r=vec2(g,1.);
  // dark tree line / hills
  r=U(r,vec2(sdEllipsoid(p-vec3(-26.,-4.,-30.),vec3(22.,10.,8.)),11.));
  r=U(r,vec2(sdEllipsoid(p-vec3(18.,-6.,-36.),vec3(26.,12.,8.)),11.));
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=vec3(-30.+fi*7.,0.,-22.-5.*fract(fi*.73)); float h=4.+3.5*fract(fi*.41);
    float t=sdSphere(p-c-vec3(0,h,0),2.6+fract(fi*.3));
    t=smin(t,sdSphere(p-c-vec3(1.8,h-1.2,.5),2.),.8); t=smin(t,sdSphere(p-c-vec3(-1.7,h-1.,.3),2.1),.8);
    t=min(t,sdCapsule(p,c,c+vec3(0,h,0),.5));
    r=U(r,vec2(t+fbm(p*.8)*.6,11.)); }
  r=U(r,vec2(sdEggOpen(p),8.));
  r=U(r,vec2(sdShard(p),8.));
  r=U(r,vec2(sdTung(p),12.));
  // player
  r=U(r,vec2(sdBox(loc(p,tO,tR),vec3(1.,1.,.5),.08),3.));
  r=U(r,vec2(sdBox(loc(p,hO,hR),vec3(.74,.72,.72),.3),2.));
  vec3 ref=tR*vec3(1,0,0);
  r=U(r,vec2(limbBox(p,shL,haL,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,shR,haR,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,hipL,ftL,ref,vec2(.5),.0,.07),5.));
  r=U(r,vec2(limbBox(p,hipR,ftR,ref,vec2(.5),.0,.07),5.));
  r=U(r,vec2(sdCapsule(p,pkA,pkB,.12),6.));
  { vec3 q=transpose(pkR)*(p-pkB); q.z*=1.5; float d=1e9; vec3 prev;
    for(int i=0;i<=10;i++){ float t=float(i)/10.*2.-1.; float a=t*1.05; vec3 c=vec3(sin(a)*1.45,-(1.-cos(a))*1.2,0.);
      if(i>0){ float rr=mix(.27,.04,pow(abs(t),1.2)); d=smin(d,sdCapsule(q,prev,c,rr),.1);} prev=c; }
    d=smin(d,sdBox(q,vec3(.27,.3,.27),.06),.08); r=U(r,vec2(d/1.5,7.)); }
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0x1a3a52),HX(0x050a1c),smoothstep(-.02,.5,y));
  sky=mix(sky,HX(0x0b1430),smoothstep(.5,1.,y)*.5);
  // stars
  vec3 sd=rd*180.; vec3 id=floor(sd); float h=h31(id); float st=step(.985,h)*smoothstep(.5,.0,length(fract(sd)-.5))*smoothstep(.05,.3,y);
  sky+=vec3(1.,.95,.85)*st*(1.5+2.*h31(id+7.));
  // moon glow upper left
  vec3 md=normalize(vec3(-.55,.62,-.56)); float m=dot(rd,md);
  sky+=HX(0x9ec4ff)*pow(clamp(m,0.,1.),60.)*.6+HX(0x4a6ab0)*pow(clamp(m,0.,1.),6.)*.15;
  sky=mix(sky,HX(0xeef4ff)*1.8,smoothstep(.9988,.9992,m));
  // thin clouds
  float cl=fbm(vec3(rd.xz/(y+.2)*1.5,1.)); sky=mix(sky,HX(0x2a3d66),smoothstep(.55,.75,cl)*smoothstep(0.,.3,y)*.5);
  return sky;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.2; detail=.25; grp=0.; RIMK=1.;
  float dE=length(p-PL_POS);
  if(id<1.5){ float g=fbm(p*vec3(.7,0,.7)); alb=mix(HX(0x1e4a1c),HX(0x3f7a2a),g); spec=.05; RIMK=0.; detail=.18+.3*(1.-smoothstep(1.5,5.,dE)); }
  else if(id<6.5 && id>1.5){
    if(id<2.5){ alb=HX(0xf2c22a); detail=.7; spec=.3; } else if(id<3.5){ alb=HX(0x1f5fd6); detail=.6; spec=.15; }
    else if(id<4.5){ alb=HX(0xf2c22a); detail=.6; spec=.3; } else if(id<5.5){ alb=HX(0x3fae3a); detail=.5; spec=.1; }
    else { alb=HX(0x7a4420); detail=.5; }
    grp=1.; vec3 L=PL_POS+vec3(0,.8,0)-p; float dl=length(L); L/=dl;
    float w=clamp(dot(n,L),0.,1.); emi=alb*HX(0xffa040)*w*7./(1.+dl*dl*.12);
    vec3 v=normalize(CAMP-p); emi+=HX(0x6fa0ff)*pow(1.-abs(dot(n,v)),3.)*.35; }
  else if(id<3.5){ alb=HX(0x1f5fd6); detail=.6; grp=1.; spec=.15; }
  else if(id<4.5){ alb=HX(0xf2c22a); detail=.6; grp=1.; spec=.3; }
  else if(id<5.5){ alb=HX(0x3fae3a); detail=.5; grp=1.; spec=.1; }
  else if(id<6.5){ alb=HX(0x7a4420); detail=.5; grp=2.; }
  else if(id<7.5){ alb=HX(0x22d4f0); spec=1.; emi=HX(0x10c0ff)*.35; detail=.6; grp=2.; }
  else if(id<8.5){ // shell, glowing from inside
    vec3 q=p/ES-vec3(0.,1.35,0.); float sp=fbm(q*1.7+3.);
    alb=mix(HX(0xf3e2c0),HX(0x8a5aa8),smoothstep(.6,.63,sp));
    alb=mix(alb,HX(0x3fb0d8),smoothstep(.66,.69,fbm(q*2.4+9.)));
    float inside=step(length(q.xz*(1.+.16*q.y)),1.0)*0.;
    vec3 ps=p/ES; float rimTop=1.-smoothstep(0.,.3,abs(ps.y-2.05-zig(atan(ps.z,ps.x))));
    emi=HX(0xffb02a)*rimTop*4.+HX(0xff8a1a)*smoothstep(.0,1.,dot(n,normalize(PL_POS-p)))*smoothstep(3.,.5,dE)*.6;
    // thin cracks running down
    float ve=voroEdge(q*2.8); float cr=(1.-smoothstep(0.,.04,ve))*smoothstep(.6,2.2,p.y/ES);
    alb=mix(alb,HX(0x2a1405),cr); emi+=HX(0xffa020)*cr*3.;
    detail=.75; grp=3.; spec=.4; }
  else if(id<11.5){ alb=HX(0x060c14); RIMK=.3; detail=.1; spec=0.; }
  else { // brainrot silhouette: near-black with a hot golden rim
    alb=HX(0x0d0806); spec=0.; RIMK=0.; grp=5.; detail=.85;
    vec3 v=normalize(CAMP-p); float fr=smoothstep(.62,.97,1.-abs(dot(n,v)));
    emi=HX(0xffc850)*fr*4.+HX(0xff8a10)*clamp(-n.y,0.,1.)*1.2;
    vec3 q=transpose(sR)*(p/ES-sO);
    for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 e=vec2(q.x-sg*.17,q.y-1.5);
      float de=length(e/vec2(.085,.11)); emi+=HX(0xfff6d8)*smoothstep(1.,.6,de)*9.+HX(0xffc040)*smoothstep(2.4,1.,de)*1.5*step(0.,q.z); } }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.15); col*=1.-.32*dot(uv*.6,uv*.6); return col; }
