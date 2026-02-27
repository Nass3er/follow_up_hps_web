// sync.js - Offline sync queue manager
document.addEventListener('DOMContentLoaded', () => {
    checkSyncStatus();
    window.addEventListener('online', checkSyncStatus);
    window.addEventListener('offline', checkSyncStatus);
});

async function checkSyncStatus() {
    try {
        const unsynced = await getFromDB('unsynced_vitals');
        let badge = document.getElementById('sync-badge-container');
        if (!badge) {
            badge = document.createElement('div');
            badge.id = 'sync-badge-container';
            badge.style.cssText = 'position: fixed; bottom: 20px; right: 20px; z-index: 9999;';
            document.body.appendChild(badge);
        }

        if (unsynced && unsynced.length > 0) {
            badge.innerHTML = `
                <button onclick="performSync()" class="btn btn-primary" style="background:#e67e22; border:none; box-shadow: 0 4px 10px rgba(0,0,0,0.3); font-size:16px;">
                    🔄 لديك ${unsynced.length} سجل غير مزامن (اضغط للمزامنة)
                </button>
            `;
            badge.style.display = 'block';
        } else {
            badge.style.display = 'none';
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

async function performSync() {
    if (!navigator.onLine) {
        alert("أنت غير متصل بالإنترنت حالياً! يرجى الاتصال بالشبكة للمزامنة.");
        return;
    }

    // Disable button to prevent multiple clicks
    const btn = document.querySelector('#sync-badge-container button');
    if (btn) {
        btn.disabled = true;
        btn.innerText = "جاري المزامنة...";
    }

    const unsynced = await getFromDB('unsynced_vitals');
    if (!unsynced || unsynced.length === 0) return;

    let successCount = 0;
    let failCount = 0;

    for (let item of unsynced) {
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
                console.error("Failed to sync item", item.id, await res.text());
                failCount++;
            }
        } catch (e) {
            console.error("Network error syncing item", item.id, e);
            failCount++;
        }
    }

    if (successCount > 0) {
        let msg = `✅ تمت مزامنة ${successCount} سجل بنجاح!`;
        if (failCount > 0) msg += `\n❌ فشلت ${failCount} سجلات بسبب أخطاء من الخادم.`;
        alert(msg);
        checkSyncStatus();
        if (typeof loadAndShowTable === 'function') loadAndShowTable();
    } else {
        alert("⚠️ لم يتم مزامنة أي سجل، تأكد من اتصال الخادم.");
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = `🔄 لديك ${unsynced.length} سجل غير مزامن (اضغط للمزامنة)`;
        }
    }
}
