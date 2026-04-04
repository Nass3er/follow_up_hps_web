const CACHE_NAME = 'hps-app-v2';
const urlsToCache = [
    './',
    './index.html',
    './vitals.html',
    './intake_output.html',
    './doctor-orders.html',
    './login.html',
    './settings.html',
    './sync.html',
    './assets/css/style.css',
    './assets/css/login.css',
    './assets/js/config.js',
    './assets/js/login.js',
    './assets/js/db.js',
    './assets/js/sync.js',
    './assets/js/vitals.js',
    './assets/js/intake_output.js',
    './assets/js/doctor_orders.js',
    './assets/js/settings.js',
    './icon.png',
    'https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap'
];

// Install Event: Caching Assets
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('SW: Pre-caching assets');
                return cache.addAll(urlsToCache);
            })
            .then(() => self.skipWaiting())
    );
});

// Activate Event: Cleanup Old Caches
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cache => {
                    if (cache !== CACHE_NAME) {
                        console.log('SW: Clearing old cache:', cache);
                        return caches.delete(cache);
                    }
                })
            );
        })
    );
});

// Fetch Event: Stale-While-Revalidate Strategy
self.addEventListener('fetch', event => {
    // Skip non-GET requests and API calls for this strategy
    if (event.request.method !== 'GET' || event.request.url.includes('/api/')) {
        return;
    }

    event.respondWith(
        caches.open(CACHE_NAME).then(cache => {
            return cache.match(event.request).then(response => {
                const fetchPromise = fetch(event.request).then(networkResponse => {
                    if (networkResponse && networkResponse.status === 200) {
                        cache.put(event.request, networkResponse.clone());
                    }
                    return networkResponse;
                }).catch(() => {
                    // Fail silently or handle specific offline fallback
                });
                return response || fetchPromise;
            });
        })
    );
});
