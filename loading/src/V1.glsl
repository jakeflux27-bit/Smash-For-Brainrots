// ===== Verity thumbnail 1: VERITY HELPS SMASH =====
uniform sampler2D uTex0;  // verity face
const float FAR=300.;
const float CAM_ROLL=-.06;
const vec3 KEY_DIR=normalize(vec3(-.5,.8,.55));
const vec3 KEY_COL=vec3(2.0,1.7,1.3);
const vec3 SKY_COL=vec3(.13,.22,.45);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.3,-.6));
const vec3 RIM_COL=vec3(.9,1.1,1.5);
const vec3 PL_POS=vec3(.2,4.2,2.4);
const vec3 PL_COL=vec3(2.6,1.7,.5);
const float PL_FALL=.08;
const vec3 FOG_COL=vec3(.55,.72,.95);
const float FOG_START=30.; const float FOG_DENS=.006;
vec3 EGGC; const float ES=2.6; mat3 EGR; vec3 IMP; vec3 VC; const float VR=1.95; mat3 VRM; vec3 CAMP;
void setup(){
  avatarColors(); FACE=0; PKS=1.45; HOODIE=HX(0xe8322a); PANTS=HX(0x1d2a4a); SKIN=HX(0xf3c690); HAIR=HX(0x2a1810); PICKC=HX(0x35e0ff);
  EGGC=vec3(2.2,1.3*ES,-.4); EGR=eulD(vec3(4.,0.,-6.));
  IMP=EGGC+normalize(vec3(-.95,.55,.55))*vec3(ES,ES*1.3,ES)*.98;
  vec3 base=vec3(-3.4,0.,2.1);
  avatarRig(base, vec3(-6.,58.,-6.), vec3(-8.,32.,4.), vec3(0.,-1.,0.), vec3(0.,-1.,0.), vec3(-.1,-1.,.35), vec3(.1,-1.,-.35));
  vec3 grip=tO+tR*vec3(0.,.55,1.25);
  haL=shL+normalize(grip-shL)*1.95; haR=shR+normalize(grip-shR)*1.95; grip=(haL+haR)*.5;
  vec3 pB=IMP+vec3(-.4,1.3,0.); vec3 X,Y;
  for(int k=0;k<6;k++){ Y=normalize(pB-grip); vec3 d=IMP-pB; X=normalize(d-Y*dot(d,Y)); pB=IMP-X*1.26*PKS+Y*.6*PKS; }
  pkB=pB; pkA=grip-Y*.55; pkR=mat3(X,Y,cross(X,Y));
  VC=vec3(5.5,6.9,1.7); VRM=eulD(vec3(4.,-22.,10.));
  CAMP=vec3(.9,1.5,10.2);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=vec3(1.1,4.7,0.); fov=1.45; }
float sdEgg(vec3 p){ vec3 q=transpose(EGR)*(p-EGGC)/ES; q.xz*=1.+.16*q.y; return sdEllipsoid(q,vec3(1.,1.3,1.))*ES; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.3*fbm(p*vec3(.3,0,.3)),1.);
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(13.+fi*2.6+4.*fract(fi*.7)),0.,-13.-8.*fract(fi*.53)-fi*1.6);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  for(int i=0;i<7;i++){ float fi=float(i); vec3 c=vec3(-24.+fi*8.,0.,-7.-7.*fract(fi*.61)); if(abs(c.x-2.)<5.) c.x+=10.; float s=.8+.5*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.3*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,vec2(sdEgg(p),8.));
  for(int i=0;i<10;i++){ float fi=float(i); float a=fi*2.4; vec3 c=IMP+vec3(-.6+1.6*sin(a),.4+1.8*fract(fi*.37)+fi*.08,1.2*cos(a)+.9);
    mat3 R=eulD(vec3(fi*37.,fi*71.,fi*23.)); r=U(r,vec2(sdBox(loc(p,c,R),vec3(.3,.05,.22)*(1.-.05*fi),.03),9.)); }
  r=U(r,vec2(sdSphere(p-VC,VR),60.));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xbfe4ff),HX(0x2f6ff0),smoothstep(-.02,.3,y)); sky=mix(sky,HX(0x1636a8),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(9.,4.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.56,.585,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(9.,4.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.56,.72,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<8.5){ vec3 q=transpose(EGR)*(p-EGGC)/ES;
    alb=HX(0xe9dcc0); float sp=fbm(q*1.4+2.); alb=mix(alb,HX(0x1f8a86),smoothstep(.53,.55,sp));
    vec3 iq=transpose(EGR)*(IMP-EGGC)/ES; float dI=length(q-iq);
    float ve=voroEdge(q*3.2+fbm(q*3.)*.6); float w=.03+.07*(1.-smoothstep(0.,.9,dI)); float cr=(1.-smoothstep(0.,w,ve))*(1.-smoothstep(.3,1.25,dI)); float ed=(1.-smoothstep(w,w*2.,ve))*(1.-smoothstep(.3,1.25,dI));
    alb=mix(alb,HX(0x3a1a06),max(ed,cr)*.92);
    emi=HX(0xff9a10)*(cr*5.)+HX(0xffe08a)*cr*cr*3.*(1.-smoothstep(0.,.5,dI))+HX(0xffffff)*(1.-smoothstep(0.,.12,dI))*12.;
    detail=.6+.39*(1.-smoothstep(.3,1.25,dI)); grp=3.; spec=.45; RIMK=.6; }
  else if(id<9.5){ alb=HX(0xf6ecd4); emi=HX(0xffb52e)*.7; detail=.6; grp=3.; }
  else if(id<41.5){ float k=fract(id); alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); detail=.3; spec=.4; RIMK=.4; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
  else { // VERITY: glossy yellow orb with the in-game face texture
    vec3 lp=transpose(VRM)*(p-VC)/VR; alb=HX(0xffd414); float fa=0.;
    if(lp.z>0.){ vec2 uv=vec2(.5+lp.x*.44,.5-lp.y*.44-.02); vec4 f=texture(uTex0,uv); fa=f.a*smoothstep(0.,.25,lp.z); alb=mix(alb,pow(f.rgb,vec3(2.2)),fa); }
    spec=.35; detail=.99; grp=5.; RIMK=.7*(1.-fa);
    vec3 v=normalize(CAMP-p); emi=(HX(0xffb000)*pow(1.-abs(dot(n,v)),2.5)*1.6+HX(0xffd030)*.12)*(1.-fa); }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.25*dot(uv*.5,uv*.5); return col; }
