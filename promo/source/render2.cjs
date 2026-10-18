// usage: node render2.cjs <html> <outDir> <W> <H> (video | t1,t2,...)
const {chromium}=require('/opt/node-tools/node_modules/playwright');
const [,,html,out,W,H,mode]=process.argv;
(async()=>{
  const b=await chromium.launch();const pg=await b.newPage({viewport:{width:+W,height:+H}});
  await pg.goto('file://'+html,{waitUntil:'networkidle'});
  await pg.evaluate(()=>document.fonts.ready);
  console.log('font ok:',await pg.evaluate(()=>document.fonts.check('900 40px "Zen Maru Gothic"')));
  if(mode!=='video'){for(const t of mode.split(',').map(Number)){await pg.evaluate(t=>render(t),t);await pg.screenshot({path:`${out}/still_${t}.png`});}}
  else{const fps=30,n=Math.round(await pg.evaluate(()=>DURATION)*fps);for(let i=0;i<n;i++){await pg.evaluate(t=>render(t),i/fps);await pg.screenshot({path:`${out}/f${String(i).padStart(4,'0')}.png`});}}
  await b.close();
})();
