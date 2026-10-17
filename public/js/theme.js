/* ═══ PERSISTENCIA Y MOTOR DE COLOR ═══ */
const PREFS_KEY='ui-prefs-v2',root=document.documentElement;
let curH=parseFloat(getComputedStyle(root).getPropertyValue('--h'))||160;
let curS=parseFloat(getComputedStyle(root).getPropertyValue('--s'))||84;

function persist(){
  try{
    localStorage.setItem(PREFS_KEY,JSON.stringify({theme:root.dataset.theme,h:curH,s:curS}))
  }catch(e){}
}

/* Motor de color */
function relLum(h,s,l){
  s/=100;l/=100;
  const k=n=>(n+h/30)%12,a=s*Math.min(l,1-l);
  const f=n=>{let x=l-a*Math.max(-1,Math.min(k(n)-3,Math.min(9-k(n),1)));return Math.max(0,Math.min(1,x))};
  const lin=c=>c<=0.04045?c/12.92:Math.pow((c+0.055)/1.055,2.4);
  return 0.2126*lin(f(0))+0.7152*lin(f(8))+0.0722*lin(f(4));
}

function inkSafeL(h,s){
  let lo=12,hi=64;
  while(hi-lo>0.5){
    const mid=(lo+hi)/2;
    if(relLum(h,s,mid)<=0.17)lo=mid;else hi=mid
  }
  return Math.round(lo);
}

function applyStrong(){
  const L=inkSafeL(curH,curS);
  root.style.setProperty('--acc-strong',`hsl(${curH} ${curS}% ${L}%)`);
  root.style.setProperty('--glow',`hsl(${curH} ${curS}% ${L}% / .38)`);
}

applyStrong();

/* ═══ CAMBIO DE TEMA ══ */
const icoSun=document.getElementById('icoSun'),icoMoon=document.getElementById('icoMoon');

function syncThemeIcons(){
  const l=root.dataset.theme==='light';
  icoSun.style.display=l?'block':'none';
  icoMoon.style.display=l?'none':'block'
}

syncThemeIcons();

document.getElementById('btnTheme').onclick=()=>{
  root.dataset.theme=root.dataset.theme==='dark'?'light':'dark';
  syncThemeIcons();
  persist();
};

matchMedia('(prefers-color-scheme: light)').addEventListener('change',e=>{
  let saved={};
  try{saved=JSON.parse(localStorage.getItem(PREFS_KEY)||'{}')}catch(err){}
  if(!saved.theme){
    root.dataset.theme=e.matches?'light':'dark';
    syncThemeIcons()
  }
});

/* ══ SWATCHES DE COLOR ═══ */
document.querySelectorAll('.swatch').forEach(sw=>{
  if(+sw.dataset.h===curH&&+sw.dataset.s===curS){
    document.querySelectorAll('.swatch').forEach(x=>x.classList.remove('active'));
    sw.classList.add('active')
  }
});

document.querySelectorAll('.swatch').forEach(sw=>sw.addEventListener('click',()=>{
  curH=+sw.dataset.h;
  curS=+sw.dataset.s;
  root.style.setProperty('--h',curH);
  root.style.setProperty('--s',curS+'%');
  document.querySelectorAll('.swatch').forEach(x=>x.classList.remove('active'));
  sw.classList.add('active');
  applyStrong();
  persist();
  if(typeof renderDash==='function' && !document.getElementById('viewDash').hidden) renderDash();
}));

/* ═══ COLOR PICKER ═══ */
document.getElementById('customColor').addEventListener('input',e=>{
  const hex=e.target.value;
  const r=parseInt(hex.slice(1,3),16)/255,
        g=parseInt(hex.slice(3,5),16)/255,
        b=parseInt(hex.slice(5,7),16)/255;
  const max=Math.max(r,g,b),min=Math.min(r,g,b),d=max-min;
  let h=0,s=0;
  if(d!==0){
    s=(max+min)/2>0.5 ? d/(2-max-min) : d/(max+min);
    if(max===r)h=(g-b)/d+(g<b?6:0);
    else if(max===g)h=(b-r)/d+2;
    else h=(r-g)/d+4;
    h=Math.round(h*60);
  }
  s=Math.round(s*100);
  if(s<10)return;
  curH=h;
  curS=Math.max(s,45);
  root.style.setProperty('--h',curH);
  root.style.setProperty('--s',curS+'%');
  document.querySelectorAll('.swatch').forEach(x=>x.classList.remove('active'));
  applyStrong();
  persist();
  if(typeof renderDash==='function' && !document.getElementById('viewDash').hidden) renderDash();
});