// db.js - IndexedDB Helper for Offline First Architecture
const DB_NAME = 'HPS_Offline_DB';
const DB_VERSION = 4;

let dbInstance = null;

function initDB() {
    if (dbInstance) return Promise.resolve(dbInstance);

    return new Promise((resolve, reject) => {
        const request = window.indexedDB.open(DB_NAME, DB_VERSION);
        request.onupgradeneeded = (e) => {
            const db = e.target.result;
            if (!db.objectStoreNames.contains('branches')) db.createObjectStore('branches', { keyPath: 'branchNo' });
            if (!db.objectStoreNames.contains('admissions')) db.createObjectStore('admissions', { keyPath: 'docNo' });
            if (!db.objectStoreNames.contains('nurses')) db.createObjectStore('nurses', { keyPath: 'empNo' });
            if (!db.objectStoreNames.contains('vitals_history')) db.createObjectStore('vitals_history', { keyPath: 'cacheKey' });
            if (!db.objectStoreNames.contains('patients_details')) db.createObjectStore('patients_details', { keyPath: 'cacheKey' });
            if (!db.objectStoreNames.contains('unsynced_vitals')) db.createObjectStore('unsynced_vitals', { keyPath: 'id', autoIncrement: true });

            // Intake & Output Stores
            if (!db.objectStoreNames.contains('io_history')) db.createObjectStore('io_history', { keyPath: 'cacheKey' });
            if (!db.objectStoreNames.contains('unsynced_io')) db.createObjectStore('unsynced_io', { keyPath: 'id', autoIncrement: true });

            // Doctor Order Stores
            if (!db.objectStoreNames.contains('doctor_orders_history')) db.createObjectStore('doctor_orders_history', { keyPath: 'cacheKey' });
            if (!db.objectStoreNames.contains('unsynced_doctor_orders')) db.createObjectStore('unsynced_doctor_orders', { keyPath: 'id', autoIncrement: true });
            if (!db.objectStoreNames.contains('items_cache')) db.createObjectStore('items_cache', { keyPath: 'cacheKey' });
        };
        request.onsuccess = () => {
            dbInstance = request.result;
            resolve(dbInstance);
        };
        request.onerror = () => reject(request.error);
    });
}

function saveToDB(storeName, data, clear = true) {
    return initDB().then(db => {
        return new Promise((resolve, reject) => {
            const tx = db.transaction(storeName, 'readwrite');
            const store = tx.objectStore(storeName);
            if (clear) store.clear();
            if (Array.isArray(data)) {
                data.forEach(item => store.put(item));
            } else {
                store.put(data);
            }
            tx.oncomplete = () => resolve(true);
            tx.onerror = () => reject(tx.error);
        });
    });
}

function getFromDB(storeName, key = null) {
    return initDB().then(db => {
        return new Promise((resolve, reject) => {
            const tx = db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const req = key ? store.get(key) : store.getAll();
            req.onsuccess = () => resolve(req.result);
            req.onerror = () => reject(req.error);
        });
    });
}

function addUnsyncedVital(url, method, dto, isUpdate) {
    return saveToDB('unsynced_vitals', { url, method, dto, isUpdate, timestamp: new Date().getTime() }, false);
}

function removeUnsyncedVital(id) {
    return initDB().then(db => {
        return new Promise((resolve, reject) => {
            const tx = db.transaction('unsynced_vitals', 'readwrite');
            tx.objectStore('unsynced_vitals').delete(id);
            tx.oncomplete = () => resolve();
        });
    });
}

function updateUnsyncedVital(id, dto) {
    return getFromDB('unsynced_vitals', id).then(record => {
        if (record) {
            record.dto = dto;
            record.timestamp = new Date().getTime();
            return saveToDB('unsynced_vitals', record, false);
        }
    });
}

function addUnsyncedIO(url, method, dto, isUpdate) {
    return saveToDB('unsynced_io', { url, method, dto, isUpdate, timestamp: new Date().getTime() }, false);
}

function removeUnsyncedIO(id) {
    return initDB().then(db => {
        return new Promise((resolve, reject) => {
            const tx = db.transaction('unsynced_io', 'readwrite');
            tx.objectStore('unsynced_io').delete(id);
            tx.oncomplete = () => resolve();
        });
    });
}

function updateUnsyncedIO(id, dto) {
    return getFromDB('unsynced_io', id).then(record => {
        if (record) {
            record.dto = dto;
            record.timestamp = new Date().getTime();
            return saveToDB('unsynced_io', record, false);
        }
    });
}

function addUnsyncedDoctorOrder(url, method, dto, isUpdate) {
    return saveToDB('unsynced_doctor_orders', { url, method, dto, isUpdate, timestamp: new Date().getTime() }, false);
}

function removeUnsyncedDoctorOrder(id) {
    return initDB().then(db => {
        return new Promise((resolve, reject) => {
            const tx = db.transaction('unsynced_doctor_orders', 'readwrite');
            tx.objectStore('unsynced_doctor_orders').delete(id);
            tx.oncomplete = () => resolve();
        });
    });
}

function updateUnsyncedDoctorOrder(id, dto) {
    return getFromDB('unsynced_doctor_orders', id).then(record => {
        if (record) {
            record.dto = dto;
            record.timestamp = new Date().getTime();
            return saveToDB('unsynced_doctor_orders', record, false);
        }
    });
}
