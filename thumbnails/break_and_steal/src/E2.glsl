// ===== Egg thumbnail 2: THE GRAND MUSHROOM MAGE WAKES UP (galaxy egg, night) =====
const float FAR=400.;
const float CAM_ROLL=.03;
const vec3 KEY_DIR=normalize(vec3(.55,.75,.45));
const vec3 KEY_COL=vec3(.95,1.05,1.5);
const vec3 SKY_COL=vec3(.22,.16,.45);
const vec3 GROUND_COL=vec3(.05,.08,.1);
const vec3 RIM_DIR=normalize(vec3(-.7,.4,-.55));
const vec3 RIM_COL=vec3(1.1,.7,1.9);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(3.2,1.2,4.2);
const float PL_FALL=.045;
const vec3 FOG_COL=vec3(.22,.16,.42);
const float FOG_START=18.; const float FOG_DENS=.022;
vec3 CAMP; vec3 CAMT;
void setup(){
  avatarColors(); FACE=3; PICK_ON=1.; PICK_STYLE=2; PKS=1.35; HOODIE=HX(0x26262e); PANTS=HX(0x2a2f4a); SKIN=HX(0xf3c690); HAIR=HX(0x8a3a14);
  vec3 base=vec3(-2.6,0.,2.4);
  avatarRig(base, vec3(6.,20.,-3.), vec3(-2.,26.,-4.), vec3(-.32,1.,.2), vec3(.12,-.5,1.), vec3(-.05,-1.,.25), vec3(.05,-1.,-.25));
  vec3 Y=normalize(vec3(.12,1.,.15)); vec3 F=normalize(vec3(1.,0.,.2)); vec3 X=normalize(F-Y*dot(F,Y));
  pkA=haL-Y*.75; pkB=haL+Y*2.45; pkR=mat3(X,Y,cross(X,Y));
  // the stolen galaxy egg up front
  NEGGS=1; EGS[0]=1.55; EGP[0]=vec3(.5,1.2*1.55,4.6); EGPAT[0]=3; EGM[0]=eulD(vec3(0.,-30.,-4.)); NEST_ON[0]=1.;
  // the mage, startled awake
  MS_=2.0; MO_=vec3(5.6,0.,-5.6); MR_=eulD(vec3(-4.,-34.,3.)); MHR=eulD(vec3(12.,20.,-6.));
  mHaL=vec3(-3.25,6.3,.9); mHaR=vec3(2.35,4.7,1.25); mStA=vec3(2.45,.1,1.35); mStB=vec3(2.3,9.4,1.15);
  PL_POS=EGP[0]+vec3(0.,.6,1.9);
  CAMP=vec3(.4,3.9,11.6); CAMT=vec3(1.4,6.0,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.2; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  // dark blocky trees
  for(int i=0;i<8;i++){ float fi=float(i); float sx=(fi<3.5?-1.:1.); vec3 c=vec3(sx*(13.+fi*2.4+5.*fract(fi*.7)),0.,-15.-9.*fract(fi*.53)-fi*1.5);
    float s=1.+.45*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  // glowing mushrooms dotted around
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=vec3(-11.+fi*2.9+1.6*sin(fi*3.1),0.,-1.5-5.5*fract(fi*.61)+fi*.2); if(c.x>1.5&&c.x<9.&&c.z<-3.) c.z+=6.5;
    float s=.55+.6*fract(fi*.43);
    vec3 q=(p-c)/s; float stem=sdCapsule(q,vec3(0.),vec3(.1,1.1,0.),.22);
    float cap=sdEllipsoid(q-vec3(.1,1.2,0.),vec3(.75,.42,.75)); cap=max(cap,-(q.y-1.05));
    r=U(r,vec2(stem*s,58.)); r=U(r,vec2(cap*s,59.+fract(fi*.37)*.5)); }
  r=U(r,mapEggs(p));
  r=U(r,mapMage(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0x6a3aa8),HX(0x24186a),smoothstep(-.02,.35,y)); sky=mix(sky,HX(0x0c0a30),smoothstep(.35,.95,y));
  vec2 uv=rd.xz/(y+.25)*1.2;
  float nb=fbm2(uv*.8+vec2(3.,1.)); sky+=HX(0xd040c0)*smoothstep(.5,.85,nb)*.35*smoothstep(.0,.3,y);
  sky+=HX(0x3070ff)*smoothstep(.55,.9,fbm2(uv*1.3+9.))*.25*smoothstep(.0,.3,y);
  vec3 sg=rd*260.; vec3 sf=fract(sg)-.5; float st=step(.93,h31(floor(sg)))*(1.-smoothstep(.08,.22,length(sf)))*smoothstep(.02,.12,y);
  sky+=vec3(st)*1.8;
  // big moon
  vec3 md=normalize(vec3(-1.25,.62,-1.)); float mm=dot(rd,md);
  float moon=smoothstep(.9955,.9962,mm); vec3 mc=mix(HX(0xfff4d8),HX(0xd8c8a8),smoothstep(.55,.7,fbm(rd*60.)));
  sky=mix(sky,mc*1.4,moon); sky+=HX(0x9a7aff)*pow(clamp(mm,0.,1.),220.)*.6;
  return sky;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.5; return; }
  if(eggMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.8; return; }
  if(mageMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id>111.5&&id<112.5) emi+=alb*.45; return; }
  if(id<1.5){ alb=mix(HX(0x1f5a3a),HX(0x3f8a4a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<50.5){ alb=HX(0x3a2a30); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x1f4a5a),HX(0x2f6a5a),fbm(p*.9)); detail=.3; RIMK=.5; }
  else if(id<58.5){ alb=HX(0xe8e0d0); emi=HX(0x60e0ff)*.25; detail=.4; RIMK=.5; }
  else { float k=fract(id); vec3 g=k<.25?HX(0x40f0ff):HX(0xff5ad8); alb=g; emi=g*1.8; detail=.5; spec=.6; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); col*=1.-.3*dot(uv*.5,uv*.5); return col; }
