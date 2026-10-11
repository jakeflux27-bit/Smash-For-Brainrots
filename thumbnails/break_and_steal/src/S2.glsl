// ===== Steal thumbnail 2: VERITY HEIST (player hugs Verity, giant Cameraman grabs for it) =====
uniform sampler2D uTex0;  // verity face
const float FAR=300.;
const float CAM_ROLL=.05;
const vec3 KEY_DIR=normalize(vec3(.45,.75,.6));
const vec3 KEY_COL=vec3(1.95,1.6,1.15);
const vec3 SKY_COL=vec3(.14,.22,.45);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(-.7,.35,-.6));
const vec3 RIM_COL=vec3(1.6,1.5,1.7);
vec3 PL_POS=vec3(0.); vec3 PL_COL=vec3(2.6,1.9,.4);
const float PL_FALL=.06;
const vec3 FOG_COL=vec3(.62,.78,.97);
const float FOG_START=26.; const float FOG_DENS=.007;
vec3 CAMP; vec3 CAMT; vec3 VC; float VR=1.3; mat3 VRM;
void setup(){
  avatarColors(); FACE=1; PICK_ON=0.; HOODIE=HX(0x23b14d); PANTS=HX(0x1d2a4a); SKIN=HX(0xf3c690); HAIR=HX(0x3a2214);
  vec3 base=vec3(2.4,.35,4.8);
  avatarRig(base, vec3(12.,16.,-5.), vec3(-5.,-30.,-4.), vec3(.42,-.3,1.), vec3(-.42,-.3,1.), vec3(0.,-1.,.8), vec3(0.,-.75,-.9));
  VC=tO+tR*vec3(0.,-.1,1.95); VR=1.35; VRM=eulD(vec3(-4.,-8.,10.));
  // giant cameraman lunging in from the left, right hand reaching for Verity
  camRig(vec3(-4.9,0.,-2.0), 2.25, vec3(22.,72.,5.), vec3(16.,58.,-8.), vec3(-.1,-1.,-.35), vec3(-.15,.35,1.), vec3(0.,-1.,.75), vec3(0.,-.8,-.75));
  PL_POS=VC+vec3(-.5,1.2,2.2);
  CAMP=vec3(-.3,1.6,13.); CAMT=vec3(-.2,5.5,0.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=CAMT; fov=1.7; }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.35*fbm(p*vec3(.25,0,.25))+.25,1.);
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(11.+fi*2.6+4.*fract(fi*.7)),0.,-17.-9.*fract(fi*.53)-fi*1.4);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  // wooden base fence in the background
  { vec3 q=p-vec3(0.,0.,-10.5); float px=mod(q.x+1.25,2.5)-1.25;
    float posts=sdBox(vec3(px,q.y-1.1,q.z),vec3(.18,1.1,.18),.04);
    float rails=min(sdBox(vec3(q.x,q.y-1.5,q.z),vec3(40.,.12,.08),.03),sdBox(vec3(q.x,q.y-.7,q.z),vec3(40.,.12,.08),.03));
    r=U(r,vec2(min(posts,rails),52.)); }
  for(int i=0;i<7;i++){ float fi=float(i); vec3 c=vec3(-20.+fi*7.,0.,-6.-3.5*fract(fi*.61)); if(abs(c.x+1.)<7.) c.x+=15.; float s=.8+.5*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.25*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,vec2(sdSphere(p-VC,VR),60.));
  r=U(r,mapCam(p));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xc4e6ff),HX(0x3478f2),smoothstep(-.02,.28,y)); sky=mix(sky,HX(0x1a3cb0),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(11.,2.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.63,.655,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(-.25,-.3))*.55+vec2(11.,2.))*.75+fbm2((uv+vec2(-.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.63,.8,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; if(id<30.5) emi+=alb*.3; return; }
  if(camMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=.9; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<41.5){ float k=fract(id); vec3 q=p*1.6; float sp=smoothstep(.55,.58,fbm(q));
    alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); alb=mix(alb,alb*.55,sp); detail=.3; spec=.4; RIMK=.4; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
  else if(id<52.5){ alb=mix(HX(0xa8743e),HX(0xd9a35e),fbm(p*2.)); detail=.3; RIMK=.3; }
  else { // VERITY: glossy yellow orb with the in-game face texture
    vec3 lp=transpose(VRM)*(p-VC)/VR; alb=HX(0xffd414); float fa=0.;
    if(lp.z>0.){ vec2 uv=vec2(.5+lp.x*.44,.5-lp.y*.44-.02); vec4 f=texture(uTex0,uv); fa=f.a*smoothstep(0.,.25,lp.z); alb=mix(alb,pow(f.rgb,vec3(2.2)),fa); }
    spec=.35; detail=.99; grp=5.; RIMK=.7*(1.-fa);
    vec3 v=normalize(CAMP-p); emi=(HX(0xffb000)*pow(1.-abs(dot(n,v)),2.5)*1.6+HX(0xffd030)*.12)*(1.-fa); }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.22*dot(uv*.5,uv*.5); return col; }
