/* ═══ TOOLTIP GLOBAL ═══ */
const tipEl=document.getElementById('tooltip');
let tipTimer=null,tipCur=null;

function hideTip(){
  if(!tipEl) return;
  clearTimeout(tipTimer);
  tipTimer=null;
  tipEl.classList.remove('show','below');
  tipCur=null
}

document.addEventListener('mouseover',e=>{
  if(!tipEl) return;
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
  const container = document.getElementById('toasts');
  if(!container) return;

  const t=document.createElement('div');
  t.className='toast glass-deep '+type;
  t.innerHTML=`<span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${icons[type] || icons.info}</svg></span>
    <div><b>${title}</b><p>${msg}</p></div><button class="x">✕</button><span class="bar"></span>`;
  container.appendChild(t);
  const kill=()=>{t.classList.add('out');setTimeout(()=>t.remove(),220)};
  t.querySelector('.x').onclick=kill;
  setTimeout(kill,4000);
}

/* ══ MODALES ═══ */
function closeOv(ov){
  if(ov) ov.classList.remove('show');
}

/* ═══ MENÚ DE USUARIO ══ */
const avatarBtn=document.getElementById('avatarBtn'),
      userMenu=document.getElementById('userMenu');

if(avatarBtn && userMenu) {
  avatarBtn.addEventListener('click',e=>{
    e.stopPropagation();
    const notifMenu=document.getElementById('notifMenu');
    const btnNotif=document.getElementById('btnNotif');
    if(notifMenu) notifMenu.classList.remove('open');
    if(btnNotif) btnNotif.classList.remove('active');
    const open=userMenu.classList.toggle('open');
    avatarBtn.classList.toggle('active',open);
  });

  document.querySelectorAll('.u-item').forEach(item=>item.addEventListener('click',()=>{
    userMenu.classList.remove('open');
    avatarBtn.classList.remove('active');
    // Si el enlace ya tiene un href válido (como /avisos o /logout), dejamos que el navegador actúe.
    // Solo mostramos el toast si es un botón de prototipo sin acción.
    const a=item.dataset.action;
    if(a && a !== 'logout' && a !== 'notificaciones') {
      toast('info',item.textContent.trim(),'Vista del prototipo pendiente.');
    }
  }));
}

/* ═══ MENÚ DE NOTIFICACIONES (SOLO ABRIR/CERRAR) ═══ */
const btnNotif=document.getElementById('btnNotif'),
      notifMenu=document.getElementById('notifMenu');

if(btnNotif && notifMenu) {
  btnNotif.addEventListener('click',e=>{
    e.stopPropagation();
    if(userMenu) userMenu.classList.remove('open');
    if(avatarBtn) avatarBtn.classList.remove('active');
    notifMenu.classList.toggle('open');
    btnNotif.classList.toggle('active',notifMenu.classList.contains('open'));
  });
}

/* Cerrar menús al hacer clic fuera */
document.addEventListener('click',e=>{
  if(userMenu && avatarBtn && !e.target.closest('.user-wrap')){
    userMenu.classList.remove('open');
    avatarBtn.classList.remove('active')
  }
  if(notifMenu && btnNotif && !e.target.closest('.notif-wrap')){
    notifMenu.classList.remove('open');
    btnNotif.classList.remove('active')
  }
});