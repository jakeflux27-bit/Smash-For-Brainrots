// ===== Home-page brief W1: SECRET HATCH (bacon-hair avatar winds up a crystal pickaxe, giant lava egg bursts, mystery silhouette) =====
const float FAR=300.;
const float CAM_ROLL=-.035;
const vec3 KEY_DIR=normalize(vec3(-.5,.75,.65));
const vec3 KEY_COL=vec3(1.9,1.75,1.55);
const vec3 SKY_COL=vec3(.3,.3,.6);
const vec3 GROUND_COL=vec3(.14,.14,.08);
const vec3 RIM_DIR=normalize(vec3(.65,.35,-.65));
const vec3 RIM_COL=vec3(2.0,1.2,2.2);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(1.9,1.3,.8);
const float PL_FALL=.035;
const vec3 FOG_COL=vec3(.62,.8,1.);
const float FOG_START=28.; const float FOG_DENS=.012;
vec3 CAMP; vec3 CAMT; vec3 EC; float ESZ=3.9; mat3 ER;
void setup(){
  avatarColors(); FACE=3; OUTFIT=1; BACON=1.; PICK_ON=1.; PICK_STYLE=3; PKS=1.45; SKIN=HX(0xf3c690); HAIR=HX(0xa24c1a);
  vec3 base=vec3(-4.4,0.,.9);
  avatarRig(base, vec3(-5.,50.,-7.), vec3(-8.,22.,7.), vec3(0.,1.,0.), vec3(0.,1.,0.), vec3(-.15,-1.,.4), vec3(.25,-1.,-.45));
  vec3 grip=tO+tR*vec3(.25,2.35,-.45);
  haL=shL+normalize(grip-shL)*1.95; haR=shR+normalize(grip-shR)*1.95; grip=(haL+haR)*.5;
  vec3 Y=normalize(vec3(-.62,.72,-.32)); vec3 F=normalize(vec3(.75,.62,.15)); vec3 X=normalize(F-Y*dot(F,Y));
  pkA=grip-Y*.6; pkB=grip+Y*2.5*PKS/1.45*1.2; pkR=mat3(X,Y,cross(X,Y));
  // the giant lava egg in its nest, top blown open
  ER=eulD(vec3(0.,20.,-4.)); EC=vec3(2.9,1.29*ESZ,-1.6);
  // mystery brainrot (Tung silhouette) bursting out of the top
  TS_=.85; TR_=eulD(vec3(-4.,-12.,6.)); TO_=EC+vec3(.1,4.1,.2);
  tHaL=vec3(-3.1,1.9,.9); tHaR=vec3(2.6,2.4,.6); tFtL=vec3(-.7,-4.6,.3); tFtR=vec3(.7,-4.6,-.3);
  vec3 bd=normalize(vec3(.45,1.,.1)); tBatA=tHaR-bd*.4; tBatB=tHaR+bd*3.4;
  PL_POS=EC+vec3(-4.2,2.6,2.2);
  CAMP=vec3(.2,3.2,7.9); CAMT=vec3(1.2,6.7,-1.6);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.5; }
float zig(float a){ return abs(fract(a*7./6.2832)*2.-1.); }
float sdShell(vec3 p){
  vec3 q=transpose(ER)*(p-EC)/ESZ;
  float e=sdEggShape(q); float d=abs(e+.045)-.045;
  float rim=.46+.24*zig(atan(q.z,q.x)+.3)+.05*sin(atan(q.z,q.x)*23.);
  d=max(d,q.y-rim);
  return d*ESZ;}
vec3 shardC(int i){ float fi=float(i); float a=fi*2.35+.6; return EC+vec3(cos(a)*(3.6+2.2*fract(fi*.37)),ESZ*.7+.6+4.*fract(fi*.61),sin(a)*(1.6+1.6*fract(fi*.53))+1.); }
vec2 map(vec3 p){
  vec2 r=vec2(p.y+.03*fbm(p*.6),1.);
  r=U(r,vec2(sdShell(p),150.));
  { vec3 q=transpose(ER)*(p-EC)/ESZ; vec3 nb=vec3(0.,-1.25,0.); r=U(r,vec2(sdNest((q-nb)/.78+nb)*.78*ESZ,151.)); }
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=shardC(i);
    mat3 R=eulD(vec3(fi*41.,fi*67.,fi*29.)); vec3 q=loc(p,c,R); float s=1.-.035*fi;
    s*=1.55; float fr=sdBox(q,vec3(.85,.08,.65)*s,.05); fr=max(fr,-(dot(q.xz,vec2(.7,.7))-.3*s+.14*sin(q.x*8./s)));
    fr=max(fr,dot(q.xz,vec2(-.6,.8))-.45*s+.1*sin(q.z*9./s));
    r=U(r,vec2(fr,152.)); }
  for(int i=0;i<7;i++){ float fi=float(i); float a=fi*2.1+1.3;      // floating coins
    vec3 c=EC+vec3(cos(a)*(5.4+2.*fract(fi*.43)),1.+6.5*fract(fi*.71),sin(a)*2.5+.5+2.*fract(fi*.29));
    mat3 R=eulD(vec3(70.+fi*23.,fi*51.,fi*37.)); r=U(r,vec2(sdCyl(loc(p,c,R),.12,.75,.07),153.)); }
  for(int i=0;i<5;i++){ float fi=float(i);      // floating gems
    vec3 c=EC+(i==0?vec3(-3.9,5.6,1.2):i==1?vec3(4.6,6.8,.4):i==2?vec3(5.2,1.2,2.):i==3?vec3(-2.8,8.4,-1.):vec3(3.6,9.,-1.4));
    mat3 R=eulD(vec3(fi*33.,fi*57.,fi*19.)); vec3 q=loc(p,c,R);
    r=U(r,vec2((abs(q.x)+abs(q.y)*.7+abs(q.z))*.577-.55,154.+fi*.1)); }
  r=U(r,mapTung(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y; vec3 sky=mix(HX(0xbfe8ff),HX(0x2e86ff),smoothstep(-.02,.3,y)); return sky;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(id>19.5&&id<22.5){ alb=HX(0x07060c); spec=.12; detail=.3; grp=6.; RIMK=0.; return; }     // pure black mystery silhouette
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.3; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.3; return; }
  if(id<1.5){ vec2 tl=floor(p.xz*.5); alb=mix(HX(0x46b42a),HX(0x6fd23c),.5+.5*h21(tl))*mix(.88,1.08,fbm(p*.8)); detail=.15; spec=.03; }
  else if(id<150.5){ vec3 q=transpose(ER)*(p-EC)/ESZ; grp=3.; detail=.85; RIMK=1.;
    if(sdEggShape(q)<-.05){ alb=HX(0xfff0d0); emi=HX(0xffc84a)*(2.2-1.2*smoothstep(-.6,.3,q.y)); spec=.2; }
    else {
      alb=mix(HX(0x2a0a5c),HX(0x6b1fd0),smoothstep(-1.,.6,q.y)); spec=0.;
      vec3 v=normalize(CAMP-p); float hl=pow(max(dot(n,normalize(KEY_DIR+v)),0.),220.); float hl2=pow(max(dot(n,normalize(RIM_DIR+v)),0.),90.);
      float ve=voroEdge(q*2.4+fbm(q*2.5)*.7); float w=.035+.03*smoothstep(-.6,.5,q.y);
      float cr=1.-smoothstep(0.,w,ve); float glo=1.-smoothstep(0.,w*4.,ve);
      alb=mix(alb,HX(0x1a0428),cr*.6);
      emi=HX(0xff2fc8)*cr*5.+HX(0xff3fd0)*glo*.35*(.4+.6*smoothstep(-.8,.5,q.y))+HX(0x7a2be2)*.05+vec3(2.2)*hl*(1.-cr)+HX(0xff9ae8)*hl2*.8;
      float rimz=q.y-(.46+.24*zig(atan(q.z,q.x)+.3)); emi+=HX(0xffb040)*smoothstep(-.12,0.,rimz)*3.;
    } }
  else if(id<151.5){ vec3 q=transpose(ER)*(p-EC)/ESZ; float a=atan(q.z,q.x);
    float tw=smoothstep(.1,.7,max(sin(a*26.+q.y*11.),sin(a*-19.+q.y*13.+1.7)));
    alb=mix(HX(0x5a3416),HX(0xc08848),tw)*mix(.8,1.15,h31(floor(vec3(a*30.,q.y*20.,0.)))); detail=.75; spec=.2; grp=3.; }
  else if(id<152.5){ alb=HX(0x5a1fb8); spec=1.6; detail=.8; grp=3.; RIMK=1.;
    float ve=voroEdge(p*1.6); emi=HX(0xff2fc8)*(1.-smoothstep(0.,.06,ve))*4.+HX(0xffb040)*.15; }
  else if(id<153.5){ alb=HX(0xffc21a); spec=2.5; emi=HX(0xffa000)*.25; detail=.7; grp=5.; RIMK=1.; }
  else { float k=fract(id)*10.+.5; vec3 gc=k<1.?HX(0x38e0ff):k<2.?HX(0x3cff7a):k<3.?HX(0xff4fd0):k<4.?HX(0x3cff7a):HX(0x38e0ff);
    alb=gc; spec=3.; emi=gc*.45; detail=.8; grp=5.; RIMK=1.2; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); return col; }
