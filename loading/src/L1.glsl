// ===== Loading panel 1: INTO THE LANE (golden hour vista) =====
const float FAR=400.;
const float CAM_ROLL=-.03;
const vec3 SUN=normalize(vec3(-.55,.15,1.));
const vec3 KEY_DIR=SUN;
const vec3 KEY_COL=vec3(1.9,1.3,.78);
const vec3 SKY_COL=vec3(.16,.22,.42);
const vec3 GROUND_COL=vec3(.22,.14,.06);
const vec3 RIM_DIR=SUN;
const vec3 RIM_COL=vec3(1.3,.85,.45);
const vec3 PL_POS=vec3(-26.,22.,-30.);
const vec3 PL_COL=vec3(.75,.55,.42);
const float PL_FALL=.0003;
const vec3 FOG_COL=vec3(1.0,.70,.45);
const float FOG_START=22.; const float FOG_DENS=.0045;
vec3 GEGG;
float pathX(float z){ return -(2.5+4.*sin(z*.045)+2.*sin(z*.11))-6.; }
float hgt(vec2 p){
  float h=1.6*sin(p.x*.07+1.)*sin(p.y*.055+.5)+1.1*sin(p.x*.13-p.y*.04);
  h+=.9*exp(-(pow(p.x+2.6,2.)+pow(p.y+1.,2.))/40.);
  h-=1.2*exp(-pow(p.x-pathX(p.y),2.)/18.)*smoothstep(4.,12.,p.y);
  h+=smoothstep(110.,170.,p.y)*12.*(.5+.5*sin(p.x*.05));
  return h;}
void setup(){
  avatarColors(); FACE=0;
  vec3 base=vec3(-3.4,0.,-.6); base.y=hgt(base.xz)-.05;
  avatarRig(base, vec3(2.,-16.,0.), vec3(-8.,-84.,-4.), vec3(-.2,-1.,.05), vec3(.25,-.35,.9), vec3(-.05,-1.,.12), vec3(.05,-1.,-.12));
  vec3 up=normalize(tR*vec3(.12,1.,-1.15));
  pkA=haR-up*.5; pkB=haR+up*2.6; pkR=frameAB(pkA,pkB,tR*vec3(1,0,0));
  GEGG=vec3(-66.,0.,106.); GEGG.y=hgt(GEGG.xz)+10.5;
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=vec3(-7.6,3.6,-6.0); ta=vec3(-8.5,4.6,24.); fov=1.22; }
float sdEggS(vec3 q, float s){ q/=s; q.xz*=1.+.16*q.y; return sdEllipsoid(q,vec3(1.,1.3,1.))*s; }
vec4 eggCell(vec2 xz){ // returns center.xz, size, colour-id
  vec2 c=floor(xz/7.); float h=h21(c); vec2 o=(vec2(h21(c+3.1),h21(c+7.7))-.5)*3.; return vec4(c*7.+3.5+o,.75+.9*h21(c+1.3),h);}
vec2 map(vec3 p){
  vec2 r=vec2((p.y-hgt(p.xz))*.62,1.);
  // eggs in the fields
  if(p.z>4.&&p.z<105.&&abs(p.x)<55.){
    vec4 e=eggCell(p.xz); float keep=step(.28,e.w)*step(4.5,abs(e.x-pathX(e.y)))*step(10.,e.y);
    if(keep>.5){ vec3 c=vec3(e.x,hgt(e.xy)+1.25*e.z,e.y); vec2 cl=fract(p.xz/7.)*7.; float bd=min(min(cl.x,7.-cl.x),min(cl.y,7.-cl.y))+.25; bd=max(bd,p.y-hgt(p.xz)-4.5); r=U(r,vec2(min(sdEggS(p-c,e.z)*.9,bd),40.+floor(clamp(e.y/22.,0.,4.)))); }
  }
  // voxel trees
  if(p.z>10.&&p.z<140.){
    vec2 c=floor(p.xz/13.); float h=h21(c+9.); vec2 tc=c*13.+6.5+(vec2(h21(c+2.),h21(c+5.))-.5)*5.;
    vec2 cl=fract(p.xz/13.)*13.; float bd=min(min(cl.x,13.-cl.x),min(cl.y,13.-cl.y))+.3; bd=max(bd,p.y-hgt(p.xz)-13.); r=U(r,vec2(bd,1.));
    vec2 de=normalize(GEGG.xz-vec2(-7.6,-6.)), dt=normalize(tc-vec2(-7.6,-6.));
    if(h>.45&&abs(tc.x-pathX(tc.y))>9.&&dot(de,dt)<.985){ float gy=hgt(tc); float s=.8+.6*h;
      vec3 q=p-vec3(tc.x,gy,tc.y);
      float t=sdBox(q-vec3(0,2.2*s,0),vec3(.45,2.2,.45)*s,.05);
      float l=sdBox(q-vec3(0,5.2*s,0),vec3(2.3,1.5,2.3)*s,.15); l=min(l,sdBox(q-vec3(.4,7.*s,-.3),vec3(1.5,1.1,1.5)*s,.12));
      r=U(r,vec2(t,50.)); r=U(r,vec2(l,51.)); } }
  // zone gate arch over the path
  { vec3 g=vec3(pathX(42.),hgt(vec2(pathX(42.),42.)),42.); vec3 q=p-g;
    float a=min(sdBox(q-vec3(-6.,6.,0),vec3(1.2,6.,1.2),.2),sdBox(q-vec3(6.,6.,0),vec3(1.2,6.,1.2),.2));
    a=min(a,sdBox(q-vec3(0,12.6,0),vec3(7.8,1.2,1.5),.2)); r=U(r,vec2(a,52.));
    r=U(r,vec2(sdBox(q-vec3(0,6.,0),vec3(4.8,6.,.15),.0),53.)); }
  // giant golden egg on the far hill
  r=U(r,vec2(sdEggS(p-GEGG,8.),54.));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xffd27a),HX(0xff9a62),smoothstep(-.02,.07,y));
  sky=mix(sky,HX(0xd77ab0),smoothstep(.06,.14,y)); sky=mix(sky,HX(0x2f5fdc),smoothstep(.12,.32,y)); sky=mix(sky,HX(0x15338f),smoothstep(.4,.85,y));
  float s=max(dot(rd,SUN),0.);
  sky+=HX(0xfff2c0)*pow(s,900.)*30.+HX(0xffc070)*pow(s,40.)*.7+HX(0xff9a50)*pow(s,8.)*.25;
  // graphic cumulus clouds (sharp edges, lit + shaded)
  vec2 uv=rd.xz/(y+.13)*1.1; float dsun=1.-s;
  float cd=fbm2(uv*.62+vec2(1.,9.))*.75+fbm2(uv*1.6)*.35;
  float cl=smoothstep(.58,.6,cd)*smoothstep(.0,.14,y);
  float sh=fbm2((uv+SUN.xz*.35)*.62+vec2(1.,9.))*.75+fbm2((uv+SUN.xz*.35)*1.6)*.35;
  vec3 lit=mix(HX(0xfff1d6),HX(0xffc887),smoothstep(.5,.0,dsun*2.)); vec3 shade=mix(HX(0x8f86c6),HX(0xd98a7a),smoothstep(.3,.0,y));
  vec3 cc=mix(lit,shade,smoothstep(.55,.75,sh)*.85);
  cc+=HX(0xffd080)*smoothstep(.62,.58,cd)*cl*pow(s,8.)*2.;    // silver lining near sun
  sky=mix(sky,cc,cl);
  return sky;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  if(id<1.5){ float g=fbm(p*vec3(.35,0,.35)); alb=mix(HX(0x3f8f2a),HX(0x86c93e),g)*mix(.8,1.12,fbm(p*2.));
    float pm=1.-smoothstep(1.8,2.8,abs(p.x-pathX(p.z))); alb=mix(alb,HX(0xc9935a)*mix(.85,1.1,fbm(p*3.)),pm*smoothstep(3.,8.,p.z));
    detail=.12+.25*smoothstep(10.,40.,p.z)*smoothstep(90.,50.,p.z); spec=.02; }
  else if(id<44.5){ int z=int(id-40.); vec3 cs[5]=vec3[5](HX(0xf3ead2),HX(0xb48cff),HX(0x7ce0ff),HX(0xff8fb6),HX(0xffd64a));
    vec3 ss[5]=vec3[5](HX(0x2e9a8a),HX(0x5a2ea8),HX(0x1a6ad0),HX(0xc0306a),HX(0xd06a10));
    alb=cs[z]; float sp=fbm(p*1.3); alb=mix(alb,ss[z],smoothstep(.6,.62,sp)); detail=.55; grp=3.; spec=.5; RIMK=.6; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9))*mix(.85,1.1,step(.5,fract((p.x+p.y+p.z)*.5))); detail=.42; RIMK=.4; }
  else if(id<52.5){ alb=mix(HX(0x9a8a7a),HX(0xc8b8a0),fbm(p*.8)); detail=.6; RIMK=.4; }
  else if(id<53.5){ vec3 g=p-vec3(pathX(42.),hgt(vec2(pathX(42.),42.))+6.,42.); float a=atan(g.y,g.x)+length(g.xy)*.45; float sw=.5+.5*sin(a*3.+fbm(g*.5)*4.);
    alb=HX(0x60e0ff); emi=mix(HX(0x8a5cff),HX(0x7af0ff),sw)*1.8*(1.-.5*smoothstep(0.,6.,length(g.xy))); detail=.6; }
  else { alb=HX(0xffd23a); vec3 q=(p-GEGG)/8.; float sp=fbm(q*2.5); emi=mix(HX(0xffa010),HX(0xfff0a0),smoothstep(.5,.7,sp))*1.6; spec=1.; detail=.92; FOGK=.15; RIMK=1.; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.05); col*=1.-.25*dot(uv*.5,uv*.5); return col; }
