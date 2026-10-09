// ===== Scene C: BOSS CLASH (sunset arena) =====
const float FAR=120.;
const float CAM_ROLL=.07;
const vec3 KEY_DIR=normalize(vec3(.25,.42,-.85));      // low sun behind the fighters
const vec3 KEY_COL=vec3(2.4,1.45,.75);
const vec3 SKY_COL=vec3(.36,.24,.42);
const vec3 GROUND_COL=vec3(.32,.15,.07);
const vec3 RIM_DIR=normalize(vec3(.1,.35,-.95));
const vec3 RIM_COL=vec3(2.2,1.3,.6);
const vec3 PL_POS=vec3(-.2,5.7,.6);
const vec3 PL_COL=vec3(2.5,4.5,6.);
const float PL_FALL=.35;
const vec3 FOG_COL=vec3(.75,.42,.32);
const float FOG_START=14.; const float FOG_DENS=.03;
vec3 CAMP; vec3 CLASH;
vec3 tO; mat3 tR; vec3 hO; mat3 hR; vec3 shL,shR,haL,haR,hipL,hipR,ftL,ftR; vec3 pkA,pkB; mat3 pkR;
vec3 gO; mat3 gR; vec3 gHand,gHand2,bA,bB, gShL,gShR, gHipL,gHipR,gFtL,gFtR;
void setup(){
  CAMP=vec3(.5,1.2,7.6); CLASH=vec3(-.2,5.7,.6);
  // --- noob, leaping in from the right
  vec3 base=vec3(3.1,1.2,2.2);
  tO=base+vec3(0.,3.,0.); tR=eulD(vec3(-6.,-40.,-18.));
  vec3 neck=tO+tR*vec3(0,1.,0); hR=eulD(vec3(-18.,-24.,-8.)); hO=neck+hR*vec3(0,.74,0);
  shL=tO+tR*vec3(-1.5,.62,0.); shR=tO+tR*vec3(1.5,.62,0.);
  vec3 grip=tO+vec3(-1.75,-.25,.7);
  haL=shL+1.95*normalize(grip-shL); haR=shR+1.95*normalize(grip-shR);
  hipL=tO+tR*vec3(-.5,-1.,0.); hipR=tO+tR*vec3(.5,-1.,0.);
  ftL=hipL+tR*normalize(vec3(0.,-1.,.6))*1.9; ftR=hipR+tR*normalize(vec3(0.,-.7,-1.))*1.9;
  vec3 pd=normalize(CLASH+vec3(.55,.95,0.)-grip); pkA=grip-pd*.6; pkB=grip+pd*2.0;
  pkR=frameAB(pkA,pkB,cross(pd,vec3(0,0,1)));
  // --- giant Tung Tung Tung Sahur on the left
  gO=vec3(-4.4,0.,-.4); gR=eulD(vec3(0.,40.,-7.));
  gShL=gO+gR*vec3(-1.35,5.4,0.); gShR=gO+gR*vec3(1.35,5.4,0.);
  gHand=gO+gR*vec3(1.55,8.9,-.2);        // right hand raised (holding bat)
  gHand2=gO+gR*vec3(-2.3,4.0,1.0);
  bA=gHand-normalize(CLASH-gHand)*.5; bB=CLASH+normalize(CLASH-gHand)*.75;
  gHipL=gO+gR*vec3(-.6,2.1,0.); gHipR=gO+gR*vec3(.6,2.1,0.);
  gFtL=gO+gR*vec3(-.9,.25,.6); gFtR=gO+gR*vec3(.95,.25,-.5);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=vec3(-.4,5.3,0.); fov=1.02; }
float sdLog(vec3 q){ return sdCyl(q-vec3(0,5.0,0),3.1,1.45,.35); }
vec2 map(vec3 p){
  float n=fbm(p*vec3(.4,0.,.4));
  vec2 r=vec2(p.y-.25*n+.0, 1.);
  // cracked crater under the clash
  // distant mesas
  for(int i=0;i<6;i++){ float fi=float(i); vec3 c=vec3(-60.+fi*24.,0.,-55.-10.*fract(fi*.7)); 
    r=U(r,vec2(sdBox(p-c,vec3(7.+4.*fract(fi*.37),8.+9.*fract(fi*.53),6.),3.)+fbm(p*.25)*2.,11.)); }
  // rocks
  for(int i=0;i<7;i++){ float fi=float(i); vec3 c=vec3(-9.+fi*3.2,.2,-3.-2.*sin(fi*2.1)); r=U(r,vec2(sdEllipsoid(p-c,vec3(.8,.5,.7)*(.6+.5*fract(fi*.61)))+fbm(p*2.)*.15,13.)); }
  // --- Tung
  vec3 q=transpose(gR)*(p-gO);
  r=U(r,vec2(sdLog(q),20.));
  r=U(r,vec2(sdCapsule(p,gShR,gHand,.3),21.));
  r=U(r,vec2(sdCapsule(p,gShL,gHand2,.3),21.));
  r=U(r,vec2(sdSphere(p-gHand,.42),21.)); r=U(r,vec2(sdSphere(p-gHand2,.42),21.));
  r=U(r,vec2(sdCapsule(p,gHipL,gFtL,.32),21.)); r=U(r,vec2(sdCapsule(p,gHipR,gFtR,.32),21.));
  r=U(r,vec2(sdRoundCone(p,bA,bB,.17,.42),22.)); r=U(r,vec2(sdSphere(p-bA,.24),22.));
  // --- noob
  r=U(r,vec2(sdBox(loc(p,tO,tR),vec3(1.,1.,.5),.08),3.));
  r=U(r,vec2(sdBox(loc(p,hO,hR),vec3(.74,.72,.72),.3),2.));
  vec3 ref=tR*vec3(1,0,0);
  r=U(r,vec2(limbBox(p,shL,haL,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,shR,haR,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,hipL,ftL,ref,vec2(.5),.0,.07),5.));
  r=U(r,vec2(limbBox(p,hipR,ftR,ref,vec2(.5),.0,.07),5.));
  r=U(r,vec2(sdCapsule(p,pkA,pkB,.12),6.));
  { vec3 q2=transpose(pkR)*(p-pkB); q2.z*=1.5; float d=1e9; vec3 prev;
    for(int i=0;i<=10;i++){ float t=float(i)/10.*2.-1.; float a=t*1.05; vec3 c=vec3(sin(a)*1.5,-(1.-cos(a))*1.25,0.);
      if(i>0){ float rr=mix(.29,.04,pow(abs(t),1.2)); d=smin(d,sdCapsule(q2,prev,c,rr),.1);} prev=c; }
    d=smin(d,sdBox(q2,vec3(.27,.3,.27),.06),.08); r=U(r,vec2(d/1.5,7.)); }
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xffb36b),HX(0xff6f61),smoothstep(-.02,.12,y));
  sky=mix(sky,HX(0x8a4a9e),smoothstep(.1,.35,y)); sky=mix(sky,HX(0x2e2a6e),smoothstep(.35,.8,y));
  float s=dot(rd,normalize(vec3(-.05,.12,-1.)));
  sky+=HX(0xfff0c0)*pow(clamp(s,0.,1.),300.)*4.+HX(0xffb060)*pow(clamp(s,0.,1.),12.)*.8;
  float cl=fbm(vec3(rd.xz/(y+.15)*1.2,2.)); 
  sky=mix(sky,mix(HX(0xffcf9a),HX(0x6a3a7a),smoothstep(.0,.4,y)),smoothstep(.5,.72,cl)*smoothstep(-.02,.2,y)*.75);
  return sky;}
vec3 tungFace(vec3 q, vec3 base){
  // q in log space; face on the front (+z) between y 4.6 and 7.4
  float ang=atan(q.x,q.z); vec2 uv=vec2(ang*1.4, q.y-5.9); vec3 c=base; vec3 ink=HX(0x140a08);
  float front=smoothstep(1.25,1.0,abs(ang));
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 e=uv-vec2(sg*.52,.35);
    float eye=length(e)-.42;
    c=mix(c,ink,fill(eye-.06,.02)*front); c=mix(c,HX(0xfffaf0),fill(eye,.02)*front);
    c=mix(c,ink,fill(length(e-vec2(-sg*.05,-.02))-.12,.02)*front);
    c=mix(c,HX(0xffffff),fill(length(e-vec2(-sg*.05-.04,.04))-.035,.01)*front);
    float brow=sd2Seg(uv,vec2(sg*.95,1.05),vec2(sg*.18,.8))-.09; c=mix(c,ink,fill(brow,.02)*front); }
  // wide unhinged grin
  vec2 m=uv-vec2(0.,-.75);
  float mo=max(length(m*vec2(.85,1.6))-.75, m.y-.12);
  c=mix(c,ink,fill(mo-.05,.02)*front); c=mix(c,HX(0x5a0f14),fill(mo,.02)*front);
  float teeth=max(mo+.02, -(m.y+.0)); float tl=abs(fract(m.x*4.5+.5)-.5);
  c=mix(c,mix(HX(0xfff4e0),ink,smoothstep(.06,.02,tl)*.7),fill(max(mo+.03,-(m.y-.12)+.18 ),.02)*front*step(-.08,m.y));
  return c;}
vec3 headFace(vec3 lp, vec3 base){
  vec2 uv=lp.xy/.72; vec3 c=base;
  // only front face
  float front=smoothstep(.55,.65,lp.z/.72);
  vec3 ink=HX(0x1a0e12);
  // eyes (angry: cut by brow line)
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 q=vec2(uv.x*sg,uv.y);
    float eye=sd2Ell(q,vec2(.34,.14),vec2(.19,.15));
    float cut=dot(q-vec2(.34,.26),normalize(vec2(-.42,-1.)));
    float e=max(eye,-cut-0.);
    c=mix(c,ink,fill(e-.035,.012)*front);
    c=mix(c,HX(0xffffff),fill(e,.012)*front);
    c=mix(c,ink,fill(sd2Ell(q,vec2(.27+.05*sg*0.,.11),vec2(.075,.085)),.01)*front*fill(e,.01));
    c=mix(c,HX(0xffffff),fill(sd2Ell(q,vec2(.25,.15),vec2(.022,.022)),.008)*front);
    float brow=sd2Seg(q,vec2(.62,.47),vec2(.12,.22))-.065;
    c=mix(c,ink,fill(brow,.012)*front);
  }
  // gritted-teeth mouth
  vec2 mq=uv-vec2(.03,-.42);
  float m=sd2Box(mq,vec2(0),vec2(.42,.19),.12);
  c=mix(c,ink,fill(m-.04,.012)*front);
  c=mix(c,HX(0x6b0f1e),fill(m,.012)*front);
  float teeth=max(m+.035,abs(mq.y)-.13);
  float gap=abs(mq.y)-.012; // between rows
  vec3 tc=HX(0xfff6e6);
  float tm=fill(max(m+.03,-gap+.0),.01)*fill(abs(mq.y)-.16,.01);
  float vline=abs(fract(mq.x*6.+.5)-.5)/6.;
  tc=mix(tc,ink,(1.-smoothstep(.006,.014,vline))*.8);
  c=mix(c,tc,tm*front*fill(m+.025,.01));
  // sweat drop + anger blush
  c=mix(c,HX(0xff7b3a),fill(sd2Ell(uv,vec2(-.62,-.2),vec2(.12,.07)),.05)*front*.45);
  c=mix(c,HX(0xff7b3a),fill(sd2Ell(uv,vec2(.66,-.2),vec2(.12,.07)),.05)*front*.45);
  return c;}
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.2; detail=.25; grp=0.; RIMK=1.;
  if(id<1.5){ float g=fbm(p*vec3(.6,0,.6)); alb=mix(HX(0x9a5a34),HX(0xd49456),g)*mix(.75,1.1,fbm(p*3.)); RIMK=0.; spec=.05; detail=.15;
    float ve=voroEdge(vec3(p.xz*.45,0.)); float cr=(1.-smoothstep(0.,.06,ve))*(1.-smoothstep(3.,9.,length(p.xz-vec2(-.6,.8))));
    alb=mix(alb,HX(0x2a140a),cr); emi=HX(0x40c0ff)*cr*1.2*(1.-smoothstep(1.,6.,length(p.xz-vec2(-.6,.8)))); detail=.15+.25*cr; }
  else if(id<2.5){ vec3 lp=transpose(hR)*(p-hO); alb=headFace(lp,HX(0xf7c72c)); detail=1.; grp=1.; spec=.3; }
  else if(id<3.5){ alb=HX(0x1f5fd6); detail=.6; grp=1.; spec=.15; }
  else if(id<4.5){ alb=HX(0xf7c72c); detail=.6; grp=1.; spec=.3; }
  else if(id<5.5){ alb=HX(0x3fae3a); detail=.5; grp=1.; spec=.1; }
  else if(id<6.5){ alb=HX(0x7a4420); detail=.55; grp=2.; }
  else if(id<7.5){ alb=HX(0x22d4f0); spec=1.2; emi=HX(0x10c0ff)*.6; detail=.7; grp=2.; }
  else if(id<11.5){ alb=HX(0x8a4a3a); RIMK=0.; detail=.1; spec=0.; }
  else if(id<13.5){ alb=HX(0x7a4a2e)*mix(.7,1.1,fbm(p*3.)); detail=.3; spec=.1; RIMK=.5; }
  else if(id<20.5){ vec3 q=transpose(gR)*(p-gO);
    float grain=fbm(vec3(atan(q.x,q.z)*6.,q.y*.5,0.)*vec3(3.,1.,1.));
    alb=mix(HX(0x8a5428),HX(0xc98a4f),grain); alb=mix(alb,HX(0x5a3216),smoothstep(.62,.7,fbm(vec3(atan(q.x,q.z)*14.,q.y*.25,3.))));
    if(n.y>.8 && q.y>7.) { float rr=length(q.xz); alb=mix(HX(0xe8c08a),HX(0xb07a40),.5+.5*sin(rr*14.)); }
    alb=tungFace(q,alb); detail=.95; grp=4.; spec=.15; }
  else if(id<21.5){ alb=HX(0xc98a4f); detail=.6; grp=4.; spec=.1; }
  else { alb=mix(HX(0xe0b070),HX(0xa86a30),.5+.5*sin(dot(p,vec3(3.))*2.)); detail=.6; grp=4.; spec=.3; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.3*dot(uv*.55,uv*.55); return col; }
