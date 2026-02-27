// vitals.js - Offline First Vitals Controller
let NURSE_LIST = [];
let CURRENT_ADMISSION = null;
let SELECTED_TIME = "";
let lastFetchedData = [];
let CURRENT_DOC_SRL = null;

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();

    const now = new Date();
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    if (document.getElementById('cur-day')) document.getElementById('cur-day').innerText = days[now.getDay()];

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    if (document.getElementById('cur-date')) document.getElementById('cur-date').innerText = `${year}/${month}/${day}`;
    if (document.getElementById('doc-date-input')) document.getElementById('doc-date-input').value = `${year}-${month}-${day}`;

    initData();

    document.getElementById('adm-no-input')?.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === 'Tab') {
            searchAdmission(e.target.value);
            e.preventDefault();
        }
    });

    document.getElementById('n-id')?.addEventListener('keydown', (e) => {
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
            headers: getHeaders()
        });
        if (!res.ok) {
            if (res.status === 401) logout();
            throw new Error('Network issues');
        }
        const list = await res.json();
        await saveToDB('branches', list);
        renderBranches(list);
    } catch (e) {
        console.warn('استخدام فروع الكاش المحلي');
        const list = await getFromDB('branches');
        renderBranches(list);
    }
}

function renderBranches(list) {
    const select = document.getElementById('branch-list');
    if (!select) return;
    select.innerHTML = '<option value="">اختر الفرع...</option>';
    if (list) list.forEach(b => select.add(new Option(b.branchName, b.branchNo)));
}

async function searchAdmission(docNo) {
    if (!docNo) return;
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
            method: 'POST',
            headers: getHeaders()
        });
        const list = await res.json();
        await saveToDB('admissions', list);
        handleFoundAdmission(list, docNo);
    } catch (e) {
        console.warn('Offline mode for searchAdmission');
        const list = await getFromDB('admissions');
        handleFoundAdmission(list, docNo);
    }
}

function handleFoundAdmission(list, docNo) {
    if (!list) { alert('خطأ في الاتصال ولا توجد بيانات مخزنة'); return; }
    const admission = list.find(a => a.docNo == docNo);
    if (admission) selectAdmission(admission.docNo, admission.docSerial);
    else alert("رقم الترقيد غير موجود");
}

async function openAdmModal() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
            method: 'POST',
            headers: getHeaders()
        });
        const list = await res.json();
        await saveToDB('admissions', list);
        renderAdmissionsTable(list);
    } catch (e) {
        console.warn('Offline mode for admissions modal');
        const list = await getFromDB('admissions');
        if (list && list.length > 0) renderAdmissionsTable(list);
        else alert("لا يتوفر اتصال بالإنترنت ولا توجد بيانات سابقة لترقيدات المرضى");
    }
}

function renderAdmissionsTable(list) {
    const tbody = document.querySelector('#adm-list-table tbody');
    tbody.innerHTML = '';
    list.forEach(a => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${a.docNo}</td><td>${new Date(a.date).toLocaleDateString()}</td><td>${a.patientName}</td>`;
        tr.onclick = () => { selectAdmission(a.docNo, a.docSerial); closeModal('modal-adm'); };
        tbody.appendChild(tr);
    });
    document.getElementById('modal-adm').style.display = 'block';
}

async function selectAdmission(no, srl) {
    document.getElementById('adm-no-input').value = no;
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions/details?docNo=${no}&docSrl=${srl}`, {
            method: 'POST',
            headers: getHeaders()
        });
        const details = await res.json();

        CURRENT_ADMISSION = { ...details, docNo: no, docSrl: srl, cacheKey: `${no}_${srl}` };
        await saveToDB('patients_details', [CURRENT_ADMISSION], false);
        renderPatientDetails(CURRENT_ADMISSION);

    } catch (e) {
        console.warn("Offline fetching patient details");
        const detailsList = await getFromDB('patients_details');
        const details = detailsList.find(d => d.cacheKey === `${no}_${srl}`);
        if (details) {
            CURRENT_ADMISSION = details;
            renderPatientDetails(CURRENT_ADMISSION);
        } else {
            alert("لا يتوفر اتصال بالإنترنت وليس لديك بيانات هذا المريض مخزنة محلياً");
        }
    }
}

function renderPatientDetails(details) {
    document.getElementById('p-name').value = details.patientName || details.patientNo;
    document.getElementById('p-no').value = details.patientNo;
    document.getElementById('p-age').value = details.age;
    document.getElementById('p-room').value = details.roomNo;
    document.getElementById('p-bed').value = details.bedNo;
    document.getElementById('p-gender').value = details.gender == 1 ? "ذكر" : "أنثى";
    document.getElementById('table-area').style.display = 'none';
}

async function loadAndShowTable() {
    if (!CURRENT_ADMISSION) return alert("الرجاء اختيار مريض أولاً");

    const docDate = document.getElementById('doc-date-input').value;
    const interval = parseInt(document.getElementById('time-interval').value) || 30;
    const cacheString = `${CURRENT_ADMISSION.patientNo}_${docDate}`;

    let savedData = [];
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/history?patientNo=${CURRENT_ADMISSION.patientNo}&date=${docDate}`, {
            method: 'GET',
            headers: getHeaders()
        });

        if (!res.ok) {
            if (res.status == 401) return logout();
            throw new Error();
        }

        savedData = await res.json();
        // Save to DB in separate try-catch so failing to save locally doesn't clear the table
        try {
            await saveToDB('vitals_history', [{ cacheKey: cacheString, data: savedData }], false);
        } catch (dbErr) {
            console.error("Local caching failed", dbErr);
        }

    } catch (e) {
        console.warn("Offline loading history");
        try {
            const record = await getFromDB('vitals_history', cacheString);
            if (record && record.data) {
                savedData = record.data;
            }
        } catch (dbErr) {
            console.error("Error reading cache", dbErr);
        }
    }

    // Now inject any unsynced local changes dynamically so user sees them offline!
    const unsynced = await getFromDB('unsynced_vitals');
    if (unsynced && unsynced.length > 0) {
        // filter unsynced items belonging to this patient and date
        const localItems = unsynced.filter(u => u.dto.patientNo == CURRENT_ADMISSION.patientNo && u.dto.docTime.startsWith(`2000-01-01T`));
        localItems.forEach(u => {
            const timePart = u.dto.docTime.split('T')[1];
            // Override or push into saved data
            const existingIndex = savedData.findIndex(d => d.docTime && d.docTime.split('T')[1] === timePart);
            let localFormat = {
                docSrl: u.dto.docSrl || `local_${u.id}`,
                docTime: u.dto.docTime,
                temperature: u.dto.temperature,
                pulseRate: u.dto.pulseRate,
                respirationRate: u.dto.respirationRate,
                spO2: u.dto.spO2,
                bloodPressureOne: u.dto.bloodPressureOne,
                bloodPressureTwo: u.dto.bloodPressureTwo,
                nurseEmpNo: u.dto.nurseEmpNo,
                notes: u.dto.notes
            };
            if (existingIndex >= 0) savedData[existingIndex] = localFormat;
            else savedData.push(localFormat);
        });
    }

    lastFetchedData = Array.isArray(savedData) ? savedData : [];

    // UI processing for table
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
            if (record.docSrl && record.docSrl.toString().startsWith('local_')) tr.style.borderRight = "5px solid #e67e22"; // highlight unsynced

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
            headers: getHeaders()
        });
        if (res.ok) {
            NURSE_LIST = await res.json();
            await saveToDB('nurses', NURSE_LIST);
        }
    } catch (e) {
        console.warn("Offline fallback for nurses");
        NURSE_LIST = await getFromDB('nurses') || [];
    }
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

        // If docSrl contains local_, it means it's an offline generated ID that hasn't synced yet, 
        // we can't do a real PUT update on server. We treat it as POST/Offline re-update.
        const isActuallyLocal = CURRENT_DOC_SRL && CURRENT_DOC_SRL.toString().startsWith('local_');
        const isUpdate = CURRENT_DOC_SRL !== null && !isActuallyLocal;

        currentMethod = 'POST';

        const dto = {
            docSrl: isUpdate ? parseInt(CURRENT_DOC_SRL) : 0,
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

        if (!dto.temperature && !dto.pulseRate && !dto.respirationRate && !dto.spO2 && !dto.bloodPressureOne && !dto.bloodPressureTwo && !dto.notes.trim()) {
            alert("⚠️ لا يمكن الحفظ! يجب إدخال علامة حيوية واحدة على الأقل أو كتابة ملاحظة.");
            return;
        }

        const url = isUpdate
            ? `${getBaseApiUrl()}/VitalSigns/update/${CURRENT_DOC_SRL}`
            : `${getBaseApiUrl()}/VitalSigns`;

        if (!navigator.onLine) {
            // OfFLINE SAVING
            await addUnsyncedVital(url, currentMethod, dto, isUpdate);
            alert("⚠️ لا يتوفر اتصال بالإنترنت. يرجى العلم أنه تم حفظ القيم في هاتفك مؤقتاً وسيتم مزامنتها لاحقاً عند توفر الشبكة.");
            closeModal('modal-vitals');
            CURRENT_DOC_SRL = null;
            checkSyncStatus();
            loadAndShowTable();
            return;
        }

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
                if (jsonErr.errors) {
                    for (const key in jsonErr.errors) { errorMessages.push(`- ${key}: ${jsonErr.errors[key].join(', ')}`); }
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
        console.error("Fetch/Sync error:", error);
        alert(`⚠️ خطأ في الاتصال بالسيرفر. يرجى تفعيل وضع الانترنت للمزامنة الفورية.`);
    }
}

function closeModal(id) { document.getElementById(id).style.display = 'none'; }
