const fs=require('fs');
const {chromium}=require('/opt/node-tools/node_modules/playwright');
const [,,html,out,mode]=process.argv;
(async()=>{
  const b=await chromium.launch();const pg=await b.newPage({viewport:{width:1080,height:1920}});
  await pg.goto('file://'+html,{waitUntil:'networkidle'});
  await pg.evaluate(()=>document.fonts.ready);
  console.log('font ok:',await pg.evaluate(()=>document.fonts.check('900 40px "Zen Maru Gothic"')));
  const times=mode==='stills'?[4.7,5.2,5.6]:null;
  if(times){for(const t of times){await pg.evaluate(t=>render(t),t);await pg.screenshot({path:`${out}/still_${t}.png`});}}
  // 前回の書き出しのフレームが残っていると、短くしたときに ffmpeg が末尾へつなげてしまうため消す
  else{for(const f of fs.readdirSync(out))if(/^f\d{4}\.png$/.test(f))fs.unlinkSync(`${out}/${f}`);const fps=30,n=15*fps;for(let i=0;i<n;i++){await pg.evaluate(t=>render(t),i/fps);await pg.screenshot({path:`${out}/f${String(i).padStart(4,'0')}.png`});}}
  await b.close();
})();
