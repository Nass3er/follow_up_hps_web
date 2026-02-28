
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
    localStorage.setItem('offline_token', token); // Save backup for offline login
}

function getToken() {
    return localStorage.getItem('auth_token');
}

function checkAuth() {
    if (!getToken()) {
        window.location.href = 'login.html';
        return;
    }
}

function logout() {
    localStorage.removeItem('auth_token');
    window.location.href = 'login.html';
}

function getHeaders() {
    return {
        'Authorization': `Bearer ${getToken()}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    };
}

// Intercept 402 (License Invalid/Expired) from the backend
const _origFetch = window.fetch;
window.fetch = async function (...args) {
    const response = await _origFetch.apply(this, args);
    if (response.status === 402 && !window.location.pathname.includes('activate')) {
        window.location.href = 'activate.html';
    }
    return response;
};

// Global Custom Alerts
function appAlert(message, type = 'info') {
    return new Promise((resolve) => {
        let overlay = document.createElement('div');
        overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.6);z-index:10000;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(3px);';

        let box = document.createElement('div');
        box.style.cssText = 'background:#fff;padding:25px;border-radius:15px;width:85%;max-width:350px;text-align:center;box-shadow:0 10px 40px rgba(0,0,0,0.3);transform:scale(0.9);opacity:0;transition:all 0.3s ease;';

        let icon = type === 'error' ? '❌' : type === 'warning' ? '⚠️' : type === 'success' ? '✅' : 'ℹ️';
        let color = type === 'error' ? '#e74c3c' : type === 'warning' ? '#f39c12' : type === 'success' ? '#2ecc71' : '#3498db';

        box.innerHTML = `
            <div style="font-size:50px;margin-bottom:15px;color:${color}">${icon}</div>
            <p style="font-size:18px;color:#333;margin-bottom:25px;line-height:1.5;font-family:'Tajawal',sans-serif;">${message}</p>
            <button style="background:${color};color:#fff;border:none;padding:12px 35px;font-size:16px;border-radius:8px;font-weight:bold;cursor:pointer;font-family:'Tajawal',sans-serif;width:100%;box-shadow:0 4px 10px ${color}40;">حسناً</button>
        `;

        box.querySelector('button').onclick = () => {
            box.style.transform = 'scale(0.9)'; box.style.opacity = '0';
            setTimeout(() => document.body.removeChild(overlay), 300);
            resolve(true);
        };

        overlay.appendChild(box);
        document.body.appendChild(overlay);

        // trigger animation
        requestAnimationFrame(() => {
            box.style.transform = 'scale(1)';
            box.style.opacity = '1';
        });
    });
}

function appConfirm(message) {
    return new Promise((resolve) => {
        let overlay = document.createElement('div');
        overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.6);z-index:10000;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(3px);';

        let box = document.createElement('div');
        box.style.cssText = 'background:#fff;padding:25px;border-radius:15px;width:90%;max-width:350px;text-align:center;box-shadow:0 10px 40px rgba(0,0,0,0.3);transform:scale(0.9);opacity:0;transition:all 0.3s ease;';

        box.innerHTML = `
            <div style="font-size:50px;margin-bottom:15px;color:#e74c3c">⚠️</div>
            <p style="font-size:18px;color:#333;margin-bottom:25px;line-height:1.5;font-weight:bold;font-family:'Tajawal',sans-serif;">${message}</p>
            <div style="display:flex;gap:10px;justify-content:center;">
                <button id="btn-yes" style="flex:1;background:#e74c3c;color:#fff;border:none;padding:12px;font-size:16px;border-radius:8px;font-weight:bold;cursor:pointer;font-family:'Tajawal',sans-serif;box-shadow:0 4px 10px rgba(231,76,60,0.3);">نعم، موافق</button>
                <button id="btn-no" style="flex:1;background:#f1f2f6;color:#576574;border:none;padding:12px;font-size:16px;border-radius:8px;font-weight:bold;cursor:pointer;font-family:'Tajawal',sans-serif;">إلغاء</button>
            </div>
        `;

        box.querySelector('#btn-yes').onclick = () => {
            box.style.transform = 'scale(0.9)'; box.style.opacity = '0';
            setTimeout(() => document.body.removeChild(overlay), 300);
            resolve(true);
        };
        box.querySelector('#btn-no').onclick = () => {
            box.style.transform = 'scale(0.9)'; box.style.opacity = '0';
            setTimeout(() => document.body.removeChild(overlay), 300);
            resolve(false);
        };

        overlay.appendChild(box);
        document.body.appendChild(overlay);

        requestAnimationFrame(() => {
            box.style.transform = 'scale(1)';
            box.style.opacity = '1';
        });
    });
}

