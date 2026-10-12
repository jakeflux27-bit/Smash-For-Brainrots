// ===== Brief variation 1: MONEY (bacon-hair avatar shows off a giant gold Tung Tung Tung Sahur on their fenced base) =====
const float FAR=300.;
const float CAM_ROLL=-.03;
const vec3 KEY_DIR=normalize(vec3(-.45,.8,.6));
const vec3 KEY_COL=vec3(1.9,1.8,1.6);
const vec3 SKY_COL=vec3(.28,.38,.62);
const vec3 GROUND_COL=vec3(.14,.14,.1);
const vec3 RIM_DIR=normalize(vec3(.65,.35,-.65));
const vec3 RIM_COL=vec3(1.8,1.6,1.2);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(1.4,1.1,.5);
const float PL_FALL=.04;
const vec3 FOG_COL=vec3(.7,.86,1.);
const float FOG_START=30.; const float FOG_DENS=.01;
vec3 CAMP; vec3 CAMT;
void setup(){
  avatarColors(); FACE=3; OUTFIT=1; BACON=1.; PICK_ON=0.; SKIN=HX(0xf3c690); HAIR=HX(0xa24c1a);
  vec3 base=vec3(-3.7,.3,3.2);
  avatarRig(base, vec3(-4.,28.,-3.), vec3(-8.,12.,6.), vec3(-.04,-1.,.12), vec3(.85,.28,.55), vec3(-.18,-1.,.05), vec3(.18,-1.,-.05));
  // giant gold Tung, bat resting on the shoulder
  TS_=1.6; TR_=eulD(vec3(-3.,-22.,3.)); TUNG_FACE=0.;
  TO_=vec3(3.2,4.25*TS_+.3,-2.6);
  tHaL=vec3(-2.5,-1.,1.); tHaR=vec3(2.,1.6,1.2);
  tFtL=vec3(-.9,-4.4,.5); tFtR=vec3(.9,-4.4,-.3);
  vec3 bd=normalize(vec3(-.25,.85,-.6)); tBatA=tHaR-bd*.5; tBatB=tHaR+bd*3.6;
  PL_POS=TO_+vec3(-3.,1.,4.);
  CAMP=vec3(-.4,3.2,11.6); CAMT=vec3(.4,7.6,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.45; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y+.02*fbm(p*.5),1.);
  r=U(r,vec2(sdBox(p-vec3(0.,.15,-1.),vec3(11.,.15,8.),.05),160.));           // base floor
  // fence round the base
  float fz=-8.6; float fn=1e9;
  for(int i=0;i<12;i++){ float x=-11.+float(i)*2.; fn=min(fn,sdBox(p-vec3(x,1.25,fz),vec3(.22,1.1,.22),.06)); }
  fn=min(fn,sdBox(p-vec3(0.,1.7,fz),vec3(11.,.16,.1),.04)); fn=min(fn,sdBox(p-vec3(0.,.95,fz),vec3(11.,.16,.1),.04));
  for(int i=0;i<6;i++){ float z=fz+float(i)*2.; vec3 q=vec3(abs(p.x)-11.,p.y,p.z); fn=min(fn,sdBox(q-vec3(0.,1.25,z),vec3(.22,1.1,.22),.06)); }
  { vec3 q=vec3(abs(p.x)-11.,p.y,p.z); fn=min(fn,sdBox(q-vec3(0.,1.7,fz+5.),vec3(.1,.16,5.),.04)); fn=min(fn,sdBox(q-vec3(0.,.95,fz+5.),vec3(.1,.16,5.),.04)); }
  r=U(r,vec2(fn,161.));
  // cash stacks + coins on the floor
  for(int i=0;i<7;i++){ float fi=float(i); vec3 c=vec3(-1.+fi*1.25+.6*sin(fi*3.1),.3+.22,1.6+1.2*cos(fi*2.3));
    r=U(r,vec2(sdCyl(loc(p,c,eulD(vec3(0.,fi*40.,0.))),.12,.7,.06),153.)); }
  for(int i=0;i<3;i++){ float fi=float(i); vec3 c=vec3(5.6+fi*.9,.3+.5,1.2+fi*.6);
    r=U(r,vec2(sdBox(loc(p,c,eulD(vec3(0.,20.+fi*30.,0.))),vec3(.75,.5,.4),.05),162.)); }
  r=U(r,mapTung(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){ return mix(HX(0xbfe8ff),HX(0x2e86ff),smoothstep(-.02,.3,rd.y)); }
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(id>19.5&&id<22.5){ vec3 q=transpose(TR_)*(p-TO_)/TS_; grp=4.; RIMK=1.2; detail=.95;
    vec3 v=normalize(CAMP-p); float fr=pow(1.-abs(dot(n,v)),2.);
    vec3 gold=mix(HX(0xf2b42a),HX(0xa85a00),.25+.5*fr+.25*(1.-n.y))*.85;
    if(id<20.5){ float grain=fbm(vec3(atan(q.x,q.z)*6.,q.y*.5,0.)*vec3(3.,1.,1.)); gold*=mix(.86,1.08,grain);
      vec3 ln=transpose(TR_)*n; if(ln.y>.7&&q.y>2.7) gold=mix(HX(0xfff0a0),HX(0xe0a020),.5+.5*sin(length(q.xz)*14.));
      alb=tungFace(q,gold); }
    else alb=gold;
    float hl=pow(max(dot(n,normalize(KEY_DIR+v)),0.),160.); float hl2=pow(max(dot(n,normalize(RIM_DIR+v)),0.),60.);
    float isgold=1.-step(.5,length(alb-gold)); spec=1.2;
    vec3 R=reflect(-v,n); float env=smoothstep(-.15,.55,R.y); float strip=smoothstep(.75,.95,sin(R.y*7.+R.x*2.));
    emi=(mix(HX(0x7a3a00),HX(0xffe9a0),env)*.42+HX(0xfff3c0)*strip*.35+vec3(2.2)*hl+HX(0xfff0b0)*hl2*.9)*isgold; return; }
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.3; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.3; return; }
  if(id<1.5){ alb=mix(HX(0x46b42a),HX(0x6fd23c),.5+.5*h21(floor(p.xz*.5)))*mix(.88,1.08,fbm(p*.8)); detail=.15; spec=.03; }
  else if(id<153.5){ alb=HX(0xffc21a); spec=2.; emi=HX(0xffa000)*.25; detail=.7; grp=5.; RIMK=1.; }
  else if(id<160.5){ vec2 tl=floor(p.xz*.5); float ch=mod(tl.x+tl.y,2.); alb=mix(HX(0xe9edf5),HX(0xc9d2e3),ch); spec=.35; detail=.3; }
  else if(id<161.5){ alb=HX(0xfafafa); spec=.4; detail=.4; grp=3.; }
  else { alb=HX(0x3fbf4a); vec3 q=p; if(abs(fract(p.y*2.)-.5)<.12) alb=HX(0xf5f0d8); spec=.3; detail=.6; grp=5.; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); return col; }
