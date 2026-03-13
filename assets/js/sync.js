// sync.js - Offline sync queue manager
document.addEventListener('DOMContentLoaded', () => {
    checkSyncStatus();
    window.addEventListener('online', checkSyncStatus);
    window.addEventListener('offline', checkSyncStatus);
});

async function checkSyncStatus() {
    try {
        const unsyncedVitals = await getFromDB('unsynced_vitals') || [];
        const unsyncedIO = await getFromDB('unsynced_io') || [];
        const totalUnsynced = unsyncedVitals.length + unsyncedIO.length;

        // Remove old floating badge if it exists
        const oldBadge = document.getElementById('sync-badge-container');
        if (oldBadge) oldBadge.remove();

        // Update main dashboard card if on dashboard
        let targetDashboardCard = document.getElementById('sync-dashboard-card');
        if (targetDashboardCard) {
            if (totalUnsynced > 0) {
                targetDashboardCard.style.display = 'flex';
                document.getElementById('sync-dashboard-text').innerText = `لديك ${totalUnsynced} سجل تحتاج إلى مزامنة في السيرفر`;
            } else {
                targetDashboardCard.style.display = 'none';
            }
        }

        // ... rest of the status update icon logic
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
    if (!tbody) return;

    const unsyncedVitals = (await getFromDB('unsynced_vitals')) || [];
    const unsyncedIO = (await getFromDB('unsynced_io')) || [];

    // Combine with tags
    const all = [
        ...unsyncedVitals.map(v => ({ ...v, type: 'vitals', label: 'علامات حيوية' })),
        ...unsyncedIO.map(io => ({ ...io, type: 'io', label: 'سوائل' }))
    ].sort((a, b) => b.timestamp - a.timestamp);

    const tableParent = document.getElementById('unsynced-table');
    const noData = document.getElementById('no-sync-data');
    const btnSyncAll = document.getElementById('btn-sync-all');

    tbody.innerHTML = '';

    if (all.length === 0) {
        tableParent.style.display = 'none';
        btnSyncAll.style.display = 'none';
        noData.style.display = 'block';
        return;
    }

    tableParent.style.display = 'table';
    btnSyncAll.style.display = 'block';
    noData.style.display = 'none';

    all.forEach(item => {
        const tr = document.createElement('tr');
        const d = new Date(item.timestamp).toLocaleString('ar-YE');
        const timeParts = item.dto.docTime.split('T');
        const vTime = timeParts.length > 1 ? timeParts[1] : '';

        let details = "";
        if (item.type === 'vitals') {
            details = `حرارة: ${item.dto.temperature}, نبض: ${item.dto.pulseRate}`;
        } else {
            details = `داخل: ${item.dto.inIvf + item.dto.inOral}, خارج: ${item.dto.outUrine}`;
        }

        tr.innerHTML = `
            <td><span class="badge ${item.type === 'vitals' ? 'badge-info' : 'badge-warning'}">${item.label}</span></td>
            <td>${d}</td>
            <td>${vTime}</td>
            <td>${details}</td>
            <td>
                <button class="btn-delete" style="padding: 5px 10px; background: #e74c3c; color: white; border: none; border-radius: 4px; cursor:pointer;" onclick="deleteSyncItem('${item.type}', ${item.id})">🗑️</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function deleteSyncItem(type, id) {
    const isConfirmed = await appConfirm('هل أنت متأكد من حذف هذا السجل نهائياً قبل ارساله للسيرفر؟');
    if (isConfirmed) {
        if (type === 'vitals') await removeUnsyncedVital(id);
        else await removeUnsyncedIO(id);
        loadUnsyncedTable();
    }
}

async function performSyncAll() {
    if (!navigator.onLine) {
        appAlert("أنت غير متصل بالإنترنت حالياً! يرجى الاتصال بالشبكة للمزامنة.", 'warning');
        return;
    }

    const unsyncedVitals = await getFromDB('unsynced_vitals') || [];
    const unsyncedIO = await getFromDB('unsynced_io') || [];
    const all = [
        ...unsyncedVitals.map(v => ({ ...v, type: 'vitals' })),
        ...unsyncedIO.map(io => ({ ...io, type: 'io' }))
    ];

    if (all.length === 0) return;

    const btn = document.getElementById('btn-sync-all');
    btn.disabled = true;

    const progressContainer = document.getElementById('sync-progress-container');
    const progressBar = document.getElementById('sync-progress-bar');
    const progressText = document.getElementById('sync-progress-text');
    const progressPercent = document.getElementById('sync-progress-percent');

    progressContainer.style.display = 'block';

    let successCount = 0;
    let failCount = 0;
    const total = all.length;

    for (let i = 0; i < total; i++) {
        let item = all[i];
        try {
            const res = await fetch(item.url, {
                method: item.method,
                headers: getHeaders(),
                body: JSON.stringify(item.dto)
            });

            if (res.ok) {
                if (item.type === 'vitals') await removeUnsyncedVital(item.id);
                else await removeUnsyncedIO(item.id);
                successCount++;
            } else {
                failCount++;
            }
        } catch (e) {
            failCount++;
        }

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
