// ===== shared chase characters =====
// ---------- Tung Tung Tung Sahur (a log with a face, little limbs and a bat) ----------
vec3 TO_=vec3(0.,-100.,0.); mat3 TR_=mat3(1.); float TS_=.65;
vec3 tShL=vec3(-1.35,.5,.2), tShR=vec3(1.35,.5,.2), tHaL, tHaR, tHipL=vec3(-.6,-2.8,0.), tHipR=vec3(.6,-2.8,0.), tFtL, tFtR, tBatA, tBatB;
float TUNG_FACE=0.;  // 0 grin, 1 panic
vec2 mapTung(vec3 p){
  vec3 q=transpose(TR_)*(p-TO_)/TS_;
  float bd=length(q)-7.; if(bd>1.) return vec2(bd*TS_,0.);
  vec2 r=vec2(sdCyl(q,3.1,1.45,.35),20.);
  float l=sdCapsule(q,tShL,tHaL,.3); l=min(l,sdCapsule(q,tShR,tHaR,.3));
  l=min(l,sdSphere(q-tHaL,.42)); l=min(l,sdSphere(q-tHaR,.42));
  l=min(l,sdCapsule(q,tHipL,tFtL,.32)); l=min(l,sdCapsule(q,tHipR,tFtR,.32));
  l=min(l,sdSphere(q-tFtL,.44)); l=min(l,sdSphere(q-tFtR,.44));
  r=U(r,vec2(l,21.));
  r=U(r,vec2(min(sdRoundCone(q,tBatA,tBatB,.17,.42),sdSphere(q-tBatA,.24)),22.));
  r.x*=TS_; return r;}
vec3 tungFace(vec3 q, vec3 base){
  float ang=atan(q.x,q.z); vec2 uv=vec2(ang*1.4, q.y-.9); vec3 c=base; vec3 ink=HX(0x140a08);
  float front=smoothstep(1.25,1.0,abs(ang));
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 e=uv-vec2(sg*.52,.35);
    float eye=length(e)-(TUNG_FACE>.5?.48:.42);
    c=mix(c,ink,fill(eye-.06,.02)*front); c=mix(c,HX(0xfffaf0),fill(eye,.02)*front);
    vec2 pc=TUNG_FACE>.5?vec2(sg*.02,.02):vec2(-sg*.05,-.02); float pr=TUNG_FACE>.5?.09:.12;
    c=mix(c,ink,fill(length(e-pc)-pr,.02)*front);
    c=mix(c,HX(0xffffff),fill(length(e-pc-vec2(-.04,.05))-.035,.01)*front);
    float brow=TUNG_FACE>.5? sd2Seg(uv,vec2(sg*.85,1.0),vec2(sg*.25,1.12))-.08 : sd2Seg(uv,vec2(sg*.95,1.05),vec2(sg*.18,.8))-.09;
    c=mix(c,ink,fill(brow,.02)*front); }
  vec2 m=uv-vec2(0.,-.75);
  float mo= TUNG_FACE>.5 ? length(m*vec2(1.25,1.0))-.5 : max(length(m*vec2(.85,1.6))-.75, m.y-.12);
  c=mix(c,ink,fill(mo-.05,.02)*front); c=mix(c,HX(0x5a0f14),fill(mo,.02)*front);
  if(TUNG_FACE>.5){ c=mix(c,HX(0xe85a6a),fill(length((m-vec2(0.,-.28))*vec2(1.,1.6))-.3,.02)*front*fill(mo,.02));
    c=mix(c,HX(0xfff4e0),fill(max(mo,-(m.y-.3)),.02)*front); }
  else c=mix(c,HX(0xfff4e0),fill(max(mo+.03,-(m.y-.12)+.18 ),.02)*front*step(-.08,m.y));
  return c;}
bool tungMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<19.5||id>22.5) return false;
  vec3 q=transpose(TR_)*(p-TO_)/TS_; grp=4.;
  if(id<20.5){
    float grain=fbm(vec3(atan(q.x,q.z)*6.,q.y*.5,0.)*vec3(3.,1.,1.));
    alb=mix(HX(0x8a5428),HX(0xc98a4f),grain); alb=mix(alb,HX(0x5a3216),smoothstep(.62,.7,fbm(vec3(atan(q.x,q.z)*14.,q.y*.25,3.))));
    vec3 ln=transpose(TR_)*n;
    if(ln.y>.7 && q.y>2.7){ float rr=length(q.xz); alb=mix(HX(0xe8c08a),HX(0xb07a40),.5+.5*sin(rr*14.)); }
    alb=tungFace(q,alb); detail=.97; spec=.15; }
  else if(id<21.5){ alb=HX(0xc98a4f); detail=.65; spec=.1; }
  else { alb=mix(HX(0xe0b070),HX(0xa86a30),.5+.5*sin(dot(q,vec3(3.))*2.)); detail=.65; spec=.3; }
  return true;}

// ---------- giant toilet boss (a big shouting head popping out of a toilet) ----------
vec3 BO_=vec3(0.,-100.,0.); mat3 BR_=mat3(1.); float BS_=1.3; mat3 BHR=mat3(1.); vec3 BHC=vec3(0.,7.9,1.7); float BHS=1.2;
const vec3 BHRAD=vec3(2.0,2.45,2.05);
float BOSS_MOUTH=1.; float BOSS_LOOK=0.; float BOSS_SCARED=0.;
float sdBossHead(vec3 h){
  float d=sdEllipsoid(h,BHRAD);
  d=smin(d,sdEllipsoid(h-vec3(0.,-.05,1.95),vec3(.34,.5,.42)),.25);                 // nose
  d=smin(d,sdEllipsoid(vec3(abs(h.x),h.y,h.z)-vec3(1.95,.05,-.15),vec3(.3,.58,.42)),.15); // ears
  d=smin(d,sdEllipsoid(h-vec3(0.,-1.55,.9),vec3(1.35,.9,1.1)),.6);                  // jaw
  // brow ridge
  d=smin(d,sdEllipsoid(h-vec3(0.,.62,1.55),vec3(1.35,.32,.4)),.3);
  return d;}
vec2 mapBoss(vec3 p){
  vec3 q=transpose(BR_)*(p-BO_)/BS_;
  float bd=length(q-vec3(0,5.5,0))-10.; if(bd>1.) return vec2(bd*BS_,0.);
  // porcelain
  float d=sdRoundCone(q,vec3(0,.5,.5),vec3(0,2.4,.8),1.25,.95);
  d=smin(d,sdCyl(q-vec3(0,.22,.5),.22,1.7,.12),.25);
  float bowl=sdEllipsoid(q-vec3(0,3.55,1.2),vec3(2.55,1.55,3.15));
  bowl=max(bowl,-sdEllipsoid(q-vec3(0,4.5,1.2),vec3(2.15,1.5,2.75)));
  bowl=max(bowl,q.y-4.55);
  d=smin(d,bowl,.22);
  // tank + tank lid
  float tank=sdBox(q-vec3(0,5.6,-2.55),vec3(2.5,2.3,.95),.35);
  tank=min(tank,sdBox(q-vec3(0,8.0,-2.55),vec3(2.75,.2,1.15),.12));
  d=min(d,tank);
  vec2 r=vec2(d,60.);
  // seat ring + raised lid
  vec2 sq=q.xz-vec2(0,1.2); float re=(length(sq/vec2(2.45,3.0))-1.)*2.45;
  vec2 w=vec2(abs(re+.35)-.42, abs(q.y-4.7)-.13); float seat=length(max(w,0.))+min(max(w.x,w.y),0.)-.1;
  vec3 lq=rotX(.2)*(q-vec3(0,6.8,-1.4)); float lid=sdEllipsoid(lq,vec3(2.45,2.95,.22));
  r=U(r,vec2(min(seat,lid),61.));
  // flush handle
  r=U(r,vec2(sdCapsule(q,vec3(-2.6,7.3,-1.7),vec3(-3.2,7.2,-1.5),.12),64.));
  // neck + head
  vec3 h=transpose(BHR)*(q-BHC)/BHS;
  float hd=sdBossHead(h)*BHS;
  hd=smin(hd,sdCapsule(q,vec3(0,3.8,1.3),BHC-BHR*vec3(0,1.6,.2)*BHS,1.1),.5);
  r=U(r,vec2(hd,62.));
  r.x*=BS_; return r;}
vec3 bossFace(vec3 h, vec3 c){
  vec3 ink=HX(0x1a0d0a);
  float u=atan(h.x,h.z)*1.15, v=h.y/BHRAD.y; vec2 uv=vec2(u,v);
  float front=smoothstep(1.35,1.0,abs(atan(h.x,h.z)));
  // furrowed forehead
  for(int i=0;i<3;i++){ float fi=float(i); float y=.58+fi*.09; float wr=abs(v-y-.05*cos(u*3.))-.007;
    c=mix(c,c*.7,fill(wr,.012)*front*smoothstep(.5,.15,abs(u))); }
  // anger vein mark on the temple
  if(BOSS_SCARED<.5){ vec2 a=uv-vec2(.5,.66); a=abs(a); float vm=min(sd2Seg(a,vec2(.03,.1),vec2(.03,.03)),sd2Seg(a,vec2(.03,.03),vec2(.1,.03)))-.022;
    c=mix(c,HX(0xd8202a),fill(vm,.008)*front); }
  else { vec2 d=uv-vec2(.62,.42); float drop=max(length(d)-.07,dot(d,normalize(vec2(-.5,1.)))*0.+0.)*1.; drop=min(drop,sd2Seg(uv,vec2(.62,.45),vec2(.6,.6))-.035);
    c=mix(c,HX(0x9fe0ff),fill(drop,.01)*front); c=mix(c,vec3(1.),fill(length(uv-vec2(.6,.44))-.018,.006)*front); }
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 q=vec2(uv.x*sg,uv.y);
    c=mix(c,c*vec3(.78,.6,.58),fill(sd2Ell(q,vec2(.36,.2),vec2(.29,.18)),.08)*front*.75);   // dark sockets
    float eye=sd2Ell(q,vec2(.36,.18),mix(vec2(.22,.13),vec2(.21,.17),BOSS_SCARED));
    float cut=dot(q-vec2(.36,.2),normalize(vec2(-.55,-1.)));
    float ey=BOSS_SCARED>.5?eye:max(eye,-cut);
    c=mix(c,ink,fill(ey-.028,.01)*front);
    c=mix(c,HX(0xfff8ee),fill(ey,.01)*front);
    vec2 pc=vec2(sg*.36+BOSS_LOOK,.14);
    c=mix(c,ink,fill(length((uv-pc)/vec2(1.,1.15))-mix(.062,.045,BOSS_SCARED),.01)*front*fill(ey,.01));
    c=mix(c,HX(0xffffff),fill(length(uv-pc-vec2(-.02,.025))-.017,.006)*front*fill(ey,.01));
    // red veins in the eye white
    c=mix(c,HX(0xe04040),fill(abs(q.y-.15-.03*sin(q.x*40.))-.004,.004)*front*fill(ey+.03,.01)*step(.47,q.x)*.8);
    // thick angry brows, low over the eyes
    vec2 b0=BOSS_SCARED>.5?vec2(.66,.36):vec2(.68,.44), b1=BOSS_SCARED>.5?vec2(.12,.5):vec2(.09,.24);
    float brow=sd2Seg(q,b0,b1)-mix(.04,.07,clamp(dot(q-b0,b1-b0)/dot(b1-b0,b1-b0),0.,1.));
    c=mix(c,HX(0x2a1810),fill(brow,.012)*front);
    c=mix(c,HX(0xe0605a),fill(sd2Ell(q,vec2(.52,-.12),vec2(.16,.08)),.08)*front*.45);
  }
  // huge shouting mouth
  vec2 m=uv-vec2(0.,-.5);
  float mo=sd2Ell(m,vec2(0.),vec2(.44*BOSS_MOUTH+.12,.26*BOSS_MOUTH+.04));
  c=mix(c,HX(0x9a4a44),fill(mo-.045,.02)*front);
  c=mix(c,ink,fill(mo-.02,.01)*front);
  c=mix(c,HX(0x3a060c),fill(mo,.01)*front);
  c=mix(c,HX(0xd8485a),fill(sd2Ell(m,vec2(0.,-.2),vec2(.3,.1)),.02)*front*fill(mo,.01));        // tongue
  float tl=abs(fract(m.x*8.+.5)-.5);
  vec3 tc=mix(HX(0xfff6e2),HX(0xb8a890),smoothstep(.4,.5,tl));
  c=mix(c,tc,fill(max(mo+.012,-(m.y-.14)),.01)*front);                                           // top teeth
  return c;}
bool bossMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<59.5||id>64.5) return false;
  vec3 q=transpose(BR_)*(p-BO_)/BS_; grp=5.;
  if(id<60.5){ alb=HX(0xf2f5fa)*mix(.93,1.03,fbm(q*2.)); spec=1.1; detail=.55;
    if(q.y>3.9&&q.y<4.6&&length((q.xz-vec2(0,1.2))/vec2(2.2,2.8))<1.) alb=HX(0x7fb8d8); }
  else if(id<61.5){ alb=HX(0xe6ebf2); spec=.9; detail=.6; }
  else if(id<62.5){ vec3 h=transpose(BHR)*(q-BHC)/BHS; alb=HX(0xf2c4a4)*mix(.92,1.04,fbm(h*3.));
    alb=mix(alb,HX(0xe0a088),smoothstep(-1.2,-2.4,h.y)*.5);
    if(length(h)<3.2) alb=bossFace(h,alb); spec=.55; detail=.97; grp=6.; }
  else { alb=HX(0xc8ccd4); spec=1.5; detail=.6; }
  return true;}

// ---------- giant Cameraman boss (suit + CCTV camera head), blocky like a Roblox rig ----------
vec3 cTO=vec3(0.,-100.,0.); mat3 cTR=mat3(1.); vec3 cHO; mat3 cHR; vec3 cShL,cShR,cHaL,cHaR,cHipL,cHipR,cFtL,cFtR; float CMS=1.7; float TITAN=0.;
void camRig(vec3 base, float s, vec3 torsoEul, vec3 headEul, vec3 armL, vec3 armR, vec3 legL, vec3 legR){
  CMS=s; cTO=base+vec3(0.,3.0,0.)*s; cTR=eulD(torsoEul);
  vec3 neck=cTO+cTR*vec3(0,1.,0)*s; cHR=eulD(headEul); cHO=neck+cHR*vec3(0,.75,0)*s;
  cShL=cTO+cTR*vec3(-1.5,.62,0.)*s; cShR=cTO+cTR*vec3(1.5,.62,0.)*s;
  cHaL=cShL+cTR*normalize(armL)*1.95*s; cHaR=cShR+cTR*normalize(armR)*1.95*s;
  cHipL=cTO+cTR*vec3(-.5,-1.,0.)*s; cHipR=cTO+cTR*vec3(.5,-1.,0.)*s;
  cFtL=cHipL+cTR*normalize(legL)*1.95*s; cFtR=cHipR+cTR*normalize(legR)*1.95*s;
}
float sdCamHead(vec3 h){ // camera body, lens barrel, sun hood, mount
  float d=sdBox(h,vec3(.78,.62,1.05),.14);
  d=min(d,sdBox(h-vec3(0.,.72,.25),vec3(.88,.08,1.25),.04));                       // sun hood
  vec3 lq=h-vec3(0.,-.02,1.15); d=min(d,sdCyl(lq.xzy,.28,.5,.06));                    // lens barrel (along z)
  d=min(d,sdCyl((h-vec3(0.,-.85,-.1)),.3,.22,.05));                                  // mount
  return d;}
vec2 mapCam(vec3 p){
  float s=CMS; if(length(p-cTO)>9.5*s) return vec2(length(p-cTO)-8.*s,0.);
  vec2 r=vec2(1e9,0.);
  vec3 lt=loc(p,cTO,cTR)/s;
  r=U(r,vec2(sdBox(lt,vec3(1.,1.,.5),.1)*s,70.));
  vec3 lh=loc(p,cHO,cHR)/s;
  float hd=sdCamHead(lh)*s; float glass=sdSphere(lh-vec3(0.,-.02,1.52),.38)*s; glass=max(glass,-(lh.z-1.6)*s);
  r=U(r,vec2(hd,73.)); r=U(r,vec2(max(glass,sdCyl((lh-vec3(0.,-.02,1.15)).xzy,.52,.42,.04)*s),74.));
  vec3 ref=cTR*vec3(1,0,0);
  float lw=TITAN>.5?.58:.5;
  r=U(r,vec2(limbBox(p,cShL,cHaL,ref,vec2(lw)*s,.5*s,.12*s),71.));
  r=U(r,vec2(limbBox(p,cShR,cHaR,ref,vec2(lw)*s,.5*s,.12*s),71.));
  r=U(r,vec2(limbBox(p,cHipL,cFtL,ref,vec2(lw)*s,0.,.12*s),72.));
  r=U(r,vec2(limbBox(p,cHipR,cFtR,ref,vec2(lw)*s,0.,.12*s),72.));
  if(TITAN>.5){
    float ar=sdBox(lt-vec3(0.,.2,.05),vec3(1.16,.86,.64),.16);                                   // chest armor
    ar=min(ar,sdBox(lt-vec3(0.,-.85,0.),vec3(1.08,.22,.6),.08));                                 // belt plate
    for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 c=lt-vec3(sg*1.62,.82,0.);                 // big pauldrons
      c.xy=mat2(cos(sg*.35),sin(sg*.35),-sin(sg*.35),cos(sg*.35))*c.xy; ar=min(ar,sdBox(c,vec3(.72,.42,.78),.2)); }
    // angry brow plates over the lens
    float br=1e9;
    for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 b=lh-vec3(sg*.36,.42,1.24);
      b.xy=mat2(cos(sg*.45),sin(sg*.45),-sin(sg*.45),cos(sg*.45))*b.xy; br=min(br,sdBox(b,vec3(.38,.09,.22),.03)); }
    r=U(r,vec2(ar*s,76.)); r=U(r,vec2(br*s,77.));
    r=U(r,vec2(sdCyl((lt-vec3(0.,.25,.66)).xzy,.08,.34,.04)*s,75.));                              // glowing chest core
  }
  return r;}
bool camMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<69.5||id>77.5) return false;
  float s=CMS; grp=6.; spec=.3; detail=.6;
  if(TITAN>.5){ vec3 lt=loc(p,cTO,cTR)/s;
    if(id>76.5){ alb=HX(0x15171c); emi=HX(0xff2a10)*.25; spec=1.2; detail=.95; return true; }
    if(id>74.5&&id<75.5){ float rr=length((lt-vec3(0.,.25,.7)).xy); alb=HX(0x9af0ff); emi=HX(0x30c8ff)*(4.-smoothstep(.0,.34,rr)*2.5); detail=.95; return true; }
    if(id>75.5||id<72.5){ vec3 q=p/s*2.2; float seam=min(abs(fract(q.x)-.5),min(abs(fract(q.y)-.5),abs(fract(q.z)-.5)));
      alb=mix(HX(0x4a5260),HX(0x9aa4b4),smoothstep(.35,.75,fbm(p/s*1.5)))*mix(.55,1.,smoothstep(.0,.06,seam));
      if(id>75.5) alb=mix(alb,HX(0xc4ccd8),.45);
      if(id<70.5){ if(lt.z>.55&&abs(lt.x)<.5&&lt.y<.7&&lt.y>-.3) alb*=.75; }
      float dh=min(length(p-cHaL),length(p-cHaR))/s; if(id>70.5&&id<71.5&&dh<.55) alb=HX(0x2a2e36);
      spec=1.6; detail=.7; return true; } }
  if(id<70.5){ vec3 lt=loc(p,cTO,cTR)/s; alb=HX(0x2b2f3a)*mix(.85,1.1,fbm(lt*4.));
    if(lt.z>.38){ float vx=abs(lt.x), vy=lt.y;
      if(vy>-.35 && vx<(vy+.35)*.45) alb=HX(0xf2f2f0);                                  // shirt V
      float tw=mix(.07,.17,clamp((.75-vy)/1.1,0.,1.)); if(vx<tw && vy>-.5 && vy<.82) alb=HX(0xd0202a); // red tie
      if(vy>.8 && vx<.16) alb=HX(0xd0202a);
      if(vx>.2&&vx<.26&&vy>-.3) alb*=.6; }                                               // lapel lines
    detail=.7; }
  else if(id<71.5){ alb=HX(0x2b2f3a); float dh=min(length(p-cHaL),length(p-cHaR))/s; if(dh<.5) alb=HX(0x1a1c22); if(dh>.5&&dh<.62) alb=HX(0xf2f2f0); detail=.6; }
  else if(id<72.5){ alb=HX(0x22252d); float df=min(length(p-cFtL),length(p-cFtR))/s; if(df<.45) alb=HX(0x101114); spec=.5; detail=.55; }
  else if(id<73.5){ vec3 lh=loc(p,cHO,cHR)/s; alb=(TITAN>.5?HX(0x6a7282):HX(0xdfe3ea))*mix(.9,1.03,fbm(lh*5.)); spec=.9;
    if(lh.y<-.7||abs(lh.z-1.2)<.5&&length(lh.xy-vec2(0.,-.02))<.56) alb=HX(0x26282e);
    if(lh.z<-1.08) alb=HX(0x9aa0aa);
    // little red REC light
    float rl=length(lh-vec3(.55,.42,1.12)); if(rl<.11){ alb=HX(0xff2020); emi=HX(0xff2020)*3.; }
    detail=.75; }
  else { vec3 lh=loc(p,cHO,cHR)/s; float rr=length(lh.xy-vec2(0.,-.02));
    alb=HX(0x0b0d12); spec=2.;
    emi=HX(0xff2a1a)*(1.-smoothstep(.05,.2,rr))*6.+HX(0xff5030)*(1.-smoothstep(.12,.36,rr))*.9;
    detail=.99; grp=6.; }
  return true;}

// ---------- Tralalero Tralala (blue shark on three sneakers) ----------
vec3 SO_=vec3(0.,-100.,0.); mat3 SR_=mat3(1.); float SS_=1.; vec3 sLeg[3]; vec3 sFoot[3];
float sdShark(vec3 q){
  float d=sdEllipsoid(q,vec3(2.3,.95,.9));
  d=smin(d,sdEllipsoid(q-vec3(1.75,.0,0.),vec3(1.05,.72,.74)),.4);                       // head
  d=smin(d,sdEllipsoid(q-vec3(-2.05,.12,0.),vec3(1.25,.42,.36)),.4);                     // tail stalk
  vec3 t=q-vec3(-3.15,.62,0.); t.xy=mat2(cos(.75),sin(.75),-sin(.75),cos(.75))*t.xy; d=smin(d,sdEllipsoid(t,vec3(.95,.3,.1)),.2);   // upper tail lobe
  t=q-vec3(-3.0,-.32,0.); t.xy=mat2(cos(-.65),sin(-.65),-sin(-.65),cos(-.65))*t.xy; d=smin(d,sdEllipsoid(t,vec3(.62,.24,.09)),.2); // lower lobe
  t=q-vec3(.0,1.0,0.); t.xy=mat2(cos(.6),sin(.6),-sin(.6),cos(.6))*t.xy; d=smin(d,sdEllipsoid(t,vec3(.62,.72,.11)),.25);         // dorsal fin
  vec3 f=vec3(q.x,q.y,abs(q.z))-vec3(.7,-.45,.85); f.yz=mat2(cos(.7),sin(.7),-sin(.7),cos(.7))*f.yz; d=smin(d,sdEllipsoid(f,vec3(.55,.1,.5)),.2); // side fins
  return d;}
vec2 mapShark(vec3 p){
  vec3 q=transpose(SR_)*(p-SO_)/SS_;
  float bd=length(q)-5.; if(bd>1.) return vec2(bd*SS_,0.);
  vec2 r=vec2(sdShark(q),80.);
  float l=1e9, sh=1e9;
  for(int i=0;i<3;i++){ l=min(l,sdCapsule(q,sLeg[i],sFoot[i]+vec3(0,.2,0),.2));
    vec3 s=q-sFoot[i]-vec3(.18,-.05,0.); sh=min(sh,sdBox(s,vec3(.42,.17,.24),.14)); }
  r=U(r,vec2(l,80.)); r=U(r,vec2(sh,81.));
  r.x*=SS_; return r;}
bool sharkMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<79.5||id>81.5) return false;
  vec3 q=transpose(SR_)*(p-SO_)/SS_; grp=3.;
  if(id<80.5){
    vec3 ln=transpose(SR_)*n;
    float belly=smoothstep(-.15,-.45,q.y+.12*sin(q.x*1.3));
    alb=mix(HX(0x3d8fd8),HX(0x2a6cc0),smoothstep(.3,.9,q.y)); alb=mix(alb,HX(0xf2f4f8),belly);
    if(q.y<-.75) alb=HX(0x3d8fd8);                                                     // legs
    // eye on each side of the head
    vec3 e=vec3(q.x,q.y,abs(q.z))-vec3(2.05,.28,.5); float ed=length(e.xy);
    if(abs(q.z)>.35){ if(ed<.2) alb=HX(0x101018); if(ed<.17&&ed>.0&&length(e.xy-vec2(.05,.06))<.06) alb=HX(0xffffff); if(ed>.2&&ed<.26) alb=mix(alb,HX(0xf8f8ff),.9); }
    // grin with teeth along the lower front
    float mx=q.x-1.6; float my=q.y+.32+.18*mx*mx*.6-.0;
    if(q.x>1.25 && abs(my)<.075 && abs(q.z)<.66){ alb=HX(0x2a0a10); float tl=fract(q.x*7.); if(my>.0&&tl<.5) alb=HX(0xffffff); if(my<.0&&tl>.5&&my>-.06) alb=HX(0xffffff); }
    // gills
    for(int i=0;i<3;i++){ float gx=1.0-float(i)*.18; if(abs(q.z)>.6&&abs(q.x-gx)<.025&&q.y>-.35&&q.y<.3) alb*=.6; }
    detail=.97; spec=.7; }
  else { alb=HX(0x2f6ff0); vec3 s=q-vec3(0.); float soleY=-.0;
    // white sole + toe cap, blue upper
    float yb=1e9; for(int i=0;i<3;i++){ vec3 ss=q-sFoot[i]-vec3(.18,-.05,0.); if(length(ss)<.8){ if(ss.y<-.07) alb=HX(0xf6f6f6); if(ss.x>.38) alb=HX(0xf6f6f6); if(abs(ss.z)<.1&&ss.y>.08&&ss.x>-.1&&ss.x<.3) alb=HX(0xffffff); } }
    detail=.8; spec=.5; }
  return true;}

// ---------- patterned eggs sitting in twig nests ----------
vec3 EGP[3]; float EGS[3]; int EGPAT[3]; mat3 EGM[3]; int NEGGS=0; float NEST_ON[3];
float sdEggShape(vec3 q){ q.xz*=1.+.16*q.y; return sdEllipsoid(q,vec3(1.,1.3,1.))*.88; }
float sdNest(vec3 q){
  float a=atan(q.z,q.x);
  vec2 t=vec2(length(q.xz)-1.18,(q.y+1.0)*1.45); float d=(length(t)-.5)/1.45;
  d+=.035*sin(a*21.+q.y*9.)*sin(a*13.-q.y*14.);
  d=min(d,sdCyl(q-vec3(0.,-1.17,0.),.12,1.15,.08));
  for(int i=0;i<7;i++){ float fi=float(i); float b=fi*.9+.3; vec3 c0=vec3(cos(b)*1.35,-.95+.25*fract(fi*.37),sin(b)*1.35);
    vec3 c1=c0+vec3(cos(b+.5+fract(fi*.61)),.25*fract(fi*.53)-.05,sin(b+.5+fract(fi*.61)))*.8; d=min(d,sdCapsule(q,c0,c1,.055)); }
  return d;}
vec2 mapEggs(vec3 p){
  vec2 r=vec2(1e9,0.);
  for(int i=0;i<3;i++){ if(i>=NEGGS) break;
    vec3 q=transpose(EGM[i])*(p-EGP[i])/EGS[i];
    float bd=length(q)-2.4; if(bd>.5){ r=U(r,vec2(bd*EGS[i],0.)); continue; }
    r=U(r,vec2(sdEggShape(q)*EGS[i],90.+float(i)));
    if(NEST_ON[i]>.5){
      vec3 nq=q; r=U(r,vec2(sdNest(nq)*EGS[i],93.));
      // two leaves tucked into the rim
      vec3 lq=nq-vec3(1.2,-.62,.75); lq.xy=mat2(.85,.52,-.52,.85)*lq.xy; float lf=sdEllipsoid(lq,vec3(.36,.05,.17));
      vec3 lq2=nq-vec3(-1.1,-.55,.9); lq2.xy=mat2(.85,-.52,.52,.85)*lq2.xy; lf=min(lf,sdEllipsoid(lq2,vec3(.32,.05,.15)));
      r=U(r,vec2(lf*EGS[i],94.)); }
  }
  return r;}
vec3 eggPattern(int pat, vec3 q, inout vec3 emi, inout float spec){
  float a=atan(q.z,q.x); float zz=(abs(fract(a*7./6.2832)*2.-1.)*2.-1.)*.12;
  float z=(q.y+zz)*2.4+.35; float bi=floor(z); float bf=fract(z);
  vec3 c;
  if(pat==0){ c=rainbow(bi*.145+.02); emi=c*.18; }
  else if(pat==1){ c=mod(bi,2.)<.5?HX(0x2fb6ff):HX(0x1440c8); if(mod(bi,3.)>1.5) c=HX(0xb8f2ff); emi=c*.12; }
  else if(pat==2){ c=mod(bi,2.)<.5?HX(0xff4fd0):HX(0x6a18c8); if(mod(bi,3.)>1.5) c=HX(0xffb8ee); emi=c*.12; }
  else if(pat==3){ float nb=fbm(q*2.2+5.); c=mix(HX(0x120a3a),HX(0x7a2be2),smoothstep(.35,.72,nb)); c=mix(c,HX(0xff4fd8),smoothstep(.62,.82,fbm(q*3.3+1.)));
    c=mix(c,HX(0x2ac8ff),smoothstep(.66,.85,fbm(q*2.7+11.))*.8);
    vec3 gq=q*9.; vec3 gf=fract(gq)-.5; float st=step(.8,h31(floor(gq)))*(1.-smoothstep(.05,.11,length(gf))); c=mix(c,vec3(1.),st); emi=c*.55+vec3(st*3.); spec=1.4; return c; }
  else { c=mix(HX(0xffc21a),HX(0xffe680),.5+.5*sin(z*3.14159)); emi=HX(0xffa800)*.35; spec=2.; return c; }
  c*=mix(1.,.55,smoothstep(.07,0.,bf)+smoothstep(.93,1.,bf));     // darker seams between bands
  spec=.5; return c;}
bool eggMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<89.5||id>94.5) return false;
  grp=3.;
  if(id<92.5){ int i=int(id-89.5); vec3 q=transpose(EGM[i])*(p-EGP[i])/EGS[i];
    alb=eggPattern(EGPAT[i],q,emi,spec); detail=.9; }
  else if(id<93.5){ int k=0; vec3 q=vec3(0.); float best=1e9;
    for(int i=0;i<3;i++){ if(i>=NEGGS) break; float dd=length(p-EGP[i]); if(dd<best){best=dd;k=i;} }
    q=transpose(EGM[k])*(p-EGP[k])/EGS[k]; float a=atan(q.z,q.x);
    float w1=sin(a*26.+q.y*11.), w2=sin(a*-19.+q.y*13.+1.7);
    float tw=smoothstep(.1,.7,max(w1,w2));
    alb=mix(HX(0x5a3416),HX(0xb27840),tw)*mix(.8,1.15,h31(floor(vec3(a*30.,q.y*20.,0.))));
    detail=.8; spec=.15; }
  else { alb=HX(0x5fbf3a); detail=.7; spec=.3; }
  return true;}

// ---------- sleeping samurai boss (blocky, sitting cross-legged, arms folded) ----------
vec3 sTO=vec3(0.,-100.,0.); mat3 sTR=mat3(1.); mat3 sYR=mat3(1.); vec3 sHO; mat3 sHR; vec3 sShL,sShR,sHaL,sHaR,sHipL,sHipR,sKnL,sKnR; float SMS=2.; vec3 kTip,kGuard,kEnd,sBub; float SBUBR=.3;
void samRig(vec3 base, float s, float yaw, vec3 torsoEul, vec3 headEul, vec3 armL, vec3 armR, vec3 legL, vec3 legR){
  SMS=s; sYR=rotY(yaw*PI/180.); sTR=sYR*eulD(torsoEul);
  vec3 hipC=base+vec3(0.,.55,0.)*s;
  sHipL=hipC+sYR*vec3(-.5,0.,0.)*s; sHipR=hipC+sYR*vec3(.5,0.,0.)*s;
  sTO=hipC+sTR*vec3(0.,1.,0.)*s;
  vec3 neck=sTO+sTR*vec3(0,1.,0)*s; sHR=sYR*eulD(headEul); sHO=neck+sHR*vec3(0,.72,0)*s;
  sShL=sTO+sTR*vec3(-1.5,.62,0.)*s; sShR=sTO+sTR*vec3(1.5,.62,0.)*s;
  sHaL=sShL+sTR*normalize(armL)*1.95*s; sHaR=sShR+sTR*normalize(armR)*1.95*s;
  sKnL=sHipL+sYR*normalize(legL)*2.1*s; sKnR=sHipR+sYR*normalize(legR)*2.1*s;
  // sheathed katana resting in the folded arms
  kTip=sTO+sTR*vec3(-1.9,-1.5,1.05)*s; kEnd=sTO+sTR*vec3(1.45,1.75,1.2)*s; kGuard=mix(kTip,kEnd,.7);
  sBub=sHO+sHR*vec3(.16,-.18,.78)*s; SBUBR=.34*s;
}
float sdKabuto(vec3 h){
  float dome=sdEllipsoid(h-vec3(0.,.5,0.),vec3(.86,.64,.86)); dome=max(dome,.36-h.y);
  float rim=length(vec2(length(h.xz)-.86,h.y-.42))-.07;
  float rr=.88+(.42-h.y)*.62;
  float shik=max(max(abs(length(h.xz)-rr)*.85-.05, abs(h.y-.12)-.3), h.z-.15);
  return min(min(dome,rim),shik);}
float sdHorns(vec3 h){
  vec3 c=h-vec3(0.,1.32,.88); float tor=length(vec2(length(c.xy)-.74,c.z))-.075;
  tor=max(tor, c.y+.12); 
  float disc=sdCyl((h-vec3(0.,.6,.9)).xzy,.04,.17,.03);
  return min(tor,disc);}
vec2 mapSamurai(vec3 p){
  float s=SMS; if(length(p-sTO)>8.*s) return vec2(length(p-sTO)-7.*s,0.);
  vec2 r=vec2(1e9,0.);
  vec3 lt=loc(p,sTO,sTR)/s;
  float tor=sdBox(lt,vec3(1.,1.,.5),.1); tor=min(tor,sdBox(lt-vec3(0.,.28,.04),vec3(1.08,.66,.58),.12));
  r=U(r,vec2(tor*s,100.));
  float kz=sdBox(lt-vec3(0.,-1.02,.0),vec3(1.22,.36,.7),.08);              // kusazuri skirt plates
  r=U(r,vec2(kz*s,101.));
  // sode shoulder plates
  for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 c=(i==0?sShL:sShR)+sTR*vec3(sg*.62,-.38,0.)*s;
    mat3 R=sTR*rotZ(sg*.32); r=U(r,vec2(sdBox(loc(p,c,R)/s,vec3(.16,.62,.66),.05)*s,101.)); }
  vec3 ref=sTR*vec3(1,0,0);
  r=U(r,vec2(limbBox(p,sShL,sHaL,ref,vec2(.5)*s,.5*s,.1*s),102.));
  r=U(r,vec2(limbBox(p,sShR,sHaR,ref,vec2(.5)*s,.5*s,.1*s),102.));
  vec3 yref=sYR*vec3(0,1,0);
  r=U(r,vec2(limbBox(p,sHipL,sKnL,yref,vec2(.62,.52)*s,.3*s,.12*s),103.));
  r=U(r,vec2(limbBox(p,sHipR,sKnR,yref,vec2(.62,.52)*s,.3*s,.12*s),103.));
  vec3 lh=loc(p,sHO,sHR)/s;
  r=U(r,vec2(sdBox(lh,vec3(.74,.7,.72),.24)*s,104.));
  r=U(r,vec2(sdKabuto(lh)*s,105.));
  r=U(r,vec2(sdHorns(lh)*s,106.));
  // katana: scabbard, guard, wrapped hilt
  vec3 ax=normalize(kEnd-kTip);
  r=U(r,vec2(sdCapsule(p,kTip,kGuard,.11*s),107.));
  r=U(r,vec2(sdCyl(transpose(frameAB(kGuard,kEnd,ref))*(p-kGuard),.035*s,.3*s,.02*s),106.));
  r=U(r,vec2(sdCapsule(p,kGuard+ax*.08*s,kEnd,.12*s),108.));
  // snot bubble
  r=U(r,vec2(sdSphere(p-sBub,SBUBR),109.));
  return r;}
vec3 samFace(vec3 lh, vec3 c){
  vec3 ink=HX(0x1a0d0a); if(lh.z<.6) return c; vec2 uv=lh.xy;
  for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec2 e=uv-vec2(sg*.3,.06);
    float arc=abs(length(e-vec2(0.,.1))-.15)-.028; arc=max(arc,e.y-.06);                 // closed sleepy eyes (u-shaped)
    c=mix(c,ink,fill(arc,.012));
    float brow=sd2Seg(uv,vec2(sg*.5,.36),vec2(sg*.13,.32))-.05; c=mix(c,ink,fill(brow,.012));
    // curly mustache
    vec2 m=uv-vec2(sg*.2,-.24); float mu=abs(length(m-vec2(sg*.02,.1))-.14)-.04; mu=max(mu,m.y-.04);
    c=mix(c,ink,fill(mu,.012));
    c=mix(c,HX(0xff8a7a),fill(sd2Ell(uv,vec2(sg*.45,-.12),vec2(.13,.07)),.06)*.45);
  }
  // little open snoring mouth + drool
  vec2 mo=uv-vec2(-.05,-.45); float o=sd2Ell(mo,vec2(0.),vec2(.1,.075));
  c=mix(c,ink,fill(o,.01)); c=mix(c,HX(0x9cdcff),fill(sd2Seg(uv,vec2(.04,-.48),vec2(.07,-.66))-.025,.01));
  return c;}
bool samMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<99.5||id>109.5) return false;
  float s=SMS; grp=6.; detail=.65; spec=.6;
  vec3 RED=HX(0xc8161e), NAVY=HX(0x1c2440), GOLD=HX(0xffc23a);
  if(id<100.5){ vec3 lt=loc(p,sTO,sTR)/s; alb=RED*mix(.88,1.06,fbm(lt*4.));
    float lace=abs(fract(lt.y*3.2)-.5); if(lace>.44) alb=NAVY;
    if(lace<.06&&fract(lt.x*3.)<.18) alb=GOLD;                                              // lacing knots
    if(lt.z>.5&&lt.y>.82) alb=NAVY; spec=1.; }
  else if(id<101.5){ vec3 lt=loc(p,sTO,sTR)/s; alb=RED*.92; float lace=abs(fract(p.y/s*4.)-.5); if(lace>.43) alb=NAVY; if(lace<.06) alb=mix(alb,GOLD,.6); spec=1.; }
  else if(id<102.5){ alb=RED*.95; float lace=abs(fract(p.y/s*3.6)-.5); if(lace>.43) alb=NAVY; float dh=min(length(p-sHaL),length(p-sHaR))/s; if(dh<.55) alb=HX(0x1b1d26); spec=1.; }
  else if(id<103.5){ alb=HX(0x2a2f45); float pl=abs(fract(dot(p/s,sYR*vec3(1.,0.,0.))*2.2)-.5); if(pl>.45) alb*=.6; }
  else if(id<104.5){ vec3 lh=loc(p,sHO,sHR)/s; alb=samFace(lh,HX(0xf1c27d)); detail=.98; spec=.35; }
  else if(id<105.5){ vec3 lh=loc(p,sHO,sHR)/s; alb=HX(0x1b1d26); if(lh.y<.42){ float lace=abs(fract(lh.y*6.)-.5); alb= lace>.42?RED:HX(0x232634); }
    if(abs(lh.y-.42)<.08) alb=GOLD; spec=1.3; detail=.75; }
  else if(id<106.5){ alb=GOLD; spec=2.; emi=GOLD*.25; detail=.85; }
  else if(id<107.5){ alb=HX(0x15151c); spec=1.4; detail=.75; }
  else if(id<108.5){ vec3 ax=normalize(kEnd-kTip); float t=dot(p-kGuard,ax)/s; vec3 rp=p-kGuard-ax*dot(p-kGuard,ax);
    float ang=atan(dot(rp,normalize(cross(ax,vec3(0,1,0)))),dot(rp,normalize(cross(ax,cross(ax,vec3(0,1,0))))));
    float dia=abs(fract(t*6.+ang*.32)-.5)+abs(fract(t*6.-ang*.32)-.5); alb=dia>.62?HX(0xd8202a):HX(0x15151c); detail=.85; }
  else { alb=HX(0xbfe8ff); spec=2.5; emi=HX(0x9ad8ff)*.45; detail=.95; grp=6.; }
  return true;}

// ---------- Grand Mushroom Mage (robe, long beard, giant spotted mushroom cap, glowing staff) ----------
vec3 MO_=vec3(0.,-100.,0.); mat3 MR_=mat3(1.); float MS_=1.3; mat3 MHR=mat3(1.); vec3 mHaL=vec3(-2.6,6.6,1.4), mHaR=vec3(2.4,4.6,1.2); vec3 mStA, mStB;
const vec3 MHC=vec3(0.,7.2,.3); const float MHS=1.3;
float sdMageHead(vec3 h){ // h relative to head center, in mage units
  float d=sdEllipsoid(h,vec3(1.22,1.2,1.1));
  d=smin(d,sdSphere(h-vec3(0.,-.14,1.13),.33),.15);                                       // round nose
  return d;}
float sdCap(vec3 h){
  vec3 c=h-vec3(0.,1.05,.0); c.yz=mat2(cos(.14),-sin(.14),sin(.14),cos(.14))*c.yz;
  float dome=sdEllipsoid(c,vec3(2.4,1.65,2.3)); dome=max(dome,-(c.y+.12));
  dome=smin(dome,sdEllipsoid(c-vec3(0.,-.08,0.),vec3(2.6,.34,2.5)),.25);                 // thick rim
  return dome;}
float sdBeard(vec3 h){
  float d=sdRoundCone(h,vec3(0.,-.6,.5),vec3(.05,-2.9,.85),1.02,.3);
  d=smin(d,sdEllipsoid(h-vec3(0.,-.38,.5),vec3(1.0,.55,.62)),.3);
  return d;}
vec2 mapMage(vec3 p){
  vec3 q=transpose(MR_)*(p-MO_)/MS_;
  float bd=length(q-vec3(0,5.5,0))-8.5; if(bd>1.) return vec2(bd*MS_,0.);
  vec2 r=vec2(1e9,0.);
  float robe=sdRoundCone(q,vec3(0.,1.1,0.),vec3(0.,5.4,0.),2.25,1.25);
  robe=smin(robe,sdCyl(q-vec3(0.,.35,0.),.35,2.35,.25),.4);
  r=U(r,vec2(robe,110.));
  r=U(r,vec2(length(vec2(length(q.xz)-1.72,(q.y-3.3)*1.4))/1.4-.16,111.));             // belt
  vec3 sL=vec3(-1.35,5.1,0.), sR=vec3(1.35,5.1,0.);
  float sl=sdRoundCone(q,sL,mHaL+normalize(sL-mHaL)*.55,.55,.72); sl=min(sl,sdRoundCone(q,sR,mHaR+normalize(sR-mHaR)*.55,.55,.72));
  r=U(r,vec2(sl,110.));
  r=U(r,vec2(min(sdSphere(q-mHaL,.42),sdSphere(q-mHaR,.42)),112.));
  vec3 h=transpose(MHR)*(q-MHC)/MHS;
  r=U(r,vec2(sdMageHead(h)*MHS,112.));
  r=U(r,vec2(sdBeard(h)*MHS,113.));
  r=U(r,vec2(sdEllipsoid(vec3(abs(h.x),h.y,h.z)-vec3(.46,.58,.95),vec3(.36,.13,.18))*MHS,113.));  // bushy brows
  r=U(r,vec2(sdCap(h)*MHS,114.));
  // staff with a glowing crystal
  float st=sdCapsule(q,mStA,mStB,.16); r=U(r,vec2(st,115.));
  vec3 cq=q-mStB-vec3(0.,.55,0.); float cr=sdEllipsoid(cq,vec3(.42,.62,.42)); r=U(r,vec2(cr,116.));
  r.x*=MS_; return r;}
vec3 mageFace(vec3 h, vec3 c){
  vec3 ink=HX(0x1a0d0a); if(h.z<.5) return c;
  vec2 uv=h.xy;
  for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec2 e=uv-vec2(sg*.42,.14);
    float eye=length(e/vec2(.25,.3))-1.;
    c=mix(c,ink,fill(eye*.25-.03,.01)); c=mix(c,HX(0xffffff),fill(eye*.25,.01));
    vec2 pc=vec2(sg*.42-.1,.1); c=mix(c,ink,fill(length(uv-pc)-.085,.01));
    c=mix(c,HX(0xffffff),fill(length(uv-pc-vec2(-.03,.035))-.026,.006)); }
  c=mix(c,HX(0xff8a7a),fill(sd2Ell(uv,vec2(-.55,-.22),vec2(.16,.08)),.07)*.5);
  c=mix(c,HX(0xff8a7a),fill(sd2Ell(uv,vec2(.55,-.22),vec2(.16,.08)),.07)*.5);
  return c;}
bool mageMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<109.5||id>116.5) return false;
  vec3 q=transpose(MR_)*(p-MO_)/MS_; vec3 h=transpose(MHR)*(q-MHC)/MHS; grp=6.; detail=.65; spec=.3;
  if(id<110.5){ alb=HX(0x3b2a9a)*mix(.85,1.1,fbm(q*2.)); 
    if(q.y<.95&&q.y>.45) alb=HX(0xffc23a);                                                   // gold hem
    float a=atan(q.x,q.z); vec2 su=vec2(a*2.2,q.y*.9); vec2 g=fract(su)-.5; vec2 gi=floor(su);
    float star=length(g)-.13*step(.55,h21(gi)); if(star<0.&&q.y>1.2&&q.y<4.9) alb=HX(0xffd76a);
    spec=.2; }
  else if(id<111.5){ alb=HX(0xffc23a); spec=1.6; }
  else if(id<112.5){ alb=HX(0xf6c9a6); if(length(h)<1.6) alb=mageFace(h,alb); detail=.98; spec=.35; }
  else if(id<113.5){ alb=HX(0xf4f1ea)*mix(.82,1.05,fbm(vec3(h.x*9.,h.y*1.5,h.z*9.))); emi=alb*.18; detail=.8; spec=.15;
    // open surprised mouth inside the beard
    if(h.z>.8&&length((h.xy-vec2(0.,-.62))/vec2(.19,.24))<1.) alb=HX(0x3a0a12); }
  else if(id<114.5){ vec3 c=(h-vec3(0.,1.05,.0))*1.25; c.yz=mat2(cos(.14),-sin(.14),sin(.14),cos(.14))*c.yz;
    alb=HX(0xe0262a)*mix(.82,1.08,fbm(c*1.5));
    if(c.y<.12) { alb=HX(0xf2e2c8)*mix(.7,1.,.5+.5*sin(atan(c.x,c.z)*60.)); }             // gills underneath
    else { vec3 g=c*1.15; vec3 gi=floor(g); vec3 gf=fract(g)-.5; vec3 o=vec3(h31(gi),h31(gi+7.),h31(gi+13.))-.5;
      float sp=length(gf-o*.4)-mix(.16,.3,h31(gi+3.)); if(sp<0.) alb=HX(0xfff6ea); }
    spec=.6; detail=.7; }
  else if(id<115.5){ alb=mix(HX(0x5a3416),HX(0x8a5a2e),.5+.5*sin(dot(q,vec3(4.,9.,4.)))); detail=.6; }
  else { alb=HX(0x7af0ff); emi=HX(0x40d8ff)*3.; spec=2.; detail=.9; }
  return true;}

// ---------- Titan Cameraman (series look: black suit + long coat, black camera head with cyan lens,
//            side cameras, antenna with red light, cyan chest core with claws, silver jet wings, big hammer) ----------
vec3 tcO=vec3(0.,-100.,0.); mat3 tcR=mat3(1.); float tcS=1.25; mat3 tcLean=mat3(1.); mat3 tcHead=mat3(1.);
const vec3 tcH=vec3(0.,4.2,0.); const vec3 tcHC=vec3(0.,9.05,.15); const float tcHS=1.35;
vec3 tcElL,tcHaL,tcElR,tcHaR,tcKnL,tcAnL,tcKnR,tcAnR,tcHamA,tcHamB; vec3 tcHamAx=vec3(1.,0.,0.);
vec3 tcUp(vec3 q){ return tcH+transpose(tcLean)*(q-tcH); }           // query point -> upper-body frame
float tcCoat(vec3 u){
  float y=u.y; float t=clamp((6.6-y)/4.,0.,1.);
  vec2 rr=vec2(mix(1.22,1.55,t),mix(.72,1.05,t));
  float e=(length(u.xz/rr)-1.)*min(rr.x,rr.y);
  float sh=max(abs(e)-.09, abs(y-4.5)-2.1);
  if(abs(u.x)<.4+.25*t) sh=max(sh,u.z-.1);                               // open front
  return sh;}
vec2 mapTitan(vec3 p){
  vec3 q=transpose(tcR)*(p-tcO)/tcS;
  float bd=length(q-vec3(0.,7.,0.))-9.5; if(bd>1.) return vec2(bd*tcS,0.);
  vec2 r=vec2(1e9,0.);
  // legs + boots (world-upright)
  float lg=min(sdCapsule(q,vec3(-.62,4.2,0.),tcKnL,.62),sdCapsule(q,tcKnL,tcAnL,.55));
  lg=min(lg,min(sdCapsule(q,vec3(.62,4.2,0.),tcKnR,.62),sdCapsule(q,tcKnR,tcAnR,.55)));
  r=U(r,vec2(lg,130.));
  float bt=min(sdBox(q-tcAnL-vec3(0.,-.25,.4),vec3(.5,.36,.8),.16),sdBox(q-tcAnR-vec3(0.,-.25,.4),vec3(.5,.36,.8),.16));
  r=U(r,vec2(bt,131.));
  // upper body
  vec3 u=tcUp(q);
  float tor=smin(sdBox(u-vec3(0.,6.45,0.),vec3(1.32,1.05,.7),.28),sdBox(u-vec3(0.,5.0,0.),vec3(1.08,.8,.62),.22),.4);
  tor=min(tor,tcCoat(u));
  tor=min(tor,sdCapsule(u,vec3(0.,7.3,0.),vec3(0.,7.9,.05),.42));                              // neck
  r=U(r,vec2(tor,130.));
  // arms
  vec3 sL=vec3(-1.6,7.05,0.), sR=vec3(1.6,7.05,0.);
  float ar=min(sdCapsule(u,sL,tcElL,.55),sdCapsule(u,tcElL,tcHaL,.5));
  ar=min(ar,min(sdCapsule(u,sR,tcElR,.55),sdCapsule(u,tcElR,tcHaR,.5)));
  r=U(r,vec2(ar,130.));
  r=U(r,vec2(min(sdSphere(u-tcHaL,.62),sdSphere(u-tcHaR,.62)),131.));                         // gloves
  // shoulder cameras
  float sc=1e9; for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 c=u-vec3(sg*1.4,7.75,.05);
    sc=min(sc,sdBox(c,vec3(.32,.26,.5),.06)); sc=min(sc,sdCyl((c-vec3(0.,0.,.55)).xzy,.12,.17,.03)); }
  r=U(r,vec2(sc,135.));
  // chest core: casing, glowing lens, three claws
  vec3 cc=u-vec3(0.,6.6,.72);
  r=U(r,vec2(sdCyl(cc.xzy,.14,.6,.05),133.));
  r=U(r,vec2(sdCyl((cc-vec3(0.,0.,.12)).xzy,.05,.4,.03),138.));
  float cl=1e9; for(int i=0;i<3;i++){ float a=float(i)*2.094+1.571; vec3 d=vec3(cos(a),sin(a),0.);
    cl=min(cl,sdCapsule(cc,d*.6,d*.86+vec3(0.,0.,.22),.07)); }
  r=U(r,vec2(cl,136.));
  // jetpack wings (4 silver blades) on the back
  float wg=1e9; for(int i=0;i<4;i++){ float sg=i<2?-1.:1.; float a=(mod(float(i),2.)<.5?.55:1.05)*sg;
    vec3 w=u-vec3(sg*.45,6.9,-.85); w.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*w.xy; wg=min(wg,sdBox(w-vec3(0.,1.25,0.),vec3(.2,1.35,.05),.04)); }
  r=U(r,vec2(wg,139.));
  // head (camera)
  vec3 h=tcHC+transpose(tcHead)*(u-tcHC)/tcHS;
  vec2 rh=vec2(1e9,0.);
  float hd=sdBox(h-tcHC,vec3(.95,.75,1.),.16);
  rh=U(rh,vec2(hd,132.));
  vec3 lq=h-tcHC-vec3(0.,-.05,1.05);
  rh=U(rh,vec2(max(sdCyl(lq.xzy,.22,.74,.05),-sdCyl((lq-vec3(0.,0.,.2)).xzy,.12,.58,.02)),133.));      // lens bezel
  rh=U(rh,vec2(sdCyl((lq-vec3(0.,0.,.05)).xzy,.06,.6,.02),134.));                                     // glowing screen
  float sd=1e9; for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 c=h-tcHC-vec3(sg*1.18,-.1,.15);
    sd=min(sd,sdBox(c,vec3(.24,.32,.6),.06)); sd=min(sd,sdCyl((c-vec3(0.,0.,.62)).xzy,.1,.16,.03)); }
  rh=U(rh,vec2(sd,135.));
  float ant=sdCapsule(h,tcHC+vec3(0.,.7,-.35),tcHC+vec3(0.,2.5,-.6),.05);
  for(int i=0;i<2;i++){ float sg=i==0?-1.:1.; vec3 c=h-tcHC-vec3(sg*.55,.88,-.15); c.xy=mat2(cos(sg*.5),sin(sg*.5),-sin(sg*.5),cos(sg*.5))*c.xy;
    ant=min(ant,sdBox(c,vec3(.36,.035,.3),.02)); }                                                  // ear screens / plates
  ant=min(ant,sdBox(h-tcHC-vec3(0.,1.05,-.75),vec3(.03,.3,.28),.02));                              // fin
  rh=U(rh,vec2(ant,136.));
  rh=U(rh,vec2(sdSphere(h-tcHC-vec3(0.,2.56,-.61),.13),137.));                                       // red light
  rh.x*=tcHS; r=U(r,rh);
  // mechanical hammer
  r=U(r,vec2(sdCapsule(u,tcHamA,tcHamB,.14),136.));
  vec3 hq=u-tcHamB; vec3 ax=tcHamAx; vec3 yy=normalize(tcHamB-tcHamA); vec3 zz=normalize(cross(ax,yy)); vec3 xx=cross(yy,zz);
  vec3 hl=vec3(dot(hq,xx),dot(hq,yy),dot(hq,zz));
  r=U(r,vec2(sdCyl(hl.yxz,1.35,.78,.12),139.));
  r=U(r,vec2(sdCyl((hl-vec3(1.35,0.,0.)).yxz,.22,.5,.05),136.));                                   // jet nozzle
  r=U(r,vec2(min(sdCyl((hl-vec3(.75,0.,0.)).yxz,.09,.82,.02),sdCyl((hl+vec3(.75,0.,0.)).yxz,.09,.82,.02)),140.));  // blue bands
  r.x*=tcS; return r;}
bool titanMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<129.5||id>140.5) return false;
  vec3 q=transpose(tcR)*(p-tcO)/tcS; grp=6.; detail=.7; spec=.6;
  if(id<130.5){ alb=HX(0x1c1e24)*mix(.85,1.15,fbm(q*2.)); spec=.5;
    vec3 u=tcUp(q); if(u.z>.3&&abs(u.x)<.34&&u.y>5.3&&u.y<7.2){ alb=HX(0x2c2f38); if(abs(u.x)<.06) alb=HX(0x0c0d10); } }   // vest + center line
  else if(id<131.5){ alb=HX(0x0e0f12); spec=.8; }
  else if(id<132.5){ alb=HX(0x17191e)*mix(.9,1.1,fbm(q*4.)); spec=1.6; detail=.85; }
  else if(id<133.5){ alb=HX(0x3a3e48); spec=1.8; detail=.9; }
  else if(id<134.5){ vec3 u=tcUp(q); vec3 h=tcHC+transpose(tcHead)*(u-tcHC)/tcHS; float rr=length((h-tcHC-vec3(0.,-.05,1.1)).xy);
    alb=HX(0x9cf6ff); emi=HX(0x2ad8ff)*(3.5-2.*smoothstep(.0,.6,rr))+HX(0xffffff)*(1.-smoothstep(.0,.12,rr))*3.; detail=.99; }
  else if(id<135.5){ alb=HX(0x2a2d34); spec=1.4; detail=.8; }
  else if(id<136.5){ alb=HX(0x101114); spec=1.2; detail=.75; }
  else if(id<137.5){ alb=HX(0xff3020); emi=HX(0xff2010)*5.; detail=.9; }
  else if(id<138.5){ alb=HX(0x9cf6ff); emi=HX(0x2ad8ff)*4.5; detail=.95; }
  else if(id<139.5){ alb=HX(0xc8d0dc)*mix(.85,1.08,fbm(q*3.)); spec=2.2; detail=.75; }
  else { alb=HX(0x2a8cff); emi=HX(0x2a8cff)*1.2; spec=1.5; detail=.8; }
  return true;}
