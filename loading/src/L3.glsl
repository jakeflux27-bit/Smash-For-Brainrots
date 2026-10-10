// ===== Loading panel 3: GOLDEN EGG NIGHT =====
const float FAR=300.;
const float CAM_ROLL=-.08;
const vec3 KEY_DIR=normalize(vec3(.6,.65,-.45));     // moonlight from behind-right
const vec3 KEY_COL=vec3(.35,.45,.9);
const vec3 SKY_COL=vec3(.05,.06,.16);
const vec3 GROUND_COL=vec3(.02,.03,.04);
const vec3 RIM_DIR=normalize(vec3(.5,.4,-.8));
const vec3 RIM_COL=vec3(.6,.8,1.6);
const vec3 PL_POS=vec3(-3.4,6.,3.4);
const vec3 PL_COL=vec3(6.,3.8,1.);
const float PL_FALL=.05;
const vec3 FOG_COL=vec3(.05,.05,.15);
const float FOG_START=14.; const float FOG_DENS=.03;
vec3 GE; const float GS=3.6; vec3 IMP;
void setup(){
  avatarColors(); FACE=2; HOODIE=HX(0x13b88a); PANTS=HX(0x222a3a); SKIN=HX(0xf3c690); HAIR=HX(0xffd23a); PICKC=HX(0xff3fd2);
  GE=vec3(0.,1.3*GS,0.);
  IMP=vec3(-2.6,5.6,2.1);
  vec3 base=vec3(-6.2,1.2,3.6);   // mid-jump
  avatarRig(base, vec3(10.,72.,6.), vec3(-2.,40.,4.), vec3(.1,.8,.6), vec3(-.1,.8,.6), vec3(0.,-1.,.6), vec3(0.,-.7,-.7));
  vec3 grip=tO+tR*vec3(0.,.3,1.4)+normalize(IMP-tO)*.6;
  haL=shL+normalize(grip-shL)*1.95; haR=shR+normalize(grip-shR)*1.95; grip=(haL+haR)*.5;
  vec3 d=normalize(IMP+vec3(-.3,1.45,0.)-grip); pkA=grip-d*.5; pkB=grip+d*2.2; pkR=frameAB(pkA,pkB,cross(d,vec3(0,1,0)));
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=vec3(-1.2,1.4,13.5); ta=vec3(-1.4,5.0,0.); fov=1.55; }
float sdGEgg(vec3 p){ vec3 q=(p-GE)/GS; q.xz*=1.+.16*q.y; return sdEllipsoid(q,vec3(1.,1.3,1.))*GS; }
vec2 map(vec3 p){
  float n=fbm(p*vec3(.3,0,.3));
  vec2 r=vec2(p.y-.35*n,1.);
  // dark tree line silhouettes + small eggs
  for(int i=0;i<10;i++){ float fi=float(i); vec3 c=vec3(-34.+fi*7.6,0.,-16.-8.*fract(fi*.53)); float s=1.1+.6*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  for(int i=0;i<8;i++){ float fi=float(i); vec3 c=vec3(-22.+fi*6.4,0.,-3.-6.*fract(fi*.61)); if(abs(c.x)<5.) c.x+=9.; float s=.7+.5*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.3*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,vec2(sdGEgg(p),8.));
  // coins bursting out (cylinders) + gems (octahedra)
  for(int i=0;i<18;i++){ float fi=float(i); float a=fi*2.39996; float rr=2.+4.5*fract(fi*.618);
    vec3 c=IMP+vec3(cos(a)*rr*1.1+1.2,abs(sin(a))*rr*.9+.6*fract(fi*.3),sin(a)*1.2+1.5);
    mat3 R=eulD(vec3(fi*53.,fi*31.,fi*77.)); vec3 q=loc(p,c,R);
    if(i<13) r=U(r,vec2(sdCyl(q,.06,.42,.04),60.));
    else { q=abs(q); r=U(r,vec2((q.x+q.y+q.z-.55)*.57,61.)); } }
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0x3a2a6a),HX(0x0c1238),smoothstep(-.02,.45,y)); sky=mix(sky,HX(0x060a20),smoothstep(.45,.95,y));
  vec3 sd=rd*200.; vec3 id=floor(sd); float h=h31(id); float st=step(.982,h)*smoothstep(.5,.0,length(fract(sd)-.5))*smoothstep(.04,.25,y);
  sky+=vec3(1.,.95,.85)*st*(1.2+2.5*h31(id+7.));
  vec3 md=normalize(vec3(.5,.42,-.75)); float m=dot(rd,md);
  sky+=HX(0x9ec4ff)*pow(clamp(m,0.,1.),80.)*.7+HX(0x4a5ab0)*pow(clamp(m,0.,1.),5.)*.18;
  sky=mix(sky,HX(0xeef4ff)*1.6,smoothstep(.9985,.999,m));
  vec2 uv=rd.xz/(y+.18)*1.2; float cd=fbm2(uv*.6+vec2(7.,2.))*.75+fbm2(uv*1.8)*.3;
  float cl=smoothstep(.57,.6,cd)*smoothstep(.0,.2,y);
  vec3 cc=mix(HX(0x2a3470),HX(0x8a9ad8),pow(clamp(m,0.,1.),3.)*.8+.15);
  sky=mix(sky,cc,cl*.9);
  // aurora ribbon
  float au=smoothstep(.12,.0,abs(y-.32-.08*sin(rd.x*6.+fbm2(rd.xz*3.)*3.)))*smoothstep(.0,.3,y);
  sky+=mix(HX(0x30ffb0),HX(0x9a5cff),.5+.5*sin(rd.x*4.))*au*.35;
  return sky;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  if(id<1.5){ alb=mix(HX(0x1d4a24),HX(0x3f7a2a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15+.2*smoothstep(8.,2.,length(p.xz)); spec=.02; }
  else if(id<8.5){ vec3 q=(p-GE)/GS;
    alb=HX(0xffc21a); float sp=fbm(q*2.2); alb=mix(alb,HX(0xffe680),smoothstep(.55,.62,sp));
    vec3 iq=transpose(eulD(vec3(0.)))*((IMP-GE)/GS); float dI=length(q-iq);
    float ve=voroEdge(q*3.2+fbm(q*3.)*.5); float w=.03+.06*(1.-smoothstep(0.,1.,dI)); float cr=(1.-smoothstep(0.,w,ve))*(1.-smoothstep(.25,.95,dI));
    alb=mix(alb,HX(0x5a2a00),cr*.85); emi=HX(0xffd04a)*cr*6.+HX(0xffffff)*(1.-smoothstep(0.,.14,dI))*10.;
    emi+=HX(0xff9a10)*.25; spec=1.6; detail=.6+.35*max(cr,1.-smoothstep(.2,1.2,dI)); grp=3.; RIMK=.8; }
  else if(id<41.5){ float k=fract(id); alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); detail=.3; spec=.4; RIMK=.6; emi=alb*.05; }
  else if(id<50.5){ alb=HX(0x2a1c14); detail=.12; }
  else if(id<51.5){ alb=HX(0x183a2a)*mix(.8,1.2,fbm(p*.8)); detail=.18; RIMK=.4; }
  else if(id<60.5){ alb=HX(0xffcc2a); emi=HX(0xffb020)*.6; spec=2.; detail=.75; grp=5.; RIMK=1.; }
  else { alb=HX(0x9a4cff); emi=HX(0xc070ff)*.8; spec=2.; detail=.75; grp=5.; RIMK=1.; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.1); col*=1.-.3*dot(uv*.55,uv*.55); return col; }
