// ===== Brief set: VERITY (bacon-hair avatar shows off a giant glossy Verity with a gold halo on their fenced base) =====
uniform sampler2D uTex0;  // verity face
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
vec3 CAMP; vec3 CAMT; vec3 VC; float VR=3.4; mat3 VRM; vec3 HAC;
void setup(){
  avatarColors(); FACE=3; OUTFIT=1; BACON=1.; PICK_ON=0.; SKIN=HX(0xf3c690); HAIR=HX(0xa24c1a);
  vec3 base=vec3(-3.7,.3,3.2);
  avatarRig(base, vec3(-4.,28.,-3.), vec3(-8.,12.,6.), vec3(-.04,-1.,.12), vec3(.85,.28,.55), vec3(-.18,-1.,.05), vec3(.18,-1.,-.05));
  VR=4.7; VC=vec3(3.7,VR+1.5,-3.4); VRM=eulD(vec3(-4.,-16.,6.)); HAC=VC+VRM*vec3(0.,VR+1.,0.);
  PL_POS=VC+vec3(-4.,1.,4.);
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
  r=U(r,vec2(sdSphere(p-VC,VR),120.));
  { vec3 q=transpose(VRM)*(p-HAC); vec2 t=vec2(length(q.xz)-2.5,q.y); r=U(r,vec2(length(t)-.36,121.)); }   // halo
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){ return mix(HX(0xbfe8ff),HX(0x2e86ff),smoothstep(-.02,.3,rd.y)); }
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(id>119.5&&id<120.5){ vec3 lp=transpose(VRM)*(p-VC)/VR; alb=HX(0xffd414); float fa=0.;
    if(lp.z>0.){ vec2 uv=vec2(.5+lp.x*.44,.5-lp.y*.44-.02); vec4 f=texture(uTex0,uv); fa=f.a*smoothstep(0.,.25,lp.z); alb=mix(alb,pow(f.rgb,vec3(2.2)),fa); }
    spec=.6; detail=.99; grp=4.; RIMK=1.*(1.-fa);
    vec3 v=normalize(CAMP-p); float hl=pow(max(dot(n,normalize(KEY_DIR+v)),0.),180.);
    emi=(HX(0xffb000)*pow(1.-abs(dot(n,v)),2.5)*1.3+HX(0xffd030)*.1+vec3(1.6)*hl)*(1.-fa); return; }
  if(id>120.5&&id<121.5){ vec3 v=normalize(CAMP-p); alb=HX(0xffcf3a); spec=2.; emi=HX(0xffb000)*.9+vec3(1.5)*pow(max(dot(n,normalize(KEY_DIR+v)),0.),120.); detail=.8; grp=5.; RIMK=1.; return; }
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.3; if(id<30.5||id>35.5&&id<36.5) emi+=alb*.3; return; }
  if(id<1.5){ alb=mix(HX(0x46b42a),HX(0x6fd23c),.5+.5*h21(floor(p.xz*.5)))*mix(.88,1.08,fbm(p*.8)); detail=.15; spec=.03; }
  else if(id<153.5){ alb=HX(0xffc21a); spec=2.; emi=HX(0xffa000)*.25; detail=.7; grp=5.; RIMK=1.; }
  else if(id<160.5){ vec2 tl=floor(p.xz*.5); float ch=mod(tl.x+tl.y,2.); alb=mix(HX(0xe9edf5),HX(0xc9d2e3),ch); spec=.35; detail=.3; }
  else if(id<161.5){ alb=HX(0xfafafa); spec=.4; detail=.4; grp=3.; }
  else { alb=HX(0x3fbf4a); vec3 q=p; if(abs(fract(p.y*2.)-.5)<.12) alb=HX(0xf5f0d8); spec=.3; detail=.6; grp=5.; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); return col; }
