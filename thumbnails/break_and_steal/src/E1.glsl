// ===== Egg thumbnail 1: SNEAK PAST THE SLEEPING SAMURAI =====
const float FAR=400.;
const float CAM_ROLL=-.03;
const vec3 KEY_DIR=normalize(vec3(-.45,.8,.6));
const vec3 KEY_COL=vec3(1.9,1.65,1.3);
const vec3 SKY_COL=vec3(.14,.23,.46);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.35,-.6));
const vec3 RIM_COL=vec3(1.,1.15,1.5);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(1.4,1.2,1.4);
const float PL_FALL=.06;
const vec3 FOG_COL=vec3(.62,.78,.98);
const float FOG_START=30.; const float FOG_DENS=.006;
vec3 CAMP; vec3 CAMT;
void setup(){
  avatarColors(); FACE=3; PICK_ON=1.; PICK_STYLE=1; PKS=1.55; HOODIE=HX(0x26262e); PANTS=HX(0x234a3a); SKIN=HX(0xf3c690); HAIR=HX(0xb24a1c);
  vec3 base=vec3(-3.7,0.,4.3);
  avatarRig(base, vec3(4.,26.,-3.), vec3(-4.,34.,-5.), vec3(0.,-1.,0.), vec3(0.,-1.,0.), vec3(-.05,-1.,.35), vec3(.05,-1.,-.35));
  vec3 grip=tO+vec3(-1.55,1.75,.55);
  haL=shL+normalize(grip-shL)*1.95; haR=shR+normalize(grip-shR)*1.95; grip=(haL+haR)*.5;
  vec3 Y=normalize(vec3(1.,.62,-.35)); vec3 F=normalize(vec3(-.2,1.,.1)); vec3 X=normalize(F-Y*dot(F,Y));
  pkA=grip-Y*.7; pkB=grip+Y*2.9; pkR=mat3(X,Y,cross(X,Y));
  // eggs
  NEGGS=3;
  EGS[0]=1.6; EGP[0]=vec3(1.0,1.2*1.6,1.3); EGPAT[0]=0; EGM[0]=eulD(vec3(0.,-20.,-3.)); NEST_ON[0]=1.;
  EGS[1]=1.15; EGP[1]=vec3(3.6,1.2*1.15,-.8); EGPAT[1]=1; EGM[1]=eulD(vec3(0.,30.,5.)); NEST_ON[1]=1.;
  EGS[2]=1.35; EGP[2]=vec3(5.6,1.2*1.35,.9); EGPAT[2]=2; EGM[2]=eulD(vec3(0.,10.,4.)); NEST_ON[2]=1.;
  // the sleeping samurai sits behind its eggs
  samRig(vec3(4.3,0.,-5.0), 2.55, -22., vec3(14.,0.,3.), vec3(30.,8.,16.), vec3(.62,-.42,.75), vec3(-.62,-.36,.75), vec3(.6,-.05,1.), vec3(-.6,-.05,1.));
  PL_POS=vec3(0.,6.,8.);
  CAMP=vec3(.2,2.5,9.8); CAMT=vec3(.9,5.2,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.22; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  // far snowy mountain
  { vec3 q=p-vec3(26.,0.,-190.); float cone=max(length(q.xz)*.62+q.y*.78-46.,-q.y); r=U(r,vec2(cone,55.)); }
  // cherry blossom trees
  for(int i=0;i<8;i++){ float fi=float(i); float sx=(fi<3.5?-1.:1.); vec3 c=vec3(sx*(14.+fi*2.2+5.*fract(fi*.7)),0.,-17.-10.*fract(fi*.53)-fi*1.6);
    float s=1.+.45*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.2,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.7,8.6*s,-.4),vec3(2.1,1.4,2.)*s,.15)); l=min(l,sdBox(p-c-vec3(-2.2,5.2*s,1.),vec3(1.6,1.2,1.5)*s,.15)); r=U(r,vec2(l,51.)); }
  // red torii gate in the distance
  { vec3 q=p-vec3(-8.,0.,-34.); float s=2.2; q/=s; vec3 a=vec3(abs(q.x),q.y,q.z);
    float t=sdCyl(a-vec3(2.2,2.6,0.),2.6,.28,.05); t=min(t,sdBox(q-vec3(0.,4.6,0.),vec3(3.,.18,.22),.04));
    float top=sdBox(q-vec3(0.,5.5+.05*q.x*q.x*.2,0.),vec3(3.6,.22,.32),.05); r=U(r,vec2(t*s,56.)); r=U(r,vec2(top*s,57.)); }
  r=U(r,mapEggs(p));
  r=U(r,mapSamurai(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xcfe9ff),HX(0x3a7ff2),smoothstep(-.02,.28,y)); sky=mix(sky,HX(0x1c40b4),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(7.,3.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.6,.625,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(7.,3.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0xa8b8e8),smoothstep(.6,.77,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.5; return; }
  if(eggMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.7; return; }
  if(samMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.8; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02;
    alb=mix(alb,HX(0xffb3d1),smoothstep(.72,.78,fbm(p*1.7+4.))*.7); }
  else if(id<50.5){ alb=HX(0x5a3420); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0xff9cc8),HX(0xffd0e4),fbm(p*.9)); detail=.3; RIMK=.4; }
  else if(id<55.5){ alb=mix(HX(0x6a86c8),vec3(1.),smoothstep(26.,30.,p.y)); detail=.1; }
  else if(id<56.5){ alb=HX(0xe0301e); detail=.3; }
  else { alb=HX(0x1a1a20); detail=.3; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.22*dot(uv*.5,uv*.5); return col; }
