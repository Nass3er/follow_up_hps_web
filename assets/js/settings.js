// settings.js - Backup and Cache management

async function exportData() {
    try {
        const data = {};
        const stores = [
            'branches', 'admissions', 'nurses', 'vitals_history', 
            'patients_details', 'unsynced_vitals', 'io_history', 
            'unsynced_io', 'doctor_orders_history', 'unsynced_doctor_orders',
            'items_cache'
        ];
        for (const store of stores) {
            data[store] = await getFromDB(store) || [];
        }

        const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `HPS_Backup_${new Date().toISOString().slice(0, 10)}.json`;
        a.click();

        URL.revokeObjectURL(url);
        appAlert('✅ تم استخراج وحفظ النسخة الاحتياطية بنجاح!', 'success');
    } catch (e) {
        console.error("Backup error", e);
        appAlert('❌ تعذر إنشاء النسخة الاحتياطية.', 'error');
    }
}

function triggerImport() {
    document.getElementById('import-file').click();
}

async function importData(event) {
    const file = event.target.files[0];
    if (!file) return;

    const isConfirmed = await appConfirm('⚠️ إستيراد البيانات سيمسح البيانات المسجلة بالكامل ويستبدلها بالبيانات من الملف. هل أنت متأكد؟');

    if (!isConfirmed) {
        event.target.value = '';
        return;
    }

    const reader = new FileReader();
    reader.onload = async (e) => {
        try {
            const data = JSON.parse(e.target.result);
            const stores = [
                'branches', 'admissions', 'nurses', 'vitals_history', 
                'patients_details', 'unsynced_vitals', 'io_history', 
                'unsynced_io', 'doctor_orders_history', 'unsynced_doctor_orders',
                'items_cache'
            ];
            for (const store of stores) {
                if (data[store]) {
                    await saveToDB(store, data[store], true);
                }
            }
            appAlert('✅ تم استيراد البيانات بنجاح!', 'success');
        } catch (err) {
            console.error("Import error", err);
            appAlert('❌ الملف غير صالح أو تالف.', 'error');
        }
        event.target.value = ''; // Reset input
    };
    reader.readAsText(file);
}

async function clearCache() {
    const isConfirmed = await appConfirm('هل أنت متأكد من تنظيف الذاكرة المؤقتة المحفوظة؟ (لن يتم حذف السجلات المعلقة التي تنتظر المزامنة)');
    if (!isConfirmed) return;

    try {
        // We only clear history data
        await saveToDB('admissions', [], true);
        await saveToDB('vitals_history', [], true);
        await saveToDB('io_history', [], true);
        await saveToDB('doctor_orders_history', [], true);
        await saveToDB('patients_details', [], true);

        appAlert('✨ تم تنظيف الذاكرة المؤقتة بنجاح، التطبيق الآن أسرع وأخف!', 'success');
    } catch (e) {
        appAlert('❌ حدث خطأ أثناء تنظيف الذاكرة.', 'error');
    }
}
