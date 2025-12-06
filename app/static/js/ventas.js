document.addEventListener('DOMContentLoaded', function() {
    let carrito = [];
    
    const selectProducto = document.getElementById('selectProducto');
    const inputCantidad = document.getElementById('inputCantidad');
    const btnAgregar = document.getElementById('btnAgregar');
    const tablaVentas = document.getElementById('tablaVentas');
    const emptyRow = document.getElementById('emptyRow');
    const totalDisplay = document.getElementById('totalDisplay');
    const subtotalDisplay = document.getElementById('subtotalDisplay');
    const itemsCount = document.getElementById('itemsCount');
    const btnFinalizar = document.getElementById('btnFinalizar');
    const selectCliente = document.getElementById('selectCliente');
    
    document.getElementById('fechaActual').value = new Date().toLocaleDateString();

    btnAgregar.addEventListener('click', function() {
        const option = selectProducto.options[selectProducto.selectedIndex];
        
        if (!option || option.disabled) {
            showAlert('Por favor seleccione un producto');
            return;
        }

        const codigo = parseInt(option.value);
        const nombre = option.dataset.nombre;
        const precio = parseFloat(option.dataset.precio);
        const stock = parseFloat(option.dataset.stock);
        const cantidad = parseFloat(inputCantidad.value);

        if (cantidad <= 0) {
            showAlert('La cantidad debe ser mayor a 0');
            return;
        }

        if (cantidad > stock) {
            showAlert(`Stock insuficiente. Solo hay ${stock} disponibles.`);
            return;
        }

        const existingItem = carrito.find(item => item.codigo === codigo);
        if (existingItem) {
            if (existingItem.cantidad + cantidad > stock) {
                showAlert(`No puedes agregar más. Ya tienes ${existingItem.cantidad} en el carrito y el stock es ${stock}.`);
                return;
            }
            existingItem.cantidad += cantidad;
            existingItem.subtotal = existingItem.cantidad * precio;
        } else {
            carrito.push({
                codigo: codigo,
                nombre: nombre,
                precio: precio,
                cantidad: cantidad,
                subtotal: cantidad * precio
            });
        }

        renderCarrito();
        inputCantidad.value = 1;
        selectProducto.selectedIndex = 0;
    });

    function renderCarrito() {
        tablaVentas.innerHTML = '';

        if (carrito.length === 0) {
            tablaVentas.appendChild(emptyRow);
            updateTotals();
            return;
        }

        carrito.forEach((item, index) => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="ps-4">
                    <div class="fw-bold">${item.nombre}</div>
                    <small class="text-muted">#${item.codigo}</small>
                </td>
                <td class="text-center">${item.cantidad}</td>
                <td class="text-end">$${item.precio.toFixed(2)}</td>
                <td class="text-end fw-bold">$${item.subtotal.toFixed(2)}</td>
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-danger btn-remove" data-index="${index}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            `;
            tablaVentas.appendChild(tr);
        });


        document.querySelectorAll('.btn-remove').forEach(btn => {
            btn.addEventListener('click', function() {
                const index = parseInt(this.dataset.index);
                carrito.splice(index, 1);
                renderCarrito();
            });
        });

        updateTotals();
    }

    
    function updateTotals() {
        const total = carrito.reduce((sum, item) => sum + item.subtotal, 0);
        totalDisplay.textContent = `$${total.toFixed(2)}`;
        subtotalDisplay.textContent = `$${total.toFixed(2)}`;
        itemsCount.textContent = `${carrito.length} items`;
    }

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
                    showAlert(result.message, "Éxito");
                    // Esperar a que el usuario lea el mensaje o recargar después de un momento
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
