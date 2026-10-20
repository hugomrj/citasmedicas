/* CitasMédicas — app.js
   Solo contiene lo que necesita JS real:
   - Desactivar autocompletado en formularios
   - Sidebar móvil / collapsible
   - Kebab menu en filas de tabla
   - Modal de eliminación genérico
   - Inicialización de fsel (usa initFsel de components.js si existe)
*/

document.addEventListener('DOMContentLoaded', function(){

  /* ═══ Desactivar autocompletado (memoria) en formularios ═══ */
  document.querySelectorAll('form').forEach(form => {
    form.setAttribute('autocomplete', 'off');
  });

  document.querySelectorAll('input, textarea').forEach(input => {
    // Chrome es rebelde con las contraseñas, así que usamos new-password
    if (input.type === 'password') {
      input.setAttribute('autocomplete', 'new-password');
    } else {
      input.setAttribute('autocomplete', 'off');
    }
  });

  /* ═══ Sidebar móvil / collapsible ═══ */
  const side     = document.getElementById('sidebar');
  const scrim    = document.getElementById('scrim');
  const btnSide  = document.getElementById('btnSide');
  const btnColl  = document.getElementById('btnCollapse');
  const mqMobile = matchMedia('(max-width:900px)');

  if (btnSide) {
    btnSide.addEventListener('click', () => {
      if (mqMobile.matches) {
        side.classList.add('open');
        scrim.classList.add('show');
      } else {
        document.body.classList.toggle('collapsed');
      }
    });
  }

  if (btnColl) {
    btnColl.addEventListener('click', () => document.body.classList.toggle('collapsed'));
  }

  if (scrim) {
    scrim.addEventListener('click', () => {
      side.classList.remove('open');
      scrim.classList.remove('show');
    });
  }

  mqMobile.addEventListener('change', () => {
    side.classList.remove('open');
    scrim.classList.remove('show');
  });

  /* ═══ Grupos del sidebar (acordeón) ═══ */
  document.querySelectorAll('[data-group]').forEach(btn => {
    btn.addEventListener('click', () => {
      const g = btn.closest('.group');
      const wasOpen = g.classList.contains('open');
      document.querySelectorAll('.group.open').forEach(x => x.classList.remove('open'));
      if (!wasOpen) g.classList.add('open');
    });
  });

  /* ═══ Kebab menu en filas de tabla ═══ */
  document.addEventListener('click', e => {
    const kb = e.target.closest('[data-kebab]');
    document.querySelectorAll('.dd.open').forEach(d => {
      if (!kb || d.previousElementSibling !== kb) d.classList.remove('open');
    });
    if (kb) kb.nextElementSibling.classList.toggle('open');

    if (!e.target.closest('.row-actions')) {
      document.querySelectorAll('.dd.open').forEach(d => d.classList.remove('open'));
    }
  });

  /* ═══ Modal de eliminación genérico ═══ */
  /* Uso: cualquier elemento con data-del-url="..." data-del-name="..." abre el modal */
  const ovDel  = document.getElementById('ovDel');
  const btnDel = document.getElementById('btnDel');
  let pendingDeleteUrl = null;

  document.addEventListener('click', e => {
    const dl = e.target.closest('[data-del-url]');
    if (!dl) return;
    pendingDeleteUrl = dl.dataset.delUrl;
    const nombre = dl.dataset.delName || 'este registro';
    document.getElementById('delSub').innerHTML =
      '¿Seguro que deseas eliminar <b style="color:var(--text)">' + nombre + '</b>? Esta acción no se puede deshacer.';
    ovDel.classList.add('show');
  });

  if (btnDel) {
    btnDel.addEventListener('click', () => {
      if (!pendingDeleteUrl) return;
      // Crear un form POST con _method=DELETE (para Sinatra con Rack::MethodOverride)
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = pendingDeleteUrl;
      const m = document.createElement('input');
      m.type = 'hidden'; m.name = '_method'; m.value = 'DELETE';
      form.appendChild(m);
      document.body.appendChild(form);
      form.submit();
    });
  }

  /* ═══ Filtros custom (initFsel de components.js) ═══ */
  if (typeof initFsel === 'function') {
    document.querySelectorAll('.fsel').forEach(f => {
      if (f.id && !f._initialized) {
        try {
          initFsel(f.id, () => { /* no-op por defecto; las páginas pueden override */ });
          f._initialized = true;
        } catch(err) { /* noop */ }
      }
    });
  }

});