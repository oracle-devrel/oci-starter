let BASE_URL = 'app';
let csrfToken = '';
let currentUser = 'customer';

const form = document.getElementById('config-form');
const fieldsEl = document.getElementById('config-fields');
const statusEl = document.getElementById('config-status');
const closeButton = document.getElementById('close-config');

function setStatus(message) {
    statusEl.textContent = message;
}

function authHeaders(extraHeaders = {}) {
    return {
        ...extraHeaders,
        "Authorization": `User ${currentUser}`,
        "X-CSRF-TOKEN": csrfToken,
    };
}

async function fetchUserInfo() {
    BASE_URL = '/openid/server';
    const response = await fetch('/openid/userinfo', {
        method: 'GET',
        credentials: 'include'
    });
    if (!response.ok) throw new Error('Failed to fetch UserInfo');
    csrfToken = response.headers.get('x-csrf-token') || '';
    const data = await response.json();
    currentUser = data.sub;
}

async function fetchParameters() {
    const response = await fetch(`${BASE_URL}/config/parameters`, {
        method: 'GET',
        headers: authHeaders(),
        credentials: 'include',
    });
    if (!response.ok) throw new Error(`Configuration service responded with ${response.status}`);
    return response.json();
}

async function fetchLov(fieldName, values) {
    const params = new URLSearchParams({
        region: values.REGION || '',
        auth_type: values.AUTH_TYPE || '',
    });
    const response = await fetch(`${BASE_URL}/config/lov/${fieldName}?${params}`, {
        method: 'GET',
        headers: authHeaders(),
        credentials: 'include',
    });
    if (!response.ok) throw new Error(`List service responded with ${response.status}`);
    return response.json();
}

function currentValues() {
    const values = {};
    form.querySelectorAll('[name]').forEach((field) => {
        if (field.dataset.optionalConfig === 'true') {
            const checkbox = form.querySelector(`[data-optional-toggle="${field.name}"]`);
            values[field.name] = checkbox && checkbox.checked ? field.value : '';
            return;
        }
        values[field.name] = field.value;
    });
    return values;
}

function optionHtml(value, selectedValue, labels = {}) {
    const selected = value === selectedValue ? ' selected' : '';
    const label = labels[value] || value;
    return `<option value="${escapeHtml(value)}"${selected}>${escapeHtml(label)}</option>`;
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function renderField(parameter) {
    const wrapper = document.createElement('div');
    wrapper.className = 'config-field';
    if (parameter.optional === 'true') {
        wrapper.classList.add('config-field-optional');
    }

    const id = `config-${parameter.name.toLowerCase().replaceAll('_', '-')}`;
    const label = document.createElement('label');
    label.htmlFor = id;
    label.textContent = parameter.label || parameter.name;

    let control;
    if (parameter.type === 'LOV') {
        control = document.createElement('select');
        const values = Array.isArray(parameter.lov) ? [...parameter.lov] : [];
        if (parameter.value && !values.includes(parameter.value)) {
            values.unshift(parameter.value);
        }
        control.innerHTML = values
            .map((value) => optionHtml(value, parameter.value, parameter.lov_labels || {}))
            .join('');
    } else if (parameter.type === 'TEXTAREA') {
        control = document.createElement('textarea');
        control.rows = 8;
        control.value = parameter.value || '';
    } else {
        control = document.createElement('input');
        control.type = parameter.type === 'PASSWORD' ? 'password' : 'text';
        control.value = parameter.value || '';
    }

    control.id = id;
    control.name = parameter.name;
    control.autocomplete = parameter.type === 'PASSWORD' ? 'new-password' : 'off';
    if (parameter.optional === 'true') {
        const optionShell = document.createElement('div');
        optionShell.className = 'config-optional-control';

        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'config-enable-checkbox';
        checkbox.setAttribute('data-optional-toggle', parameter.name);
        checkbox.id = `${id}-enabled`;
        checkbox.checked = Boolean(parameter.value);
        checkbox.setAttribute('aria-label', `Enable ${parameter.label || parameter.name}`);

        control.disabled = !checkbox.checked;
        control.dataset.optionalConfig = 'true';
        checkbox.addEventListener('change', () => {
            control.disabled = !checkbox.checked;
            if (!checkbox.checked) {
                control.value = '';
            }
        });

        optionShell.append(checkbox, control);
        wrapper.append(label, optionShell);
    } else {
        wrapper.append(label, control);
    }
    return wrapper;
}

async function refreshLov(fieldName, loadingMessage, errorMessage) {
    const field = form.querySelector(`[name="${fieldName}"]`);
    if (!field) return;

    const selectedValue = field.value;
    const optionalCheckbox = form.querySelector(`[data-optional-toggle="${fieldName}"]`);
    field.disabled = true;
    setStatus(loadingMessage);

    try {
        const data = await fetchLov(fieldName, currentValues());
        const values = Array.isArray(data.values) ? data.values : [];
        if (selectedValue && !values.includes(selectedValue)) {
            values.unshift(selectedValue);
        }
        field.innerHTML = values
            .map((value) => optionHtml(value, selectedValue, data.lov_labels || {}))
            .join('');
        setStatus('');
    } catch (error) {
        console.error(error);
        setStatus(errorMessage);
    } finally {
        field.disabled = optionalCheckbox ? !optionalCheckbox.checked : false;
    }
}

function refreshStores() {
    return Promise.all([
        refreshLov('VECTOR_STORE_ID', 'Loading vector stores...', 'Unable to load vector stores.'),
        refreshLov('SEMANTIC_STORE_OCID', 'Loading semantic stores...', 'Unable to load semantic stores.'),
    ]);
}

function refreshGenAiModels() {
    return refreshLov('GENAI_MODEL', 'Loading models...', 'Unable to load models.');
}

function renderParameters(parameters) {
    form.setAttribute('aria-busy', 'false');
    fieldsEl.innerHTML = '';
    parameters.forEach((parameter) => fieldsEl.appendChild(renderField(parameter)));

    const regionField = form.querySelector('[name="REGION"]');
    const authField = form.querySelector('[name="AUTH_TYPE"]');

    if (regionField) {
        regionField.addEventListener('change', async () => {
            await refreshStores();
            await refreshGenAiModels();
        });
    }
    if (authField) {
        authField.addEventListener('change', async () => {
            await refreshStores();
            await refreshGenAiModels();
        });
    }
}

form.addEventListener('submit', async (event) => {
    event.preventDefault();
    setStatus('Saving...');

    try {
        const response = await fetch(`${BASE_URL}/config/parameters`, {
            method: 'PUT',
            headers: authHeaders({ "Content-Type": "application/json" }),
            credentials: 'include',
            body: JSON.stringify(currentValues()),
        });
        if (!response.ok) {
            const error = await response.json().catch(() => ({}));
            throw new Error(error.detail || `Save failed with ${response.status}`);
        }
        const data = await response.json();
        renderParameters(data.parameters || []);
        setStatus(data.warning || 'Saved.');
    } catch (error) {
        console.error(error);
        setStatus(error.message || 'Save failed.');
    }
});

if (closeButton) {
    closeButton.addEventListener('click', () => {
        window.location.href = 'index.html';
    });
}

(async function init() {
    try {
        if (window.location.pathname.startsWith('/openid')) {
            await fetchUserInfo();
        }
        const data = await fetchParameters();
        renderParameters(data.parameters || []);
        setStatus(data.warning || '');
    } catch (error) {
        console.error(error);
        form.setAttribute('aria-busy', 'false');
        fieldsEl.innerHTML = '';
        setStatus('Configuration service unavailable.');
    }
})();
