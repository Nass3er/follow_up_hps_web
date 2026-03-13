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

    // Display device serial for the user to copy
    const serialElem = document.getElementById('display-device-serial');
    if (serialElem) serialElem.innerText = getDeviceSerial();
});

function switchTab(tabId, event) {
    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));

    document.getElementById(tabId).classList.add('active');
    if (event && event.currentTarget) {
        event.currentTarget.classList.add('active');
    }
}

async function login() {
    const errorDiv = document.getElementById('login-error');
    errorDiv.innerText = '';

    const userId = document.getElementById('u-id').value;
    const password = document.getElementById('u-pass').value;
    const year = document.getElementById('u-year').value;
    const act = document.getElementById('u-act').value;

    if (!userId || !password || !year || !act) {
        errorDiv.innerText = 'يرجى تعبئة جميع الحقول (رقم المستخدم، الباسوورد، السنة، النشاط)';
        return;
    }

    const dto = {
        userId: parseInt(userId),
        password: password,
        financialYear: parseInt(year),
        activityNo: parseInt(act),
        deviceId: getDeviceSerial()
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
            if (res.status === 401) {
                errorDiv.innerText = '⚠️ بيانات الدخول غير صحيحة! تأكد من رقم المستخدم وكلمة المرور.';
            } else if (res.status === 403) {
                const errorData = await res.json();
                window.appAlert(`${errorData.message} <br><br> <strong style="font-size:24px;color:#d35400;">${errorData.deviceId}</strong>`, 'warning');
            } else {
                errorDiv.innerText = '❌ حدث خطأ في السيرفر أو تعذر الاتصال!';
            }
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

        // Offline Fallback for Login
        if (localStorage.getItem('last_u_id') === userId &&
            localStorage.getItem('last_u_year') === year &&
            localStorage.getItem('last_u_act') === act &&
            localStorage.getItem('offline_token')) {

            console.warn("Offline Login applied.");
            saveToken(localStorage.getItem('offline_token'));
            window.appAlert("⚠️ السيرفر غير متصل، تم تسجيل الدخول في وضع (عدم الاتصال) باستخدام بياناتك المتوفرة في الجهاز.", 'warning').then(() => {
                window.location.href = 'index.html';
            });
        } else {
            errorDiv.innerText = "تعذر الاتصال بالسيرفر للمصادقة. يجب أن تكون متصلاً بالسيرفر في أول مرة لتسجيل الدخول.";
        }
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

function copySerial() {
    const serialText = document.getElementById('display-device-serial').innerText;
    const btn = document.getElementById('copy-serial-btn');
    const iconContainer = document.getElementById('copy-status-icon');
    const textElem = document.getElementById('copy-status-text');

    const originalIcon = iconContainer.innerHTML;
    const originalText = textElem.innerText;
    const originalBg = btn.style.background;

    navigator.clipboard.writeText(serialText).then(() => {
        // Change to green checkmark
        btn.style.background = '#27ae60';
        textElem.innerText = 'تم!';
        iconContainer.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" 
                 stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
        `;

        // Reset after 2 seconds
        setTimeout(() => {
            btn.style.background = originalBg;
            textElem.innerText = originalText;
            iconContainer.innerHTML = originalIcon;
        }, 2000);
    });
}
