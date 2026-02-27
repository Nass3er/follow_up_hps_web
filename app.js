const API_URL = "http://localhost/hps/api";
let TOKEN = "";
let NURSE_LIST = [];
let CURRENT_ADMISSION = null;
let SELECTED_TIME = ""; // متغير عالمي لتخزين الوقت المختار من الجدول
let lastFetchedData = [];  // لتخزين السجلات المحفوظة لهذا اليوم
let CURRENT_DOC_SRL = null;

// تعبئة تاريخ اليوم
document.getElementById('cur-date').innerText = new Date().toLocaleDateString('ar-YE');
const days = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
document.getElementById('cur-day').innerText = days[new Date().getDay()];

// تعيين تاريخ اليوم تلقائياً عند تحميل الصفحة
document.getElementById('doc-date-input').value = new Date().toISOString().split('T')[0];
// 1. الدخول وجلب التوكن
async function login() {
    const dto = {
        userId: parseInt(document.getElementById('u-id').value),
        financialYear: parseInt(document.getElementById('u-year').value),
        activityNo: parseInt(document.getElementById('u-act').value)
    };

    try {
        const res = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(dto)
        });
        const data = await res.json();
        TOKEN = data.token;
        
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('main-screen').style.display = 'block';
        
        initData();
    } catch (e) { alert("خطأ في الاتصال بالسيرفر"); }
}

async function initData() {
    loadBranches();
    fetchNurses(); 
}

// 2. جلب الفروع
async function loadBranches() {
    const res = await fetch(`${API_URL}/VitalSigns/branches`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    const list = await res.json();
    const select = document.getElementById('branch-list');
    list.forEach(b => select.add(new Option(b.branchName, b.branchNo)));
}

// 3. البحث عن ترقيد
document.getElementById('adm-no-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === 'Tab') searchAdmission(e.target.value);
});

async function searchAdmission(docNo) {
    const res = await fetch(`${API_URL}/VitalSigns/admissions`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    const list = await res.json();
    const admission = list.find(a => a.docNo == docNo);
    if(admission) selectAdmission(admission.docNo, admission.docSerial);
    else alert("رقم الترقيد غير موجود");
}

async function openAdmModal() {
    const res = await fetch(`${API_URL}/VitalSigns/admissions`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    const list = await res.json();
    const tbody = document.querySelector('#adm-list-table tbody');
    tbody.innerHTML = '';
    list.forEach(a => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${a.docNo}</td><td>${new Date(a.date).toLocaleDateString()}</td><td>${a.patientName}</td>`;
        tr.ondblclick = () => { selectAdmission(a.docNo, a.docSerial); closeModal('modal-adm'); };
        tbody.appendChild(tr);
    });
    document.getElementById('modal-adm').style.display = 'block';
}

async function selectAdmission(no, srl) {
    document.getElementById('adm-no-input').value = no;
    const res = await fetch(`${API_URL}/VitalSigns/admissions/details?docNo=${no}&docSrl=${srl}`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    const details = await res.json();
    CURRENT_ADMISSION = { ...details, docNo: no, docSrl: srl };
    
    document.getElementById('p-name').value = "المريض: " + details.patientNo;
    document.getElementById('p-no').value = details.patientNo;
    document.getElementById('p-age').value = details.age;
    document.getElementById('p-room').value = details.roomNo;
    document.getElementById('p-bed').value = details.bedNo;
    document.getElementById('p-gender').value = details.gender == 1 ? "ذكر" : "أنثى";
}



async function loadAndShowTable() {    //new
    if (!CURRENT_ADMISSION) return alert("الرجاء اختيار مريض أولاً");
    
    const docDate = document.getElementById('doc-date-input').value;
    const interval = parseInt(document.getElementById('time-interval').value) || 30;
    
    // 1. جلب البيانات المحفوظة لهذا التاريخ من السيرفر
    const res = await fetch(`${API_URL}/VitalSigns/history?patientNo=${CURRENT_ADMISSION.patientNo}&date=${docDate}`, {
        method: 'GET', // أو POST حسب تصميمك
        headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    const savedData = await res.json(); // نُفترض أنها مصفوفة كائنات تحتوي على الوقت والبيانات

    lastFetchedData = savedData;
    // 2. توليد الأوقات الافتراضية بناءً على التقسيم
    let timeSlots = [];
    for (let totalMin = 1 * 60; totalMin < 24 * 60; totalMin += interval) {
        let h = Math.floor(totalMin / 60);
        let m = totalMin % 60;
        timeSlots.push(`${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:00`);
    }

    // 3. دمج الأوقات المخزنة مع الأوقات الافتراضية
    // نأخذ الأوقات من البيانات المحفوظة ونضيفها للقائمة إذا لم تكن موجودة
    savedData.forEach(item => {
        let savedTime = item.docTime.split('T')[1]; // استخراج الوقت من DateTime
        if (!timeSlots.includes(savedTime)) {
            timeSlots.push(savedTime);
        }
    });

    // 4. ترتيب جميع الأوقات زمنياً
    timeSlots.sort();

    // 5. بناء الجدول
    const tbody = document.querySelector('#vitals-table tbody');
    tbody.innerHTML = '';

    timeSlots.forEach(time => {
        const record = savedData.find(d => d.docTime.split('T')[1] === time);
        const tr = document.createElement('tr');
        
        if (record) {
            // حالة وجود بيانات: عرض البيانات + زر تعديل
            tr.style.backgroundColor = "#e8f5e9"; // تمييز الصف المحفوظ
            tr.innerHTML = `
                <td><b>${time}</b></td>
                <td>${record.temperature}</td>
                <td>${record.pulseRate}</td>
                <td>${record.respirationRate}</td>
                <td>${record.spO2}</td>
                <td>${record.bloodPressureOne}/${record.bloodPressureTwo}</td>
                <td>
                    <button class="btn-edit" onclick="openEditModal('${record.docSrl}')">تعديل ✏️</button>
                </td>
            `;
        } else {
            // حالة وقت افتراضي فارغ: عرض زر إضافة
            tr.innerHTML = `
                <td>${time}</td>
                <td>-</td><td>-</td><td>-</td><td>-</td><td>-</td>
                <td>
                    <button class="btn-add" onclick="openVitalsModal('${time}')">إضافة ➕</button>
                </td>
            `;
        }
        tbody.appendChild(tr);
    });
    
    document.getElementById('table-area').style.display = 'block';
}



// دالة فتح المودال للتعديل وتعبئة الحقول المحددة
// دالة لفتح المودال وتعبئة البيانات للتعديل
function openEditModal(docSrl) {
    // 1. تخزين السيريال الحالي لنعرف أننا في حالة "تعديل" وليس "إضافة"
    CURRENT_DOC_SRL = docSrl;

    // 2. البحث عن البيانات في المصفوفة التي جلبناها من السيرفر (savedData)
    // ملاحظة: تأكد أن savedData معرفة كنطاق عام أو مررها بشكل صحيح
    const record = lastFetchedData.find(d => d.docSrl == docSrl);
    
    if (record) {
        SELECTED_TIME = record.docTime.split('T')[1];
        document.getElementById('vitals-title').innerText = "تعديل علامات الساعة " + SELECTED_TIME;
        
        // 3. تعبئة الحقول بالبيانات الموجودة
        document.getElementById('n-id').value = record.nurseEmpNo || "";
        findNurseName(record.nurseEmpNo); // لعرض اسم الممرض بجانب رقمه

        document.getElementById('v-temp').value = record.temperature;
        document.getElementById('v-pulse').value = record.pulseRate;
        document.getElementById('v-resp').value = record.respirationRate;
        document.getElementById('v-spo2').value = record.spO2;
        document.getElementById('v-bp1').value = record.bloodPressureOne;
        document.getElementById('v-bp2').value = record.bloodPressureTwo;
        document.getElementById('v-notes').value = record.notes || "";

        // 4. فتح المودال
        document.getElementById('modal-vitals').style.display = 'block';
    } else {
        alert("تعذر العثور على بيانات السجل");
    }
}

// دالة مساعدة لعرض اسم الممرض عند التعديل
function findNurseName(empNo) {
    if(!empNo) return;
    const nurse = NURSE_LIST.find(n => n.empNo == empNo);
    document.getElementById('n-name').value = nurse ? nurse.empName : "ممرض غير معروف";
}

// تعديل دالة الحفظ لتدعم الإضافة والتعديل
async function saveVitals() {
    const getValue = (id) => parseFloat(document.getElementById(id).value) || 0;

    const dto = {
        docSrl: CURRENT_DOC_SRL, // null في الإضافة، قيمة في التعديل
        branchNo: parseInt(document.getElementById('branch-list').value),
        docNo: (document.getElementById('adm-no-input').value).toString(),
        docSrlAdmt: parseInt(CURRENT_ADMISSION.docSrl),
        patientNo: CURRENT_ADMISSION.patientNo,
        docTime: `2000-01-01T${SELECTED_TIME}`,
        
        // الحقول المطلوب تعديلها
        nurseEmpNo: parseInt(document.getElementById('n-id').value) || 0,
        temperature: getValue('v-temp'),
        pulseRate: getValue('v-pulse'),
        respirationRate: getValue('v-resp'),
        spO2: getValue('v-spo2'),
        bloodPressureOne: getValue('v-bp1'),
        bloodPressureTwo: getValue('v-bp2'),
        notes: document.getElementById('v-notes').value || ""
    };

    const method = CURRENT_DOC_SRL ? 'PUT' : 'POST';
    const url = CURRENT_DOC_SRL ? `${API_URL}/VitalSigns/${CURRENT_DOC_SRL}` : `${API_URL}/VitalSigns`;

    const res = await fetch(url, {
        method: method,
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` },
        body: JSON.stringify(dto)
    });

    if (res.ok) {
        alert(CURRENT_DOC_SRL ? "✅ تم التعديل بنجاح" : "✅ تم الحفظ بنجاح");
        closeModal('modal-vitals');
        CURRENT_DOC_SRL = null; // تصفير السيريال
        loadAndShowTable(); // إعادة تحميل الجدول لإظهار التغييرات
    } else {
        alert("❌ فشلت العملية");
    }
}

async function fetchNurses() {
    try {
        const res = await fetch(`${API_URL}/staff/nurses`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${TOKEN}` }
        });
        NURSE_LIST = await res.json();
    } catch (e) { console.error("Error fetching nurses", e); }
}

document.getElementById('n-id').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === 'Tab') {
        const nurse = NURSE_LIST.find(n => n.empNo == e.target.value);
        if(nurse) document.getElementById('n-name').value = nurse.empName;
        else { alert("الممرض غير موجود"); document.getElementById('n-name').value = ""; }
    }
});

function openNurseModal() {
    const tbody = document.querySelector('#nurse-list-table tbody');
    tbody.innerHTML = '';
    NURSE_LIST.forEach(n => {
        let tr = document.createElement('tr');
        tr.innerHTML = `<td>${n.empNo}</td><td>${n.empName}</td>`;
        tr.ondblclick = () => {
            document.getElementById('n-id').value = n.empNo;
            document.getElementById('n-name').value = n.empName;
            closeModal('modal-nurse');
        };
        tbody.appendChild(tr);
    });
    document.getElementById('modal-nurse').style.display = 'block';
}

// 6. الحفظ النهائي مع الوقت المختار
function openVitalsModal(time) {
   
    if(!CURRENT_ADMISSION) return alert("اختر مريضاً أولاً");
    
    CURRENT_DOC_SRL = null; // هام جداً: نحن الآن في وضع إضافة سجل جديد
    SELECTED_TIME = time;
    
    document.getElementById('vitals-title').innerText = "تسجيل علامات الساعة " + time;
    
    // تصفير جميع المدخلات في المودال
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
    try {
        const getValue = (id) => parseFloat(document.getElementById(id).value) || 0;

        const isUpdate = CURRENT_DOC_SRL !== null;
        
        const dto = {
            docSrl: CURRENT_DOC_SRL,
            branchNo: parseInt(document.getElementById('branch-list').value),
            docNo: document.getElementById('adm-no-input').value.toString(),
            docSrlAdmt: parseInt(CURRENT_ADMISSION.docSrl),
            patientNo: CURRENT_ADMISSION.patientNo,
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

        const method = isUpdate ? 'PUT' : 'POST';
        const url = isUpdate 
            ? `${API_URL}/VitalSigns/${CURRENT_DOC_SRL}` 
            : `${API_URL}/VitalSigns`;

        const res = await fetch(url, {
            method: method,
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${TOKEN}`,
                'Accept': 'application/json'
            },
            body: JSON.stringify(dto)
        });

        if (res.ok) {
            alert(isUpdate ? "✅ تم التعديل بنجاح" : "✅ تم الحفظ بنجاح");
            closeModal('modal-vitals');
            CURRENT_DOC_SRL = null; 
            
            // تأكد أن هذا العنصر موجود في الـ HTML قبل استدعاء الدالة
            loadAndShowTable(); 
        } else {
            const errData = await res.text();
            console.error("Server Error:", errData);
            alert("❌ فشلت العملية: السيرفر أرجع خطأ " + res.status);
        }
    } catch (error) {
        console.error("Error during fetch:", error);
        alert("⚠️ خطأ في الاتصال بالسيرفر (تأكد من إعدادات CORS و PUT method)");
    }
}
function closeModal(id) { document.getElementById(id).style.display = 'none'; }