// usage: node render.js scene.glsl out.png W H [pass]
const { chromium } = require('playwright'); const fs=require('fs'); const http=require('http'); const path=require('path');
const [scene,out,W,H,pass,tex]=process.argv.slice(2);
const srv=http.createServer((req,res)=>{const f=path.join(process.cwd(),decodeURIComponent(req.url.split('?')[0]));fs.readFile(f,(e,d)=>{if(e){res.writeHead(404);res.end();return;}res.end(d);});}).listen(0, async()=>{
  const port=srv.address().port;
  const b=await chromium.launch({args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist']});
  const p=await b.newPage(); p.on('console',m=>console.log('console:',m.text())); p.on('pageerror',e=>console.log('ERR',e.message));
  await p.goto(`http://127.0.0.1:${port}/harness.html?w=${W}&h=${H}&scene=${scene}&pass=${pass||0}&strips=${Math.max(1,Math.round(H/40))}&tex=${tex||''}`);
  const t=Date.now();
  try{ const d=await p.evaluate(()=>window.go()); fs.writeFileSync(out,Buffer.from(d.split(',')[1],'base64')); console.log('wrote',out,(Date.now()-t)/1000+'s'); }
  catch(e){ console.log('FAIL',e.message); }
  await b.close(); srv.close();
});
