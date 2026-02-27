document.addEventListener('DOMContentLoaded', () => {
    // Load existing settings into inputs
    const config = getApiConfig();
    document.getElementById('api-host').value = config.host;
    document.getElementById('api-port').value = config.port;
    document.getElementById('api-service').value = config.service;

    // Load last login credentials
    if (localStorage.getItem('last_u_id')) document.getElementById('u-id').value = localStorage.getItem('last_u_id');
    if (localStorage.getItem('last_u_year')) document.getElementById('u-year').value = localStorage.getItem('last_u_year');
    if (localStorage.getItem('last_u_act')) document.getElementById('u-act').value = localStorage.getItem('last_u_act');
});

function switchTab(tabId) {
    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));

    document.getElementById(tabId).classList.add('active');
    event.currentTarget.classList.add('active');
}

async function login() {
    const errorDiv = document.getElementById('login-error');
    errorDiv.innerText = '';

    const userId = document.getElementById('u-id').value;
    const year = document.getElementById('u-year').value;
    const act = document.getElementById('u-act').value;

    if (!userId || !year || !act) {
        errorDiv.innerText = 'يرجى تعبئة جميع الحقول!';
        return;
    }

    const dto = {
        userId: parseInt(userId),
        financialYear: parseInt(year),
        activityNo: parseInt(act)
    };

    const apiUrl = getBaseApiUrl();

    try {
        const btn = document.getElementById('login-btn');
        btn.innerText = 'جاري الدخول...';
        btn.disabled = true;

        const res = await fetch(`${apiUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(dto)
        });

        btn.innerText = 'تسجيل الدخول';
        btn.disabled = false;

        if (!res.ok) {
            errorDiv.innerText = 'بيانات الدخول غير صحيحة أو السيرفر غير متوفر!';
            return;
        }

        const data = await res.json();
        saveToken(data.token);

        localStorage.setItem('last_u_id', dto.userId);
        localStorage.setItem('last_u_year', dto.financialYear);
        localStorage.setItem('last_u_act', dto.activityNo);

        window.location.href = 'index.html';
    } catch (e) {
        document.getElementById('login-btn').innerText = 'تسجيل الدخول';
        document.getElementById('login-btn').disabled = false;
        errorDiv.innerText = "خطأ في الاتصال بالسيرفر. يرجى التحقق من إعدادات السيرفر والاتصال.";
    }
}

async function saveAndTestSettings() {
    const statusDiv = document.getElementById('test-result');
    statusDiv.className = 'status-msg'; // reset classes
    statusDiv.innerText = 'جاري الحفظ والاختبار...';

    const host = document.getElementById('api-host').value.trim();
    const port = document.getElementById('api-port').value.trim();
    const service = document.getElementById('api-service').value.trim();

    if (!host || !service) {
        statusDiv.innerText = 'الرجاء إدخال الهوست واسم الخدمة على الأقل';
        statusDiv.classList.add('error');
        return;
    }

    saveApiConfig(host, port, service);
    const testUrl = getBaseApiUrl();

    try {
        const res = await fetch(`${testUrl}/auth/login`, {
            method: 'OPTIONS',
            headers: { 'Content-Type': 'application/json' }
        }).catch(err => {
            return fetch(`${testUrl}/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        });

        statusDiv.innerText = '✅ تم الحفظ. الاتصال بالسيرفر جاهز!';
        statusDiv.classList.add('success');
    } catch (e) {
        statusDiv.innerText = '❌ تم الحفظ، لكن فشل الاتصال بالسيرفر. يرجى التأكد من البيانات أو تشغيل السيرفر.';
        statusDiv.classList.add('error');
    }
}
