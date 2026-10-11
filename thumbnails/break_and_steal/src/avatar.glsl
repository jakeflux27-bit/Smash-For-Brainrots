// ===== custom Roblox avatar (classic cylinder head, hoodie, hair, sneakers) =====
vec3 tO; mat3 tR; vec3 hO; mat3 hR; vec3 shL,shR,haL,haR,hipL,hipR,ftL,ftR; vec3 pkA,pkB; mat3 pkR;
int FACE=0;           // 0 grin, 1 wow, 2 determined, 3 sneaky smirk
int PICK_STYLE=0;     // 0 solid, 1 rainbow, 2 galaxy
vec3 rainbow(float t){ t=fract(t); vec3 c=clamp(abs(fract(t+vec3(0.,2./3.,1./3.))*6.-3.)-1.,0.,1.); return C(mix(vec3(1.),c,.9)); }
vec3 HOODIE=vec3(0.); vec3 PANTS=vec3(0.); vec3 SKIN=vec3(0.); vec3 HAIR=vec3(0.); vec3 PICKC=vec3(0.);
float PICK_ON=1.; float PKS=1.;
void avatarColors(){ HOODIE=HX(0xff6a1f); PANTS=HX(0x2b3a66); SKIN=HX(0xf3c690); HAIR=HX(0x3a2214); PICKC=HX(0x35e0ff); }
// helper: place limbs from torso frame
void avatarRig(vec3 base, vec3 torsoEul, vec3 headEul, vec3 armL, vec3 armR, vec3 legL, vec3 legR){
  tO=base+vec3(0.,3.0,0.); tR=eulD(torsoEul);
  vec3 neck=tO+tR*vec3(0,1.,0); hR=eulD(headEul); hO=neck+hR*vec3(0,.66,0);
  shL=tO+tR*vec3(-1.5,.62,0.); shR=tO+tR*vec3(1.5,.62,0.);
  haL=shL+tR*normalize(armL)*1.95; haR=shR+tR*normalize(armR)*1.95;
  hipL=tO+tR*vec3(-.5,-1.,0.); hipR=tO+tR*vec3(.5,-1.,0.);
  ftL=hipL+tR*normalize(legL)*1.95; ftR=hipR+tR*normalize(legR)*1.95;
}
float sdHead(vec3 q){ return sdCyl(q,.6,.66,.24); }       // classic Roblox head
float sdHair(vec3 q){
  float d=sdCyl(q-vec3(0,.2,-.06),.46,.71,.22);
  d=max(d,-(sdBox(q-vec3(0,-.25,.55),vec3(.8,.42,.4),.05)));   // open face
  d=max(d,-(q.y+.05-.35*smoothstep(.2,.7,-q.z))); return d; }
float pickHeadSD(vec3 p){
  vec3 q=transpose(pkR)*(p-pkB)/PKS; q.z*=1.5; float d=1e9; vec3 prev;
  for(int i=0;i<=10;i++){ float t=float(i)/10.*2.-1.; float a=t*1.05; vec3 c=vec3(sin(a)*1.45,-(1.-cos(a))*1.2,0.);
    if(i>0){ float rr=mix(.28,.04,pow(abs(t),1.2)); d=smin(d,sdCapsule(q,prev,c,rr),.1);} prev=c; }
  d=smin(d,sdBox(q,vec3(.27,.3,.27),.06),.08); return d/1.5*PKS; }
vec2 mapAvatar(vec3 p){
  vec2 r=vec2(1e9,0.);
  if(length(p-tO)>9.) return vec2(length(p-tO)-7.,0.);
  vec3 lt=loc(p,tO,tR);
  r=U(r,vec2(sdBox(lt,vec3(1.,1.,.5),.12),31.));
  r=U(r,vec2(sdBox(lt-vec3(0.,.78,-.52),vec3(.72,.26,.16),.12),31.));    // hood on the back
  vec3 lh=loc(p,hO,hR);
  r=U(r,vec2(sdHead(lh),30.));
  r=U(r,vec2(sdHair(lh),36.));
  vec3 ref=tR*vec3(1,0,0);
  r=U(r,vec2(limbBox(p,shL,haL,ref,vec2(.5),.5,.1),32.));
  r=U(r,vec2(limbBox(p,shR,haR,ref,vec2(.5),.5,.1),32.));
  r=U(r,vec2(limbBox(p,hipL,ftL,ref,vec2(.5),.0,.1),34.));
  r=U(r,vec2(limbBox(p,hipR,ftR,ref,vec2(.5),.0,.1),34.));
  if(PICK_ON>.5){ r=U(r,vec2(sdCapsule(p,pkA,pkB,.12),37.)); r=U(r,vec2(pickHeadSD(p),38.)); }
  return r;}
vec3 avatarFace(vec3 lh, vec3 base){
  float ang=atan(lh.x,lh.z); vec2 uv=vec2(ang*.75,lh.y); vec3 c=base; vec3 ink=HX(0x1a0f0c);
  float front=smoothstep(1.3,1.05,abs(ang));
  if(FACE==3){
    for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 e=uv-vec2(sg*.2,.08);
      float eye=max(length(e/vec2(.085,.075))-1., (e.y-.012+sg*.18*e.x)*12.);            // half-lidded, slanted lids
      c=mix(c,ink,fill(eye*.07,.01)*front);
      c=mix(c,HX(0xffffff),fill(length(e-vec2(-.03,-.025))-.017,.007)*front);
      float brow= sg<0. ? sd2Seg(uv,vec2(-.34,.3),vec2(-.1,.2))-.024 : sd2Seg(uv,vec2(.1,.25),vec2(.34,.33))-.024;
      c=mix(c,ink,fill(brow,.01)*front); }
    vec2 m=uv-vec2(.02,-.2);
    float top=m.y-(.02+.2*m.x+.5*m.x*m.x);                                            // lopsided upper lip
    float mo=max(length(m/vec2(.25,.14))-1., top*6.)*.12;
    c=mix(c,ink,fill(mo,.01)*front);
    c=mix(c,HX(0xfdfaf4),fill(max(mo+.012,-(top+.06)),.008)*front);                 // teeth
    c=mix(c,ink,fill(abs(top+.06)-.004,.004)*front*fill(mo+.012,.008));
    c=mix(c,HX(0xff8a7a),fill(length((uv-vec2(.33,-.1))/vec2(.09,.05))-1.,.3)*front*.3);
    c=mix(c,HX(0xff8a7a),fill(length((uv-vec2(-.33,-.1))/vec2(.09,.05))-1.,.3)*front*.3);
    return c; }
  for(int s=0;s<2;s++){ float sg=s==0?-1.:1.; vec2 e=uv-vec2(sg*.2,.1);
    if(FACE==1){ float eye=length(e/vec2(.075,.1))-1.; c=mix(c,ink,fill(eye*.08,.01)*front);
      c=mix(c,HX(0xffffff),fill(length(e-vec2(-.02,.035))-.025,.008)*front); }
    else { float eye=length(e/vec2(.06,.095))-1.; c=mix(c,ink,fill(eye*.06,.01)*front);
      c=mix(c,HX(0xffffff),fill(length(e-vec2(-.015,.035))-.02,.008)*front); }
    if(FACE==2){ float brow=sd2Seg(uv,vec2(sg*.33,.3),vec2(sg*.1,.24))-.025; c=mix(c,ink,fill(brow,.01)*front); }
    else { float brow=sd2Seg(uv,vec2(sg*.3,.27),vec2(sg*.12,.29))-.02; c=mix(c,ink,fill(brow,.01)*front); } }
  vec2 m=uv-vec2(0.,-.2);
  if(FACE==1){ float mo=length(m/vec2(.09,.12))-1.; c=mix(c,ink,fill(mo*.09,.01)*front); c=mix(c,HX(0xc8323c),fill((mo+.35)*.09,.01)*front); }
  else { float sm=max(length(m/vec2(.22,.13))-1., m.y)*.13; c=mix(c,ink,fill(sm,.01)*front); c=mix(c,HX(0xb0283a),fill(sm+.02,.01)*front*step(m.y,-.04)); }
  c=mix(c,HX(0xff8a7a),fill(length((uv-vec2(.33,-.1))/vec2(.09,.05))-1.,.3)*front*.35);
  c=mix(c,HX(0xff8a7a),fill(length((uv-vec2(-.33,-.1))/vec2(.09,.05))-1.,.3)*front*.35);
  return c;}
bool avatarMaterial(vec3 p, vec3 n, float id, inout vec3 alb, inout vec3 emi, inout float spec, inout float detail, inout float grp){
  if(id<29.5||id>38.5) return false;
  grp=1.; spec=.25; detail=.6;
  if(id<30.5){ vec3 lh=loc(p,hO,hR); alb=avatarFace(lh,SKIN); detail=1.; spec=.3; }
  else if(id<31.5){ vec3 lt=loc(p,tO,tR); alb=HOODIE*mix(.85,1.05,fbm(lt*3.));
    if(abs(lt.x)<.08&&lt.z>.4&&lt.y>.2) alb=HX(0xfff3e0);                 // drawstrings
    if(lt.z>.45&&lt.y<-.15&&lt.y>-.75&&abs(lt.x)<.65) alb*=.82;           // front pocket
    detail=.65; }
  else if(id<32.5){ alb=HOODIE*.95; vec3 q=p; float dh=min(length(p-haL),length(p-haR)); if(dh<.45) alb=SKIN; }
  else if(id<34.5){ float dl=min(length(p-ftL),length(p-ftR)); alb=PANTS; if(dl<.55) alb=mix(HX(0xffffff),HX(0x111111),step(.25,dl)*0.+step(dl,.18)); detail=.55; }
  else if(id<36.5){ alb=HAIR*mix(.8,1.25,fbm(p*6.)); detail=.8; spec=.4; }
  else if(id<37.5){ alb=HX(0x7a4420); detail=.75; grp=2.; }
  else { alb=PICKC; spec=1.2; emi=PICKC*.45; detail=.9; grp=2.;
    vec3 q=transpose(pkR)*(p-pkB)/PKS;
    if(PICK_STYLE==1){ alb=rainbow(q.x*.32+.55+q.y*.15); emi=alb*.55; if(abs(q.x)<.32&&abs(q.y)<.34){ alb=HX(0x7fdcff); emi=HX(0x40c8ff)*1.2; } }
    if(PICK_STYLE==2){ float nb=fbm(q*2.6+3.); alb=mix(HX(0x1a0d4a),HX(0x9a3cff),smoothstep(.35,.7,nb)); alb=mix(alb,HX(0xff5ad8),smoothstep(.6,.8,fbm(q*4.1+9.)));
      float st=step(.985,h31(floor(q*22.))); alb=mix(alb,vec3(1.),st); emi=alb*.6+st*2.; if(abs(q.x)<.32&&abs(q.y)<.34){ alb=HX(0xffd23a); emi=HX(0xffb000)*1.2; } }
  }
  return true;}
