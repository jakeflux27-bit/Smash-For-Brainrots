vec3 calcN(vec3 p){vec2 e=vec2(.0015,0);return normalize(vec3(map(p+e.xyy).x-map(p-e.xyy).x,map(p+e.yxy).x-map(p-e.yxy).x,map(p+e.yyx).x-map(p-e.yyx).x));}
float shadow(vec3 ro, vec3 rd, float tmax, float k){float r=1.,t=.02;for(int i=0;i<64;i++){float h=map(ro+rd*t).x;r=min(r,k*h/t);t+=clamp(h,.02,.4);if(r<.001||t>tmax)break;}return clamp(r,0.,1.);}
float ao(vec3 p, vec3 n){float o=0.,s=1.;for(int i=1;i<=5;i++){float h=.06*float(i);o+=(h-map(p+n*h).x)*s;s*=.75;}return clamp(1.-2.2*o,0.,1.);}
void main(){
  setup();
  vec2 fc=gl_FragCoord.xy; vec2 uv=(2.*fc-uRes)/uRes.y;
  vec3 ro,ta; float fov; camera(ro,ta,fov);
  vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0,1,0))), vv=cross(uu,ww);
  float cr=cos(CAM_ROLL),sr=sin(CAM_ROLL); vec2 ruv=vec2(cr*uv.x-sr*uv.y,sr*uv.x+cr*uv.y);
  vec3 rd=normalize(ruv.x*uu+ruv.y*vv+fov*ww);
  float t=0.; vec2 h=vec2(1e9,0.); bool hit=false;
  for(int i=0;i<260;i++){h=map(ro+rd*t); if(abs(h.x)<.0004*t){hit=true;break;} t+=h.x*.85; if(t>FAR)break;}
  vec3 col; float detail=.12, grp=0.;
  if(!hit){ col=background(rd); }
  else{
    vec3 p=ro+rd*t, n=calcN(p);
    vec3 alb, emi; float spec, rough;
    material(p,n,h.y,alb,emi,spec,detail,grp);
    float occ=ao(p,n);
    // key light
    float dif=clamp(dot(n,KEY_DIR),0.,1.); float sh=dif>0.?shadow(p+n*.01,KEY_DIR,30.,10.):0.;
    vec3 hv=normalize(KEY_DIR-rd); float sp=pow(clamp(dot(n,hv),0.,1.),40.)*spec;
    // fill from sky + bounce
    vec3 amb=mix(GROUND_COL,SKY_COL,.5+.5*n.y)*occ;
    // rim
    float rim=pow(1.-clamp(dot(n,-rd),0.,1.),3.)*clamp(dot(n,RIM_DIR)+.35,0.,1.);
    // point light (glow source)
    vec3 lp=PL_POS-p; float ld=length(lp); lp/=ld; float pdif=clamp(dot(n,lp)*.85+.15,0.,1.)/(1.+ld*ld*PL_FALL);
    float psh=shadow(p+n*.01,lp,ld-.3,8.);
    col = alb*(KEY_COL*dif*sh + amb + PL_COL*pdif*mix(.35,1.,psh)) + KEY_COL*sp*sh + RIM_COL*rim*occ*RIMK + emi;
    // atmospheric perspective
    col=mix(col,FOG_COL,(1.-exp(-max(t-FOG_START,0.)*FOG_DENS))*FOGK);
  }
  col=post(col,uv,rd);
  if(uPass==0) frag=vec4(pow(clamp(col,0.,1.),vec3(1./2.2)),1.);
  else frag=vec4(detail, clamp(t/FAR,0.,1.), grp/8., 1.);
}
