// ===== Icon for the brief: extreme close-up, crystal pickaxe smashes the lava egg, black mystery silhouette inside =====
const float FAR=300.;
const float CAM_ROLL=0.;
const vec3 KEY_DIR=normalize(vec3(-.5,.75,.65));
const vec3 KEY_COL=vec3(1.9,1.75,1.55);
const vec3 SKY_COL=vec3(.3,.3,.6);
const vec3 GROUND_COL=vec3(.14,.14,.08);
const vec3 RIM_DIR=normalize(vec3(.65,.35,-.65));
const vec3 RIM_COL=vec3(2.0,1.2,2.2);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(1.6,1.2,.7);
const float PL_FALL=.04;
const vec3 FOG_COL=vec3(.62,.8,1.);
const float FOG_START=28.; const float FOG_DENS=.012;
vec3 CAMP; vec3 CAMT; vec3 EC; float ESZ=3.9; mat3 ER; vec3 IMP;
void setup(){
  avatarColors(); OUTFIT=1; PICK_ON=1.; PICK_STYLE=3; PKS=1.7; SKIN=HX(0xf3c690);
  ER=eulD(vec3(0.,20.,-4.)); EC=vec3(.6,1.29*ESZ,-1.6);
  vec3 Y=normalize(vec3(.95,-.32,-.1)); vec3 X=normalize(vec3(.3,.95,.05)); X=normalize(X-Y*dot(X,Y));
  pkR=mat3(X,Y,cross(X,Y));
  IMP=EC+vec3(-3.05,1.15,3.3);
  pkB=IMP-(-X*1.37-Y*.61)*PKS+vec3(0.,0.,.3);
  vec3 grip=pkB-Y*1.75*PKS; pkA=grip-Y*.55;
  haR=grip; haL=vec3(0.,-100.,0.); shR=grip+normalize(vec3(-.75,.45,.5))*2.4; tO=vec3(0.,-100.,0.); tR=mat3(1.);
  TS_=.85; TR_=eulD(vec3(-4.,-12.,6.)); TO_=EC+vec3(.1,4.1,.2);
  tHaL=vec3(-3.1,1.9,.9); tHaR=vec3(2.6,2.4,.6); tFtL=vec3(-.7,-4.6,.3); tFtR=vec3(.7,-4.6,-.3);
  vec3 bd=normalize(vec3(.45,1.,.1)); tBatA=tHaR-bd*.4; tBatB=tHaR+bd*3.4;
  PL_POS=IMP+vec3(-.6,.8,1.6);
  CAMP=vec3(.3,4.,7.4); CAMT=vec3(.3,6.,-1.6);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.3; }
float zig(float a){ return abs(fract(a*7./6.2832)*2.-1.); }
float sdShell(vec3 p){
  vec3 q=transpose(ER)*(p-EC)/ESZ;
  float e=sdEggShape(q); float d=abs(e+.045)-.045;
  float rim=.46+.24*zig(atan(q.z,q.x)+.3)+.05*sin(atan(q.z,q.x)*23.);
  d=max(d,q.y-rim);
  return d*ESZ;}
vec3 shardC(int i){ float fi=float(i); float a=fi*2.35+.6; return EC+vec3(cos(a)*(3.4+2.*fract(fi*.37)),ESZ*.7+.8+3.5*fract(fi*.61),sin(a)*(1.6+1.6*fract(fi*.53))+1.); }
vec2 map(vec3 p){
  vec2 r=vec2(p.y+.03*fbm(p*.6),1.);
  r=U(r,vec2(sdShell(p),150.));
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=shardC(i);
    mat3 R=eulD(vec3(fi*41.,fi*67.,fi*29.)); vec3 q=loc(p,c,R); float s=(1.-.035*fi)*1.4;
    float fr=sdBox(q,vec3(.85,.08,.65)*s,.05); fr=max(fr,-(dot(q.xz,vec2(.7,.7))-.3*s+.14*sin(q.x*8./s)));
    fr=max(fr,dot(q.xz,vec2(-.6,.8))-.45*s+.1*sin(q.z*9./s));
    r=U(r,vec2(fr,152.)); }
  for(int i=0;i<6;i++){ float fi=float(i); vec3 c=IMP+vec3(-.6+1.7*sin(fi*2.4),.5+1.6*fract(fi*.37),1.3*cos(fi*2.4)+1.);   // chips off the impact
    mat3 R=eulD(vec3(fi*53.,fi*31.,fi*77.)); r=U(r,vec2(sdBox(loc(p,c,R),vec3(.32,.06,.24),.03),152.)); }
  r=U(r,mapTung(p));
  vec3 ref=normalize(cross(normalize(shR-haR),vec3(0.,0.,1.)));
  r=U(r,vec2(limbBox(p,shR,haR,ref,vec2(.5),.5,.1),32.));
  r=U(r,vec2(sdCapsule(p,pkA,pkB,.12),37.)); r=U(r,vec2(pickHeadCrystal(p),38.));
  return r;}
vec3 background(vec3 rd){ return mix(HX(0xbfe8ff),HX(0x2e86ff),smoothstep(-.02,.3,rd.y)); }
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(id>19.5&&id<22.5){ alb=HX(0x07060c); spec=.12; detail=.3; grp=6.; return; }
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.3; emi+=alb*.2; return; }
  if(id<1.5){ alb=mix(HX(0x46b42a),HX(0x6fd23c),.5+.5*h21(floor(p.xz*.5))); detail=.15; spec=.03; }
  else if(id<150.5){ vec3 q=transpose(ER)*(p-EC)/ESZ; grp=3.; detail=.85; RIMK=1.;
    if(sdEggShape(q)<-.05){ alb=HX(0xfff0d0); emi=HX(0xffc84a)*(2.2-1.2*smoothstep(-.6,.3,q.y)); spec=.2; }
    else {
      alb=mix(HX(0x2a0a5c),HX(0x6b1fd0),smoothstep(-1.,.6,q.y)); spec=0.;
      vec3 v=normalize(CAMP-p); float hl=pow(max(dot(n,normalize(KEY_DIR+v)),0.),220.); float hl2=pow(max(dot(n,normalize(RIM_DIR+v)),0.),90.);
      vec3 iq=transpose(ER)*(IMP-EC)/ESZ; float dI=length(q-iq);
      float ve=voroEdge(q*2.4+fbm(q*2.5)*.7); float w=.035+.03*smoothstep(-.6,.5,q.y)+.05*(1.-smoothstep(0.,.5,dI));
      float cr=1.-smoothstep(0.,w,ve); float glo=1.-smoothstep(0.,w*4.,ve);
      alb=mix(alb,HX(0x1a0428),cr*.6);
      emi=HX(0xff2fc8)*cr*5.+HX(0xff3fd0)*glo*.35*(.4+.6*smoothstep(-.8,.5,q.y))+HX(0x7a2be2)*.05+vec3(2.2)*hl*(1.-cr)+HX(0xff9ae8)*hl2*.8;
      emi+=HX(0xffd070)*cr*6.*(1.-smoothstep(.1,.7,dI))+HX(0xffffff)*(1.-smoothstep(0.,.12,dI))*8.;
      float rimz=q.y-(.46+.24*zig(atan(q.z,q.x)+.3)); emi+=HX(0xffb040)*smoothstep(-.12,0.,rimz)*3.;
    } }
  else { alb=HX(0x5a1fb8); spec=1.6; detail=.8; grp=3.; RIMK=1.;
    float ve=voroEdge(p*1.6); emi=HX(0xff2fc8)*(1.-smoothstep(0.,.06,ve))*4.+HX(0xffb040)*.15; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); return col; }
