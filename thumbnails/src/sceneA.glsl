// ===== Scene A: THE SMASH =====
const float FAR=80.;
const float CAM_ROLL=-.12;
const vec3 KEY_DIR=normalize(vec3(-.55,.75,.55));
const vec3 KEY_COL=vec3(1.95,1.55,1.05);
const vec3 SKY_COL=vec3(.09,.15,.34);
const vec3 GROUND_COL=vec3(.10,.13,.05);
const vec3 RIM_DIR=normalize(vec3(.7,.35,-.6));
const vec3 RIM_COL=vec3(.9,1.25,1.8);
const vec3 PL_POS=vec3(1.55,1.9,3.25);
const vec3 PL_COL=vec3(4.5,2.6,.6);
const float PL_FALL=.9;
const vec3 FOG_COL=vec3(.45,.62,.85);
const float FOG_START=18.; const float FOG_DENS=.02;

vec3 tO; mat3 tR; vec3 hO; mat3 hR; vec3 shL,shR,haL,haR,hipL,hipR,ftL,ftR; vec3 pkA,pkB; mat3 pkR; vec3 eggC; mat3 eggR; vec3 IMP;
void setup(){
  eggC=vec3(3.85,1.32,1.75); eggR=eulD(vec3(6.,0.,-8.));
  vec3 fw=normalize(vec3(eggC.x,0.,eggC.z)); float yaw=atan(fw.x,fw.z)*180./PI;
  tO=vec3(0.,3.0,0.); tR=eulD(vec3(18.,yaw-8.,-4.));
  vec3 neck=tO+tR*vec3(0,1.0,0); hR=eulD(vec3(18.,yaw-30.,-6.)); hO=neck+hR*vec3(0,.74,0);
  shL=tO+tR*vec3(-1.5,.62,0.); shR=tO+tR*vec3(1.5,.62,0.);
  vec3 grip=tO+tR*vec3(0.05,.05,1.75);
  haL=shL+1.95*normalize(grip-tR*vec3(.2,0,0)-shL); haR=shR+1.95*normalize(grip+tR*vec3(.2,0,0)-shR);
  hipL=tO+tR*vec3(-.5,-1.,0.); hipR=tO+tR*vec3(.5,-1.,0.);
  ftL=tO+tR*vec3(-.75,-2.9,1.05); ftL.y=.0; ftR=tO+tR*vec3(.75,-2.8,-1.2); ftR.y=.0;
  IMP=vec3(3.26,2.2,2.29);
  pkB=IMP+vec3(0.,1.4,0.);
  for(int k=0;k<4;k++){ vec3 y=normalize(pkB-grip); vec3 x=normalize(cross(y,cross(y,vec3(0,1,0)))); pkB=IMP-x*1.39+y*.67; }
  vec3 dir=normalize(pkB-grip);
  pkA=grip-dir*.6;
  vec3 y=normalize(pkB-pkA); pkR=frameAB(pkA,pkB,cross(y,vec3(0,1,0)));
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=vec3(2.6,1.15,6.0); ta=vec3(2.05,2.75,0.8); fov=1.22; }

float sdEgg(vec3 p){ vec3 q=transpose(eggR)*(p-eggC); q.xz*=1.+.16*q.y; return sdEllipsoid(q,vec3(1.08,1.36,1.08)); }
float pickHead(vec3 p){ // curved crescent pick head at pkB, perpendicular to handle
  vec3 q=transpose(pkR)*(p-pkB); q.z*=1.5;
  float d=1e9; vec3 prev;
  for(int i=0;i<=12;i++){ float t=float(i)/12.*2.-1.; float a=t*1.05;
    vec3 c=vec3(sin(a)*1.6,-(1.-cos(a))*1.35,0.);
    if(i>0){ float r=mix(.3,.04,pow(abs(t),1.2)); d=smin(d,sdCapsule(q,prev,c,r),.12); }
    prev=c; }
  d=smin(d, sdBox(q-vec3(0,-.02,0),vec3(.3,.34,.3),.07),.08);
  return d/1.5;}
vec2 map(vec3 p){
  vec2 r=vec2(p.y+fbm(p*vec3(.6,0,.6))*.08 - .9*smoothstep(10.,40.,length(p.xz))*sin(p.x*.12)*sin(p.z*.09)*3., 1.); // ground
  // far hills
  r=U(r,vec2(sdEllipsoid(p-vec3(-30.,-6.,-40.),vec3(26.,12.,10.)),1.));
  r=U(r,vec2(sdEllipsoid(p-vec3(25.,-8.,-48.),vec3(30.,14.,10.)),1.));
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=vec3(-14.+fi*4.3+3.*sin(fi*3.1), 0., -9.-6.*fract(fi*.618)*3.-fi*.8); float sc=.9+.5*fract(fi*.31);
    vec3 q=(p-c-vec3(0,1.3*sc,0))/sc; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.05,1.33,1.05))*sc,10.+fract(fi*.37))); }
  // body
  r=U(r,vec2(sdBox(loc(p,tO,tR),vec3(1.,1.,.5),.08),3.));
  r=U(r,vec2(sdBox(loc(p,hO,hR),vec3(.74,.72,.72),.3),2.));
  vec3 ref=tR*vec3(1,0,0);
  r=U(r,vec2(limbBox(p,shL,haL,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,shR,haR,ref,vec2(.5),.5,.07),4.));
  r=U(r,vec2(limbBox(p,hipL,ftL,vec3(1,0,0),vec2(.5),.0,.07),5.));
  r=U(r,vec2(limbBox(p,hipR,ftR,vec3(1,0,0),vec2(.5),.0,.07),5.));
  // pickaxe
  r=U(r,vec2(sdCapsule(p,pkA,pkB,.13),6.));
  r=U(r,vec2(pickHead(p),7.));
  // egg (cut-out chunk where it's being cracked)
  float e=sdEgg(p);
  r=U(r,vec2(e,8.));
  // flying shell shards
  for(int i=0;i<9;i++){ float fi=float(i); vec3 c=IMP+vec3(1.5*sin(fi*2.3+.5),.25+1.3*fract(fi*.37)+fi*.09,1.1*cos(fi*1.7)+.5);
    mat3 R=eulD(vec3(fi*47.,fi*83.,fi*29.)); r=U(r,vec2(sdBox(loc(p,c,R),vec3(.16,.025,.12)*(1.-.05*fi),.02),9.)); }
  return r;}

vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0x9fd8ff),HX(0x1550c0),smoothstep(-.02,.6,y));
  float cl=fbm(vec3(rd.xz/(y+.25)*1.3,0.)+vec3(3.,1.,0.));
  float cm=smoothstep(.45,.7,cl)*smoothstep(-.1,.25,y); float cs=smoothstep(.45,.75,fbm(vec3(rd.xz/(y+.25)*1.3,0.)+vec3(3.,1.08,0.)));
  sky=mix(sky,mix(HX(0xffffff),HX(0xb8c8e8),cs*.6),cm*.95);
  float sun=pow(clamp(dot(rd,KEY_DIR),0.,1.),8.);
  return sky*1.15+vec3(1.,.85,.6)*sun*.6;
}
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
  if(id<1.5){ float g=fbm(p*vec3(.5,0,.5)); float g2=fbm(p*vec3(3.,0,3.));
    alb=mix(HX(0x2f7a22),HX(0x6cc23a),g)*mix(.65,1.2,g2); detail=.15; spec=.02; RIMK=0.;
    if(length(p.xz)>25.) alb=mix(alb,HX(0x6aa8d8),.3);
  }
  else if(id<2.5){ vec3 lp=transpose(hR)*(p-hO); alb=headFace(lp,HX(0xf7c72c)); detail=1.; grp=1.; spec=.35; }
  else if(id<3.5){ alb=HX(0x1f5fd6); detail=.6; grp=1.; spec=.15;
    vec3 lp=transpose(tR)*(p-tO); // little 67 badge? keep plain fabric with fold shading
    alb*=.9+.15*fbm(lp*4.);}
  else if(id<4.5){ alb=HX(0xf7c72c); detail=.6; grp=1.; spec=.3; }
  else if(id<5.5){ alb=HX(0x3fae3a); detail=.5; grp=1.; spec=.1; }
  else if(id<6.5){ vec3 q=transpose(pkR)*(p-pkA); alb=mix(HX(0x6b3a17),HX(0xa8642c),.5+.5*sin(q.y*9.+fbm(q*6.)*4.)); detail=.6; grp=2.; spec=.3; }
  else if(id<7.5){ vec3 q=transpose(pkR)*(p-pkB); bool core=abs(q.x)<.3&&q.y>-.4;
    alb=core?HX(0x4a2a12):HX(0x22d4f0); spec=core?.2:1.2; detail=.75; grp=2.;
    if(!core) emi=HX(0x10c0ff)*.55*(.4+.6*pow(1.-abs(dot(n,normalize(p-vec3(1.9,2.35,8.6)))),2.)); }
  else if(id<8.5){ vec3 q=transpose(eggR)*(p-eggC);
    float sp=fbm(q*1.6+2.); float sp2=fbm(q*2.3+9.);
    alb=HX(0xfbeccb);
    alb=mix(alb,HX(0xa8693d),smoothstep(.6,.63,sp));
    alb=mix(alb,HX(0x6fc24e),smoothstep(.64,.67,sp2));
    // glowing cracks spreading from the impact point (upper-left of egg)
    vec3 imp=transpose(eggR)*(IMP-eggC); float dI=length(q-imp);
    float ve=voroEdge(q*3.4+fbm(q*3.)*.6); float w=.02+.07*(1.-smoothstep(0.,1.,dI)); float crack=1.-smoothstep(.0,w,ve); float edge=1.-smoothstep(w,w*1.9,ve);
    float fall=1.-smoothstep(.25,1.25,dI); crack*=fall; edge*=fall;
    float hole=1.-smoothstep(.0,.38,dI);
    alb=mix(alb,HX(0x3a1a06),max(edge,crack)*.92);
    emi=HX(0xff9a10)*(crack*5.+hole*14.)+HX(0xffe08a)*crack*crack*3.*(1.-smoothstep(0.,.6,dI));
    detail=.55+.42*max(fall,crack); grp=3.; spec=.5; }
  else if(id<9.5){ alb=HX(0xfbeccb); emi=HX(0xffb52e)*1.4; detail=.5; grp=3.; spec=.4; }
  else { float k=fract(id); vec3 cs[5]=vec3[5](HX(0xf6e2b8),HX(0xb48cff),HX(0x7cc8ff),HX(0xff8fb0),HX(0xffd84a));
    alb=cs[int(k*5.)]; float sp=fbm(p*2.); alb=mix(alb,HX(0xa8693d),smoothstep(.62,.65,sp)); detail=.3; grp=4.; spec=.3; }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){
  col=aces(col*1.05);
  col*=1.-.28*dot(uv*.55,uv*.55);
  return col;}
