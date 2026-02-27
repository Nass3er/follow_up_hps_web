function getApiConfig() {
    const host = localStorage.getItem('api_host') || 'localhost';
    const port = localStorage.getItem('api_port') || '80';
    const service = localStorage.getItem('api_service') || 'hps';
    return { host, port, service };
}

function saveApiConfig(host, port, service) {
    localStorage.setItem('api_host', host);
    localStorage.setItem('api_port', port);
    localStorage.setItem('api_service', service);
}

function getBaseApiUrl() {
    const { host, port, service } = getApiConfig();
    const portString = port ? `:${port}` : '';
    // Format: http://host:port/service/api
    return `http://${host}${portString}/${service}/api`;
}

// Global functions for token management
function saveToken(token) {
    localStorage.setItem('auth_token', token);
}

function getToken() {
    return localStorage.getItem('auth_token');
}

function checkAuth() {
    if (!getToken()) {
        window.location.href = 'login.html';
    }
}

function logout() {
    localStorage.removeItem('auth_token');
    window.location.href = 'login.html';
}
