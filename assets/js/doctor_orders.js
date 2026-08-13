// doctor_orders.js
window.openHistoryModal = openHistoryModal; // Explicitly attach to window to avoid "not defined" errors

let CURRENT_ADMISSION = null;
let CACHED_ITEMS = [];
let CURRENT_ROW_TO_POPULATE = null;
let DETAIL_ROWS_COUNT = 0;
let CURRENT_ORDER_SRL = null;
let IS_EDIT_MODE = false;
let CACHED_HISTORY = [];

// Helper to safely set values on elements that might be missing from DOM
const setVal = (id, val) => { const el = document.getElementById(id); if (el) el.value = val; };
const getVal = (id) => { const el = document.getElementById(id); return el ? el.value : ""; };
const getInt = (id) => parseInt(getVal(id)) || 0;

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();

    const now = new Date();
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    if (document.getElementById('cur-day')) document.getElementById('cur-day').innerText = days[now.getDay()];

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');

    if (document.getElementById('cur-date')) document.getElementById('cur-date').innerText = `${year}/${month}/${day}`;
    if (document.getElementById('doc-date')) document.getElementById('doc-date').value = `${year}-${month}-${day}`;

    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    const ss = String(now.getSeconds()).padStart(2, '0');
    if (document.getElementById('doc-time')) document.getElementById('doc-time').value = `${hh}:${mm}:${ss}`;

    loadBranches();
    loadProcedureTypes().then(() => {
        loadUsageMethods();
        if (navigator.onLine) preloadAllItems();
    });

    document.getElementById('adm-no-input')?.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === 'Tab') {
            searchAdmission(e.target.value);
            e.preventDefault();
        }
    });

    window.onclick = function (event) {
        if (event.target.classList.contains('modal')) {
            event.target.style.display = "none";
        }
    }

    onProcedureTypeChanged();
    updateUIForState('INIT'); // عند تحميل الصفحة: زر الإضافة فعّال دائماً

    // Auto-select patient if coming from patient-dashboard
    const savedPatient = localStorage.getItem('selected_patient');
    if (savedPatient) {
        try {
            const details = JSON.parse(savedPatient);
            document.getElementById('branch-list').value = details.branchNo || "";
            document.getElementById('adm-no-input').value = details.docNo;
            selectAdmission(details.docNo, details.docSerial || details.docSrl);
            updateUIForState('NEW'); // Prepare for a new order for this patient
            localStorage.removeItem('selected_patient');
        } catch (e) { console.error("Error loading saved patient", e); }
    }
});

function goBack() {
    if (CURRENT_ADMISSION) {
        localStorage.setItem('selected_patient', JSON.stringify(CURRENT_ADMISSION));
    }
    if (window.history.length > 1) {
        window.history.back();
    } else {
        window.location.href = 'index.html';
    }
}

function updateUIForState(state) {
    const btnAdd = document.getElementById('btn-add');
    const btnEdit = document.getElementById('btn-edit');
    const btnDelete = document.getElementById('btn-delete');
    const btnSave = document.getElementById('btn-save');
    const inputs = document.querySelectorAll('.main-content input, .main-content select, .main-content textarea');
    const innerButtons = document.querySelectorAll('.main-content button:not(#btn-add):not(#btn-edit):not(#btn-delete):not(#btn-search-orders):not(#btn-save)');

    if (state === 'INIT') {
        // الحالة الابتدائية: زر الإضافة فعّال، باقي أزرار العمل معطّلة
        IS_EDIT_MODE = false;
        CURRENT_ORDER_SRL = null;
        if (btnAdd) { btnAdd.disabled = false; }
        if (btnEdit) btnEdit.disabled = true;
        if (btnDelete) btnDelete.disabled = true;
        if (btnSave) btnSave.disabled = true;
        inputs.forEach(i => i.disabled = true);
        innerButtons.forEach(b => b.disabled = true);
    } else if (state === 'NEW') {
        // المستخدم ضغط على إضافة: زر الإضافة يصبح باهتاً
        IS_EDIT_MODE = false;
        CURRENT_ORDER_SRL = null;
        if (btnAdd) btnAdd.disabled = true;
        if (btnEdit) btnEdit.disabled = true;
        if (btnDelete) btnDelete.disabled = true;
        if (btnSave) btnSave.disabled = false;
        inputs.forEach(i => {
            if (!i.readOnly && i.style.backgroundColor !== 'rgb(238, 238, 238)') {
                i.disabled = false;
            }
        });
        innerButtons.forEach(b => b.disabled = false);
    } else if (state === 'VIEW') {
        IS_EDIT_MODE = false;
        if (btnAdd) btnAdd.disabled = false;
        if (btnEdit) btnEdit.disabled = false;
        if (btnDelete) btnDelete.disabled = false;
        if (btnSave) btnSave.disabled = true;
        inputs.forEach(i => i.disabled = true);
        innerButtons.forEach(b => b.disabled = true);
    } else if (state === 'EDIT') {
        IS_EDIT_MODE = true;
        if (btnAdd) btnAdd.disabled = true;
        if (btnEdit) btnEdit.disabled = true;
        if (btnDelete) btnDelete.disabled = true;
        if (btnSave) btnSave.disabled = false;
        inputs.forEach(i => {
            if (i.id !== 'adm-no-input' && i.id !== 'doc-no' && i.id !== 'prcdr-typ') {
                i.disabled = false;
            }
        });
        innerButtons.forEach(b => b.disabled = false);
        // زر البحث عن الترقيد يتم تعطيله لأن رقم الترقيد غير قابل للتعديل
        const admSearchBtn = document.querySelector('.section-search button');
        if (admSearchBtn) admSearchBtn.disabled = true;
    }
}

function addNewOrder() {
    document.getElementById('doc-no').value = '1';
    document.getElementById('doc-dsc').value = '';
    document.getElementById('ref-no').value = '';
    document.getElementById('adm-no-input').value = '';
    document.getElementById('patient-info-section').style.display = 'none';
    document.getElementById('table-area').style.display = 'none';
    CURRENT_ADMISSION = null;

    document.getElementById('prcdr-typ').value = ""; // Default empty
    onProcedureTypeChanged(); // Will clear table area
    updateUIForState('NEW');

    // Focus on admission input first since it's the first step usually
    document.getElementById('adm-no-input').focus();
}

function enableEditing() {
    updateUIForState('EDIT');
}

async function deleteOrder() {
    if (!CURRENT_ORDER_SRL) return;
    const confirmed = await appConfirm("هل أنت متأكد من حذف هذا السجل؟");
    if (!confirmed) return;

    try {
        const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/${CURRENT_ORDER_SRL}`, {
            method: 'DELETE',
            headers: getHeaders()
        });
        if (res.ok) {
            const result = await res.json();
            appAlert(result.message, 'success');
            addNewOrder();
        } else {
            const err = await res.json();
            appAlert(err.message || "فشل الحذف", 'error');
        }
    } catch (e) {
        appAlert("خطأ في الاتصال بالسيرفر", 'error');
    }
}

async function openHistoryModal() {
    try {
        let history = [];
        try {
            const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/history`, {
                method: 'GET',
                headers: getHeaders()
            });
            if (res.ok) {
                history = await res.json();
            }
        } catch (e) {
            console.warn("Offline, loading local only");
        }

        const unsynced = await getFromDB('unsynced_doctor_orders') || [];
        const localHistory = unsynced.map(item => ({
            docSrl: `local_${item.id}`,
            docNo: item.dto.docNo + ' (معلق)',
            docDate: item.dto.docDate,
            procedureTypeName: item.dto.procedureType === 1 ? 'أدوية' : item.dto.procedureType === 2 ? 'فحوصات' : item.dto.procedureType === 3 ? 'أشعة' : item.dto.procedureType === 4 ? 'عمليات' : item.dto.procedureType === 5 ? 'إجراءات أخرى' : item.dto.procedureType === 6 ? 'معاينة' : 'إجراءات أخرى',
            doctorName: item.dto.doctorNo,
            patientName: item.dto.patientNo || 'مريض غير معروف',
            isLocal: true
        }));

        CACHED_HISTORY = [...localHistory, ...history];

        CACHED_HISTORY.sort((a, b) => {
            const srlA = a.docSrl.toString().startsWith('local_') ? 9999999999 : parseInt(a.docSrl);
            const srlB = b.docSrl.toString().startsWith('local_') ? 9999999999 : parseInt(b.docSrl);
            return srlB - srlA;
        });

        renderHistory(CACHED_HISTORY);
        document.getElementById('modal-history').style.display = 'block';
    } catch (e) {
        console.error(e);
        appAlert("خطأ في جلب بيانات السجل", 'error');
    }
}

function renderHistory(list) {
    const tbody = document.querySelector('#history-list-table tbody');
    tbody.innerHTML = '';
    list.forEach(item => {
        let tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${item.docNo}</td>
            <td>${item.docDate}</td>
            <td>${item.procedureTypeName}</td>
            <td>${item.doctorName}</td>
            <td>${item.patientName}</td>
        `;
        tr.onclick = () => loadOrder(item.docSrl);
        tbody.appendChild(tr);
    });
}

function filterHistory() {
    const term = document.getElementById('history-search-input').value.toLowerCase();
    const filtered = CACHED_HISTORY.filter(i =>
        Object.values(i).some(val => val && val.toString().toLowerCase().includes(term))
    );
    renderHistory(filtered);
}

async function loadOrder(docSrl) {
    try {
        closeModal('modal-history');
        let data = null;

        if (docSrl.toString().startsWith('local_')) {
            const localId = parseInt(docSrl.toString().replace('local_', ''));
            const record = await getFromDB('unsynced_doctor_orders', localId);
            if (record) {
                data = {
                    master: {
                        ...record.dto,
                        docDate: record.dto.docDate,
                        docTime: record.dto.docTime.split('T')[1]
                    },
                    details: record.dto.details
                };
            }
        } else {
            const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/details/${docSrl}`, {
                method: 'GET',
                headers: getHeaders()
            });
            if (res.ok) {
                data = await res.json();
            } else {
                let errData = {}; try { errData = await res.json(); } catch (e) { }
                appAlert("فشل تحميل تفاصيل السجل: " + (errData.message || res.statusText || res.status), 'error');
                return;
            }
        }

        if (data) {
            const m = data.master;
            CURRENT_ORDER_SRL = docSrl;

            document.getElementById('branch-list').value = m.branchNo;
            document.getElementById('adm-no-input').value = m.docNoAdmission;
            document.getElementById('doc-no').value = m.docNo;
            document.getElementById('doc-date').value = m.docDate;

            const timePart = (m.docTime || '').substring(0, 8);
            document.getElementById('doc-time').value = timePart;
            document.getElementById('prcdr-typ').value = m.procedureType;
            document.getElementById('prorty-no').value = m.priorityNo || 1;
            document.getElementById('doc-dsc').value = m.notes || '';
            document.getElementById('ref-no').value = m.refNo || '';

            document.getElementById('patient-no').value = m.patientNo;
            document.getElementById('patient-name').value = m.patientName || '';
            document.getElementById('doctor-no').value = m.doctorNo || '';
            document.getElementById('doctor-name').value = m.doctorName || '';
            document.getElementById('p-room').value = m.roomNo || '';
            document.getElementById('p-bed').value = m.bedNo || '';
            document.getElementById('p-dept').value = m.deptNo || '';
            setVal('p-gender', m.gender == 1 ? "ذكر" : "أنثى");
            setVal('p-age', m.age || '');
            setVal('p-adm-date', m.admDate || '');

            // Important: Populate CURRENT_ADMISSION so saveOrder works correctly for edits
            CURRENT_ADMISSION = {
                docNo: m.docNoAdmission,
                docSrl: m.docSrlAdmission || 0,
                patientNo: m.patientNo,
                patientName: m.patientName,
                roomNo: m.roomNo,
                bedNo: m.bedNo,
                deptNo: m.deptNo,
                buldNo: m.buildNo,
                roomService: m.roomSer,
                gender: m.gender,
                age: m.age,
                ageType: m.ageType,
                dctrNo: m.doctorNo
            };

            document.getElementById('patient-info-section').style.display = 'block';
            document.getElementById('table-area').style.display = 'block';

            onProcedureTypeChanged();
            const tbody = document.getElementById('details-tbody');
            tbody.innerHTML = '';
            DETAIL_ROWS_COUNT = 0;

            const procedureType = parseInt(m.procedureType);
            data.details.forEach(det => {
                DETAIL_ROWS_COUNT++;
                const rowId = DETAIL_ROWS_COUNT;
                const tr = document.createElement('tr');
                tr.id = `detail-row-${rowId}`;

                const expectedDateFormatted = det.expectedDate ? det.expectedDate.split('T')[0] : '';
                const codeVal = det.itemCode || det.I_CODE || '';
                const nameVal = det.itemName || det.I_NAME || '';

                if (procedureType === 2) {
                    tr.innerHTML = `
                        <td><div class="input-with-btn"><button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button><input type="text" id="row-code-${rowId}" value="${codeVal}" readonly></div></td>
                        <td><input type="text" id="row-name-${rowId}" value="${nameVal}" readonly></td>
                        <td><input type="number" id="row-price-${rowId}" value="${det.price || det.PRICE || 0}" readonly></td>
                        <td><input type="text" id="row-unit-${rowId}" value="${det.unit || det.UNIT || ''}" readonly></td>
                        <td><input type="number" id="row-qty-${rowId}" value="${det.quantity || det.I_QTY || 1}"></td>
                        <td><input type="date" id="row-date-${rowId}" value="${expectedDateFormatted}"></td>
                        <td><input type="text" id="row-note-${rowId}" value="${det.notes || det.DOC_DSC_DTL || ''}"></td>
                        <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
                    `;
                } else if (procedureType === 3) {
                    tr.innerHTML = `
                        <td><div class="input-with-btn"><button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button><input type="text" id="row-code-${rowId}" value="${codeVal}" readonly></div></td>
                        <td><input type="text" id="row-name-${rowId}" value="${nameVal}" readonly></td>
                        <td><input type="number" id="row-price-${rowId}" value="${det.price || det.PRICE || 0}" readonly></td>
                        <td><input type="number" id="row-qty-${rowId}" value="${det.quantity || det.I_QTY || 1}"></td>
                        <td><input type="date" id="row-date-${rowId}" value="${expectedDateFormatted}"></td>
                        <td><input type="text" id="row-note-${rowId}" value="${det.notes || det.DOC_DSC_DTL || ''}"></td>
                        <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
                    `;
                } else if (procedureType === 1) {
                    tr.innerHTML = `
                        <td><div class="input-with-btn"><button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button><input type="text" id="row-code-${rowId}" value="${codeVal}"></div></td>
                        <td><input type="text" id="row-name-${rowId}" value="${nameVal}"></td>
                        <td><input type="number" id="row-price-${rowId}" value="${det.price || det.PRICE || 0}"></td>
                        <td><input type="text" id="row-unit-${rowId}" value="${det.unit || det.UNIT || ''}"></td>
                        <td><input type="number" id="row-qty-${rowId}" value="${det.quantity || det.I_QTY || 1}"></td>
                        <td>
                            <div class="input-with-btn">
                                <button class="mini-search-btn" onclick="openUsagesModal(${rowId})">🔍</button>
                                <input type="text" id="row-use-${rowId}" value="${det.useDesc || ''}" data-mthduse="${det.mthdUse || ''}" oninput="this.removeAttribute('data-mthduse')">
                            </div>
                        </td>
                        <td><input type="number" id="row-duration-${rowId}" value="${det.durtion || ''}" style="width:70px;"></td>
                        <td>
                            <select id="row-durtyp-${rowId}" style="width:80px;">
                                <option value="">-- اختر --</option>
                                <option value="1" ${det.durTyp == 1 ? 'selected' : ''}>يوم</option>
                                <option value="2" ${det.durTyp == 2 ? 'selected' : ''}>شهر</option>
                                <option value="3" ${det.durTyp == 3 ? 'selected' : ''}>سنة</option>
                            </select>
                        </td>
                        <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
                    `;
                } else {
                    tr.innerHTML = `
                        <td><div class="input-with-btn"><button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button><input type="text" id="row-code-${rowId}" value="${codeVal}"></div></td>
                        <td><input type="text" id="row-name-${rowId}" value="${nameVal}"></td>
                        <td><input type="number" id="row-price-${rowId}" value="${det.price || det.PRICE || 0}"></td>
                        <td><input type="number" id="row-qty-${rowId}" value="${det.quantity || det.I_QTY || 1}"></td>
                        <td><input type="text" id="row-note-${rowId}" value="${det.notes || det.DOC_DSC_DTL || ''}"></td>
                        <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
                    `;
                }
                tbody.appendChild(tr);
            });
            addNewDetailRow();
            updateUIForState('VIEW');
        }
    } catch (e) {
        console.error(e);
        appAlert("خطأ في الاتصال بالسيرفر: " + e.message, 'error');
    }
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
        } else {
            throw new Error('API Error');
        }
    } catch (e) {
        console.warn('Offline: Loading branches from DB');
        const list = await getFromDB('branches') || [];
        renderBranches(list);
    }
}

function renderBranches(list) {
    const select = document.getElementById('branch-list');
    if (!select) return;
    select.innerHTML = '<option value="">اختر الفرع...</option>';
    if (list) {
        list.forEach(b => select.add(new Option(b.branchName, b.branchNo)));

        // Auto-select the branch from localStorage
        const savedBranch = localStorage.getItem('last_u_brn');
        if (savedBranch) {
            select.value = savedBranch;
        } else if (list.length === 1) {
            select.value = list[0].branchNo;
        }
    }
}

async function loadProcedureTypes() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/procedure-types`, {
            method: 'GET',
            headers: getHeaders()
        });
        if (res.ok) {
            const list = await res.json();
            localStorage.setItem('procedure_types', JSON.stringify(list));
            renderProcedureTypes(list);
        } else {
            throw new Error('API Error');
        }
    } catch (e) {
        console.warn('Offline: Loading procedure types from localStorage', e);
        const stored = localStorage.getItem('procedure_types');
        const list = stored ? JSON.parse(stored) : [];
        renderProcedureTypes(list);
    }
}

function renderProcedureTypes(list) {
    const select = document.getElementById('prcdr-typ');
    if (!select) return;

    const curVal = select.value;
    select.innerHTML = '<option value="">-- اختر النوع --</option>';
    if (list && list.length > 0) {
        list.forEach(p => {
            select.add(new Option(`${p.procedureType}- ${p.procedureTypeName}`, p.procedureType));
        });
    }

    if (curVal) {
        select.value = curVal;
    }
}

let CACHED_USAGES = [];
window.openUsagesModal = openUsagesModal;
window.filterUsages = filterUsages;

async function loadUsageMethods() {
    try {
        const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/usage-methods`, {
            method: 'GET',
            headers: getHeaders()
        });
        if (res.ok) {
            const list = await res.json();
            localStorage.setItem('usage_methods', JSON.stringify(list));
            CACHED_USAGES = list;
        } else {
            throw new Error('API Error');
        }
    } catch (e) {
        console.warn('Offline: Loading usage methods from localStorage', e);
        const stored = localStorage.getItem('usage_methods');
        CACHED_USAGES = stored ? JSON.parse(stored) : [];
    }
}

function openUsagesModal(rowId) {
    CURRENT_ROW_TO_POPULATE = rowId;
    document.getElementById('modal-usages').style.display = 'block';
    renderUsagesFilter(CACHED_USAGES);
}

function filterUsages() {
    const term = document.getElementById('usage-search-input').value.toLowerCase();
    const filtered = CACHED_USAGES.filter(i =>
        (i.codeNo && i.codeNo.toString().toLowerCase().includes(term)) ||
        (i.codeName && i.codeName.toLowerCase().includes(term))
    );
    renderUsagesFilter(filtered);
}

function renderUsagesFilter(list) {
    const tbody = document.getElementById('usages-tbody');
    tbody.innerHTML = '';

    const limit = list.slice(0, 100);
    limit.forEach(i => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${i.codeNo}</td><td>${i.codeName}</td>`;
        tr.onclick = () => selectUsage(i);
        tbody.appendChild(tr);
    });
}

function selectUsage(usageData) {
    if (!CURRENT_ROW_TO_POPULATE) return;
    const rId = CURRENT_ROW_TO_POPULATE;

    const useInput = document.getElementById(`row-use-${rId}`);
    if (useInput) {
        useInput.value = usageData.codeName || '';
        useInput.dataset.mthduse = usageData.codeNo || '';
    }

    closeModal('modal-usages');
}

async function searchAdmission(docNo) {
    if (!docNo) return;
    try {
        const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions`, {
            method: 'POST',
            headers: getHeaders()
        });
        if (res.ok) {
            const list = await res.json();
            await saveToDB('admissions', list);
            handleFoundAdmission(list, docNo);
        } else {
            throw new Error('API Error');
        }
    } catch (e) {
        console.warn('Offline: Searching admissions from DB');
        const list = await getFromDB('admissions') || [];
        handleFoundAdmission(list, docNo);
    }
}

function handleFoundAdmission(list, docNo) {
    const admission = list.find(a => a.docNo == docNo);
    if (admission) selectAdmission(admission.docNo, admission.docSerial);
    else appAlert("رقم الترقيد غير موجود", 'error');
}

async function openAdmModal() {
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
                throw new Error("HTTP " + res.status);
            }
        } catch (e) {
            console.warn("Offline: Fetching admissions from DB for modal");
            list = await getFromDB('admissions') || [];
        }

        window.CURRENT_ADM_LIST = list;
        const tbody = document.querySelector('#adm-list-table tbody');
        tbody.innerHTML = '';
        list.forEach(a => {
            let tr = document.createElement('tr');
            tr.innerHTML = `<td>${a.docNo}</td><td>${new Date(a.date).toLocaleDateString()}</td><td>${a.patientName}</td>`;
            tr.onclick = () => { selectAdmission(a.docNo, a.docSerial); closeModal('modal-adm'); };
            tbody.appendChild(tr);
        });
        document.getElementById('modal-adm').style.display = 'block';
    } catch (e) {
        appAlert("خطأ في جلب بيانات الترقيد", "error");
    }
}

function filterAdmissions() {
    const term = document.getElementById('adm-search-input').value.toLowerCase();
    const list = window.CURRENT_ADM_LIST || [];
    const filtered = list.filter(a =>
        (a.patientName && a.patientName.toLowerCase().includes(term)) ||
        (a.docNo && a.docNo.toString().includes(term))
    );
    const tbody = document.querySelector('#adm-list-table tbody');
    tbody.innerHTML = '';
    filtered.forEach(a => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${a.docNo}</td><td>${new Date(a.date).toLocaleDateString()}</td><td>${a.patientName}</td>`;
        tr.onclick = () => { selectAdmission(a.docNo, a.docSerial); closeModal('modal-adm'); };
        tbody.appendChild(tr);
    });
}

async function selectAdmission(no, srl) {
    document.getElementById('adm-no-input').value = no;
    const cacheKey = `${no}_${srl}`;
    try {
        let details = null;
        try {
            const res = await fetch(`${getBaseApiUrl()}/VitalSigns/admissions/details?docNo=${no}&docSrl=${srl}`, {
                method: 'POST',
                headers: getHeaders()
            });

            if (res.ok) {
                details = await res.json();
                const cacheObj = { ...details, cacheKey, docNo: no, docSrl: srl };
                await saveToDB('patients_details', cacheObj, false);
                details = cacheObj;
            } else {
                throw new Error("HTTP " + res.status);
            }
        } catch (e) {
            console.warn("Offline: Fetching patient details from DB");
            const detailsList = await getFromDB('patients_details');
            details = detailsList.find(d => d.cacheKey === cacheKey);
        }

        if (!details) throw new Error("لا توجد بيانات محفوظة لهذا الترقيد. يرجى فتحه مرة واحدة أثناء توفر الإنترنت.");

        CURRENT_ADMISSION = { ...details, docNo: no, docSrl: srl };

        setVal('patient-no', details.patientNo);
        setVal('patient-name', details.patientName);
        setVal('doctor-no', details.dctrNo || details.doctorNo || '');
        setVal('doctor-name', details.doctorName || '');
        setVal('p-room', details.roomNo);
        setVal('p-bed', details.bedNo);
        setVal('p-dept', details.deptNo || '');
        setVal('p-gender', details.gender == 1 ? "ذكر" : "أنثى");
        setVal('p-age', details.age || '');
        setVal('p-adm-date', details.admDate ? new Date(details.admDate).toLocaleDateString() : '');

        document.getElementById('patient-info-section').style.display = 'block';

        // Only show table-area if a procedure type is already selected (e.g. during an edit/load)
        const prcdrTyp = document.getElementById('prcdr-typ').value;
        if (prcdrTyp) {
            document.getElementById('table-area').style.display = 'block';
        } else {
            document.getElementById('table-area').style.display = 'none';
        }

        // Focus on procedure type after selection
        document.getElementById('prcdr-typ').focus();

    } catch (e) {
        appAlert("فشل استرجاع تفاصيل الترقيد: " + e.message, "error");
    }
}

function onProcedureTypeChanged() {
    const procedureTypeStr = document.getElementById('prcdr-typ').value;
    const procedureType = parseInt(procedureTypeStr);
    CACHED_ITEMS = [];

    const theadTr = document.getElementById('details-thead-tr');
    const tbody = document.getElementById('details-tbody');

    if (!procedureTypeStr) {
        document.getElementById('table-area').style.display = 'none';
        theadTr.innerHTML = '';
        tbody.innerHTML = '';
        return;
    }

    document.getElementById('table-area').style.display = 'block';
    tbody.innerHTML = '';
    DETAIL_ROWS_COUNT = 0;

    let html = '';
    if (procedureType === 2) {
        html = `
            <th style="width:160px;">كود الفحص</th>
            <th>اسم الفحص</th>
            <th>سعر الفحص</th>
            <th>العينة</th>
            <th style="width:80px;">العدد</th>
            <th style="width:140px;">التاريخ</th>
            <th>ملاحظة</th>
            <th style="width:50px;">🗑️</th>
        `;
    } else if (procedureType === 3) {
        html = `
            <th style="width:160px;">كود الأشعة</th>
            <th>اسم الأشعة</th>
            <th>سعر الأشعة</th>
            <th style="width:80px;">العدد</th>
            <th style="width:140px;">التاريخ</th>
            <th>ملاحظة</th>
            <th style="width:50px;">🗑️</th>
        `;
    } else if (procedureType === 1) {
        html = `
            <th style="width:160px;">رقم الصنف</th>
            <th>اسم الصنف</th>
            <th>السعر</th>
            <th>الوحدة</th>
            <th style="width:80px;">العدد</th>
            <th>طريقة الاستخدام</th>
            <th style="width:80px;">المدة</th>
            <th style="width:90px;">نوع المدة</th>
            <th style="width:50px;">🗑️</th>
        `;
    } else {
        html = `
            <th style="width:160px;">رقم الإجراء</th>
            <th>اسم الإجراء</th>
            <th>السعر</th>
            <th style="width:80px;">العدد</th>
            <th>ملاحظات</th>
            <th style="width:50px;">🗑️</th>
         `;
    }

    theadTr.innerHTML = html;
    addNewDetailRow();
}

function addNewDetailRow() {
    const procedureType = parseInt(document.getElementById('prcdr-typ').value);
    const tbody = document.getElementById('details-tbody');

    DETAIL_ROWS_COUNT++;
    const rowId = DETAIL_ROWS_COUNT;

    const tr = document.createElement('tr');
    tr.id = `detail-row-${rowId}`;

    const d = new Date();
    const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

    if (procedureType === 2) {
        tr.innerHTML = `
            <td>
                <div class="input-with-btn">
                    <button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button>
                    <input type="text" id="row-code-${rowId}" readonly>
                </div>
            </td>
            <td><input type="text" id="row-name-${rowId}" readonly></td>
            <td><input type="number" id="row-price-${rowId}" readonly></td>
            <td><input type="text" id="row-unit-${rowId}" readonly></td>
            <td><input type="number" id="row-qty-${rowId}" value="1"></td>
            <td><input type="date" id="row-date-${rowId}" value="${todayStr}"></td>
            <td><input type="text" id="row-note-${rowId}" placeholder="ملاحظة..."></td>
            <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
        `;
    } else if (procedureType === 3) {
        tr.innerHTML = `
            <td>
                <div class="input-with-btn">
                    <button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button>
                    <input type="text" id="row-code-${rowId}" readonly>
                </div>
            </td>
            <td><input type="text" id="row-name-${rowId}" readonly></td>
            <td><input type="number" id="row-price-${rowId}" readonly></td>
            <td><input type="number" id="row-qty-${rowId}" value="1"></td>
            <td><input type="date" id="row-date-${rowId}" value="${todayStr}"></td>
            <td><input type="text" id="row-note-${rowId}" placeholder="ملاحظة..."></td>
            <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
        `;
    } else if (procedureType === 1) {
        tr.innerHTML = `
            <td>
                <div class="input-with-btn">
                     <button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button>
                     <input type="text" id="row-code-${rowId}">
                </div>
            </td>
            <td><input type="text" id="row-name-${rowId}"></td>
            <td><input type="number" id="row-price-${rowId}"></td>
            <td><input type="text" id="row-unit-${rowId}"></td>
            <td><input type="number" id="row-qty-${rowId}" value="1"></td>
            <td>
                <div class="input-with-btn">
                     <button class="mini-search-btn" onclick="openUsagesModal(${rowId})">🔍</button>
                     <input type="text" id="row-use-${rowId}" oninput="this.removeAttribute('data-mthduse')">
                </div>
            </td>
            <td><input type="number" id="row-duration-${rowId}" style="width:70px;" placeholder="المدة"></td>
            <td>
                <select id="row-durtyp-${rowId}" style="width:80px;">
                    <option value="">-- اختر --</option>
                    <option value="1">يوم</option>
                    <option value="2">شهر</option>
                    <option value="3">سنة</option>
                </select>
            </td>
            <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
        `;
    } else {
        tr.innerHTML = `
            <td>
                <div class="input-with-btn">
                     <button class="mini-search-btn" onclick="openItemsModal(${rowId})">🔍</button>
                     <input type="text" id="row-code-${rowId}">
                </div>
            </td>
            <td><input type="text" id="row-name-${rowId}"></td>
            <td><input type="number" id="row-price-${rowId}"></td>
            <td><input type="number" id="row-qty-${rowId}" value="1"></td>
            <td><input type="text" id="row-note-${rowId}"></td>
            <td><button class="btn btn-secondary" onclick="removeDetailRow(${rowId})" style="padding:5px;">❌</button></td>
        `;
    }
    tbody.appendChild(tr);
}

function removeDetailRow(rowId) {
    const tr = document.getElementById(`detail-row-${rowId}`);
    if (tr) tr.remove();
}

async function openItemsModal(rowId) {
    CURRENT_ROW_TO_POPULATE = rowId;
    const procedureType = parseInt(document.getElementById('prcdr-typ').value);

    document.getElementById('modal-items-title').innerText = procedureType === 2 ? 'قائمة الفحوصات' : procedureType === 3 ? 'قائمة الأشعة' : 'قائمة الإجراءات';

    const thead = document.getElementById('items-thead-tr');
    if (procedureType === 2) {
        thead.innerHTML = `<th>كود</th><th>اسم الفحص</th><th>العينة</th>`;
    } else {
        thead.innerHTML = `<th>كود</th><th>اسم الإجراء</th>`;
    }

    document.getElementById('modal-items').style.display = 'block';

    try {
        let items = [];
        try {
            const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/items?procedureType=${procedureType}`, {
                method: 'GET',
                headers: getHeaders()
            });

            if (res.ok) {
                items = await res.json();
                await saveToDB('items_cache', { items, cacheKey: `items_${procedureType}` }, false);
            } else {
                throw new Error("HTTP " + res.status);
            }
        } catch (e) {
            console.warn("Offline: Fetching items from DB");
            const cached = await getFromDB('items_cache', `items_${procedureType}`);
            items = cached ? cached.items : [];
        }

        CACHED_ITEMS = items;
        if (CACHED_ITEMS.length === 0) {
            document.getElementById('items-tbody').innerHTML = `<tr><td colspan="3" style="text-align:center; padding:20px; color:red;">⚠️ لا توجد بيانات محفوظة لهذا الإجراء. يرجى فتح هذه النائية لمرة واحدة أثناء توفر الإنترنت لتحميل القائمة.</td></tr>`;
            return;
        }
        renderItemsFilter(CACHED_ITEMS);
    } catch (e) {
        console.error(e);
        appAlert("خطأ في الاتصال بالسيرفر: " + e.message, "error");
    }
}

async function preloadAllItems() {
    try {
        const stored = localStorage.getItem('procedure_types');
        const list = stored ? JSON.parse(stored) : [];
        let types = list.map(p => parseInt(p.procedureType)).filter(t => !isNaN(t));
        if (types.length === 0) {
            types = [1, 2, 3, 4, 5];
        }
        for (const type of types) {
            const res = await fetch(`${getBaseApiUrl()}/DoctorOrder/items?procedureType=${type}`, {
                method: 'GET', headers: getHeaders()
            });
            if (res.ok) {
                const items = await res.json();
                await saveToDB('items_cache', { items, cacheKey: `items_${type}` }, false);
            }
        }
        console.log("All doctor items preloaded to cache.");
    } catch (e) { }
}

function filterItems() {
    const term = document.getElementById('item-search-input').value.toLowerCase();
    const filtered = CACHED_ITEMS.filter(i =>
        (i.itemCode && i.itemCode.toLowerCase().includes(term)) ||
        (i.itemName && i.itemName.toLowerCase().includes(term))
    );
    renderItemsFilter(filtered);
}

function renderItemsFilter(list) {
    const procedureType = parseInt(document.getElementById('prcdr-typ').value);
    const tbody = document.getElementById('items-tbody');
    tbody.innerHTML = '';

    const limit = list.slice(0, 100);
    limit.forEach(i => {
        let tr = document.createElement('tr');
        const code = i.itemCode || i.I_CODE || i.item_CODE || '';
        const name = i.itemName || i.I_NAME || i.item_NAME || '';
        const sample = i.sampleType || i.SAMPLE_TYPE || '-';

        if (procedureType === 2) {
            tr.innerHTML = `<td>${code}</td><td>${name}</td><td>${sample}</td>`;
        } else {
            tr.innerHTML = `<td>${code}</td><td>${name}</td>`;
        }
        tr.onclick = () => selectItem(i);
        tbody.appendChild(tr);
    });
}

function selectItem(itemData) {
    if (!CURRENT_ROW_TO_POPULATE) return;
    const rId = CURRENT_ROW_TO_POPULATE;

    try {
        const codeElem = document.getElementById(`row-code-${rId}`);
        codeElem.value = itemData.itemCode || '';
        codeElem.dataset.psize = itemData.pSize || 1;

        document.getElementById(`row-name-${rId}`).value = itemData.itemName || '';
        if (document.getElementById(`row-price-${rId}`)) document.getElementById(`row-price-${rId}`).value = itemData.price || 0;

        if (document.getElementById(`row-unit-${rId}`)) {
            const procedureTypeNow = parseInt(document.getElementById('prcdr-typ').value);
            const unitEl = document.getElementById(`row-unit-${rId}`);
            if (procedureTypeNow === 2) {
                // عرض اسم العينة للمستخدم (sampleType)
                unitEl.value = itemData.sampleType || '';
                // الاحتفاظ بالقيمة الأصلية (LAB) في data attribute للحفظ لاحقاً
                unitEl.dataset.saveUnit = itemData.unit || 'LAB';
            } else {
                unitEl.value = itemData.unit || '';
                delete unitEl.dataset.saveUnit;
            }
        }
    } catch (e) { }

    closeModal('modal-items');

    const allRows = document.querySelectorAll('#details-tbody tr');
    const isLastRow = allRows[allRows.length - 1].id === `detail-row-${rId}`;
    if (isLastRow) {
        addNewDetailRow();
    }
}

function closeModal(id) { document.getElementById(id).style.display = 'none'; }

async function saveOrder() {
    if (!CURRENT_ADMISSION && !IS_EDIT_MODE) return appAlert("يرجى اختيار مريض أولاً", "error");

    const procedureType = document.getElementById('prcdr-typ').value;
    if (!procedureType) {
        appAlert("يرجى اختيار نوع الإجراء الطبي أولاً", "warning");
        document.getElementById('prcdr-typ').focus();
        return;
    }

    let ageVal = getVal('p-age');
    let genderVal = getVal('p-gender') === "ذكر" ? 1 : 2;

    if (CURRENT_ADMISSION) {
        ageVal = CURRENT_ADMISSION.age || ageVal;
        genderVal = parseInt(CURRENT_ADMISSION.gender) || genderVal;
    }

    const dto = {
        branchNo: getInt('branch-list'),
        procedureType: procedureType,
        docNo: getInt('doc-no') || 1,
        docDate: getVal('doc-date'),
        docTime: `2000-01-01T${getVal('doc-time')}`,
        priorityNo: getInt('prorty-no') || 1,

        docNoAdmission: getInt('adm-no-input'),
        docSrlAdmission: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.docSrl) || 0) : 0,
        patientNo: getVal('patient-no'),
        roomSer: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.roomService) || 0) : 0,
        roomNo: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.roomNo) || 0) : 0,
        deptNo: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.deptNo) || 0) : 0,
        buildNo: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.buldNo) || 0) : 0,
        bedNo: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.bedNo) || 0) : 0,
        gender: genderVal,
        age: ageVal,
        ageType: CURRENT_ADMISSION ? (parseInt(CURRENT_ADMISSION.ageType) || 0) : 0,
        doctorNo: getVal('doctor-no') || (CURRENT_ADMISSION ? CURRENT_ADMISSION.dctrNo : ""),

        notes: getVal('doc-dsc'),
        refNo: getVal('ref-no'),

        details: []
    };

    // If we are editing an existing record, include its serial in the body too
    if (CURRENT_ORDER_SRL && !CURRENT_ORDER_SRL.toString().startsWith('local_')) {
        dto.docSrl = parseInt(CURRENT_ORDER_SRL);
    }

    const allRows = document.querySelectorAll('#details-tbody tr');
    allRows.forEach(tr => {
        const id = tr.id.split('-')[2];
        const codeElement = document.getElementById(`row-code-${id}`);

        if (codeElement && codeElement.value.trim() !== "") {
            const useInput = document.getElementById(`row-use-${id}`);
            const detailItem = {
                itemCode: codeElement.value,
                pSize: codeElement.dataset.psize ? parseFloat(codeElement.dataset.psize) : 1,
                price: document.getElementById(`row-price-${id}`) ? parseFloat(document.getElementById(`row-price-${id}`).value) : 0,
                // للفحوصات (2): يُحفظ القيمة الأصلية (LAB) من data-save-unit وليس ما يظهر للمستخدم
                unit: (() => {
                    const el = document.getElementById(`row-unit-${id}`);
                    if (!el) return 'NA';
                    return parseInt(procedureType) === 2
                        ? (el.dataset.saveUnit || 'LAB')
                        : (el.value || 'NA');
                })(),
                quantity: document.getElementById(`row-qty-${id}`) ? parseFloat(document.getElementById(`row-qty-${id}`).value) : 1,
                expectedDate: document.getElementById(`row-date-${id}`) ? document.getElementById(`row-date-${id}`).value : new Date().toISOString().split('T')[0],
                notes: document.getElementById(`row-note-${id}`) ? document.getElementById(`row-note-${id}`).value : "",
                mthdUse: useInput && useInput.dataset.mthduse ? parseInt(useInput.dataset.mthduse) : null,
                mthdUseDsc: useInput ? useInput.value : "",
                durtion: document.getElementById(`row-duration-${id}`) && document.getElementById(`row-duration-${id}`).value.trim() !== "" ? parseFloat(document.getElementById(`row-duration-${id}`).value) : null,
                durTyp: document.getElementById(`row-durtyp-${id}`) && document.getElementById(`row-durtyp-${id}`).value !== "" ? parseInt(document.getElementById(`row-durtyp-${id}`).value) : null
            };
            dto.details.push(detailItem);
        }
    });

    if (dto.details.length === 0) {
        return appAlert("يجب إضافة إجراء واحد (أشعة/فحوصات) على الأقل في الجدول قبل الحفظ", "error");
    }

    try {
        const isEdit = CURRENT_ORDER_SRL && !CURRENT_ORDER_SRL.toString().startsWith('local_');
        const method = 'POST';
        const url = isEdit
            ? `${getBaseApiUrl()}/DoctorOrder/update/${CURRENT_ORDER_SRL}`
            : `${getBaseApiUrl()}/DoctorOrder`;

        if (!navigator.onLine) {
            if (CURRENT_ORDER_SRL && CURRENT_ORDER_SRL.toString().startsWith('local_')) {
                const localId = parseInt(CURRENT_ORDER_SRL.toString().replace('local_', ''));
                await updateUnsyncedDoctorOrder(localId, dto);
            } else {
                await addUnsyncedDoctorOrder(url, method, dto, isEdit);
            }
            appAlert("⚠️ لا يتوفر اتصال بالإنترنت. تم حفظ الطلب محلياً في هاتفك وسيتم مزامنته عند توفر الشبكة.", 'warning');
            addNewOrder();
            return;
        }

        const res = await fetch(url, {
            method: method,
            headers: getHeaders(),
            body: JSON.stringify(dto)
        });

        if (res.ok) {
            const result = await res.json();
            appAlert(`✅ ${result.message}`, "success");
            addNewOrder();
        } else {
            let errorMsg = 'حصل خطأ في الخادم';
            try {
                const errorData = await res.json();
                errorMsg = errorData.message || errorMsg;
            } catch (je) { }
            appAlert(`❌ فشل الحفظ: ${errorMsg}`, "error");
        }
    } catch (e) {
        console.error("Save Order Exception Details:", e);
        console.error("Payload was:", dto);
        const isEdit = CURRENT_ORDER_SRL && !CURRENT_ORDER_SRL.toString().startsWith('local_');
        const method = 'POST';
        const url = isEdit
            ? `${getBaseApiUrl()}/DoctorOrder/update/${CURRENT_ORDER_SRL}`
            : `${getBaseApiUrl()}/DoctorOrder`;

        if (CURRENT_ORDER_SRL && CURRENT_ORDER_SRL.toString().startsWith('local_')) {
            const localId = parseInt(CURRENT_ORDER_SRL.toString().replace('local_', ''));
            await updateUnsyncedDoctorOrder(localId, dto);
        } else {
            await addUnsyncedDoctorOrder(url, method, dto, isEdit);
        }
        appAlert("⚠️ تم حفظ الطلب محلياً (تعذر الاتصال بالسيرفر)", 'warning');
        addNewOrder();
    }
}
