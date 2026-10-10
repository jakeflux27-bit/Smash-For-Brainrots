// ===== Verity thumbnail 2: THE VERITY FAMILY HATCHES =====
uniform sampler2D uTex0; uniform sampler2D uTex1; uniform sampler2D uTex2; uniform sampler2D uTex3; // verity falsity cruelty lovity
const float FAR=300.;
const float CAM_ROLL=.04;
const vec3 KEY_DIR=normalize(vec3(-.5,.75,.5));
const vec3 KEY_COL=vec3(1.8,1.55,1.2);
const vec3 SKY_COL=vec3(.13,.22,.45);
const vec3 GROUND_COL=vec3(.12,.16,.05);
const vec3 RIM_DIR=normalize(vec3(.6,.4,-.7));
const vec3 RIM_COL=vec3(1.0,1.15,1.5);
const vec3 PL_POS=vec3(0.,4.8,.6);
const vec3 PL_COL=vec3(6.5,4.2,1.2);
const float PL_FALL=.05;
const vec3 FOG_COL=vec3(.55,.72,.95);
const float FOG_START=30.; const float FOG_DENS=.006;
vec3 EGGC; const float ES=2.5; vec3 CAMP;
vec3 OC[4]; float OR[4]; mat3 OM[4];
void setup(){
  avatarColors(); FACE=1; PICK_ON=0.; HOODIE=HX(0x2f6bff); PANTS=HX(0x262b3a); SKIN=HX(0xd9a06a); HAIR=HX(0x1a120c);
  vec3 base=vec3(-4.6,0.,5.0);
  avatarRig(base, vec3(-10.,62.,4.), vec3(-24.,22.,6.), vec3(-.95,.25,.35), vec3(.85,.55,.45), vec3(-.05,-1.,.2), vec3(.08,-1.,-.25));
  EGGC=vec3(0.,1.3*ES,0.);
  OC[0]=vec3(.2,8.5,1.2);   OR[0]=1.75; OM[0]=eulD(vec3(6.,-8.,-6.));     // Verity (center, biggest)
  OC[1]=vec3(-3.3,6.9,1.6); OR[1]=1.2; OM[1]=eulD(vec3(0.,22.,14.));     // Falsity (left)
  OC[2]=vec3(3.4,6.6,1.4);  OR[2]=1.25;  OM[2]=eulD(vec3(4.,-30.,-12.));   // Cruelty (right)
  OC[3]=vec3(3.3,10.4,-.2); OR[3]=1.05;  OM[3]=eulD(vec3(10.,-18.,-16.));  // Lovity (upper right)
  CAMP=vec3(1.4,1.0,13.);
}
void camera(out vec3 ro, out vec3 ta, out float fov){ ro=CAMP; ta=vec3(-.3,6.3,0.); fov=2.05; }
float zig(float a){ return .5*abs(fract(a*8./6.2832)-.5)*2.+.15*sin(a*29.); }
float sdEggShell(vec3 p){
  vec3 q=(p-EGGC)/ES; q.xz*=1.+.16*q.y;
  float e=sdEllipsoid(q,vec3(1.,1.3,1.))*ES; float sh=abs(e+.12)-.12;
  float a=atan(p.z,p.x); return max(sh, p.y-(4.0+zig(a))); }
vec2 map(vec3 p){
  vec2 r=vec2(p.y-.3*fbm(p*vec3(.3,0,.3)),1.);
  for(int i=0;i<9;i++){ float fi=float(i); float sx=(fi<4.5?-1.:1.); vec3 c=vec3(sx*(13.+fi*2.6+4.*fract(fi*.7)),0.,-13.-8.*fract(fi*.53)-fi*1.6);
    float s=1.+.5*fract(fi*.37);
    r=U(r,vec2(sdBox(p-c-vec3(0,2.4*s,0),vec3(.6,2.4,.6)*s,.05),50.));
    float l=sdBox(p-c-vec3(0,6.*s,0),vec3(3.,2.,3.)*s,.2); l=min(l,sdBox(p-c-vec3(.6,8.6*s,-.4),vec3(2.,1.4,2.)*s,.15)); r=U(r,vec2(l,51.)); }
  for(int i=0;i<6;i++){ float fi=float(i); vec3 c=vec3(-20.+fi*8.,0.,-6.-7.*fract(fi*.61)); if(abs(c.x)<5.) c.x+=9.; float s=.8+.5*fract(fi*.43);
    vec3 q=(p-c-vec3(0,1.3*s,0))/s; q.xz*=1.+.16*q.y; r=U(r,vec2(sdEllipsoid(q,vec3(1.,1.3,1.))*s,40.+fract(fi*.31))); }
  r=U(r,vec2(sdEggShell(p),8.));
  for(int i=0;i<10;i++){ float fi=float(i); float a=fi*2.4; vec3 c=vec3(cos(a)*(2.2+1.4*fract(fi*.7)),4.4+1.6*fract(fi*.43),sin(a)*(1.6+fract(fi*.3))+1.6);
    mat3 R=eulD(vec3(fi*37.,fi*71.,fi*23.)); r=U(r,vec2(sdBox(loc(p,c,R),vec3(.4,.06,.3)*(1.-.04*fi),.03),9.)); }
  for(int i=0;i<4;i++) r=U(r,vec2(sdSphere(p-OC[i],OR[i]),60.+float(i)));
  r=U(r,mapAvatar(p));
  return r;}
vec3 background(vec3 rd){
  float y=rd.y;
  vec3 sky=mix(HX(0xbfe4ff),HX(0x2f6ff0),smoothstep(-.02,.3,y)); sky=mix(sky,HX(0x1636a8),smoothstep(.3,.9,y));
  vec2 uv=rd.xz/(y+.15)*1.2;
  float cd=fbm2(uv*.55+vec2(2.,6.))*.75+fbm2(uv*1.7)*.35; float cl=smoothstep(.56,.585,cd)*smoothstep(.0,.12,y);
  float sh=fbm2((uv+vec2(.25,-.3))*.55+vec2(2.,6.))*.75+fbm2((uv+vec2(.25,-.3))*1.7)*.35;
  vec3 cc=mix(HX(0xffffff),HX(0x9fb4e6),smoothstep(.56,.72,sh)*.8);
  return mix(sky,cc,cl)*1.05;}
vec4 faceTex(int i, vec2 uv){ if(i==0) return texture(uTex0,uv); if(i==1) return texture(uTex1,uv); if(i==2) return texture(uTex2,uv); return texture(uTex3,uv); }
void material(vec3 p, vec3 n, float id, out vec3 alb, out vec3 emi, out float spec, out float detail, out float grp){
  emi=vec3(0); spec=.15; detail=.25; grp=0.; RIMK=0.; FOGK=1.;
  if(avatarMaterial(p,n,id,alb,emi,spec,detail,grp)){ RIMK=1.; return; }
  if(id<1.5){ alb=mix(HX(0x2f7f22),HX(0x7cc23a),fbm(p*.4))*mix(.8,1.15,fbm(p*3.)); detail=.15; spec=.02; }
  else if(id<8.5){ vec3 q=(p-EGGC)/ES; alb=HX(0xe9dcc0); float sp=fbm(q*1.4+2.); alb=mix(alb,HX(0x1f8a86),smoothstep(.53,.55,sp));
    float rimT=1.-smoothstep(0.,.5,abs(p.y-4.0-zig(atan(p.z,p.x)))); emi=HX(0xffb020)*rimT*4.;
    if(dot(n,normalize(p-EGGC))<-.2){ alb=HX(0xfff0c0); emi+=HX(0xffc040)*2.; }
    float ve=voroEdge(q*3.); float cr=(1.-smoothstep(0.,.045,ve))*smoothstep(2.,3.9,p.y); alb=mix(alb,HX(0x3a1c08),cr); emi+=HX(0xffa020)*cr*4.;
    detail=.7+.25*cr; grp=3.; spec=.45; RIMK=.6; }
  else if(id<9.5){ alb=HX(0xe9dcc0); emi=HX(0xffb52e)*.7; detail=.6; grp=3.; }
  else if(id<41.5){ float k=fract(id); alb=k<.33?HX(0xf3ead2):(k<.66?HX(0xb48cff):HX(0x7cd6ff)); detail=.3; spec=.4; RIMK=.4; }
  else if(id<50.5){ alb=HX(0x6b4423); detail=.2; }
  else if(id<51.5){ alb=mix(HX(0x2f8a2a),HX(0x6cc23c),fbm(p*.9)); detail=.3; RIMK=.3; }
  else { int i=int(id-60.+.5); vec3 cols[4]=vec3[4](HX(0xffd414),HX(0x1946dc),HX(0xe11919),HX(0xf5a0c3));
    vec3 lp=transpose(OM[i])*(p-OC[i])/OR[i]; alb=cols[i]; float fa=0.;
    if(lp.z>0.){ vec2 uv=vec2(.5+lp.x*.44,.5-lp.y*.44-.02); vec4 f=faceTex(i,uv); fa=f.a*smoothstep(0.,.25,lp.z); alb=mix(alb,pow(f.rgb,vec3(2.2)),fa); }
    spec=.35; detail=.99; grp=5.; RIMK=.8*(1.-fa);
    vec3 v=normalize(CAMP-p); vec3 glowc=i==0?HX(0xffb000):(i==1?HX(0x4a8cff):(i==2?HX(0xff4020):HX(0xff8ac0)));
    emi=(glowc*pow(1.-abs(dot(n,v)),2.5)*1.6+cols[i]*.1)*(1.-fa); }
}
vec3 post(vec3 col, vec2 uv, vec3 rd){ col=aces(col*1.0); col*=1.-.25*dot(uv*.5,uv*.5); return col; }
