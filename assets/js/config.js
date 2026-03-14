
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

function getDeviceSerial() {
    let serial = localStorage.getItem('device_serial');
    if (!serial) {
        // Since pure web apps cannot access real IMEI or hardware serials for security reasons,
        // we generate a unique Hardware Fingerprint based on the device properties.
        try {
            const cores = navigator.hardwareConcurrency || 'X';
            const mem = navigator.deviceMemory || 'X';
            const screenRes = window.screen.width + 'x' + window.screen.height + 'x' + window.screen.colorDepth;
            const platform = navigator.platform || 'X';

            // Context for WebGL to get GPU Info (Stable Hardware ID)
            let gpu = 'GPU';
            try {
                const canvas = document.createElement('canvas');
                const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
                if (gl) {
                    const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
                    if (debugInfo) {
                        gpu = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) || 'GPU';
                    }
                }
            } catch (e) { }

            const cleanGpu = gpu.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();

            // We EXCLUDE navigator.userAgent and navigator.language because they differ between browsers.
            // We only use Hardware Traits.
            const rawData = screenRes + platform + cores + mem + cleanGpu;

            let hash = 0;
            for (let i = 0; i < rawData.length; i++) {
                hash = ((hash << 5) - hash) + rawData.charCodeAt(i);
                hash |= 0;
            }

            const hwHash = Math.abs(hash).toString(16).toUpperCase().padStart(8, '0');

            // Stable Hardware Serial based on internal components
            serial = `HPS-${cores}C${mem}G-${cleanGpu.substring(0, 4)}-${hwHash}`;
        } catch (e) {
            serial = 'HPS-UNQ-' + Math.random().toString(36).substring(2, 8).toUpperCase();
        }

        localStorage.setItem('device_serial', serial);
    }
    return serial;
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

// Global Fetch Interceptor to catch 402 License Expired and other crucial globals
const originalFetch = window.fetch;
window.fetch = async function (...args) {
    try {
        const response = await originalFetch(...args);
        if (response.status === 402) {
            const clone = response.clone();
            let msg = 'الترخيص التابع للمنشأة منتهي! يرجى التواصل مع الدعم الفني.';
            try {
                const data = await clone.json();
                if (data && data.message) msg = data.message;
            } catch (e) { }

            // Show alert and redirect to login
            window.appAlert(`⚠️ ${msg}`, 'error').then(() => {
                logout();
            });
        }
        return response;
    } catch (err) {
        throw err;
    }
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

