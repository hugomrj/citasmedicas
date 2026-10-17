/* ═══ SELECT CUSTOM ═══ */
function initFsel(id,onChange){
  const fsel=document.getElementById(id);
  const btn=fsel.querySelector('.fsel-btn');
  const lbl=btn.querySelector('.fsel-lbl');
  
  btn.addEventListener('click',e=>{
    e.stopPropagation();
    document.querySelectorAll('.fsel.open').forEach(x=>{if(x!==fsel)x.classList.remove('open')});
    fsel.classList.toggle('open');
  });
  
  fsel.querySelectorAll('.fsel-opt').forEach(opt=>opt.addEventListener('click',e=>{
    e.stopPropagation();
    fsel.querySelectorAll('.fsel-opt').forEach(o=>o.classList.remove('sel'));
    opt.classList.add('sel');
    lbl.textContent=opt.textContent;
    fsel.classList.remove('open');
    onChange(opt.dataset.val);
  }));
  
  return {
    set(val){
      const opt=fsel.querySelector(`.fsel-opt[data-val="${val}"]`);
      if(!opt)return;
      fsel.querySelectorAll('.fsel-opt').forEach(o=>o.classList.remove('sel'));
      opt.classList.add('sel');
      lbl.textContent=opt.textContent;
    }
  };
}

/* ═══ TOOLTIP GLOBAL ═══ */
const tipEl=document.getElementById('tooltip');
let tipTimer=null,tipCur=null;

function hideTip(){
  clearTimeout(tipTimer);
  tipTimer=null;
  tipEl.classList.remove('show','below');
  tipCur=null
}

document.addEventListener('mouseover',e=>{
  const t=e.target.closest('[data-tip]');
  if(!t||t===tipCur)return;
  clearTimeout(tipTimer);
  tipCur=t;
  tipTimer=setTimeout(()=>{
    if(tipCur!==t)return;
    tipEl.textContent=t.dataset.tip;
    const r=t.getBoundingClientRect();
    const below=r.top<64;
    tipEl.classList.toggle('below',below);
    tipEl.style.left=(r.left+r.width/2)+'px';
    tipEl.style.top=(below?r.bottom:r.top)+'px';
    tipEl.classList.add('show');
  },300);
});

document.addEventListener('mouseout',e=>{if(e.target.closest('[data-tip]'))hideTip()});
document.addEventListener('click',hideTip);
document.addEventListener('scroll',hideTip,true);

/* ═══ TOASTS ═══ */
const icons={
  ok:'<circle cx="12" cy="12" r="10"/><path d="m8.5 12.5 2.5 2.5 5-6"/>',
  err:'<circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/>',
  warn:'<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
  info:'<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>'
};

function toast(type,title,msg){
  const t=document.createElement('div');
  t.className='toast glass-deep '+type;
  t.innerHTML=`<span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${icons[type]}</svg></span>
    <div><b>${title}</b><p>${msg}</p></div><button class="x">✕</button><span class="bar"></span>`;
  document.getElementById('toasts').appendChild(t);
  const kill=()=>{t.classList.add('out');setTimeout(()=>t.remove(),220)};
  t.querySelector('.x').onclick=kill;
  setTimeout(kill,4000);
}

/* ══ MODALES ═══ */
function closeOv(ov){ov.classList.remove('show')}

/* ═══ MENÚ DE USUARIO ══ */
const avatarBtn=document.getElementById('avatarBtn'),
      userMenu=document.getElementById('userMenu');

avatarBtn.addEventListener('click',e=>{
  e.stopPropagation();
  const notifMenu=document.getElementById('notifMenu');
  const btnNotif=document.getElementById('btnNotif');
  notifMenu.classList.remove('open');
  btnNotif.classList.remove('active');
  const open=userMenu.classList.toggle('open');
  avatarBtn.classList.toggle('active',open);
});

document.querySelectorAll('.u-item').forEach(item=>item.addEventListener('click',()=>{
  userMenu.classList.remove('open');
  avatarBtn.classList.remove('active');
  const a=item.dataset.action;
  if(a==='logout')toast('warn','Sesión cerrada','En el sistema real aquí se destruye la sesión.');
  else if(a==='notificaciones'){
    const notifMenu=document.getElementById('notifMenu');
    const btnNotif=document.getElementById('btnNotif');
    notifMenu.classList.add('open');
    btnNotif.classList.add('active');
  }
  else toast('info',item.textContent.trim(),'Vista del prototipo pendiente.');
}));

/* ═══ MENÚ DE NOTIFICACIONES ═══ */
let notifs=[
  {title:'Backup completado',   msg:'El respaldo nocturno terminó sin errores.',            time:'hace 12 min', unread:true},
  {title:'Stock bajo',          msg:'3 productos de Bebidas están por agotarse.',           time:'hace 1 h',    unread:true},
  {title:'Nuevo usuario',       msg:'Carla Méndez se registró en el sistema.',              time:'hace 3 h',    unread:true},
  {title:'Factura emitida',     msg:'La factura #0248 se generó correctamente.',            time:'ayer',        unread:false},
];

const unreadCount=()=>notifs.filter(n=>n.unread).length;

const btnNotif=document.getElementById('btnNotif'),
      notifMenu=document.getElementById('notifMenu'),
      notifList=document.getElementById('notifList'),
      notifEmpty=document.getElementById('notifEmpty'),
      notifPing=document.getElementById('notifPing'),
      btnMarkAll=document.getElementById('btnMarkAll'),
      userBadge=document.getElementById('userBadge');

function syncNotifUI(){
  const u=unreadCount();
  notifPing.style.display=u?'block':'none';
  userBadge.textContent=u;
  userBadge.classList.toggle('hide',!u);
  btnMarkAll.style.display=u?'inline-block':'none';
  notifEmpty.classList.toggle('show',notifs.length===0);
  notifList.style.display=notifs.length?'block':'none';
  notifList.innerHTML=notifs.map((n,i)=>`
    <li class="n-item ${n.unread?'unread':'read'}" data-n="${i}">
      <span class="n-dot"></span>
      <div class="n-body"><b>${n.title}</b><p>${n.msg}</p><time>${n.time}</time></div>
    </li>`).join('');
}

syncNotifUI();

btnNotif.addEventListener('click',e=>{
  e.stopPropagation();
  userMenu.classList.remove('open');
  avatarBtn.classList.remove('active');
  notifMenu.classList.toggle('open');
  btnNotif.classList.toggle('active',notifMenu.classList.contains('open'));
});

notifList.addEventListener('click',e=>{
  const li=e.target.closest('[data-n]');
  if(!li)return;
  notifs[+li.dataset.n].unread=false;
  syncNotifUI();
});

btnMarkAll.addEventListener('click',()=>{
  notifs.forEach(n=>n.unread=false);
  syncNotifUI();
  toast('ok','Notificaciones','Todas fueron marcadas como leídas.');
});

/* Cerrar menús al hacer clic fuera */
document.addEventListener('click',e=>{
  if(!e.target.closest('.user-wrap')){
    userMenu.classList.remove('open');
    avatarBtn.classList.remove('active')
  }
  if(!e.target.closest('.notif-wrap')){
    notifMenu.classList.remove('open');
    btnNotif.classList.remove('active')
  }
  if(!e.target.closest('.fsel')){
    document.querySelectorAll('.fsel.open').forEach(x=>x.classList.remove('open'))
  }
});