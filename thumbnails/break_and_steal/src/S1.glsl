// ===== Steal thumbnail 1: RUN! (Tung overhead, giant toilet boss chasing) =====
const float FAR=300.;
const float CAM_ROLL=-.07;
const vec3 KEY_DIR=normalize(vec3(-.55,.8,.55));
const vec3 KEY_COL=vec3(1.9,1.65,1.25);
const vec3 SKY_COL=vec3(.14,.23,.46);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.35,-.6));
const vec3 RIM_COL=vec3(1.,1.15,1.5);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(2.4,1.6,.5);
const float PL_FALL=.09;
const vec3 FOG_COL=vec3(.58,.75,.97);
const float FOG_START=26.; const float FOG_DENS=.007;
vec3 CAMP; vec3 CAMT; vec3 PATH0, PATH1;
void setup(){
  avatarColors(); FACE=1; PICK_ON=0.; HOODIE=HX(0xe8322a); PANTS=HX(0x1d2a4a); SKIN=HX(0xf3c690); HAIR=HX(0x2a1810);
  vec3 base=vec3(-2.9,.35,4.6);
  avatarRig(base, vec3(13.,-17.,5.), vec3(-6.,-6.,6.), vec3(-.27,1.,.15), vec3(.27,1.,.15), vec3(0.,-1.,.7), vec3(0.,-.8,-.8));
  // Tung, carried overhead
  vec3 up=normalize((tR*vec3(0,1,0))*.4+vec3(0,1,0));
  TS_=.66; TR_=eulD(vec3(-4.,10.,9.));
  TO_=(haL+haR)*.5+TR_*vec3(0,1,0)*(3.1*TS_-.12)+vec3(0.,0.,-.05);
  TUNG_FACE=1.;
  tHaL=vec3(-2.9,2.3,.9); tHaR=vec3(2.85,2.0,.9);
  tFtL=vec3(-2.4,-3.6,.9); tFtR=vec3(2.1,-3.9,-.2);
  vec3 bd=normalize(vec3(.55,1.,.35)); tBatA=tHaR-bd*.5; tBatB=tHaR+bd*3.3;
  // giant toilet boss, lunging at the player
  BS_=1.45; BO_=vec3(5.0,0.,-5.2); BR_=eulD(vec3(15.,-40.,-3.)); BHR=eulD(vec3(10.,16.,5.)); BHS=1.25; BOSS_MOUTH=1.; BOSS_LOOK=.07;
  PL_POS=TO_+vec3(.8,.5,2.6);
  CAMP=vec3(1.0,1.6,14.); CAMT=vec3(1.3,6.6,0.);
  PATH0=vec3(BO_.x,0.,BO_.z); PATH1=vec3(base.x,0.,base.z);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.55; }
float pathD(vec2 p){ vec2 a=PATH0.xz, b=PATH1.xz; vec2 pa=p-a, ba=b-a; float h=dot(pa,ba)/dot(ba,ba); return length(pa-ba*h); }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  // blocky trees
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(12.+fi*2.4+4.*fract(fi*.7)),0.,-16.-9.*fract(fi*.53)-fi*1.5);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  // speckled eggs dotting the field
  for(int i=0;i<8;i++){ float fi=float(i); vec3 c=vec3(-22.+fi*6.3,0.,-5.-9.*fract(fi*.61)); if(abs(c.x-4.)<6.&&c.z>-14.) c.x+=12.; float s=.8+.55*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.25*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,mapBoss(p));
  r=U(r,mapTung(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xc4e6ff),HX(0x3478f2),smoothstep(-.02,.28,y)); sky=mix(sky,HX(0x1a3cb0),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(3.,7.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.55,.575,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(3.,7.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.55,.72,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.55; return; }
  if(tungMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; emi+=HX(0xffb020)*pow(1.-abs(dot(n,normalize(CAMP-p))),3.)*.9; return; }
  if(bossMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.8; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02;
    float pd=pathD(p.xz)+fbm(p*.9)*1.2; float pm=1.-smoothstep(1.6,2.4,pd);
    alb=mix(alb,mix(HX(0xc99a5a),HX(0xe6c182),fbm(p*1.3)),pm); }
  else if(id<41.5){ float k=fract(id); vec3 q=p*1.6; float sp=smoothstep(.55,.58,fbm(q));
    alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); alb=mix(alb,alb*.55,sp); detail=.3; spec=.4; RIMK=.4; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else { alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.22*dot(uv*.5,uv*.5); return col; }
