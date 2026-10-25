// static/app/js/vanilla-select.js

class VanillaSelect {
    constructor(selectElement) {
        this.select = selectElement;
        this.wrapper = null;
        this.control = null;
        this.dropdown = null;
        this.searchInput = null;
        this.optionsList = null;
        this.options = [];
        this.init();
    }

    init() {
        this.createDOM();
        this.populateOptions();
        this.bindEvents();
        this.select.classList.add('vanilla-select-original');
    }

    createDOM() {
        this.wrapper = document.createElement('div');
        this.wrapper.className = 'vanilla-select-wrapper';
        this.select.parentNode.insertBefore(this.wrapper, this.select);
        this.wrapper.appendChild(this.select);

        this.control = document.createElement('div');
        this.control.className = 'vs-control';
        
        // CAMBIO 1: Estructura más limpia. El span principal maneja el texto y la clase de placeholder.
        this.control.innerHTML = `
            <span class="vs-value vs-placeholder"></span>
            <span class="vs-arrow">▼</span>
        `;
        this.wrapper.appendChild(this.control);

        this.dropdown = document.createElement('div');
        this.dropdown.className = 'vs-dropdown';
        
        const searchWrapper = document.createElement('div');
        searchWrapper.className = 'vs-search';
        this.searchInput = document.createElement('input');
        this.searchInput.type = 'text';
        this.searchInput.placeholder = 'Buscar...';
        this.searchInput.setAttribute('autocomplete', 'off');
        searchWrapper.appendChild(this.searchInput);
        this.dropdown.appendChild(searchWrapper);

        this.optionsList = document.createElement('ul');
        this.optionsList.className = 'vs-options';
        this.dropdown.appendChild(this.optionsList);

        this.wrapper.appendChild(this.dropdown);
    }

    populateOptions() {
        const originalOptions = this.select.querySelectorAll('option');
        const valueSpan = this.control.querySelector('.vs-value');

        // CAMBIO 2: Leer el texto de la primera opción (si su valor es vacío) para usarlo como placeholder.
        if (originalOptions.length > 0 && originalOptions[0].value === "") {
            valueSpan.textContent = originalOptions[0].textContent;
        }

        originalOptions.forEach(opt => {
            const li = document.createElement('li');
            li.className = 'vs-option';
            li.dataset.value = opt.value;
            li.textContent = opt.textContent;
            
            // Si una opción viene seleccionada por defecto y NO está vacía
            if (opt.selected && opt.value !== "") {
                li.classList.add('is-selected');
                valueSpan.textContent = opt.textContent;
                valueSpan.classList.remove('vs-placeholder'); // Quitar gris
            } else if (opt.selected && opt.value === "") {
                // Si la opción seleccionada por defecto es la vacía, se marca visualmente
                li.classList.add('is-selected');
            }
            
            this.optionsList.appendChild(li);
            this.options.push(li);
        });
    }

    bindEvents() {
        this.control.addEventListener('click', (e) => {
            e.stopPropagation();
            this.toggleDropdown();
            if (this.isOpen()) {
                this.searchInput.focus();
                this.searchInput.select();
            }
        });

        this.searchInput.addEventListener('input', (e) => {
            this.filterOptions(e.target.value.toLowerCase());
        });

        this.dropdown.addEventListener('click', (e) => e.stopPropagation());

        this.optionsList.addEventListener('click', (e) => {
            const li = e.target.closest('.vs-option');
            if (li && !li.classList.contains('is-hidden')) {
                this.selectOption(li);
            }
        });

        document.addEventListener('click', () => this.closeDropdown());
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen()) {
                this.closeDropdown();
            }
        });
    }

    toggleDropdown() { this.wrapper.classList.toggle('is-open'); }
    isOpen() { return this.wrapper.classList.contains('is-open'); }

    closeDropdown() {
        this.wrapper.classList.remove('is-open');
        this.searchInput.value = '';
        this.filterOptions('');
    }

    filterOptions(query) {
        let hasVisible = false;
        this.options.forEach(li => {
            if (li.textContent.toLowerCase().includes(query)) {
                li.classList.remove('is-hidden');
                hasVisible = true;
            } else {
                li.classList.add('is-hidden');
            }
        });

        let noResults = this.dropdown.querySelector('.vs-no-results');
        if (!hasVisible && query) {
            if (!noResults) {
                noResults = document.createElement('div');
                noResults.className = 'vs-no-results';
                noResults.textContent = 'Sin resultados';
                this.dropdown.appendChild(noResults);
            }
            noResults.style.display = 'block';
        } else if (noResults) {
            noResults.style.display = 'none';
        }
    }

    selectOption(li) {
        this.options.forEach(opt => opt.classList.remove('is-selected'));
        li.classList.add('is-selected');
        
        const valueSpan = this.control.querySelector('.vs-value');
        valueSpan.textContent = li.textContent;

        // CAMBIO 3: Si el valor es vacío (ej. "Todos"), vuelve a ponerse gris. Si no, se quita el gris.
        if (li.dataset.value === "") {
            valueSpan.classList.add('vs-placeholder');
        } else {
            valueSpan.classList.remove('vs-placeholder');
        }

        this.select.value = li.dataset.value;
        this.select.dispatchEvent(new Event('change', { bubbles: true }));
        this.closeDropdown();
    }
}

// ==========================================================================
// 👇 MAGIA PARA HTMX
// ==========================================================================

function initVanillaSelects() {
    document.querySelectorAll('select.vanilla-select').forEach(select => {
        if (!select.dataset.vanillaInit) {
            select.dataset.vanillaInit = 'true';
            new VanillaSelect(select);
        }
    });
}

document.addEventListener('DOMContentLoaded', initVanillaSelects);

document.body.addEventListener('htmx:afterSwap', initVanillaSelects);