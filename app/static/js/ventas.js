document.addEventListener('DOMContentLoaded', function() {
    let carrito = [];
    
    // DOM Elements
    const productGrid = document.getElementById('productGrid');
    const searchInput = document.getElementById('searchInput');
    const categoryFilters = document.getElementById('categoryFilters');
    const ticketItems = document.getElementById('ticketItems');
    const emptyState = document.getElementById('emptyState');
    const totalDisplay = document.getElementById('totalDisplay');
    const subtotalDisplay = document.getElementById('subtotalDisplay');
    const itemsCount = document.getElementById('itemsCount');
    const btnFinalizar = document.getElementById('btnFinalizar');
    const selectCliente = document.getElementById('selectCliente');
    const fechaActual = document.getElementById('fechaActual');
    
    // Set Date
    if (fechaActual) {
        fechaActual.textContent = new Date().toLocaleDateString();
    }

    // --- Product Grid Logic ---

    // Add to Cart from Grid
    productGrid.addEventListener('click', function(e) {
        const card = e.target.closest('.product-card');
        if (!card) return;

        const codigo = parseInt(card.dataset.codigo);
        const nombre = card.dataset.nombre;
        const precio = parseFloat(card.dataset.precio);
        const stock = parseFloat(card.dataset.stock);
        const category = card.dataset.category;

        addToCart(codigo, nombre, precio, stock, category);
    });

    // Search Filtering
    searchInput.addEventListener('input', function(e) {
        const term = e.target.value.toLowerCase();
        filterGrid(term, getActiveCategory());
    });

    // Category Filtering
    categoryFilters.addEventListener('click', function(e) {
        if (e.target.classList.contains('category-pill')) {
            // Update active state
            document.querySelectorAll('.category-pill').forEach(p => p.classList.remove('active'));
            e.target.classList.add('active');
            
            const category = e.target.dataset.category;
            filterGrid(searchInput.value.toLowerCase(), category);
        }
    });

    function getActiveCategory() {
        const activePill = document.querySelector('.category-pill.active');
        return activePill ? activePill.dataset.category : 'all';
    }

    function filterGrid(term, category) {
        const cards = document.querySelectorAll('.product-card');
        cards.forEach(card => {
            const nombre = card.dataset.nombre.toLowerCase();
            const cardCategory = card.dataset.category.toLowerCase().trim();
            const targetCategory = category.toLowerCase().trim();
            
            const matchesTerm = nombre.includes(term);
            const matchesCategory = targetCategory === 'all' || cardCategory === targetCategory;

            if (matchesTerm && matchesCategory) {
                card.style.display = 'flex'; // Changed to flex to maintain layout
            } else {
                card.style.display = 'none';
            }
        });
    }

    // Expose to global scope for the button onclick
    window.toggleTicket = function() {
        const ticketColumn = document.getElementById('ticketColumn');
        const productsColumn = document.getElementById('productsColumn');
        
        ticketColumn.classList.add('d-none');
        productsColumn.classList.remove('col-lg-8');
        productsColumn.classList.add('col-12');
    }

    // --- Cart Logic ---

    function addToCart(codigo, nombre, precio, stock, category) {
        // Show ticket column if hidden
        const ticketColumn = document.getElementById('ticketColumn');
        const productsColumn = document.getElementById('productsColumn');
        
        if (ticketColumn.classList.contains('d-none')) {
            ticketColumn.classList.remove('d-none');
            productsColumn.classList.remove('col-12');
            productsColumn.classList.add('col-lg-8');
        }

        const existingItem = carrito.find(item => item.codigo === codigo);

        if (existingItem) {
            if (existingItem.cantidad + 1 > stock) {
                showAlert(`Stock insuficiente. Solo hay ${stock} disponibles.`);
                return;
            }
            existingItem.cantidad += 1;
            existingItem.subtotal = existingItem.cantidad * precio;
        } else {
            if (stock < 1) {
                showAlert(`Producto agotado.`);
                return;
            }
            carrito.push({
                codigo: codigo,
                nombre: nombre,
                precio: precio,
                cantidad: 1,
                subtotal: precio,
                stock: stock,
                category: category
            });
        }
        renderTicket();
    }

    function updateQuantity(codigo, change) {
        const item = carrito.find(i => i.codigo === codigo);
        if (!item) return;

        const newQuantity = item.cantidad + change;

        if (newQuantity <= 0) {
            removeFromCart(codigo);
            return;
        }

        if (newQuantity > item.stock) {
            showAlert(`Stock insuficiente. Solo hay ${item.stock} disponibles.`);
            return;
        }

        item.cantidad = newQuantity;
        item.subtotal = item.cantidad * item.precio;
        renderTicket();
    }

    function removeFromCart(codigo) {
        const index = carrito.findIndex(i => i.codigo === codigo);
        if (index > -1) {
            carrito.splice(index, 1);
            renderTicket();
        }
    }

    function renderTicket() {
        ticketItems.innerHTML = '';

        if (carrito.length === 0) {
            ticketItems.appendChild(emptyState);
            emptyState.style.display = 'block';
            updateTotals();
            return;
        } else {
            emptyState.style.display = 'none';
        }

        carrito.forEach(item => {
            const el = document.createElement('div');
            el.className = 'd-flex justify-content-between align-items-center mb-3 p-2 border rounded bg-light';
            el.innerHTML = `
                <div class="d-flex align-items-center gap-2" style="flex: 1;">
                    <div class="rounded-circle bg-white d-flex align-items-center justify-content-center border" style="width: 40px; height: 40px; font-size: 1.2rem;">
                        ${item.category === 'fruta' ? '🍎' : (item.category === 'verdura' ? '🥦' : '📦')}
                    </div>
                    <div style="min-width: 0;">
                        <div class="fw-bold text-truncate">${item.nombre}</div>
                        <div class="small text-muted">$${item.precio.toFixed(2)} x kg</div>
                    </div>
                </div>
                
                <div class="d-flex align-items-center gap-3">
                    <div class="input-group input-group-sm" style="width: 100px;">
                        <button class="btn btn-outline-secondary btn-minus" data-codigo="${item.codigo}">-</button>
                        <input type="text" class="form-control text-center px-0" value="${item.cantidad}" readonly>
                        <button class="btn btn-outline-secondary btn-plus" data-codigo="${item.codigo}">+</button>
                    </div>
                    <div class="fw-bold text-end" style="width: 60px;">
                        $${item.subtotal.toFixed(2)}
                    </div>
                </div>
            `;
            ticketItems.appendChild(el);
        });

        // Attach event listeners to new buttons
        document.querySelectorAll('.btn-minus').forEach(btn => {
            btn.addEventListener('click', (e) => updateQuantity(parseInt(e.target.dataset.codigo), -1));
        });
        document.querySelectorAll('.btn-plus').forEach(btn => {
            btn.addEventListener('click', (e) => updateQuantity(parseInt(e.target.dataset.codigo), 1));
        });

        updateTotals();
    }

    function updateTotals() {
        const total = carrito.reduce((sum, item) => sum + item.subtotal, 0);
        totalDisplay.textContent = `$${total.toFixed(2)}`;
        subtotalDisplay.textContent = `$${total.toFixed(2)}`;
        itemsCount.textContent = `${carrito.length} items`;
    }

 
    document.addEventListener('keydown', function(e) {
        if (e.key === 'F9') {
            e.preventDefault();
            btnFinalizar.click();
        }
    });

    btnFinalizar.addEventListener('click', function() {
        if (carrito.length === 0) {
            showAlert('El carrito está vacío');
            return;
        }

        const id_cliente = selectCliente.value;
        if (!id_cliente) {
            showAlert('Por favor seleccione un cliente');
            return;
        }

        showConfirmationModal('¿Confirmar venta?', async function() {
            try {
                const response = await fetch('/ventas/crear', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        id_cliente: id_cliente,
                        items: carrito.map(item => ({ codigo: item.codigo, cantidad: item.cantidad }))
                    })
                });
    
                const result = await response.json();
    
                if (result.success) {
                    showAlert(result.message, "¡Venta Exitosa!");
                    setTimeout(() => {
                        window.location.reload();
                    }, 1500);
                } else {
                    showAlert('Error: ' + result.message, "Error");
                }
            } catch (error) {
                console.error('Error:', error);
                showAlert('Error de conexión', "Error");
            }
        });
    });
});
