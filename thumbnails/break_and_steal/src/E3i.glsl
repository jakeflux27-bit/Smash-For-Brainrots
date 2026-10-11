// ===== Egg thumbnail 3: TRIPLE T CATCHES YOU (golden egg, sunset) =====
const float FAR=400.;
const float CAM_ROLL=-.07;
const vec3 KEY_DIR=normalize(vec3(-.6,.62,.6));
const vec3 KEY_COL=vec3(2.1,1.5,1.0);
const vec3 SKY_COL=vec3(.3,.22,.42);
const vec3 GROUND_COL=vec3(.16,.12,.05);
const vec3 RIM_DIR=normalize(vec3(.6,.3,-.75));
const vec3 RIM_COL=vec3(2.0,1.1,1.2);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(3.,2.1,.5);
const float PL_FALL=.07;
const vec3 FOG_COL=vec3(1.,.66,.5);
const float FOG_START=24.; const float FOG_DENS=.01;
vec3 CAMP; vec3 CAMT;
void setup(){
  avatarColors(); FACE=1; PICK_ON=0.; HOODIE=HX(0x2b7bff); PANTS=HX(0x1d2a4a); SKIN=HX(0xf3c690); HAIR=HX(0x2a1810);
  vec3 base=vec3(-3.1,.35,4.4);
  avatarRig(base, vec3(13.,-17.,5.), vec3(-6.,-6.,6.), vec3(-.27,1.,.15), vec3(.27,1.,.15), vec3(0.,-1.,.7), vec3(0.,-.8,-.8));
  // the golden egg, carried overhead
  NEGGS=3;
  EGS[0]=1.25; EGP[0]=(haL+haR)*.5+vec3(0.,1.45,0.); EGPAT[0]=4; EGM[0]=eulD(vec3(0.,0.,10.)); NEST_ON[0]=0.;
  EGS[1]=1.2; EGP[1]=vec3(1.2,1.2*1.2,-1.4); EGPAT[1]=0; EGM[1]=eulD(vec3(0.,-20.,4.)); NEST_ON[1]=1.;
  EGS[2]=1.05; EGP[2]=vec3(3.6,1.2*1.05,.1); EGPAT[2]=2; EGM[2]=eulD(vec3(0.,30.,-4.)); NEST_ON[2]=1.;
  // giant Tung Tung Tung Sahur, bat raised, charging
  TS_=2.15; TR_=eulD(vec3(16.,-30.,-5.)); TUNG_FACE=0.;
  TO_=vec3(5.4,4.5*TS_+.2,-5.2);
  tHaL=vec3(-2.6,1.1,1.7); tHaR=vec3(2.3,3.5,.2);
  tFtL=vec3(-.8,-4.6,1.4); tFtR=vec3(.9,-4.4,-1.2);
  vec3 bd=normalize(vec3(-.2,1.,-.55)); tBatA=tHaR-bd*.5; tBatB=tHaR+bd*3.8;
  PL_POS=EGP[0]+vec3(.5,.8,2.4);
  CAMP=vec3(1.2,2.0,12.6); CAMT=vec3(.6,7.7,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.22; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(13.+fi*2.4+4.*fract(fi*.7)),0.,-18.-9.*fract(fi*.53)-fi*1.5);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  r=U(r,mapEggs(p));
  r=U(r,mapTung(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xffd27a),HX(0xff8a5a),smoothstep(-.02,.1,y)); sky=mix(sky,HX(0xd8589a),smoothstep(.08,.3,y)); sky=mix(sky,HX(0x4a3aa8),smoothstep(.3,.85,y));
  float s=dot(rd,normalize(vec3(.35,.06,-1.)));
  sky+=HX(0xfff0c0)*pow(clamp(s,0.,1.),400.)*3.+HX(0xffb060)*pow(clamp(s,0.,1.),14.)*.7;
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(2.,9.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.58,.61,cd)*smoothstep(.0,.12,y);
  vec3 cc=mix(HX(0xffd8b0),HX(0xb05a9a),smoothstep(.0,.4,y));
  return mix(sky,cc,cl*.85);}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.45; return; }
  if(eggMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.8; if(id<90.5) emi+=HX(0xffb000)*pow(1.-abs(dot(n,normalize(CAMP-p))),2.5)*1.2; return; }
  if(tungMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  if(id<1.5){ alb=mix(HX(0x3f8a22),HX(0x9ac23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else { alb=mix(HX(0x3f8a2a),HX(0x8cc23c),fbm(p*.9)); detail=.3; RIMK=.4; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.24*dot(uv*.5,uv*.5); return col; }
