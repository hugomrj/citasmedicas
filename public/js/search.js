/* public/js/search.js */
document.addEventListener('DOMContentLoaded', function() {
  const searchOv = document.getElementById('searchOv');
  const searchInput = document.getElementById('searchInput');
  const searchResults = document.getElementById('searchResults');
  const btnSearch = document.getElementById('btnSearch');

  // Si no estamos en una página con el buscador, salimos silenciosamente
  if (!searchOv || !btnSearch) return;

  // Función para quitar tildes y pasar a minúsculas
  function normalizar(texto) {
    return texto.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  }

  // Extraemos los enlaces del menú lateral automáticamente
  let menuLinks = [];
  document.querySelectorAll('.sidebar .nav-item, .sidebar .sub-item').forEach(a => {
    const textEl = a.querySelector('span');
    if (textEl) {
      menuLinks.push({ label: textEl.textContent.trim(), url: a.getAttribute('href') });
    }
  });

  let selectedIndex = -1;
  let filteredLinks = [];

  function openSearch() {
    searchOv.classList.add('show');
    searchInput.value = '';
    searchInput.focus();
    renderResults('');
  }

  function closeSearch() {
    searchOv.classList.remove('show');
    selectedIndex = -1;
  }

  btnSearch.addEventListener('click', openSearch);
  
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      openSearch();
    }
    if (e.key === 'Escape' && searchOv.classList.contains('show')) {
      closeSearch();
    }
  });

  searchOv.addEventListener('click', (e) => {
    if (e.target === searchOv) closeSearch();
  });

  function renderResults(query) {
    // ACA USAMOS LA FUNCIÓN NORMALIZAR PARA AMBOS LADOS
    const queryNormalizada = normalizar(query);
    
    filteredLinks = menuLinks.filter(link => 
      normalizar(link.label).includes(queryNormalizada)
    );
    
    selectedIndex = -1;
    searchResults.innerHTML = '';

    if (filteredLinks.length === 0) {
      searchResults.innerHTML = '<li style="padding: 1rem; text-align: center; color: var(--text-2); font-size: 0.85rem;">No se encontraron resultados.</li>';
      return;
    }

    filteredLinks.forEach((link, index) => {
      const li = document.createElement('li');
      li.style.cssText = 'padding: 0.75rem 1.25rem; cursor: pointer; display: flex; align-items: center; gap: 0.75rem; color: var(--text); font-size: 0.9rem;';
      li.innerHTML = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="var(--text-2)" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg> ${link.label}`;
      
      li.addEventListener('mouseenter', () => setSelected(index));
      li.addEventListener('click', () => { window.location.href = link.url; });
      
      searchResults.appendChild(li);
    });
  }

  function setSelected(index) {
    const items = searchResults.querySelectorAll('li');
    items.forEach(item => item.style.background = 'transparent');
    selectedIndex = index;
    if (selectedIndex >= 0 && items[selectedIndex]) {
      items[selectedIndex].style.background = 'var(--hover)';
      items[selectedIndex].scrollIntoView({ block: 'nearest' });
    }
  }

  searchInput.addEventListener('input', (e) => renderResults(e.target.value));

  searchInput.addEventListener('keydown', (e) => {
    const items = searchResults.querySelectorAll('li');
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, items.length - 1);
      setSelected(selectedIndex);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
      setSelected(selectedIndex);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (selectedIndex >= 0 && filteredLinks[selectedIndex]) {
        window.location.href = filteredLinks[selectedIndex].url;
      }
    }
  });
});