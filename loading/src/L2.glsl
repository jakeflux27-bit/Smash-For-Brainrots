// ===== Loading panel 2: TUNG TUNG TUNG SAHUR HATCHES =====
const float FAR=300.;
const float CAM_ROLL=.05;
const vec3 KEY_DIR=normalize(vec3(-.55,.75,.5));
const vec3 KEY_COL=vec3(2.1,1.75,1.3);
const vec3 SKY_COL=vec3(.12,.2,.42);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.3,-.6));
const vec3 RIM_COL=vec3(.9,1.1,1.5);
const vec3 PL_POS=vec3(0.,4.6,.6);
const vec3 PL_COL=vec3(4.2,2.8,.9);
const float PL_FALL=.06;
const vec3 FOG_COL=vec3(.55,.72,.95);
const float FOG_START=30.; const float FOG_DENS=.006;
vec3 EGGC; const float ES=2.55; vec3 tgO; mat3 tgR; vec3 gShL,gShR,gHL,gHR,bA,bB;
void setup(){
  avatarColors(); FACE=1; HOODIE=HX(0x7a3cff); PANTS=HX(0x1d2433); SKIN=HX(0xd9a06a); HAIR=HX(0x14100c); PICKC=HX(0xffcf3a);
  vec3 base=vec3(-4.6,0.,4.2);
  avatarRig(base, vec3(-5.,62.,0.), vec3(-24.,40.,5.), vec3(-.25,-1.,.25), vec3(.25,-1.,.2), vec3(0.,-1.,.12), vec3(0.,-1.,-.12));
  vec3 d=normalize(tR*vec3(.2,-.6,.8)); pkA=haR-d*.4; pkB=haR+d*2.2; pkR=frameAB(pkA,pkB,tR*vec3(0,0,1));
  EGGC=vec3(0.,1.3*ES,0.);
  tgO=vec3(0.,3.3,0.); tgR=eulD(vec3(6.,10.,-5.));
  gShL=tgO+tgR*vec3(-1.45,3.7,.1); gShR=tgO+tgR*vec3(1.45,3.8,.1);
  gHL=tgO+tgR*vec3(-2.7,2.7,1.3); gHR=tgO+tgR*vec3(2.65,5.7,.9);
  bA=gHR+tgR*vec3(-.05,-.5,0.); bB=gHR+tgR*normalize(vec3(.55,1.,-.55))*4.4;
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=vec3(1.8,1.0,12.); ta=vec3(-.1,6.4,0.); fov=2.15; }
float zig(float a){ return .5*abs(fract(a*8./6.2832)-.5)*2.+.15*sin(a*29.); }
float sdEggShell(vec3 p){
  vec3 q=(p-EGGC)/ES; q.xz*=1.+.16*q.y;
  float e=sdEllipsoid(q,vec3(1.,1.3,1.))*ES;
  float sh=abs(e+.12)-.12;
  float a=atan(p.z,p.x); return max(sh, p.y-(4.1+zig(a))); }
float sdTung(vec3 p){
  vec3 q=transpose(tgR)*(p-tgO);
  float d=sdCyl(q-vec3(0,3.,0),3.,1.55,.3);
  d=min(d,sdSphere(q-vec3(-.62,4.65,1.18),.6)); d=min(d,sdSphere(q-vec3(.62,4.65,1.18),.6));   // bulging eyes
  d=smin(d,sdBox(q-vec3(0.,4.05,1.72),vec3(.2,.6,.4),.08),.08);                                // long nose
  return d;}
vec2 map(vec3 p){
  float n=fbm(p*vec3(.3,0,.3));
  vec2 r=vec2(p.y-.3*n,1.);
  // background voxel trees + eggs
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(14.+fi*3.+5.*fract(fi*.7)),0.,-14.-9.*fract(fi*.53)-fi*2.);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15));
    r=U(r,vec2(l,51.)); }
  for(int i=0;i<7;i++){ float fi=float(i); vec3 c=vec3(-26.+fi*8.6,0.,-8.-7.*fract(fi*.61)); float s=.8+.5*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.3*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,vec2(sdEggShell(p),8.));
  // shell shards flying
  for(int i=0;i<12;i++){ float fi=float(i); float a=fi*2.4; vec3 c=vec3(cos(a)*(3.4+1.6*fract(fi*.7)),4.8+3.2*fract(fi*.43)+fi*.12,sin(a)*(2.+fract(fi*.3))+1.2);
    mat3 R=eulD(vec3(fi*37.,fi*71.,fi*23.)); r=U(r,vec2(sdBox(loc(p,c,R),vec3(.42,.06,.32)*(1.-.04*fi),.03),9.)); }
  // Tung Tung Tung Sahur
  r=U(r,vec2(sdTung(p),20.));
  r=U(r,vec2(sdCapsule(p,gShL,gHL,.32),21.)); r=U(r,vec2(sdCapsule(p,gShR,gHR,.32),21.));
  r=U(r,vec2(sdBox(p-gHL,vec3(.42),.15),21.)); r=U(r,vec2(sdBox(p-gHR,vec3(.42),.15),21.));
  r=U(r,vec2(sdRoundCone(p,bA,bB,.2,.48),22.));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xbfe4ff),HX(0x2f6ff0),smoothstep(-.02,.3,y)); sky=mix(sky,HX(0x1636a8),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(3.,1.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.56,.585,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(3.,1.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.56,.72,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
vec3 tungFace(vec3 q, vec3 base, vec3 n){
  vec3 c=base; vec3 ink=HX(0x2a1408);
  float ang=atan(q.x,q.z); vec2 uv=vec2(ang*1.55,q.y);
  // eyes: white bulges with tiny pupils + dark eyelid ring
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec3 ec=vec3(sg*.62,4.65,1.18); vec3 e=q-ec; float de=length(e);
    if(de<.63){ vec3 en=e/de; c=mix(HX(0xfdf8ee),HX(0xe6d8c0),smoothstep(.3,-.4,en.y));
      vec2 pp=en.xy-vec2(-.14+sg*.0,.05); float pd=length(pp);
      c=mix(c,HX(0x120a06),1.-smoothstep(.13,.16,pd)); c=mix(c,HX(0xffffff),1.-smoothstep(.03,.05,length(pp-vec2(.05,.06))));
      c=mix(c,ink,smoothstep(.4,.62,1.-en.z)*.0); }
    float ring=abs(length(vec2(q.x-sg*.62,q.y-4.65))-.66); c=mix(c,ink,(1.-smoothstep(.03,.08,ring))*step(1.0,q.z)*.85);
    // brow wrinkle
    float br=abs(length(vec2(q.x-sg*.6,q.y-4.5))-.95); c=mix(c,ink,(1.-smoothstep(.02,.05,br))*step(.25,q.y-4.5)*step(1.,q.z)*.7);
  }
  // flat worried mouth
  float m=sd2Seg(vec2(q.x,q.y),vec2(-.62,3.05),vec2(.6,2.95))-.07; c=mix(c,ink,(1.-smoothstep(0.,.03,m))*step(1.,q.z));
  return c;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  float dE=length(p-PL_POS);
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<8.5){ vec3 q=(p-EGGC)/ES; alb=HX(0xf6ecd4); float sp=fbm(q*1.5+2.); alb=mix(alb,HX(0x1f8a86),smoothstep(.58,.6,sp));
    float rimT=1.-smoothstep(0.,.5,abs(p.y-4.1-zig(atan(p.z,p.x)))); emi=HX(0xffb020)*rimT*3.5;
    float inner=step(length((p-EGGC).xz),2.9*(1.+.0))*0.; if(dot(n,normalize(p-EGGC))<-.2) { alb=HX(0xfff0c0); emi+=HX(0xffc040)*1.5; }
    float ve=voroEdge(q*3.); float cr=(1.-smoothstep(0.,.04,ve))*smoothstep(2.2,4.,p.y); alb=mix(alb,HX(0x3a1c08),cr); emi+=HX(0xffa020)*cr*4.;
    detail=.7; grp=3.; spec=.45; RIMK=.6; }
  else if(id<9.5){ alb=HX(0xf6ecd4); emi=HX(0xffb52e)*.6; detail=.6; grp=3.; }
  else if(id<41.5){ float k=fract(id); alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); detail=.3; spec=.4; RIMK=.4; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
  else if(id<20.5+0.){ }
  if(id>19.5&&id<20.5){ vec3 q=transpose(tgR)*(p-tgO); float ang=atan(q.x,q.z);
    float grain=fbm(vec3(ang*5.,q.y*.45,0.)*vec3(2.5,1.,1.)); alb=mix(HX(0x9a5a2c),HX(0xd9944e),grain);
    alb=mix(alb,HX(0x5e3216),smoothstep(.6,.7,fbm(vec3(ang*12.,q.y*.22,5.))));
    if(n.y>.8&&q.y>5.7){ float rr=length(q.xz); alb=mix(HX(0xf0c890),HX(0xb98448),.5+.5*sin(rr*12.)); }
    alb=tungFace(q,alb,n); detail=.97; grp=4.; spec=.2; RIMK=.8; }
  else if(id>20.5&&id<21.5){ alb=HX(0xc4834a)*mix(.85,1.1,fbm(p*4.)); detail=.7; grp=4.; RIMK=.8; }
  else if(id>21.5&&id<22.5){ alb=mix(HX(0xd8995a),HX(0x9a5a2c),.5+.5*sin(dot(p,vec3(2.))*3.)); detail=.75; grp=4.; spec=.4; RIMK=.8; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.25*dot(uv*.5,uv*.5); return col; }
