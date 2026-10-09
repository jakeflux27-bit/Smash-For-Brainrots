const { chromium } = require('playwright'); const path=require('path');
(async()=>{const [f,out,w,h]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:+w,height:+h}});
await p.goto('file://'+path.resolve(f));await p.waitForTimeout(500);await p.screenshot({path:out,omitBackground:true});await b.close();console.log('wrote',out);})();
