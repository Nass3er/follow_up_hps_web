// app.js main module
let NURSE_LIST = [];
let CURRENT_ADMISSION = null;
let SELECTED_TIME = "";
let lastFetchedData = [];
let CURRENT_DOC_SRL = null;

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();

    const now = new Date();
    document.getElementById('cur-date').innerText = now.toLocaleDateString('ar-YE');
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    document.getElementById('cur-day').innerText = days[now.getDay()];

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    document.getElementById('doc-date-input').value = `${year}-${month}-${day}`;

    initData();

    document.getElementById('adm-no-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === 'Tab') {
            searchAdmission(e.target.value);
            e.preventDefault();
        }
    });

    document.getElementById('n-id').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === 'Tab') {
            const nurse = NURSE_LIST.find(n => n.empNo == e.target.value);
            if (nurse) document.getElementById('n-name').value = nurse.empName;
            else { alert("الممرض غير موجود"); document.getElementById('n-name').value = ""; }
            e.preventDefault();
        }
    });

    // Handle closing modal outside clicks
    window.onclick = function (event) {
        if (event.target.classList.contains('modal')) {
            event.target.style.display = "none";
        }
    }
});

async function initData() {
    loadBranches();
    fetchNurses();
}

const getHeaders = () => ({
    'Authorization': `Bearer ${getToken()}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json'
});

async function loadBranches() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/branches`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });
        if (!res.ok) {
            if (res.status === 401) logout();
            return;
        }
        const list = await res.json();
        const select = document.getElementById('branch-list');
        select.innerHTML = '<option value="">اختر الفرع...</option>';
        list.forEach(b => select.add(new Option(b.branchName, b.branchNo)));
    } catch (e) { console.error('Branches fetch error', e); }
}

async function searchAdmission(docNo) {
    if (!docNo) return;
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });
        const list = await res.json();
        const admission = list.find(a => a.docNo == docNo);
        if (admission) selectAdmission(admission.docNo, admission.docSerial);
        else alert("رقم الترقيد غير موجود");
    } catch (e) { alert("خطأ في الاتصال"); }
}

async function openAdmModal() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });
        const list = await res.json();
        const tbody = document.querySelector('#adm-list-table tbody');
        tbody.innerHTML = '';
        list.forEach(a => {
            let tr = document.createElement('tr');
            tr.innerHTML = `<td>${a.docNo}</td><td>${new Date(a.date).toLocaleDateString()}</td><td>${a.patientName}</td>`;
            tr.onclick = () => { selectAdmission(a.docNo, a.docSerial); closeModal('modal-adm'); };
            tbody.appendChild(tr);
        });
        document.getElementById('modal-adm').style.display = 'block';
    } catch (e) { alert("خطأ في الاتصال"); }
}

async function selectAdmission(no, srl) {
    document.getElementById('adm-no-input').value = no;
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions/details?docNo=${no}&docSrl=${srl}`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });
        const details = await res.json();
        CURRENT_ADMISSION = { ...details, docNo: no, docSrl: srl };

        document.getElementById('p-name').value = details.patientName || details.patientNo;
        document.getElementById('p-no').value = details.patientNo;
        document.getElementById('p-age').value = details.age;
        document.getElementById('p-room').value = details.roomNo;
        document.getElementById('p-bed').value = details.bedNo;
        document.getElementById('p-gender').value = details.gender == 1 ? "ذكر" : "أنثى";

        document.getElementById('table-area').style.display = 'none';

    } catch (e) { console.error(e); }
}

async function loadAndShowTable() {
    if (!CURRENT_ADMISSION) return alert("الرجاء اختيار مريض أولاً");

    const docDate = document.getElementById('doc-date-input').value;
    const interval = parseInt(document.getElementById('time-interval').value) || 30;

    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/history?patientNo=${CURRENT_ADMISSION.patientNo}&date=${docDate}`, {
            method: 'GET',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });

        if (!res.ok) {
            if (res.status == 401) return logout();
        }

        let savedData = [];
        try { savedData = await res.json(); } catch (e) { }
        lastFetchedData = Array.isArray(savedData) ? savedData : [];

        let timeSlots = [];
        for (let totalMin = 1 * 60; totalMin < 24 * 60; totalMin += interval) {
            let h = Math.floor(totalMin / 60);
            let m = totalMin % 60;
            timeSlots.push(`${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:00`);
        }

        lastFetchedData.forEach(item => {
            if (item.docTime) {
                let savedTime = item.docTime.split('T')[1];
                if (!timeSlots.includes(savedTime)) { timeSlots.push(savedTime); }
            }
        });

        timeSlots.sort();
        const tbody = document.querySelector('#vitals-table tbody');
        tbody.innerHTML = '';

        timeSlots.forEach(time => {
            const record = lastFetchedData.find(d => d.docTime && d.docTime.split('T')[1] === time);
            const tr = document.createElement('tr');

            if (record) {
                tr.className = "saved-row";
                tr.innerHTML = `
                    <td><b>${time}</b></td>
                    <td>${record.temperature || '-'}</td>
                    <td>${record.pulseRate || '-'}</td>
                    <td>${record.respirationRate || '-'}</td>
                    <td>${record.spO2 || '-'}</td>
                    <td>${record.bloodPressureOne || '-'}/${record.bloodPressureTwo || '-'}</td>
                    <td>
                        <button class="btn-edit" onclick="openEditModal('${record.docSrl}')">تعديل ✏️</button>
                    </td>
                `;
            } else {
                tr.innerHTML = `
                    <td>${time}</td>
                    <td style="color:#aaa">-</td><td style="color:#aaa">-</td><td style="color:#aaa">-</td><td style="color:#aaa">-</td><td style="color:#aaa">-</td>
                    <td>
                        <button class="btn-add" onclick="openVitalsModal('${time}')">إضافة ➕</button>
                    </td>
                `;
            }
            tbody.appendChild(tr);
        });

        document.getElementById('table-area').style.display = 'block';
    } catch (e) {
        alert("فشل جلب بيانات المتابعة");
        console.error(e);
    }
}

function openEditModal(docSrl) {
    CURRENT_DOC_SRL = docSrl;
    const record = lastFetchedData.find(d => d.docSrl == docSrl);

    if (record) {
        SELECTED_TIME = record.docTime.split('T')[1];
        document.getElementById('vitals-title').innerText = "تعديل علامات الساعة " + SELECTED_TIME;

        document.getElementById('n-id').value = record.nurseEmpNo || "";
        findNurseName(record.nurseEmpNo);

        document.getElementById('v-temp').value = record.temperature || "";
        document.getElementById('v-pulse').value = record.pulseRate || "";
        document.getElementById('v-resp').value = record.respirationRate || "";
        document.getElementById('v-spo2').value = record.spO2 || "";
        document.getElementById('v-bp1').value = record.bloodPressureOne || "";
        document.getElementById('v-bp2').value = record.bloodPressureTwo || "";
        document.getElementById('v-notes').value = record.notes || "";

        document.getElementById('modal-vitals').style.display = 'block';
    } else {
        alert("تعذر العثور على بيانات السجل");
    }
}

function findNurseName(empNo) {
    if (!empNo) return;
    const nurse = NURSE_LIST.find(n => n.empNo == empNo);
    document.getElementById('n-name').value = nurse ? nurse.empName : "ممرض غير معروف";
}

async function fetchNurses() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/staff/nurses`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` }
        });
        if (res.ok) {
            NURSE_LIST = await res.json();
        }
    } catch (e) { console.error("Error fetching nurses", e); }
}

function openNurseModal() {
    const tbody = document.querySelector('#nurse-list-table tbody');
    tbody.innerHTML = '';
    NURSE_LIST.forEach(n => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${n.empNo}</td><td>${n.empName}</td>`;
        tr.onclick = () => {
            document.getElementById('n-id').value = n.empNo;
            document.getElementById('n-name').value = n.empName;
            closeModal('modal-nurse');
        };
        tbody.appendChild(tr);
    });
    document.getElementById('modal-nurse').style.display = 'block';
}

function openVitalsModal(time) {
    if (!CURRENT_ADMISSION) return alert("اختر مريضاً أولاً");
    if (!document.getElementById('branch-list').value) return alert("يرجى اختيار الفرع");

    CURRENT_DOC_SRL = null;
    SELECTED_TIME = time;

    document.getElementById('vitals-title').innerText = "تسجيل علامات الساعة " + time;

    document.getElementById('v-temp').value = "";
    document.getElementById('v-pulse').value = "";
    document.getElementById('v-resp').value = "";
    document.getElementById('v-spo2').value = "";
    document.getElementById('v-bp1').value = "";
    document.getElementById('v-bp2').value = "";
    document.getElementById('v-notes').value = "";

    document.getElementById('modal-vitals').style.display = 'block';
}

async function saveVitals() {
    let currentMethod = 'POST';
    try {
        const getValue = (id) => parseFloat(document.getElementById(id).value) || 0;

        const isUpdate = CURRENT_DOC_SRL !== null;
        currentMethod = 'POST'; // دائماً POST لتخطي حجب IIS لطريقة PUT

        const dto = {
            docSrl: CURRENT_DOC_SRL ? parseInt(CURRENT_DOC_SRL) : 0,
            branchNo: parseInt(document.getElementById('branch-list').value),
            docNo: document.getElementById('adm-no-input').value.toString(),
            docSrlAdmt: parseInt(CURRENT_ADMISSION.docSrl),
            patientNo: CURRENT_ADMISSION.patientNo,
            age: CURRENT_ADMISSION.age ? CURRENT_ADMISSION.age.toString() : "",
            ageType: parseInt(CURRENT_ADMISSION.ageType) || 0,
            roomNo: parseInt(CURRENT_ADMISSION.roomNo) || 0,
            bedNo: parseInt(CURRENT_ADMISSION.bedNo) || 0,
            roomSer: parseInt(CURRENT_ADMISSION.roomService) || 0,
            buildingNo: parseInt(CURRENT_ADMISSION.buldNo) || 0,
            docTime: `2000-01-01T${SELECTED_TIME}`,
            nurseEmpNo: parseInt(document.getElementById('n-id').value) || 0,
            temperature: getValue('v-temp'),
            pulseRate: getValue('v-pulse'),
            respirationRate: getValue('v-resp'),
            spO2: getValue('v-spo2'),
            bloodPressureOne: getValue('v-bp1'),
            bloodPressureTwo: getValue('v-bp2'),
            notes: document.getElementById('v-notes').value || ""
        };

        // Validate that at least one vital sign or note is provided
        if (!dto.temperature && !dto.pulseRate && !dto.respirationRate && !dto.spO2 && !dto.bloodPressureOne && !dto.bloodPressureTwo && !dto.notes.trim()) {
            alert("⚠️ لا يمكن الحفظ! يجب إدخال علامة حيوية واحدة على الأقل أو كتابة ملاحظة.");
            return; // Stop execution
        }

        const url = isUpdate
            ? `${getBaseApiUrl()}/VitalSigns/update/${CURRENT_DOC_SRL}`
            : `${getBaseApiUrl()}/VitalSigns`;

        const res = await fetch(url, {
            method: currentMethod,
            headers: getHeaders(),
            body: JSON.stringify(dto)
        });

        if (res.ok) {
            alert(isUpdate ? "✅ تم التعديل بنجاح" : "✅ تم الحفظ بنجاح");
            closeModal('modal-vitals');
            CURRENT_DOC_SRL = null;

            loadAndShowTable();
        } else {
            try {
                const jsonErr = await res.json();
                let errorMessages = [];

                // If it's a validation error (400 Bad Request) from ASP.NET Core
                if (jsonErr.errors) {
                    for (const key in jsonErr.errors) {
                        errorMessages.push(`- ${key}: ${jsonErr.errors[key].join(', ')}`);
                    }
                } else if (jsonErr.message) {
                    errorMessages.push(jsonErr.message);
                } else {
                    errorMessages.push(JSON.stringify(jsonErr, null, 2));
                }

                alert(`❌ فشلت العملية (${res.status}):\n${errorMessages.join('\n')}`);
            } catch (e) {
                const errText = await res.text();
                alert(`❌ فشلت العملية (${res.status}):\n${errText}`);
            }
        }
    } catch (error) {
        console.error("Error during fetch:", error);
        alert(`⚠️ خطأ في الاتصال بالسيرفر أثناء عملية الـ ${currentMethod}.\nيرجى التأكد من تشغيل السيرفر أو أن إعدادات CORS تسمح بالـ PUT / POST`);
    }
}

function closeModal(id) { document.getElementById(id).style.display = 'none'; }
