// intake_output.js - Offline First Intake & Output Controller
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

async function loadBranches() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/branches`, {
            method: 'POST',
            headers: getHeaders()
        });
        if (res.ok) {
            const list = await res.json();
            await saveToDB('branches', list);
            renderBranches(list);
        }
    } catch (e) {
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
        const list = await getFromDB('admissions');
        handleFoundAdmission(list, docNo);
    }
}

function handleFoundAdmission(list, docNo) {
    if (!list) { appAlert('خطأ في الاتصال ولا توجد بيانات مخزنة', 'error'); return; }
    const admission = list.find(a => a.docNo == docNo);
    if (admission) selectAdmission(admission.docNo, admission.docSerial);
    else appAlert("رقم الترقيد غير موجود", 'error');
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
        const list = await getFromDB('admissions');
        if (list && list.length > 0) renderAdmissionsTable(list);
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
        const detailsList = await getFromDB('patients_details');
        const details = detailsList.find(d => d.cacheKey === `${no}_${srl}`);
        if (details) {
            CURRENT_ADMISSION = details;
            renderPatientDetails(CURRENT_ADMISSION);
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
    if (!CURRENT_ADMISSION) return appAlert("الرجاء اختيار مريض أولاً", 'warning');

    const docDate = document.getElementById('doc-date-input').value;
    const interval = parseInt(document.getElementById('time-interval').value) || 30;
    const cacheString = `${CURRENT_ADMISSION.docSrl}_${docDate}`;

    let savedData = [];
    try {
        const res = await fetch(`${getBaseApiUrl()}/IntakeOutput/${CURRENT_ADMISSION.docSrl}`, {
            method: 'GET',
            headers: getHeaders()
        });
        if (res.ok) {
            savedData = await res.json();
            await saveToDB('io_history', [{ cacheKey: cacheString, data: savedData }], false);
        } else {
            const err = await res.json();
            appAlert(`فشل تحميل البيانات: ${err.message || 'خطأ غير معروف'}`, 'error');
        }
    } catch (e) {
        console.error("Fetch IO History Error:", e);
        const record = await getFromDB('io_history', cacheString);
        if (record && record.data) savedData = record.data;
    }

    // Inject unsynced
    const unsynced = await getFromDB('unsynced_io');
    if (unsynced) {
        const localItems = unsynced.filter(u => u.dto.docSrlAdmt == CURRENT_ADMISSION.docSrl);
        localItems.forEach(u => {
            const timePart = u.dto.docTime.split('T')[1];
            const existingIndex = savedData.findIndex(d => d.docTime === timePart);
            let localFormat = {
                docSrl: u.dto.docSrl || `local_${u.id}`,
                docTime: timePart,
                nurseEmpNo: u.dto.nurseEmpNo,
                inIvf: u.dto.inIvf, inOral: u.dto.inOral, inNgt: u.dto.inNgt, inBld: u.dto.inBld, inOthr: u.dto.inOthr,
                outUrine: u.dto.outUrine, outGstrc: u.dto.outGstrc, outEmss: u.dto.outEmss, outDrng1: u.dto.outDrng1, outDrng2: u.dto.outDrng2, outOthr: u.dto.outOthr,
                notes: u.dto.notes
            };
            if (existingIndex >= 0) savedData[existingIndex] = localFormat;
            else savedData.push(localFormat);
        });
    }

    lastFetchedData = savedData;

    let totalDayIn = 0;
    let totalDayOut = 0;

    let timeSlots = [];
    for (let totalMin = 1 * 60; totalMin < 24 * 60; totalMin += interval) {
        let h = Math.floor(totalMin / 60);
        let m = totalMin % 60;
        timeSlots.push(`${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:00`);
    }
    // Ensure any data from server not on intervals is shown
    lastFetchedData.forEach(item => { if (item.docTime && !timeSlots.includes(item.docTime)) timeSlots.push(item.docTime); });
    timeSlots.sort();

    const tbody = document.querySelector('#io-table tbody');
    tbody.innerHTML = '';
    timeSlots.forEach(time => {
        const record = lastFetchedData.find(d => d.docTime === time);
        const tr = document.createElement('tr');
        if (record) {
            tr.className = "saved-row";
            if (record.docSrl && record.docSrl.toString().startsWith('local_')) tr.style.borderRight = "5px solid #e67e22";

            const rowSumIn = (record.inIvf || 0) + (record.inOral || 0) + (record.inNgt || 0) + (record.inBld || 0) + (record.inOthr || 0);
            const rowSumOut = (record.outUrine || 0) + (record.outGstrc || 0) + (record.outEmss || 0) + (record.outDrng1 || 0) + (record.outDrng2 || 0) + (record.outOthr || 0);

            totalDayIn += rowSumIn;
            totalDayOut += rowSumOut;

            tr.innerHTML = `
                <td><b>${time}</b></td>
                <td class="intake-cell">${record.inIvf || '-'}</td>
                <td class="intake-cell">${record.inOral || '-'}</td>
                <td class="intake-cell">${record.inNgt || '-'}</td>
                <td class="intake-cell">${record.inBld || '-'}</td>
                <td class="intake-cell">${record.inOthr || '-'}</td>
                <td style="background:#d4e6f1; font-weight:bold;">${rowSumIn > 0 ? rowSumIn.toFixed(1) : '-'}</td>
                <td class="output-cell">${record.outUrine || '-'}</td>
                <td class="output-cell">${record.outGstrc || '-'}</td>
                <td class="output-cell">${record.outDrng1 || '-'}</td>
                <td class="output-cell">${record.outDrng2 || '-'}</td>
                <td class="output-cell">${record.outOthr || '-'}</td>
                <td style="background:#f5cba7; font-weight:bold;">${rowSumOut > 0 ? rowSumOut.toFixed(1) : '-'}</td>
                <td>
                    <div style="display: flex; gap: 2px;">
                        <button class="btn-edit" onclick="openEditModal('${record.docSrl}')">✏️</button>
                        <button class="btn-delete" style="background:#e74c3c; color:white;" onclick="deleteIO('${record.docSrl}')">🗑️</button>
                    </div>
                </td>
            `;
        } else {
            tr.innerHTML = `<td>${time}</td>` + Array(12).fill('<td style="color:#aaa">-</td>').join('') +
                `<td><button class="btn-add" onclick="openIOModal('${time}')">➕</button></td>`;
        }
        tbody.appendChild(tr);
    });

    // Update daily totals in header
    document.getElementById('total-day-in').innerText = ` (إجمالي اليوم: ${totalDayIn.toFixed(1)})`;
    document.getElementById('total-day-out').innerText = ` (إجمالي اليوم: ${totalDayOut.toFixed(1)})`;

    document.getElementById('table-area').style.display = 'block';
}

function openIOModal(time) {
    if (!CURRENT_ADMISSION) return appAlert("اختر مريضاً أولاً", 'warning');
    if (!document.getElementById('branch-list').value) return appAlert("يرجى اختيار الفرع", 'warning');
    CURRENT_DOC_SRL = null;
    SELECTED_TIME = time;
    document.getElementById('io-title').innerText = "سجل السوائل - الساعة " + time;
    const ids = ['in-ivf', 'in-oral', 'in-ngt', 'in-bld', 'in-othr', 'out-urine', 'out-gstrc', 'out-drng1', 'out-drng2', 'out-emss', 'out-othr', 'n-id', 'n-name', 'io-notes'];
    ids.forEach(id => document.getElementById(id).value = "");
    document.getElementById('modal-io').style.display = 'block';
}

function openEditModal(docSrl) {
    CURRENT_DOC_SRL = docSrl;
    const record = lastFetchedData.find(d => d.docSrl == docSrl);
    if (record) {
        SELECTED_TIME = record.docTime;
        document.getElementById('io-title').innerText = "تعديل سجل السوائل - الساعة " + SELECTED_TIME;
        document.getElementById('in-ivf').value = record.inIvf || "";
        document.getElementById('in-oral').value = record.inOral || "";
        document.getElementById('in-ngt').value = record.inNgt || "";
        document.getElementById('in-bld').value = record.inBld || "";
        document.getElementById('in-othr').value = record.inOthr || "";
        document.getElementById('out-urine').value = record.outUrine || "";
        document.getElementById('out-gstrc').value = record.outGstrc || "";
        document.getElementById('out-drng1').value = record.outDrng1 || "";
        document.getElementById('out-drng2').value = record.outDrng2 || "";
        document.getElementById('out-emss').value = record.outEmss || "";
        document.getElementById('out-othr').value = record.outOthr || "";
        document.getElementById('n-id').value = record.nurseEmpNo || "";
        findNurseName(record.nurseEmpNo);
        document.getElementById('io-notes').value = record.notes || "";
        document.getElementById('modal-io').style.display = 'block';
    }
}

async function fetchNurses() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/staff/nurses`, { method: 'POST', headers: getHeaders() });
        if (res.ok) { NURSE_LIST = await res.json(); await saveToDB('nurses', NURSE_LIST); }
    } catch (e) { NURSE_LIST = await getFromDB('nurses') || []; }
}

function findNurseName(empNo) {
    if (!empNo) return;
    const nurse = NURSE_LIST.find(n => n.empNo == empNo);
    document.getElementById('n-name').value = nurse ? nurse.empName : "غير معروف";
}

function openNurseModal() {
    const tbody = document.querySelector('#nurse-list-table tbody');
    tbody.innerHTML = '';
    NURSE_LIST.forEach(n => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${n.empNo}</td><td>${n.empName}</td>`;
        tr.onclick = () => { document.getElementById('n-id').value = n.empNo; document.getElementById('n-name').value = n.empName; closeModal('modal-nurse'); };
        tbody.appendChild(tr);
    });
    document.getElementById('modal-nurse').style.display = 'block';
}

async function saveIO() {
    const getValue = (id) => parseFloat(document.getElementById(id).value) || 0;
    const isUpdate = CURRENT_DOC_SRL !== null && !CURRENT_DOC_SRL.toString().startsWith('local_');

    const dto = {
        docSrl: isUpdate ? parseInt(CURRENT_DOC_SRL) : 0,
        branchNo: parseInt(document.getElementById('branch-list').value),
        docNo: document.getElementById('adm-no-input').value.toString(),
        docSrlAdmt: parseInt(CURRENT_ADMISSION.docSrl),
        patientNo: CURRENT_ADMISSION.patientNo,
        age: CURRENT_ADMISSION.age || "",
        ageType: parseInt(CURRENT_ADMISSION.ageType) || 0,
        roomNo: parseInt(CURRENT_ADMISSION.roomNo) || 0,
        bedNo: parseInt(CURRENT_ADMISSION.bedNo) || 0,
        roomSer: parseInt(CURRENT_ADMISSION.roomService) || 0,
        buildingNo: parseInt(CURRENT_ADMISSION.buldNo) || 0,
        docTime: `2000-01-01T${SELECTED_TIME}`,
        nurseEmpNo: parseInt(document.getElementById('n-id').value) || 0,
        inIvf: getValue('in-ivf'), inOral: getValue('in-oral'), inNgt: getValue('in-ngt'), inBld: getValue('in-bld'), inOthr: getValue('in-othr'),
        outUrine: getValue('out-urine'), outGstrc: getValue('out-gstrc'), outEmss: getValue('out-emss'), outDrng1: getValue('out-drng1'), outDrng2: getValue('out-drng2'), outOthr: getValue('out-othr'),
        notes: document.getElementById('io-notes').value || ""
    };

    const url = isUpdate ? `${getBaseApiUrl()}/IntakeOutput/update` : `${getBaseApiUrl()}/IntakeOutput/add`;

    if (!navigator.onLine) {
        if (CURRENT_DOC_SRL && CURRENT_DOC_SRL.toString().startsWith('local_')) {
            await updateUnsyncedIO(parseInt(CURRENT_DOC_SRL.replace('local_', '')), dto);
        } else {
            await addUnsyncedIO(url, 'POST', dto, isUpdate);
        }
        appAlert("تم الحفظ محلياً", 'warning');
        closeModal('modal-io');
        loadAndShowTable();
        return;
    }

    try {
        const res = await fetch(url, {
            method: 'POST',
            headers: getHeaders(),
            body: JSON.stringify(dto)
        });
        if (res.ok) {
            appAlert("تم الحفظ بنجاح", 'success');
            closeModal('modal-io');
            loadAndShowTable();
        } else {
            const errJson = await res.json();
            appAlert(`فشل الحفظ: ${errJson.message || "خطأ غير معروف"}`, 'error');
        }
    } catch (e) {
        console.error("Save IO Error:", e);
        await addUnsyncedIO(url, 'POST', dto, isUpdate);
        appAlert("تم الحفظ محلياً (خطأ شبكة)", 'warning');
        closeModal('modal-io');
        loadAndShowTable();
    }
}

async function deleteIO(docSrl) {
    if (!confirm("هل أنت متأكد؟")) return;
    if (docSrl.toString().startsWith('local_')) {
        await removeUnsyncedIO(parseInt(docSrl.replace('local_', '')));
        loadAndShowTable();
        return;
    }
    try {
        const res = await fetch(`${getBaseApiUrl()}/IntakeOutput/${docSrl}`, { method: 'DELETE', headers: getHeaders() });
        if (res.ok) { appAlert("تم الحذف", 'success'); loadAndShowTable(); }
    } catch (e) { appAlert("فشل الحذف (أوفلاين)", 'error'); }
}

function closeModal(id) { document.getElementById(id).style.display = 'none'; }
