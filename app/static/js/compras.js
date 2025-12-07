document.addEventListener('DOMContentLoaded', function() {
    let carrito = [];
    
    const selectProducto = document.getElementById('selectProducto');
    const inputCantidad = document.getElementById('inputCantidad');
    const btnAgregar = document.getElementById('btnAgregar');
    const tablaCompras = document.getElementById('tablaCompras');
    const emptyRow = document.getElementById('emptyRow');
    const itemsCount = document.getElementById('itemsCount');
    const btnFinalizar = document.getElementById('btnFinalizar');
    const selectProveedor = document.getElementById('selectProveedor');
    const inputNoLote = document.getElementById('inputNoLote');
    
    document.getElementById('fechaActual').value = new Date().toLocaleDateString();

    btnAgregar.addEventListener('click', function() {
        const option = selectProducto.options[selectProducto.selectedIndex];
        
        if (!option || option.disabled) {
            showAlert('Por favor seleccione un producto');
            return;
        }

        const codigo = parseInt(option.value);
        const nombre = option.dataset.nombre;
        const cantidad = parseFloat(inputCantidad.value);

        if (cantidad <= 0) {
            showAlert('La cantidad debe ser mayor a 0');
            return;
        }

        const existingItem = carrito.find(item => item.codigo === codigo);
        if (existingItem) {
            existingItem.cantidad += cantidad;
        } else {
            carrito.push({
                codigo: codigo,
                nombre: nombre,
                cantidad: cantidad
            });
        }

        renderCarrito();
        inputCantidad.value = 1;
        selectProducto.selectedIndex = 0;
    });

    function renderCarrito() {
        tablaCompras.innerHTML = '';

        if (carrito.length === 0) {
            tablaCompras.appendChild(emptyRow);
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
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-danger btn-remove" data-index="${index}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            `;
            tablaCompras.appendChild(tr);
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
        itemsCount.textContent = `${carrito.length} items`;
    }

    btnFinalizar.addEventListener('click', function() {
        if (carrito.length === 0) {
            showAlert('El carrito está vacío');
            return;
        }

        const id_proveedor = selectProveedor.value;
        if (!id_proveedor) {
            showAlert('Por favor seleccione un proveedor');
            return;
        }

        const no_lote = inputNoLote.value;
        if (!no_lote) {
            showAlert('Por favor ingrese el número de lote');
            return;
        }

        showConfirmationModal('¿Confirmar compra?', async function() {
            try {
                const response = await fetch('/compras/crear', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        id_proveedor: id_proveedor,
                        no_lote: no_lote,
                        items: carrito.map(item => ({ codigo: item.codigo, cantidad: item.cantidad }))
                    })
                });
    
                const result = await response.json();
    
                if (result.success) {
                    showAlert(result.message, "Éxito");
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
