<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>متابعة مريض - HPS</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="manifest.json">
    <meta name="theme-color" content="#1565c0">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <link rel="apple-touch-icon" href="icon.png">
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #1565c0 0%, #1e88e5 100%);
            --secondary-gradient: linear-gradient(135deg, #26a69a 0%, #4db6ac 100%);
            --accent-gradient: linear-gradient(135deg, #ff7043 0%, #ff8a65 100%);
            --card-shadow: 0 8px 32px rgba(0,0,0,0.08);
            --glass-bg: rgba(255, 255, 255, 0.95);
        }

        body {
            background-color: #f0f4f8;
            font-family: 'Tajawal', sans-serif;
            margin: 0;
            padding-bottom: 10px;
            max-height: 100vh;
            overflow: hidden;
        }

        /* Container designed to fit viewport */
        .dashboard-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 10px 15px;
            box-sizing: border-box;
        }

        /* Slimmer, beautiful header */
        .header-section {
            background: var(--primary-gradient);
            color: white;
            padding: 10px 15px;
            border-bottom-left-radius: 25px;
            border-bottom-right-radius: 25px;
            box-shadow: 0 4px 20px rgba(21, 101, 192, 0.25);
            margin-bottom: 10px;
            position: relative;
        }

        .header-title {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
        }

        /* Very compact patient card */
        .patient-card {
            background: var(--glass-bg);
            border-radius: 20px;
            padding: 12px 15px;
            box-shadow: var(--card-shadow);
            margin-top: 5px;
            display: none;
            animation: slideUp 0.4s ease-out;
            border: 1px solid rgba(21, 101, 192, 0.08);
        }

        @keyframes slideUp {
            from { opacity: 0; transform: translateY(15px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Compact Info Grid */
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            margin-top: 10px;
        }

        .info-item {
            background: #f8fbff;
            padding: 6px 12px;
            border-radius: 8px;
            border: 1px solid #e3f2fd;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
        }

        .info-label {
            font-size: 11px;
            color: #78909c;
            font-weight: 500;
            white-space: nowrap;
        }

        .info-value {
            font-size: 12px;
            font-weight: 600;
            color: #37474f;
            text-align: left;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        /* Grid layout for Action Buttons: 2 columns to save height */
        .action-buttons {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 12px;
        }

        .action-btn {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 10px 8px;
            border-radius: 12px;
            text-decoration: none;
            color: white;
            font-weight: 700;
            font-size: 12px;
            transition: all 0.2s ease;
            box-shadow: 0 4px 10px rgba(0,0,0,0.06);
            gap: 6px;
            text-align: center;
        }

        .action-btn:active {
            transform: scale(0.95);
        }

        .btn-vitals { background: var(--secondary-gradient); }
        .btn-io { background: var(--primary-gradient); }
        .btn-order { background: var(--accent-gradient); }

        .btn-icon {
            font-size: 18px;
            background: rgba(255,255,255,0.25);
            width: 34px;
            height: 34px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
        }

        .action-btn:hover .btn-icon {
            transform: scale(1.1);
        }

        /* Modal Styles */
        .modal-content {
            border-radius: 25px !important;
            padding: 0 !important;
            overflow: hidden;
        }

        .modal-header {
            background: #f8fbff;
            padding: 20px !important;
            border-bottom: 1px solid #e3f2fd !important;
        }

        .search-box-container {
            padding: 15px;
            background: white;
        }

        .search-input {
            width: 100%;
            padding: 15px;
            border: 2px solid #e3f2fd;
            border-radius: 12px;
            font-size: 16px;
            outline: none;
            transition: border-color 0.3s;
            box-sizing: border-box;
        }

        .search-input:focus {
            border-color: #1565c0;
        }

        .adm-table-container {
            max-height: 400px;
            overflow-y: auto;
        }

        .modern-table {
            width: 100%;
            border-collapse: collapse;
        }

        .modern-table th {
            background: #f1f8fe;
            padding: 15px;
            text-align: right;
            font-size: 14px;
            color: #1565c0;
            position: sticky;
            top: 0;
        }

        .modern-table td {
            padding: 15px;
            border-bottom: 1px solid #f1f8fe;
            font-size: 15px;
            cursor: pointer;
        }

        .modern-table tr:hover {
            background: #f9fbff;
        }

        .empty-state {
            text-align: center;
            padding: 30px 20px;
            color: #78909c;
        }

        .empty-icon {
            font-size: 50px;
            margin-bottom: 15px;
            opacity: 0.7;
        }

        @media (max-width: 600px) {
            .info-grid {
                grid-template-columns: 1fr 1fr;
                gap: 8px;
            }
            .dashboard-container {
                padding: 8px 10px;
            }
            .header-title { font-size: 18px; }
            .action-btn { font-size: 11px; padding: 8px 5px; }
            .btn-icon { width: 30px; height: 30px; font-size: 16px; }
        }

        @media (max-height: 500px) {
            body {
                overflow-y: auto;
                max-height: none;
            }
        }
    </style>
</head>
<body>
    <div class="app-layout">
        <!-- Curved premium header containing back button, title, and search trigger in one line -->
        <header class="header-section">
            <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
                <a href="index.html" style="text-decoration:none; font-size: 22px; color: white; display: inline-flex; align-items: center; transition: transform 0.2s;" title="الرجوع للرئيسية" onmouseover="this.style.transform='scale(1.1)'" onmouseout="this.style.transform='scale(1)'">➡</a>
                <h1 class="header-title">متابعة مريض</h1>
                <button onclick="openSearchModal()" style="background: rgba(255,255,255,0.25); border: none; color: white; width: 36px; height: 36px; border-radius: 50%; font-size: 16px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: background 0.2s, transform 0.2s;" title="بحث عن مريض" onmouseover="this.style.background='rgba(255,255,255,0.35)'; this.style.transform='scale(1.05)'" onmouseout="this.style.background='rgba(255,255,255,0.25)'; this.style.transform='scale(1)'">🔍</button>
            </div>
        </header>

        <main class="dashboard-container">
            <!-- Welcome screen shown when no patient is selected -->
            <div id="welcome-msg" class="empty-state" style="margin-top: 30px;">
                <div class="empty-icon">🏥</div>
                <h2 style="color: #1565c0; font-size: 20px; margin-bottom: 10px;">أهلاً بك في نظام المتابعة</h2>
                <p style="color: #78909c; font-size: 14px; margin-bottom: 25px;">الرجاء اختيار مريض من قائمة الترقيدات النشطة للبدء بالمتابعة وإجراء المعاملات الطبية</p>
                <button class="btn btn-primary" onclick="openSearchModal()" style="background: var(--primary-gradient); padding: 12px 30px; border-radius: 25px; border: none; color: white; font-weight: bold; font-size: 15px; cursor: pointer; box-shadow: 0 4px 15px rgba(21, 101, 192, 0.2); transition: transform 0.2s;" onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
                    🔍 اختيار مريض للبدء
                </button>
            </div>

            <!-- Patient Info Card & Navigation Actions -->
            <div class="patient-card card" id="patient-card">
                <!-- Compact Header of the card -->
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; border-bottom: 1px solid #f1f8fe; padding-bottom: 6px;">
                    <div style="display: flex; gap: 8px; align-items: center; flex: 1; overflow: hidden;">
                        <div class="patient-icon" id="p-icon" style="font-size: 20px;">👨‍💼</div>
                        <h2 id="display-p-name" style="margin:0; color:#1565c0; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">--</h2>
                    </div>
                    <button onclick="clearSelection()" class="btn" style="background:#fff1f0; color:#ff4d4f; font-size:11px; padding:3px 8px; border: 1px solid #ffa39e; border-radius: 6px; margin-right: 10px; cursor: pointer;" title="إلغاء التحديد">❌ إلغاء</button>
                </div>
                
                <!-- Compact 2-column info grid where values are aligned side-by-side to save height -->
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">رقم الترقيد</span>
                        <span class="info-value" id="display-adm-no">--</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">رقم المريض</span>
                        <span class="info-value" id="display-p-no">--</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">العمر / الجنس</span>
                        <span class="info-value"><span id="display-p-age">--</span> / <span id="display-p-gender">--</span></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">الغرفة / السرير</span>
                        <span class="info-value"><span id="display-p-room">--</span> / <span id="display-p-bed">--</span></span>
                    </div>
                    <div class="info-item" style="grid-column: 1 / -1; background: #fffde7; border-color: #fff9c4;">
                        <span class="info-label">الطبيب المعالج</span>
                        <span class="info-value" id="display-doctor" style="color: #f57f17;">--</span>
                    </div>
                </div>

                <!-- Action buttons rendered in a 2x2 grid with centered icon on top to minimize height and mimic a native app -->
                <div class="action-buttons">
                    <a href="javascript:void(0)" onclick="navigateTo('vitals')" class="action-btn btn-vitals">
                        <div class="btn-icon">🩺</div>
                        <span>إضافة علامات حيوية</span>
                    </a>
                    <a href="javascript:void(0)" onclick="navigateTo('io')" class="action-btn btn-io">
                        <div class="btn-icon">💧</div>
                        <span>إضافة سوائل (داخل/خارج)</span>
                    </a>
                    <a href="javascript:void(0)" onclick="navigateTo('order')" class="action-btn btn-order">
                        <div class="btn-icon">📋</div>
                        <span>إضافة أمر طبيب</span>
                    </a>
                    <a href="javascript:void(0)" onclick="navigateTo('lab')" class="action-btn" style="background: linear-gradient(135deg, #673ab7 0%, #9575cd 100%);">
                        <div class="btn-icon">🧪</div>
                        <span>عرض نتائج العينات</span>
                    </a>
                </div>
            </div>
        </main>
    </div>

    <!-- Search Modal -->
    <div id="modal-search" class="modal">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <div style="display:flex; justify-content: space-between; align-items: center; width: 100%;">
                    <h3 style="margin:0;">قائمة الترقيدات النشطة</h3>
                    <span class="close-btn" onclick="closeModal('modal-search')">&times;</span>
                </div>
            </div>
            <div class="search-box-container">
                <input type="text" id="adm-search-input" class="search-input" placeholder="ابحث باسم المريض أو رقم الترقيد..." onkeyup="filterAdmissions()">
            </div>
            <div class="adm-table-container">
                <table id="adm-list-table" class="modern-table">
                    <thead>
                        <tr>
                            <th>رقم الترقيد</th>
                            <th>المريض</th>
                            <th>التاريخ</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Rows populated by JS -->
                    </tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button onclick="closeModal('modal-search')" class="btn btn-secondary">إغلاق</button>
            </div>
        </div>
    </div>

    <script src="assets/js/config.js"></script>
    <script src="assets/js/db.js"></script>
    <script>
        let ALL_ADMISSIONS = [];
        let SELECTED_ADMISSION = null;

        document.addEventListener('DOMContentLoaded', () => {
            checkAuth();
            
            // Check if we are returning from a module with a selected patient
            const saved = localStorage.getItem('selected_patient');
            if (saved) {
                try {
                    const details = JSON.parse(saved);
                    SELECTED_ADMISSION = details;
                    showPatientCard(details);
                    // Clear it immediately so it doesn't stay stuck on refresh or future visits
                    localStorage.removeItem('selected_patient');
                } catch(e) { console.error(e); }
            }
            
            // Load admissions in background
            loadAdmissions();
        });

        async function loadAdmissions() {
            try {
                let list = [];
                try {
                    const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
                        method: 'POST',
                        headers: getHeaders()
                    });
                    if (res.ok) {
                        list = await res.json();
                        await saveToDB('admissions', list);
                    } else {
                        throw new Error("HTTP Status " + res.status);
                    }
                } catch(netErr) {
                    console.warn("Fetch admissions failed, falling back to local DB", netErr);
                    list = await getFromDB('admissions') || [];
                }
                ALL_ADMISSIONS = list;
                renderAdmissions(list);
            } catch (e) {
                console.error("Load admissions error", e);
            }
        }

        function renderAdmissions(list) {
            const tbody = document.querySelector('#adm-list-table tbody');
            tbody.innerHTML = '';
            if (!list || list.length === 0) {
                tbody.innerHTML = '<tr><td colspan="3" class="empty-state">لا توجد ترقيدات حالية</td></tr>';
                return;
            }
            list.forEach(a => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td style="font-weight:bold; color:#1565c0;">${a.docNo}</td>
                    <td>${a.patientName}</td>
                    <td style="font-size:12px; color:#78909c;">${new Date(a.date).toLocaleDateString('ar-YE')}</td>
                `;
                tr.onclick = () => selectAdmission(a);
                tbody.appendChild(tr);
            });
        }

        function filterAdmissions() {
            const term = document.getElementById('adm-search-input').value.toLowerCase();
            const filtered = ALL_ADMISSIONS.filter(a => 
                (a.patientName && a.patientName.toLowerCase().includes(term)) ||
                (a.docNo && a.docNo.toString().includes(term))
            );
            renderAdmissions(filtered);
        }

        function openSearchModal() {
            document.getElementById('modal-search').style.display = 'block';
            document.getElementById('adm-search-input').focus();
        }

        function closeModal(id) {
            document.getElementById(id).style.display = 'none';
        }

        async function selectAdmission(adm) {
            closeModal('modal-search');
            
            try {
                let details = null;
                try {
                    const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions/details?docNo=${adm.docNo}&docSrl=${adm.docSerial}`, {
                        method: 'POST',
                        headers: getHeaders()
                    });
                    if (res.ok) {
                        details = await res.json();
                        const fullData = { ...details, docNo: adm.docNo, docSerial: adm.docSerial, cacheKey: `${adm.docNo}_${adm.docSerial}` };
                        await saveToDB('patients_details', [fullData], false);
                        details = fullData;
                    } else {
                        throw new Error("HTTP Status " + res.status);
                    }
                } catch(netErr) {
                    console.warn("Fetch patient details failed, falling back to local DB", netErr);
                    const cachedDetails = await getFromDB('patients_details') || [];
                    details = cachedDetails.find(d => d.cacheKey === `${adm.docNo}_${adm.docSerial}`);
                }

                if (details) {
                    SELECTED_ADMISSION = details;
                    localStorage.setItem('selected_patient', JSON.stringify(details));
                    showPatientCard(details);
                } else {
                    appAlert("عذراً، لم نتمكن من جلب تفاصيل هذا المريض. يرجى الاتصال بالإنترنت.", "warning");
                }
            } catch (e) {
                console.error(e);
                appAlert("حدث خطأ أثناء جلب البيانات", "error");
            }
        }

        function showPatientCard(details) {
            document.getElementById('welcome-msg').style.display = 'none';
            document.getElementById('patient-card').style.display = 'block';
            
            document.getElementById('display-p-name').innerText = details.patientName;
            document.getElementById('display-adm-no').innerText = details.docNo;
            document.getElementById('display-p-no').innerText = details.patientNo;
            document.getElementById('display-p-age').innerText = details.age || '--';
            document.getElementById('display-p-gender').innerText = details.gender == 1 ? 'ذكر' : 'أنثى';
            document.getElementById('display-p-room').innerText = details.roomNo || '--';
            document.getElementById('display-p-bed').innerText = details.bedNo || '--';
            document.getElementById('display-doctor').innerText = details.doctorName || details.dctrNo || '--';
            
            document.getElementById('p-icon').innerText = details.gender == 1 ? '👨‍💼' : '👩‍💼';
        }

        function navigateTo(page) {
            if (!SELECTED_ADMISSION) return;
            
            // Save to localStorage so the target page can read it
            localStorage.setItem('selected_patient', JSON.stringify(SELECTED_ADMISSION));
            
            const urls = {
                'vitals': 'vitals.html',
                'io': 'intake_output.html',
                'order': 'doctor-orders.html',
                'lab': 'lab-results.html'
            };
            window.location.href = urls[page];
        }

        function clearSelection() {
            localStorage.removeItem('selected_patient');
            SELECTED_ADMISSION = null;
            document.getElementById('patient-card').style.display = 'none';
            document.getElementById('welcome-msg').style.display = 'block';
        }

        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.style.display = "none";
            }
        }
    </script>
</body>
</html>
