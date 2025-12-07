/**
 * Normalizes a string by removing accents and converting to lowercase.
 * @param {string} str - The string to normalize.
 * @returns {string} - The normalized string.
 */
function normalizeString(str) {
    return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

/**
 * Filters a table based on the input value.
 * @param {string} inputId - The ID of the search input element.
 * @param {string} tableId - The ID of the table to filter.
 */
function filterTable(inputId, tableSelector) {
    const input = document.getElementById(inputId);
    if (!input) return;

    input.addEventListener('keyup', function() {
        const filter = normalizeString(this.value);
        const rows = document.querySelectorAll(`${tableSelector} tbody tr`);

        rows.forEach(row => {
            const text = normalizeString(row.textContent);
            if (text.includes(filter)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });
}
