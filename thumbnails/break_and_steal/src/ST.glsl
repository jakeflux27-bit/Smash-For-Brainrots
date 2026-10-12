// ===== Steal thumbnail: TOILET HEIST 2 (player carries a scared toilet boss, angry Titan Cameraman chasing) =====
const float FAR=300.;
const float CAM_ROLL=-.07;
const vec3 KEY_DIR=normalize(vec3(-.55,.8,.55));
const vec3 KEY_COL=vec3(1.9,1.65,1.25);
const vec3 SKY_COL=vec3(.14,.23,.46);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.35,-.6));
const vec3 RIM_COL=vec3(1.,1.15,1.5);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(2.6,1.8,.4);
const float PL_FALL=.08;
const vec3 FOG_COL=vec3(.58,.75,.97);
const float FOG_START=26.; const float FOG_DENS=.007;
vec3 CAMP; vec3 CAMT; vec3 VC; float VR=1.5; mat3 VRM;
void setup(){
  avatarColors(); FACE=1; PICK_ON=0.; HOODIE=HX(0x26262e); PANTS=HX(0x234a3a); SKIN=HX(0xf3c690); HAIR=HX(0xb24a1c);
  vec3 base=vec3(-2.9,.35,4.6);
  avatarRig(base, vec3(12.,-14.,4.), vec3(-6.,-4.,6.), vec3(-.35,-.75,.55), vec3(.15,-.55,-.8), vec3(0.,-1.,.7), vec3(0.,-.8,-.8));
  // a little (terrified) toilet boss, hugged in the player's arms
  BS_=.34; BR_=tR*eulD(vec3(-4.,30.,8.));
  BO_=haL+tR*vec3(-.35,.15,-.1)-BR_*vec3(0.,3.4,1.0)*BS_;
  BHR=eulD(vec3(-8.,40.,8.)); BHS=1.25; BOSS_MOUTH=.85; BOSS_LOOK=-.05; BOSS_SCARED=1.;
  // angry Titan Cameraman stomping after them
  TITAN=1.;
  camRig(vec3(6.4,0.,-8.4), 3.35, vec3(18.,-38.,4.), vec3(20.,-30.,-6.), vec3(.12,.3,1.), vec3(.15,-.85,-.45), vec3(0.,-1.,.75), vec3(0.,-.8,-.75));
  NEGGS=2;
  EGS[0]=1.0; EGP[0]=vec3(1.6,1.2,-2.6); EGPAT[0]=0; EGM[0]=eulD(vec3(0.,-20.,4.)); NEST_ON[0]=1.;
  EGS[1]=.95; EGP[1]=vec3(9.6,1.2*.95,-3.0); EGPAT[1]=1; EGM[1]=eulD(vec3(0.,30.,-4.)); NEST_ON[1]=1.;
  PL_POS=BO_+vec3(.4,2.5,2.6);
  CAMP=vec3(.3,1.7,14.); CAMT=vec3(.4,6.0,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.85; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(12.+fi*2.4+4.*fract(fi*.7)),0.,-16.-9.*fract(fi*.53)-fi*1.5);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  r=U(r,mapEggs(p));
  r=U(r,mapCam(p));
  r=U(r,mapBoss(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xc4e6ff),HX(0x3478f2),smoothstep(-.02,.28,y)); sky=mix(sky,HX(0x1a3cb0),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(3.,7.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.58,.605,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(3.,7.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.58,.75,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.5; return; }
  if(eggMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.7; return; }
  if(bossMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.8; return; }
  if(camMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.9; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
  else { alb=vec3(1.,0.,1.); }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.22*dot(uv*.5,uv*.5); return col; }
