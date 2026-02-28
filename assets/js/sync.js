// sync.js - Offline sync queue manager
document.addEventListener('DOMContentLoaded', () => {
    checkSyncStatus();
    window.addEventListener('online', checkSyncStatus);
    window.addEventListener('offline', checkSyncStatus);
});

async function checkSyncStatus() {
    try {
        const unsynced = await getFromDB('unsynced_vitals');

        // Remove old floating badge if it exists
        const oldBadge = document.getElementById('sync-badge-container');
        if (oldBadge) oldBadge.remove();

        // Update main dashboard card if on dashboard
        let targetDashboardCard = document.getElementById('sync-dashboard-card');
        if (targetDashboardCard) {
            if (unsynced && unsynced.length > 0) {
                targetDashboardCard.style.display = 'flex';
                document.getElementById('sync-dashboard-text').innerText = `لديك ${unsynced.length} سجل تحتاج إلى مزامنة في السيرفر`;
            } else {
                targetDashboardCard.style.display = 'none';
            }
        }

        // Show offline status in header if disconnected
        document.querySelectorAll('.app-layout h1, .brand h1, .dashboard-header h1').forEach(h1 => {
            if (!navigator.onLine) {
                if (!h1.innerHTML.includes('وضع عدم الاتصال')) {
                    h1.innerHTML += ' <span style="font-size:12px;color:#e74c3c;background:#fff;border-radius:4px;padding:2px 5px;vertical-align:middle;margin-right:10px;">(وضع عدم الاتصال)</span>';
                }
            } else {
                h1.innerHTML = h1.innerHTML.replace(/ <span.*?>\(وضع عدم الاتصال\)<\/span>/g, '');
            }
        });
    } catch (e) { console.error("Sync check error", e); }
}

// ------ Functions specifically for sync.html UI ------- //

async function loadUnsyncedTable() {
    const tbody = document.querySelector('#unsynced-table tbody');
    if (!tbody) return; // Only run on sync.html

    const unsynced = await getFromDB('unsynced_vitals');
    const tableParent = document.getElementById('unsynced-table');
    const noData = document.getElementById('no-sync-data');
    const btnSyncAll = document.getElementById('btn-sync-all');

    tbody.innerHTML = '';

    if (!unsynced || unsynced.length === 0) {
        tableParent.style.display = 'none';
        btnSyncAll.style.display = 'none';
        noData.style.display = 'block';
        return;
    }

    tableParent.style.display = 'table';
    btnSyncAll.style.display = 'block';
    noData.style.display = 'none';

    unsynced.forEach(v => {
        const tr = document.createElement('tr');
        const d = new Date(v.timestamp).toLocaleString('ar-YE');
        const timeParts = v.dto.docTime.split('T');
        const vTime = timeParts.length > 1 ? timeParts[1] : '';

        tr.innerHTML = `
            <td>${d}</td>
            <td>${vTime}</td>
            <td dir="ltr">${v.dto.temperature || '-'}</td>
            <td dir="ltr">${v.dto.pulseRate || '-'}</td>
            <td>
                <div style="display: flex; gap: 2px; width: 100%;">
                    <button class="btn-edit" style="flex:1; padding: 5px; font-size: 14px; margin:0;" onclick="openSyncEdit(${v.id})">✏️</button>
                    <button class="btn-delete" style="flex:1; padding: 5px; font-size: 14px; background: #e74c3c; color: white; border: none; border-radius: 4px; margin:0; cursor:pointer;" onclick="deleteSyncItem(${v.id})">🗑️</button>
                </div>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function closeModal(id) { document.getElementById(id).style.display = 'none'; }

async function openSyncEdit(id) {
    const unsynced = await getFromDB('unsynced_vitals', id);
    if (!unsynced) return;

    document.getElementById('edit-sync-id').value = id;
    document.getElementById('e-temp').value = unsynced.dto.temperature || "";
    document.getElementById('e-pulse').value = unsynced.dto.pulseRate || "";
    document.getElementById('e-resp').value = unsynced.dto.respirationRate || "";
    document.getElementById('e-spo2').value = unsynced.dto.spO2 || "";
    document.getElementById('e-bp1').value = unsynced.dto.bloodPressureOne || "";
    document.getElementById('e-bp2').value = unsynced.dto.bloodPressureTwo || "";
    document.getElementById('e-notes').value = unsynced.dto.notes || "";

    document.getElementById('modal-edit-sync').style.display = 'block';
}

async function saveEditedSync() {
    const id = parseInt(document.getElementById('edit-sync-id').value);
    const unsynced = await getFromDB('unsynced_vitals', id);
    if (!unsynced) return;

    unsynced.dto.temperature = parseFloat(document.getElementById('e-temp').value) || 0;
    unsynced.dto.pulseRate = parseFloat(document.getElementById('e-pulse').value) || 0;
    unsynced.dto.respirationRate = parseFloat(document.getElementById('e-resp').value) || 0;
    unsynced.dto.spO2 = parseFloat(document.getElementById('e-spo2').value) || 0;
    unsynced.dto.bloodPressureOne = parseFloat(document.getElementById('e-bp1').value) || 0;
    unsynced.dto.bloodPressureTwo = parseFloat(document.getElementById('e-bp2').value) || 0;
    unsynced.dto.notes = document.getElementById('e-notes').value || "";

    await saveToDB('unsynced_vitals', unsynced, false);
    closeModal('modal-edit-sync');
    loadUnsyncedTable();
    appAlert("تم التعديل محلياً بنجاح", 'success');
}

async function deleteSyncItem(id) {
    const isConfirmed = await appConfirm('هل أنت متأكد من حذف هذا السجل نهائياً قبل ارساله للسيرفر؟');
    if (isConfirmed) {
        await removeUnsyncedVital(id);
        loadUnsyncedTable();
    }
}

async function performSyncAll() {
    if (!navigator.onLine) {
        appAlert("أنت غير متصل بالإنترنت حالياً! يرجى الاتصال بالشبكة للمزامنة.", 'warning');
        return;
    }

    const unsynced = await getFromDB('unsynced_vitals');
    if (!unsynced || unsynced.length === 0) return;

    const btn = document.getElementById('btn-sync-all');
    btn.disabled = true;

    const progressContainer = document.getElementById('sync-progress-container');
    const progressBar = document.getElementById('sync-progress-bar');
    const progressText = document.getElementById('sync-progress-text');
    const progressPercent = document.getElementById('sync-progress-percent');

    progressContainer.style.display = 'block';

    let successCount = 0;
    let failCount = 0;
    const total = unsynced.length;

    for (let i = 0; i < total; i++) {
        let item = unsynced[i];
        try {
            const res = await fetch(item.url, {
                method: item.method,
                headers: getHeaders(),
                body: JSON.stringify(item.dto)
            });

            if (res.ok) {
                await removeUnsyncedVital(item.id);
                successCount++;
            } else {
                failCount++;
            }
        } catch (e) {
            failCount++;
        }

        // Update progress UI
        let percentage = Math.round(((i + 1) / total) * 100);
        progressBar.style.width = percentage + '%';
        progressPercent.innerText = percentage + '%';
        progressText.innerText = `جاري رفع ${i + 1} من ${total}...`;
    }

    setTimeout(() => {
        progressContainer.style.display = 'none';
        btn.disabled = false;

        let msg = `✅ تمت مزامنة ${successCount} سجلات بنجاح!`;
        if (failCount > 0) {
            msg += `\n❌ فشلت ${failCount} سجلات. تأكد من اتصال السيرفر.`;
            appAlert(msg, 'error');
        } else {
            appAlert(msg, 'success');
        }

        loadUnsyncedTable();
    }, 800);
}
